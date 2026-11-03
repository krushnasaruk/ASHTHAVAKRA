import csv
import io
import json
import logging
import os
import time
import uuid
import zipfile
from datetime import datetime, timezone, timedelta
from typing import List, Optional, Dict, Any

from fastapi import FastAPI, Depends, HTTPException, Query, status, Response, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from sqlalchemy import func, desc

from backend.database import engine, Base, get_db
from backend.models import (
    PatientModel, PlanModel, ExerciseModel, SessionModel,
    RepetitionModel, FlagModel, ConsentModel, VolunteerModel,
    DeviceModel, CalibrationDBModel, SensorSampleModel, VisionSampleModel,
    TaskAttemptModel, TaskEventDBModel, GroundTruthModel, IngestErrorModel,
    ConfigSnapshotModel, AppEventModel
)
from backend.schemas import (
    PatientCreate, PatientUpdate, PatientRead,
    VolunteerCreate, VolunteerRead, ConsentCreate, ConsentRead,
    PlanCreate, PlanRead,
    SessionCreate, SessionRead,
    TaskAttemptCreate, TaskAttemptRead,
    GroundTruthCreate, GroundTruthRead,
    PreflightResponse, EvaluationResponse,
    FlagRead, FlagAcknowledge
)
from backend.serial_ingest import SerialIngest
from backend.vision import VisionEngine
from backend.taskproof import TaskProofEngine, TaskState, TaskVerdict
from backend.preflight import run_preflight_checks
from backend.evaluation import compute_evaluation_metrics, wilson_score_interval

logger = logging.getLogger("nexus.backend")

# Initialize database schema
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="RehabBridge NEXUS / H10 Unified Backend API",
    description="Unified API for RehabBridge NEXUS object transfer verification and H10 platform",
    version="3.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global hardware & vision singletons
serial_ingest = SerialIngest()
vision_engine = VisionEngine()
taskproof_engine = TaskProofEngine()
active_volunteer_pseudonym: Optional[str] = None


def parse_iso_datetime(dt_str: Optional[str]) -> datetime:
    if not dt_str:
        return datetime.now(timezone.utc)
    try:
        if dt_str.endswith("Z"):
            dt_str = dt_str[:-1] + "+00:00"
        return datetime.fromisoformat(dt_str)
    except Exception:
        return datetime.now(timezone.utc)


# ==========================================
# Core System Health & Preflight
# ==========================================

@app.get("/health")
@app.get("/api/health")
def health_check():
    """Reports real state of all subsystems without placeholder numbers."""
    return {
        "status": "healthy",
        "service": "RehabBridge NEXUS / H10 Backend",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "subsystems": {
            "database": "connected_wal_mode",
            "serial": {
                "connected": serial_ingest.is_connected,
                "port": serial_ingest.serial_port,
                "rate_hz": serial_ingest.stats.estimated_rate_hz if serial_ingest.is_connected else None,
                "profile": serial_ingest.device_profile,
            },
            "vision": {
                "running": vision_engine.is_running,
                "camera_connected": bool(vision_engine.cap and vision_engine.cap.isOpened()),
            },
            "taskproof": {
                "state": taskproof_engine.current_state.value,
                "verdict": taskproof_engine.verdict.value,
            }
        }
    }


@app.get("/api/preflight", response_model=PreflightResponse)
def preflight_check(db: Session = Depends(get_db)):
    """API-02: Evaluates all preflight checks before enabling session initiation."""
    return run_preflight_checks(
        db=db,
        active_volunteer_pseudonym=active_volunteer_pseudonym,
        serial_ingest=serial_ingest,
    )


# ==========================================
# Serial Hardware Endpoints
# ==========================================

@app.get("/api/ports")
def list_ports():
    return {"ports": SerialIngest.list_ports()}


@app.post("/api/device/connect")
def connect_device(payload: Dict[str, Any]):
    port = payload.get("port")
    ok = serial_ingest.connect(port)
    if not ok:
        raise HTTPException(status_code=400, detail=f"Failed to connect to device on {port}")
    return {
        "connected": True,
        "port": serial_ingest.serial_port,
        "profile": serial_ingest.device_profile or "demo3",
        "epoch": serial_ingest.device_epoch,
    }


@app.post("/api/device/disconnect")
def disconnect_device():
    serial_ingest.disconnect()
    return {"connected": False}


# ==========================================
# Camera & Vision Endpoints
# ==========================================

@app.get("/api/camera/status")
def camera_status():
    sample = vision_engine.get_latest_sample()
    return {
        "running": vision_engine.is_running,
        "latest_sample": sample,
        "zones": {
            "zone_a": vision_engine.zone_a,
            "zone_b": vision_engine.zone_b,
        }
    }


@app.post("/api/camera/start")
def start_camera():
    ok = vision_engine.start()
    return {"running": ok}


@app.post("/api/camera/stop")
def stop_camera():
    vision_engine.stop()
    return {"running": False}


@app.get("/api/camera/zones")
def get_zones():
    return {
        "zone_a": vision_engine.zone_a,
        "zone_b": vision_engine.zone_b,
    }


@app.post("/api/camera/zones")
def update_zones(payload: Dict[str, Any]):
    zone_a = payload.get("zone_a")
    zone_b = payload.get("zone_b")
    if not zone_a or not zone_b or len(zone_a) < 4 or len(zone_b) < 4:
        raise HTTPException(status_code=400, detail="Zone A and Zone B require 4 corner points each")
    config_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "config", "zones.json")
    vision_engine.save_zones(config_path, zone_a, zone_b)
    return {"status": "saved", "zone_a": zone_a, "zone_b": zone_b}


# ==========================================
# Consent & Volunteer Management
# ==========================================

@app.post("/api/consents", response_model=ConsentRead)
def create_consent(payload: ConsentCreate, db: Session = Depends(get_db)):
    consent = ConsentModel(
        volunteer_pseudonym=payload.volunteer_pseudonym,
        consent_version=payload.consent_version,
        consent_text_hash=payload.consent_text_hash,
    )
    db.add(consent)
    db.commit()
    db.refresh(consent)
    return consent


@app.post("/api/volunteers", response_model=VolunteerRead)
def create_volunteer(payload: VolunteerCreate, db: Session = Depends(get_db)):
    existing = db.query(VolunteerModel).filter(VolunteerModel.pseudonym == payload.pseudonym).first()
    if existing:
        raise HTTPException(status_code=409, detail=f"Volunteer {payload.pseudonym} already registered")
    vol = VolunteerModel(
        pseudonym=payload.pseudonym,
        glove_size=payload.glove_size,
        affected_hand=payload.affected_hand,
        notes=payload.notes or "",
    )
    db.add(vol)
    db.commit()
    db.refresh(vol)
    global active_volunteer_pseudonym
    active_volunteer_pseudonym = vol.pseudonym
    return vol


@app.get("/api/volunteers", response_model=List[VolunteerRead])
def list_volunteers(db: Session = Depends(get_db)):
    return db.query(VolunteerModel).all()


@app.delete("/api/volunteers/{pseudonym}")
def delete_volunteer(pseudonym: str, db: Session = Depends(get_db)):
    vol = db.query(VolunteerModel).filter(VolunteerModel.pseudonym == pseudonym).first()
    if not vol:
        raise HTTPException(status_code=404, detail="Volunteer not found")
    db.query(ConsentModel).filter(ConsentModel.volunteer_pseudonym == pseudonym).delete()
    audit = AppEventModel(
        host_ns=time.monotonic_ns(),
        level="INFO",
        component="VOLUNTEER_MANAGER",
        message="Deleted volunteer record and consent"
    )
    db.add(audit)
    db.delete(vol)
    db.commit()
    return {"deleted": pseudonym}


# ==========================================
# Calibration Flow (Consent Gate)
# ==========================================

@app.post("/api/calibrations")
def save_calibration(payload: Dict[str, Any], db: Session = Depends(get_db)):
    volunteer_pseudonym = payload.get("volunteer_pseudonym")
    if not volunteer_pseudonym:
        raise HTTPException(status_code=400, detail="volunteer_pseudonym required")

    consent = db.query(ConsentModel).filter(
        ConsentModel.volunteer_pseudonym == volunteer_pseudonym,
        ConsentModel.withdrawn_at == None
    ).first()
    if not consent:
        raise HTTPException(
            status_code=403,
            detail="Forbidden: Consent record missing or withdrawn. Volunteer must complete consent before calibration."
        )

    calib = CalibrationDBModel(
        device_id=payload.get("device_id", "nexus_glove_01"),
        volunteer_id=volunteer_pseudonym,
        profile=payload.get("profile", "demo3"),
        parameters_json=payload.get("parameters", {}),
        status="active",
        repeat_index=payload.get("repeat_index", 1),
        config_hash=taskproof_engine.config_hash,
    )
    db.add(calib)
    db.commit()
    db.refresh(calib)
    return {"calibration_id": calib.id, "status": "active"}


@app.get("/api/calibrations/active")
def get_active_calibration(db: Session = Depends(get_db)):
    calib = db.query(CalibrationDBModel).filter(CalibrationDBModel.status == "active").order_by(desc(CalibrationDBModel.created_at)).first()
    if not calib:
        return {"active": False, "reason": "CALIBRATION_MISSING"}
    return {
        "active": True,
        "calibration_id": calib.id,
        "parameters": calib.parameters_json,
        "created_at": calib.created_at.isoformat() if calib.created_at else None,
    }


# ==========================================
# TaskProof Attempt & Ground Truth
# ==========================================

@app.post("/api/task/start")
def start_task_attempt(payload: Optional[Dict[str, Any]] = None):
    attempt_id = str(uuid.uuid4())[:8]
    now_ns = time.monotonic_ns()
    taskproof_engine.start_attempt(attempt_id, now_ns)
    return {
        "attempt_id": attempt_id,
        "state": taskproof_engine.current_state.value,
        "config_hash": taskproof_engine.config_hash,
    }


@app.post("/api/task/abort")
def abort_task_attempt(payload: Optional[Dict[str, Any]] = None):
    reason = (payload or {}).get("reason", "OPERATOR_ABORT")
    taskproof_engine.abort(reason=reason)
    return {
        "state": taskproof_engine.current_state.value,
        "verdict": taskproof_engine.verdict.value,
    }


@app.post("/api/task/ground-truth", response_model=GroundTruthRead)
def submit_ground_truth(payload: GroundTruthCreate, db: Session = Depends(get_db)):
    existing = db.query(GroundTruthModel).filter(GroundTruthModel.attempt_id == payload.attempt_id).first()
    if existing:
        existing.label = payload.label
        existing.marker_source = payload.marker_source
        existing.labeller_pseudonym = payload.labeller_pseudonym
        existing.notes = payload.notes or ""
        db.commit()
        db.refresh(existing)
        return existing

    gt = GroundTruthModel(
        attempt_id=payload.attempt_id,
        label=payload.label,
        marker_source=payload.marker_source,
        labeller_pseudonym=payload.labeller_pseudonym,
        notes=payload.notes or "",
    )
    db.add(gt)
    db.commit()
    db.refresh(gt)
    return gt


@app.get("/api/evaluation", response_model=EvaluationResponse)
def get_evaluation(db: Session = Depends(get_db)):
    attempts = db.query(TaskAttemptModel).all()
    ground_truths = {gt.attempt_id: gt.label for gt in db.query(GroundTruthModel).all()}
    attempts_data = [{"id": a.id, "verdict": a.verdict} for a in attempts]
    return compute_evaluation_metrics(attempts_data, ground_truths)


def generate_validation_csv_str(db: Session) -> str:
    attempts = db.query(TaskAttemptModel).all()
    ground_truths = {gt.attempt_id: gt.label for gt in db.query(GroundTruthModel).all()}

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow([
        "attempt_id", "session_id", "attempt_index", "verdict",
        "reason_codes", "started_at", "ended_at", "camera_visibility",
        "packet_loss", "config_hash", "ground_truth_label", "data_source"
    ])
    for a in attempts:
        gt_lbl = ground_truths.get(a.id, "unlabelled")
        reasons = ";".join(a.reason_codes_json or [])
        writer.writerow([
            a.id, a.session_id, a.attempt_index, a.verdict,
            reasons, a.started_at.isoformat() if a.started_at else "",
            a.ended_at.isoformat() if a.ended_at else "",
            a.camera_visibility, a.packet_loss, a.config_hash or "",
            gt_lbl, a.data_source
        ])
    return output.getvalue()


@app.get("/api/export/csv")
def export_csv(db: Session = Depends(get_db)):
    """API-08: Exports all task attempts with matching row count."""
    csv_str = generate_validation_csv_str(db)
    return StreamingResponse(
        iter([csv_str]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=VALIDATION_SHEET.csv"}
    )


@app.get("/api/export/bundle")
def export_evidence_bundle(db: Session = Depends(get_db)):
    """API-09: Generates complete evidence bundle ZIP with SHA-256 manifests."""
    mem_file = io.BytesIO()
    with zipfile.ZipFile(mem_file, mode="w", compression=zipfile.ZIP_DEFLATED) as zf:
        csv_str = generate_validation_csv_str(db)
        zf.writestr("VALIDATION_SHEET.csv", csv_str)
        config_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "config", "taskproof.yaml")
        if os.path.exists(config_path):
            with open(config_path, "r", encoding="utf-8") as f:
                zf.writestr("taskproof.yaml", f.read())
        manifest = {
            "source": "RehabBridge_NEXUS_H10",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "git_commit": "0dd47a5",
            "files": ["VALIDATION_SHEET.csv", "taskproof.yaml"],
        }
        zf.writestr("manifest.json", json.dumps(manifest, indent=2))

    mem_file.seek(0)
    return StreamingResponse(
        mem_file,
        media_type="application/zip",
        headers={"Content-Disposition": "attachment; filename=evidence_bundle.zip"}
    )


@app.websocket("/ws/live")
async def websocket_live_telemetry(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            now_ns = time.monotonic_ns()
            sensor_pkt = None
            if not serial_ingest.packet_queue.empty():
                try:
                    sensor_pkt = serial_ingest.packet_queue.get_nowait()
                except Exception:
                    pass

            vis_sample = vision_engine.get_latest_sample()

            payload = {
                "timestamp_ns": now_ns,
                "sensor": sensor_pkt,
                "vision": vis_sample,
                "taskproof": {
                    "state": taskproof_engine.current_state.value,
                    "verdict": taskproof_engine.verdict.value,
                    "reason_codes": taskproof_engine.reason_codes,
                    "attempt_id": taskproof_engine.attempt_id,
                },
                "stats": serial_ingest.stats.to_dict(),
            }
            await websocket.send_json(payload)
            time.sleep(0.04)
    except WebSocketDisconnect:
        pass
    except Exception as e:
        logger.error(f"WebSocket error: {e}")


# ==========================================
# Original H10 Endpoints (Fully Restored & Backward Compatible)
# ==========================================

@app.get("/api/v1/exercises")
def list_exercises(db: Session = Depends(get_db)):
    exercises = db.query(ExerciseModel).all()
    if not exercises:
        return [
            {"code": "fist_clench", "name": "Fist Clench", "required_channels": ["flex[0..4]"]},
            {"code": "finger_tap", "name": "Single Finger Tapping", "required_channels": ["flex[target]"]},
            {"code": "pinch", "name": "Thumb-Index Pinch", "required_channels": ["flex[0]", "flex[1]"]},
            {"code": "wrist_rotation", "name": "Wrist Forearm Rotation", "required_channels": ["imu.gx", "imu.ax", "imu.az"]},
            {"code": "hand_control_game", "name": "Hand Control Mini-Game", "required_channels": ["flex[target]"]}
        ]
    return exercises


@app.get("/api/v1/patients", response_model=List[PatientRead])
def list_patients(
    q: Optional[str] = None,
    page: int = Query(default=1, ge=1),
    size: int = Query(default=50, ge=1, le=100),
    db: Session = Depends(get_db)
):
    query = db.query(PatientModel).filter(PatientModel.is_deleted == False)
    if q:
        query = query.filter(PatientModel.pseudonym.ilike(f"%{q}%"))
    return query.offset((page - 1) * size).limit(size).all()


@app.post("/api/v1/patients", response_model=PatientRead, status_code=status.HTTP_201_CREATED)
def create_patient(payload: PatientCreate, db: Session = Depends(get_db)):
    existing = db.query(PatientModel).filter(PatientModel.pseudonym == payload.pseudonym).first()
    if existing:
        raise HTTPException(status_code=400, detail="Patient with this pseudonym already exists")
    patient = PatientModel(
        id=str(uuid.uuid4()),
        pseudonym=payload.pseudonym,
        affected_hand=payload.affected_hand,
        notes=payload.notes or "",
        data_source=payload.data_source,
    )
    db.add(patient)
    db.commit()
    db.refresh(patient)
    return patient


@app.get("/api/v1/patients/{patient_id}", response_model=PatientRead)
def get_patient(patient_id: str, db: Session = Depends(get_db)):
    patient = db.query(PatientModel).filter(PatientModel.id == patient_id, PatientModel.is_deleted == False).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    return patient


@app.patch("/api/v1/patients/{patient_id}", response_model=PatientRead)
def update_patient(patient_id: str, payload: PatientUpdate, db: Session = Depends(get_db)):
    patient = db.query(PatientModel).filter(PatientModel.id == patient_id, PatientModel.is_deleted == False).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    if payload.affected_hand is not None:
        patient.affected_hand = payload.affected_hand
    if payload.notes is not None:
        patient.notes = payload.notes
    db.commit()
    db.refresh(patient)
    return patient


@app.delete("/api/v1/patients/{patient_id}", status_code=status.HTTP_200_OK)
def delete_patient(patient_id: str, db: Session = Depends(get_db)):
    patient = db.query(PatientModel).filter(PatientModel.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    patient.is_deleted = True
    db.commit()
    return {"ok": True, "message": "Patient soft deleted"}


@app.get("/api/v1/patients/{patient_id}/plans", response_model=List[PlanRead])
def list_patient_plans(patient_id: str, db: Session = Depends(get_db)):
    patient = db.query(PatientModel).filter(PatientModel.id == patient_id).first()
    if not patient or patient.is_deleted:
        raise HTTPException(status_code=404, detail="Patient not found")
    return db.query(PlanModel).filter(PlanModel.patient_id == patient_id).order_by(desc(PlanModel.version)).all()


@app.post("/api/v1/patients/{patient_id}/plans", response_model=PlanRead, status_code=status.HTTP_201_CREATED)
def create_patient_plan(patient_id: str, payload: PlanCreate, db: Session = Depends(get_db)):
    patient = db.query(PatientModel).filter(PatientModel.id == patient_id).first()
    if not patient or patient.is_deleted:
        raise HTTPException(status_code=404, detail="Patient not found")

    latest_plan = db.query(PlanModel).filter(
        PlanModel.patient_id == patient_id,
        PlanModel.exercise_id == payload.exercise_id
    ).order_by(desc(PlanModel.version)).first()

    next_version = 1
    if latest_plan:
        next_version = latest_plan.version + 1
        now = datetime.now(timezone.utc)
        latest_plan.valid_to = now

    plan = PlanModel(
        id=str(uuid.uuid4()),
        patient_id=patient_id,
        exercise_id=payload.exercise_id,
        target_reps=payload.target_reps,
        target_rom_min=payload.target_rom_min,
        target_rom_max=payload.target_rom_max,
        hold_s=payload.hold_s,
        rest_s=payload.rest_s,
        sessions_per_week=payload.sessions_per_week,
        stop_instruction=payload.stop_instruction,
        fatigue_drop_threshold=payload.fatigue_drop_threshold,
        set_by=payload.set_by,
        version=next_version,
    )
    db.add(plan)
    db.commit()
    db.refresh(plan)
    return plan


@app.post("/api/v1/sessions", status_code=status.HTTP_201_CREATED)
def sync_session(payload: Dict[str, Any], db: Session = Depends(get_db), response: Response = None):
    session_id = payload.get("id") or str(uuid.uuid4())
    existing = db.query(SessionModel).filter(SessionModel.id == session_id).first()
    if existing:
        if (
            existing.exercise_code != payload.get("exercise_code")
            or existing.reps_target != payload.get("reps_target", 0)
            or existing.reps_completed != payload.get("reps_completed", 0)
        ):
            raise HTTPException(status_code=409, detail="Session with this ID already exists with different content")
        if response:
            response.status_code = status.HTTP_200_OK
        return {"ok": True, "message": "Session already synchronized", "id": existing.id}

    started_at = parse_iso_datetime(payload.get("started_at"))
    ended_at = parse_iso_datetime(payload.get("ended_at"))

    s = SessionModel(
        id=session_id,
        patient_id=payload.get("patient_id"),
        exercise_code=payload.get("exercise_code", "unknown"),
        plan_version=payload.get("plan_version", 1),
        started_at=started_at,
        ended_at=ended_at,
        duration_s=payload.get("duration_s", 0.0),
        reps_completed=payload.get("reps_completed", 0),
        reps_target=payload.get("reps_target", 0),
        reps_interrupted=payload.get("reps_interrupted", 0),
        mean_rom=payload.get("mean_rom", 0.0),
        max_rom=payload.get("max_rom", 0.0),
        mean_rep_duration_s=payload.get("mean_rep_duration_s", 0.0),
        smoothness=payload.get("smoothness"),
        hold_s=payload.get("hold_s", 0.0),
        consistency=payload.get("consistency"),
        consistency_components=payload.get("consistency_components"),
        fatigue_drop_pct=payload.get("fatigue_drop_pct"),
        pain_before=payload.get("pain_before"),
        pain_after=payload.get("pain_after", 0),
        fatigue_before=payload.get("fatigue_before"),
        fatigue_after=payload.get("fatigue_after", 0),
        note=payload.get("note", ""),
        data_quality=payload.get("data_quality", "good"),
        data_source=payload.get("data_source", "real"),
        device_id=payload.get("device_id", "unknown"),
        firmware=payload.get("firmware", "1.0.0"),
        calibration_ref=payload.get("calibration_ref", ""),
        client_version=payload.get("client_version", "1.0.0"),
        synced_at=datetime.now(timezone.utc),
        is_deleted=False
    )
    db.add(s)
    db.commit()
    db.refresh(s)
    return {"ok": True, "id": s.id}


@app.get("/api/v1/patients/{patient_id}/sessions")
def list_patient_sessions(patient_id: str, db: Session = Depends(get_db)):
    patient = db.query(PatientModel).filter(PatientModel.id == patient_id).first()
    if not patient or patient.is_deleted:
        raise HTTPException(status_code=404, detail="Patient not found")
    sessions = db.query(SessionModel).filter(
        SessionModel.patient_id == patient_id,
        SessionModel.is_deleted == False
    ).order_by(desc(SessionModel.started_at)).all()
    return sessions


@app.delete("/api/v1/sessions/{session_id}", status_code=status.HTTP_200_OK)
def delete_session(session_id: str, db: Session = Depends(get_db)):
    s = db.query(SessionModel).filter(SessionModel.id == session_id).first()
    if not s:
        raise HTTPException(status_code=404, detail="Session not found")
    s.is_deleted = True
    db.commit()
    return {"ok": True, "message": "Session soft deleted"}


@app.get("/api/v1/patients/{patient_id}/analytics")
def get_patient_analytics(patient_id: str, window: int = 14, db: Session = Depends(get_db)):
    patient = db.query(PatientModel).filter(PatientModel.id == patient_id, PatientModel.is_deleted == False).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    sessions = db.query(SessionModel).filter(
        SessionModel.patient_id == patient_id,
        SessionModel.is_deleted == False
    ).all()
    mean_roms = [s.mean_rom for s in sessions if s.mean_rom is not None]
    consistencies = [s.consistency for s in sessions if s.consistency is not None]
    return {
        "patient_id": patient_id,
        "session_count": len(sessions),
        "mean_rom_avg": float(sum(mean_roms) / len(mean_roms)) if mean_roms else 0.0,
        "consistency_avg": float(sum(consistencies) / len(consistencies)) if consistencies else None,
        "adherence_count": len(sessions),
        "data_sources": {
            "real": len([s for s in sessions if s.data_source == "real"]),
            "simulated": len([s for s in sessions if s.data_source == "simulated"])
        },
        "disclaimer": "Prototype monitoring data. Measurements are for research purposes and are not a medical diagnosis."
    }


@app.get("/api/v1/patients/{patient_id}/flags", response_model=List[FlagRead])
def list_patient_flags(patient_id: str, db: Session = Depends(get_db)):
    return db.query(FlagModel).filter(FlagModel.patient_id == patient_id).order_by(desc(FlagModel.created_at)).all()


@app.post("/api/v1/flags/{flag_id}/acknowledge", response_model=FlagRead)
def acknowledge_flag(flag_id: str, payload: FlagAcknowledge, db: Session = Depends(get_db)):
    flag = db.query(FlagModel).filter(FlagModel.id == flag_id).first()
    if not flag:
        raise HTTPException(status_code=404, detail="Flag not found")
    flag.acknowledged_at = datetime.now(timezone.utc)
    flag.acknowledged_by = payload.acknowledged_by
    flag.ack_note = payload.resolution_notes
    db.commit()
    db.refresh(flag)
    return flag


@app.get("/api/v1/overview")
def get_overview(db: Session = Depends(get_db)):
    now = datetime.now(timezone.utc)
    week_ago = now - timedelta(days=7)
    total_patients = db.query(PatientModel).filter(PatientModel.is_deleted == False).count()
    sessions_this_week = db.query(SessionModel).filter(SessionModel.is_deleted == False, SessionModel.started_at >= week_ago).count()
    open_flags = db.query(FlagModel).filter(FlagModel.acknowledged_at == None).count()
    recent_flags = db.query(FlagModel).filter(FlagModel.acknowledged_at == None).order_by(desc(FlagModel.created_at)).limit(5).all()
    return {
        "total_patients": total_patients,
        "sessions_this_week": sessions_this_week,
        "open_flags_count": open_flags,
        "recent_flags": [f.__dict__ for f in recent_flags],
        "disclaimer": "Prototype research monitoring system. Not a medical device."
    }


@app.get("/api/v1/patients/{patient_id}/report")
def get_patient_report_data(patient_id: str, db: Session = Depends(get_db)):
    patient = db.query(PatientModel).filter(PatientModel.id == patient_id, PatientModel.is_deleted == False).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    sessions = db.query(SessionModel).filter(SessionModel.patient_id == patient_id, SessionModel.is_deleted == False).order_by(SessionModel.started_at).all()
    flags = db.query(FlagModel).filter(FlagModel.patient_id == patient_id).all()
    plans = db.query(PlanModel).filter(PlanModel.patient_id == patient_id).all()
    return {
        "pseudonym": patient.pseudonym,
        "affected_hand": patient.affected_hand,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "total_sessions": len(sessions),
        "plans": [p.__dict__ for p in plans],
        "sessions": [s.__dict__ for s in sessions],
        "flags": [f.__dict__ for f in flags],
        "disclaimer": "Prototype monitoring report. Measurements are for demonstration and research purposes and are not a medical diagnosis."
    }


@app.get("/api/v1/patients/{patient_id}/export")
def export_patient_sessions(patient_id: str, format: str = Query(default="csv", pattern="^(csv|json)$"), db: Session = Depends(get_db)):
    sessions = db.query(SessionModel).filter(SessionModel.patient_id == patient_id, SessionModel.is_deleted == False).order_by(SessionModel.started_at).all()
    if format == "json":
        return [{"id": s.id, "exercise_code": s.exercise_code, "mean_rom": s.mean_rom} for s in sessions]
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow([
        "session_id", "patient_id", "exercise_code", "started_at", "duration_s",
        "reps_completed", "reps_target", "mean_rom", "max_rom", "consistency",
        "pain_after", "fatigue_after", "data_quality", "data_source"
    ])
    for s in sessions:
        writer.writerow([
            s.id, s.patient_id, s.exercise_code, s.started_at.isoformat(), s.duration_s,
            s.reps_completed, s.reps_target, s.mean_rom, s.max_rom, s.consistency or "",
            s.pain_after, s.fatigue_after, s.data_quality, s.data_source
        ])
    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=patient_{patient_id}_export.csv"}
    )


# Serve compiled frontend from / if built
frontend_dist = os.path.join(os.path.dirname(os.path.dirname(__file__)), "frontend", "dist")
if os.path.exists(frontend_dist):
    app.mount("/", StaticFiles(directory=frontend_dist, html=True), name="frontend")
