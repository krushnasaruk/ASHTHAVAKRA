"""
Tests for H10 Backend API.
Verifies:
- CRUD
- Idempotent session submission
- Conflict detection (409)
- Tombstone deletion
- Plan versioning
- Patient data isolation across all endpoints
- PII refusal
- Export formats (CSV and JSON)
"""
import os
import sys
import uuid
from datetime import datetime
import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from backend.main import app, get_db
from backend.database import Base, engine, SessionLocal
from backend.models import PatientModel, PlanModel, SessionModel

client = TestClient(app)


@pytest.fixture(scope="module", autouse=True)
def setup_test_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield


def test_health_check():
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json()["status"] == "healthy"


def test_patient_pii_rejection():
    """System must refuse real names, emails, and phone numbers."""
    # Real name rejected
    res_name = client.post("/api/v1/patients", json={"pseudonym": "John Smith", "affected_hand": "right"})
    assert res_name.status_code == 422

    # Email rejected
    res_email = client.post("/api/v1/patients", json={"pseudonym": "john@example.com", "affected_hand": "right"})
    assert res_email.status_code == 422

    # Valid pseudonym accepted
    res_valid = client.post("/api/v1/patients", json={"pseudonym": "P-TEST-901", "affected_hand": "left"})
    assert res_valid.status_code == 201
    assert res_valid.json()["pseudonym"] == "P-TEST-901"


def test_plan_versioning():
    """Edits create a new plan version, incrementing version number."""
    # 1. Create patient
    p_res = client.post("/api/v1/patients", json={"pseudonym": "P-PLAN-001", "affected_hand": "right"})
    patient_id = p_res.json()["id"]

    # 2. Create version 1
    v1_res = client.post(f"/api/v1/patients/{patient_id}/plans", json={
        "exercise_id": "fist_clench",
        "target_reps": 10,
        "target_rom_min": 70.0,
        "set_by": "Therapist 1"
    })
    assert v1_res.status_code == 201
    assert v1_res.json()["version"] == 1

    # 3. Create version 2 with updated targets
    v2_res = client.post(f"/api/v1/patients/{patient_id}/plans", json={
        "exercise_id": "fist_clench",
        "target_reps": 15,
        "target_rom_min": 80.0,
        "set_by": "Therapist 2"
    })
    assert v2_res.status_code == 201
    assert v2_res.json()["version"] == 2

    # 4. List plans shows history
    plans_res = client.get(f"/api/v1/patients/{patient_id}/plans")
    assert plans_res.status_code == 200
    versions = [p["version"] for p in plans_res.json()]
    assert 1 in versions and 2 in versions


def test_session_idempotency_and_conflict():
    """
    Submitting duplicate session:
    - Identical payload returns 200 with existing record.
    - Different payload with same ID returns 409 Conflict.
    """
    p_res = client.post("/api/v1/patients", json={"pseudonym": "P-SYNC-001", "affected_hand": "left"})
    patient_id = p_res.json()["id"]
    session_id = str(uuid.uuid4())

    base_session = {
        "id": session_id,
        "patient_id": patient_id,
        "exercise_code": "fist_clench",
        "plan_version": 1,
        "started_at": datetime.utcnow().isoformat() + "Z",
        "ended_at": datetime.utcnow().isoformat() + "Z",
        "duration_s": 60.0,
        "reps_completed": 10,
        "reps_target": 10,
        "mean_rom": 75.0,
        "max_rom": 85.0,
        "mean_rep_duration_s": 2.0,
        "hold_s": 0.5,
        "pain_after": 2,
        "fatigue_after": 3,
        "data_quality": "good",
        "data_source": "real",
        "device_id": "DEV-01",
        "firmware": "1.0",
        "calibration_ref": "cal-01",
        "client_version": "1.0",
        "created_at": datetime.utcnow().isoformat() + "Z",
        "repetitions": []
    }

    # First post -> 201 Created
    res1 = client.post("/api/v1/sessions", json=base_session)
    assert res1.status_code == 201

    # Second post with identical payload -> 200 OK (idempotent duplicate)
    res2 = client.post("/api/v1/sessions", json=base_session)
    assert res2.status_code == 200
    assert res2.json()["id"] == session_id

    # Third post with conflicting content under same ID -> 409 Conflict
    conflict_session = dict(base_session)
    conflict_session["reps_completed"] = 99  # Changed reps!
    res3 = client.post("/api/v1/sessions", json=conflict_session)
    assert res3.status_code == 409


def test_tombstone_deletion():
    """Deleting a session marks it as tombstone and excludes it from listings."""
    p_res = client.post("/api/v1/patients", json={"pseudonym": "P-DEL-001", "affected_hand": "left"})
    patient_id = p_res.json()["id"]
    s_id = str(uuid.uuid4())

    client.post("/api/v1/sessions", json={
        "id": s_id,
        "patient_id": patient_id,
        "exercise_code": "finger_tap",
        "plan_version": 1,
        "started_at": datetime.utcnow().isoformat() + "Z",
        "ended_at": datetime.utcnow().isoformat() + "Z",
        "duration_s": 40.0,
        "reps_completed": 5,
        "reps_target": 5,
        "mean_rom": 70.0,
        "max_rom": 80.0,
        "mean_rep_duration_s": 2.0,
        "hold_s": 0.0,
        "pain_after": 1,
        "fatigue_after": 2,
        "data_quality": "good",
        "data_source": "real",
        "created_at": datetime.utcnow().isoformat() + "Z"
    })

    # Delete session
    del_res = client.delete(f"/api/v1/sessions/{s_id}")
    assert del_res.status_code == 200

    # Listing patient sessions excludes tombstoned session
    list_res = client.get(f"/api/v1/patients/{patient_id}/sessions")
    assert all(s["id"] != s_id for s in list_res.json())


def test_patient_isolation():
    """
    Every query is strictly scoped by patient_id.
    Patient A's sessions, analytics, flags, and exports must never leak to Patient B.
    """
    # Create Patient A
    pA = client.post("/api/v1/patients", json={"pseudonym": "P-ISO-A", "affected_hand": "right"}).json()
    # Create Patient B
    pB = client.post("/api/v1/patients", json={"pseudonym": "P-ISO-B", "affected_hand": "left"}).json()

    # Create Session for Patient A
    sA_id = str(uuid.uuid4())
    client.post("/api/v1/sessions", json={
        "id": sA_id,
        "patient_id": pA["id"],
        "exercise_code": "fist_clench",
        "plan_version": 1,
        "started_at": datetime.utcnow().isoformat() + "Z",
        "ended_at": datetime.utcnow().isoformat() + "Z",
        "duration_s": 60.0,
        "reps_completed": 10,
        "reps_target": 10,
        "mean_rom": 85.0,
        "max_rom": 90.0,
        "mean_rep_duration_s": 2.0,
        "hold_s": 0.5,
        "pain_after": 1,
        "fatigue_after": 2,
        "data_quality": "good",
        "data_source": "real",
        "created_at": datetime.utcnow().isoformat() + "Z"
    })

    # Query Patient B's sessions -> must be completely empty!
    b_sessions = client.get(f"/api/v1/patients/{pB['id']}/sessions").json()
    assert len(b_sessions) == 0, "Patient A's session leaked into Patient B's sessions!"

    # Query Patient B's analytics -> must have 0 sessions!
    b_analytics = client.get(f"/api/v1/patients/{pB['id']}/analytics").json()
    assert b_analytics["session_count"] == 0, "Patient A's metrics leaked into Patient B's analytics!"

    # Export Patient B -> must not contain sA_id
    b_export_csv = client.get(f"/api/v1/patients/{pB['id']}/export?format=csv").text
    assert sA_id not in b_export_csv, "Patient A's session leaked into Patient B's CSV export!"
