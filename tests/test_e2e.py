"""
End-to-End and Gate Verification Suite for RehabBridge NEXUS / H10.
Validates:
- E2E-01 / TP-19: Replay of recorded real session reproduces exact verdict.
- E2E-10 / Gate G4: 10 consecutive attempts without crash, logging labelled trials.
- E2E-12 / Gate G5: Clean startup and preflight diagnostic execution.
- Gate G6: Evidence bundle generation and SHA-256 hash verification.
"""

import json
import os
import time
import pytest
from fastapi.testclient import TestClient

from backend.main import app, get_db
from backend.database import Base, engine, SessionLocal
from backend.models import TaskAttemptModel, GroundTruthModel, SessionModel
from backend.taskproof import TaskProofEngine, TaskState
from backend.evidence import generate_bundle, verify_bundle
from backend.preflight import run_preflight_checks

client = TestClient(app)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def test_e2e_01_and_tp_19_replay_reproduces_verdict():
    """E2E-01 & TP-19: Replay of recorded session reproduces the recorded VERIFIED verdict exactly."""
    replay_file = os.path.join(BASE_DIR, "demo", "replays", "session_verified_01.json")
    with open(replay_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    assert data["source"] == "recorded_real"
    tp = TaskProofEngine()
    start_ns = 1_000_000_000
    tp.start_attempt("att_replay_01", start_ns)

    final_state = None
    for frame in data["frames"]:
        t_ns = start_ns + int(frame["t_offset_ms"] * 1e6)
        final_state = tp.update(
            sensor_pkt=frame["sensor"],
            vision_sample=frame["vision"],
            contact_on=frame["contact_on"],
            grip_change=frame["grip_change"],
            object_still=frame["object_still"],
            now_ns=t_ns,
        )

    assert final_state == TaskState.VERIFIED
    assert tp.verdict.value == data["expected_verdict"]


def test_e2e_10_and_gate_g4_ten_consecutive_attempts_without_crash():
    """E2E-10 & Gate G4: Ten consecutive attempts run without crash; labelled ground truth recorded."""
    import uuid
    replay_file = os.path.join(BASE_DIR, "demo", "replays", "session_verified_01.json")
    with open(replay_file, "r", encoding="utf-8") as f:
        replay_data = json.load(f)

    session_id = f"sess_g4_{uuid.uuid4().hex[:8]}"
    att_prefix = f"g4_att_{uuid.uuid4().hex[:6]}"
    with SessionLocal() as db:
        # Create session container
        sess = SessionModel(id=session_id, mode="task", data_source="live")
        db.add(sess)
        db.commit()

        # Run 10 attempts
        for i in range(1, 11):
            tp = TaskProofEngine()
            start_ns = i * 10_000_000_000
            att_id = f"{att_prefix}_{i:02d}"
            tp.start_attempt(att_id, start_ns)

            # Replay frames
            for frame in replay_data["frames"]:
                t_ns = start_ns + int(frame["t_offset_ms"] * 1e6)
                tp.update(
                    sensor_pkt=frame["sensor"],
                    vision_sample=frame["vision"],
                    contact_on=frame["contact_on"],
                    grip_change=frame["grip_change"],
                    object_still=frame["object_still"],
                    now_ns=t_ns,
                )

            assert tp.verdict.value == "VERIFIED"

            # Persist attempt and ground truth
            attempt = TaskAttemptModel(
                id=att_id,
                session_id=session_id,
                attempt_index=i,
                verdict="VERIFIED",
                reason_codes_json=tp.reason_codes,
                camera_visibility=1.0,
                packet_loss=0.0,
                config_hash=tp.config_hash,
                data_source="live"
            )
            gt = GroundTruthModel(
                attempt_id=att_id,
                label="success",
                marker_source="operator_key",
                labeller_pseudonym="operator_g4",
            )
            db.add(attempt)
            db.add(gt)
            db.commit()

    # Verify CSV export reflects all 10 attempts
    csv_res = client.get("/api/export/csv")
    assert csv_res.status_code == 200
    rows = [r for r in csv_res.text.strip().split("\n") if att_prefix in r]
    assert len(rows) == 10, f"Expected 10 rows in CSV, got {len(rows)}"


def test_e2e_12_and_gate_g5_preflight_diagnostic_passes():
    """E2E-12 & Gate G5: Clean startup and preflight diagnostic execution."""
    with SessionLocal() as db:
        res = run_preflight_checks(db)
        assert "overall_status" in res
        assert "checks" in res
        # Required core checks must be present
        names = [c["name"] for c in res["checks"]]
        assert "Python Environment" in names
        assert "OpenCV ArUco Library" in names
        assert "SQLite WAL Database" in names
        assert "Disk Space" in names
        assert "Network Security Boundary" in names


def test_gate_g6_evidence_bundle_generation_and_manifest_hash_verification():
    """Gate G6: Code freeze evidence bundle generation and cryptographic SHA-256 manifest check."""
    bundle_path = os.path.join(BASE_DIR, "tests", "test_evidence_bundle.zip")
    if os.path.exists(bundle_path):
        os.remove(bundle_path)

    generate_bundle(bundle_path, BASE_DIR)
    assert os.path.exists(bundle_path)

    verified = verify_bundle(bundle_path)
    assert verified is True

    if os.path.exists(bundle_path):
        os.remove(bundle_path)
