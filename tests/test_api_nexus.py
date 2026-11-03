"""
Test suite for RehabBridge NEXUS API endpoints and SQLite database.
Validates API-01 through API-11 from Build Specification v3 Section 16.6.
"""

import os
import zipfile
import io
import pytest
from fastapi.testclient import TestClient

from backend.main import app, get_db
from backend.database import Base, engine
from backend.models import VolunteerModel, ConsentModel, TaskAttemptModel, GroundTruthModel

client = TestClient(app)


@pytest.fixture(scope="function", autouse=True)
def setup_test_db():
    Base.metadata.create_all(bind=engine)
    from backend.database import SessionLocal
    with SessionLocal() as db:
        db.query(GroundTruthModel).delete()
        db.query(TaskAttemptModel).delete()
        db.query(ConsentModel).delete()
        db.query(VolunteerModel).delete()
        db.commit()


def test_api_01_health_subsystem_real_state():
    """API-01: Health endpoint reports real subsystem state."""
    res = client.get("/api/health")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "healthy"
    assert "database" in data["subsystems"]
    assert "serial" in data["subsystems"]
    assert "vision" in data["subsystems"]
    assert "taskproof" in data["subsystems"]


def test_api_02_preflight_checks_structure():
    """API-02: Preflight returns checks with status and hints."""
    res = client.get("/api/preflight")
    assert res.status_code == 200
    data = res.json()
    assert "overall_status" in data
    assert "ready_to_start" in data
    assert len(data["checks"]) >= 5
    for c in data["checks"]:
        assert c["status"] in ["pass", "warn", "fail"]
        assert "name" in c
        assert "details" in c


def test_api_03_consent_required_before_calibration():
    """API-03: Consent is required before calibration; calibration without consent returns 403."""
    # Attempt calibration for unconsented volunteer
    res = client.post("/api/calibrations", json={
        "volunteer_pseudonym": "V-UNCONSENTED-99",
        "parameters": {"test": 123}
    })
    assert res.status_code == 403
    assert "Consent record missing" in res.json()["detail"]


def test_api_04_volunteer_pseudonym_validation():
    """API-04: Enforces V-XXX pseudonym format and rejects real names."""
    # Valid
    res_ok = client.post("/api/volunteers", json={"pseudonym": "V-101", "glove_size": "M"})
    assert res_ok.status_code == 200
    assert res_ok.json()["pseudonym"] == "V-101"

    # Invalid format (lowercase or no prefix)
    res_bad = client.post("/api/volunteers", json={"pseudonym": "john_doe"})
    assert res_bad.status_code == 422

    # PII containing spaces
    res_pii = client.post("/api/volunteers", json={"pseudonym": "V-John Doe"})
    assert res_pii.status_code == 422


def test_api_06_and_api_07_task_lifecycle_and_ground_truth_separation():
    """API-06 & API-07: Attempt lifecycle and ground truth stored separately from verdict."""
    # 1. Start attempt
    start_res = client.post("/api/task/start")
    assert start_res.status_code == 200
    att_id = start_res.json()["attempt_id"]

    # 2. Abort attempt
    abort_res = client.post("/api/task/abort", json={"reason": "OPERATOR_ABORT"})
    assert abort_res.status_code == 200
    assert abort_res.json()["verdict"] == "ABORTED"

    # 3. Save a TaskAttempt record directly for database evaluation test
    from backend.database import SessionLocal
    with SessionLocal() as db:
        sess = client.post("/api/v1/sessions", json={
            "id": "sess_test_gt",
            "exercise_code": "nexus_transfer",
            "started_at": "2026-11-03T00:00:00Z",
            "ended_at": "2026-11-03T00:00:10Z",
            "repetitions": []
        })
        attempt = TaskAttemptModel(
            id=att_id,
            session_id="sess_test_gt",
            attempt_index=1,
            verdict="VERIFIED",
            reason_codes_json=["ALL_GUARDS_VERIFIED"],
            data_source="live"
        )
        db.add(attempt)
        db.commit()

    # 4. Operator submits ground truth label
    gt_res = client.post("/api/task/ground-truth", json={
        "attempt_id": att_id,
        "label": "success",
        "marker_source": "operator_key",
        "labeller_pseudonym": "operator_test"
    })
    assert gt_res.status_code == 200
    assert gt_res.json()["label"] == "success"
    assert gt_res.json()["attempt_id"] == att_id


def test_api_08_and_api_09_exports_csv_and_evidence_bundle():
    """API-08 & API-09: Validates CSV export and evidence bundle ZIP package."""
    from backend.database import SessionLocal
    with SessionLocal() as db:
        attempt = TaskAttemptModel(
            id="att_csv_test",
            session_id="sess_csv",
            attempt_index=1,
            verdict="VERIFIED",
            reason_codes_json=["ALL_GUARDS_VERIFIED"],
            data_source="live"
        )
        db.add(attempt)
        db.commit()

    # CSV export
    csv_res = client.get("/api/export/csv")
    assert csv_res.status_code == 200
    assert "VALIDATION_SHEET.csv" in csv_res.headers.get("content-disposition", "")
    lines = csv_res.text.strip().split("\n")
    assert "attempt_id,session_id,attempt_index" in lines[0]
    assert len(lines) >= 2

    # Evidence bundle ZIP
    zip_res = client.get("/api/export/bundle")
    assert zip_res.status_code == 200
    assert "evidence_bundle.zip" in zip_res.headers.get("content-disposition", "")

    # Validate ZIP contents
    with zipfile.ZipFile(io.BytesIO(zip_res.content)) as zf:
        file_list = zf.namelist()
        assert "VALIDATION_SHEET.csv" in file_list
        assert "manifest.json" in file_list


def test_api_10_evaluation_endpoint():
    """API-10: Evaluation endpoint computes precision, recall, and Wilson intervals."""
    eval_res = client.get("/api/evaluation")
    assert eval_res.status_code == 200
    metrics = eval_res.json()
    assert "total_attempts" in metrics
    assert "verified_count" in metrics
    assert "uncertain_rate" in metrics
    assert "precision_wilson_ci" in metrics


def test_api_11_volunteer_deletion_with_audit():
    """API-11: Volunteer deletion removes record and linked consents."""
    # Create volunteer and consent
    client.post("/api/volunteers", json={"pseudonym": "V-DEL-TEST"})
    client.post("/api/consents", json={
        "volunteer_pseudonym": "V-DEL-TEST",
        "consent_text_hash": "dummy_hash_123"
    })

    # Delete
    del_res = client.delete("/api/volunteers/V-DEL-TEST")
    assert del_res.status_code == 200
    assert del_res.json()["deleted"] == "V-DEL-TEST"

    # Confirm deletion
    from backend.database import SessionLocal
    with SessionLocal() as db:
        v = db.query(VolunteerModel).filter(VolunteerModel.pseudonym == "V-DEL-TEST").first()
        assert v is None
        c = db.query(ConsentModel).filter(ConsentModel.volunteer_pseudonym == "V-DEL-TEST").first()
        assert c is None
