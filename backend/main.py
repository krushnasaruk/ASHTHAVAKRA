import io
import csv
import json
import uuid
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
from fastapi import FastAPI, Depends, HTTPException, Query, status, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from sqlalchemy import func, desc

from backend.database import engine, Base, get_db
from backend.models import (
    PatientModel, PlanModel, ExerciseModel, SessionModel,
    RepetitionModel, FlagModel, CalibrationModel
)
from backend.schemas import (
    PatientCreate, PatientUpdate, PatientRead,
    PlanCreate, PlanRead,
    SessionCreate, SessionRead,
    FlagRead, FlagAcknowledge
)

# Initialize database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="H10 Rehabilitation Monitoring API",
    description="Backend API for H10 AI-assisted hand rehabilitation research prototype",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "service": "H10 Rehabilitation Backend"
    }


# --- Exercise Endpoints ---

@app.get("/api/v1/exercises")
def list_exercises(db: Session = Depends(get_db)):
    exercises = db.query(ExerciseModel).all()
    if not exercises:
        # Return default 5 exercises
        return [
            {"code": "fist_clench", "name": "Fist Clench", "required_channels": ["flex[0..4]"]},
            {"code": "finger_tap", "name": "Single Finger Tapping", "required_channels": ["flex[target]"]},
            {"code": "pinch", "name": "Thumb-Index Pinch", "required_channels": ["flex[0]", "flex[1]"]},
            {"code": "wrist_rotation", "name": "Wrist Forearm Rotation", "required_channels": ["imu.gx", "imu.ax", "imu.az"]},
            {"code": "hand_control_game", "name": "Hand Control Mini-Game", "required_channels": ["flex[target]"]}
        ]
    return exercises


# --- Patient Endpoints ---

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
    patient.is_deleted = True # Soft delete
    db.commit()
    return {"ok": True, "message": "Patient soft deleted"}


# --- Plan Endpoints ---

@app.get("/api/v1/patients/{patient_id}/plans", response_model=List[PlanRead])
def list_patient_plans(patient_id: str, db: Session = Depends(get_db)):
    # Verify patient exists
    patient = db.query(PatientModel).filter(PatientModel.id == patient_id, PatientModel.is_deleted == False).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    return db.query(PlanModel).filter(PlanModel.patient_id == patient_id).order_by(desc(PlanModel.version)).all()


@app.post("/api/v1/patients/{patient_id}/plans", response_model=PlanRead, status_code=status.HTTP_201_CREATED)
def create_patient_plan(patient_id: str, payload: PlanCreate, db: Session = Depends(get_db)):
    patient = db.query(PatientModel).filter(PatientModel.id == patient_id, PatientModel.is_deleted == False).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    # Find highest current version
    highest = db.query(func.max(PlanModel.version)).filter(PlanModel.patient_id == patient_id, PlanModel.exercise_id == payload.exercise_id).scalar()
    new_version = (highest or 0) + 1

    # Invalidate previous version if any
    prev_plans = db.query(PlanModel).filter(PlanModel.patient_id == patient_id, PlanModel.exercise_id == payload.exercise_id, PlanModel.valid_to == None).all()
    now = datetime.utcnow()
    for p in prev_plans:
        p.valid_to = now

    new_plan = PlanModel(
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
        valid_from=now,
        valid_to=None,
        set_by=payload.set_by,
        version=new_version
    )
    db.add(new_plan)
    db.commit()
    db.refresh(new_plan)
    return new_plan


# --- Session Endpoints (Idempotent Sync) ---

@app.post("/api/v1/sessions", response_model=SessionRead, status_code=status.HTTP_201_CREATED)
def sync_session(payload: SessionCreate, response: Response, db: Session = Depends(get_db)):
    # 1. Idempotency Check
    existing = db.query(SessionModel).filter(SessionModel.id == payload.id).first()
    if existing:
        # Check if identical
        if (existing.patient_id == payload.patient_id and
            existing.exercise_code == payload.exercise_code and
            abs(existing.mean_rom - payload.mean_rom) < 1e-4 and
            existing.reps_completed == payload.reps_completed):
            # Identical resubmission -> return 200 with existing
            response.status_code = status.HTTP_200_OK
            return existing
        else:
            # Different content with same ID -> 409 Conflict
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Conflict: Session with ID {payload.id} already exists with different contents"
            )

    # 2. Patient Isolation check
    patient = db.query(PatientModel).filter(PatientModel.id == payload.patient_id, PatientModel.is_deleted == False).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient does not exist or is deleted")

    session_obj = SessionModel(
        id=payload.id,
        patient_id=payload.patient_id,
        exercise_code=payload.exercise_code,
        plan_version=payload.plan_version,
        started_at=payload.started_at,
        ended_at=payload.ended_at,
        duration_s=payload.duration_s,
        reps_completed=payload.reps_completed,
        reps_target=payload.reps_target,
        reps_interrupted=payload.reps_interrupted,
        mean_rom=payload.mean_rom,
        max_rom=payload.max_rom,
        mean_rep_duration_s=payload.mean_rep_duration_s,
        smoothness=payload.smoothness,
        hold_s=payload.hold_s,
        consistency=payload.consistency,
        consistency_components=payload.consistency_components,
        fatigue_drop_pct=payload.fatigue_drop_pct,
        pain_before=payload.pain_before,
        pain_after=payload.pain_after,
        fatigue_before=payload.fatigue_before,
        fatigue_after=payload.fatigue_after,
        note=payload.note or "",
        data_quality=payload.data_quality,
        data_source=payload.data_source,
        device_id=payload.device_id,
        firmware=payload.firmware,
        calibration_ref=payload.calibration_ref,
        model_version=payload.model_version,
        client_version=payload.client_version,
        created_at=payload.created_at,
        received_at=datetime.utcnow(),
        is_deleted=False
    )
    db.add(session_obj)

    # Add repetitions
    for r in payload.repetitions:
        rep_obj = RepetitionModel(
            id=r.id or str(uuid.uuid4()),
            session_id=payload.id,
            index=r.index,
            start_ms=r.start_ms,
            end_ms=r.end_ms,
            duration_s=r.duration_s,
            peak=r.peak,
            mean=r.mean,
            min=r.min,
            rom=r.rom,
            hold_s=r.hold_s,
            smoothness=r.smoothness,
            quality=r.quality,
            status=r.status,
            reject_reason=r.reject_reason
        )
        db.add(rep_obj)

    db.commit()
    db.refresh(session_obj)
    return session_obj


@app.get("/api/v1/patients/{patient_id}/sessions", response_model=List[SessionRead])
def list_patient_sessions(
    patient_id: str,
    exercise: Optional[str] = None,
    source: Optional[str] = None,
    page: int = Query(default=1, ge=1),
    size: int = Query(default=50, ge=1, le=100),
    db: Session = Depends(get_db)
):
    query = db.query(SessionModel).filter(
        SessionModel.patient_id == patient_id,
        SessionModel.is_deleted == False
    )
    if exercise:
        query = query.filter(SessionModel.exercise_code == exercise)
    if source:
        query = query.filter(SessionModel.data_source == source)

    return query.order_by(desc(SessionModel.started_at)).offset((page - 1) * size).limit(size).all()


@app.get("/api/v1/sessions/{session_id}")
def get_session_detail(session_id: str, db: Session = Depends(get_db)):
    session_obj = db.query(SessionModel).filter(SessionModel.id == session_id, SessionModel.is_deleted == False).first()
    if not session_obj:
        raise HTTPException(status_code=404, detail="Session not found")
    reps = db.query(RepetitionModel).filter(RepetitionModel.session_id == session_id).order_by(RepetitionModel.index).all()
    res = SessionRead.from_orm(session_obj).dict()
    res["repetitions"] = [r.__dict__ for r in reps]
    return res


@app.delete("/api/v1/sessions/{session_id}", status_code=status.HTTP_200_OK)
def delete_session(session_id: str, db: Session = Depends(get_db)):
    session_obj = db.query(SessionModel).filter(SessionModel.id == session_id).first()
    if not session_obj:
        raise HTTPException(status_code=404, detail="Session not found")
    session_obj.is_deleted = True # Tombstone
    db.commit()
    return {"ok": True, "message": "Session marked as deleted tombstone"}


# --- Analytics & Flags Endpoints ---

@app.get("/api/v1/patients/{patient_id}/analytics")
def get_patient_analytics(
    patient_id: str,
    exercise: Optional[str] = None,
    window: int = Query(default=30, ge=7, le=180),
    db: Session = Depends(get_db)
):
    cutoff = datetime.utcnow() - timedelta(days=window)
    query = db.query(SessionModel).filter(
        SessionModel.patient_id == patient_id,
        SessionModel.is_deleted == False,
        SessionModel.started_at >= cutoff
    )
    if exercise:
        query = query.filter(SessionModel.exercise_code == exercise)

    sessions = query.order_by(SessionModel.started_at).all()
    if not sessions:
        return {"patient_id": patient_id, "session_count": 0, "trends": {}, "disclaimer": "No medical diagnosis"}

    mean_roms = [s.meanRom for s in sessions if hasattr(s, 'meanRom') or hasattr(s, 'mean_rom')]
    mean_roms = [s.mean_rom for s in sessions]
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
    flag.acknowledged_at = datetime.utcnow()
    flag.acknowledged_by = payload.acknowledged_by
    flag.ack_note = payload.ack_note
    db.commit()
    db.refresh(flag)
    return flag


# --- Overview Dashboard Endpoint ---

@app.get("/api/v1/overview")
def get_overview(db: Session = Depends(get_db)):
    now = datetime.utcnow()
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


# --- Report & Export Endpoints ---

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
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "total_sessions": len(sessions),
        "plans": [p.__dict__ for p in plans],
        "sessions": [s.__dict__ for s in sessions],
        "flags": [f.__dict__ for f in flags],
        "disclaimer": "Prototype monitoring report. Measurements are for demonstration and research purposes and are not a medical diagnosis. Interpretation requires qualified professional review."
    }


@app.get("/api/v1/patients/{patient_id}/export")
def export_patient_sessions(patient_id: str, format: str = Query(default="csv", pattern="^(csv|json)$"), db: Session = Depends(get_db)):
    sessions = db.query(SessionModel).filter(SessionModel.patient_id == patient_id, SessionModel.is_deleted == False).order_by(SessionModel.started_at).all()
    if format == "json":
        data = [SessionRead.from_orm(s).dict() for s in sessions]
        return data

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
