"""
Tests for ML dataset validator, manifest verification, and inference handling.
"""
import os
import sys
import json
import hashlib
import pytest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from ml.dataset_validator import DatasetValidator


def test_validator_rejects_real_data_without_consent():
    """Real data collection strictly requires consent_given == True."""
    validator = DatasetValidator()
    trial = {
        "participant_id": "P-999",
        "session_id": "s-1",
        "trial_id": "t-1",
        "exercise_label": "fist_clench",
        "movement_phase": "peak",
        "source": "real",
        "consent_given": False,  # Missing consent!
        "calibration_ref": "cal-1",
        "device_firmware": "1.0",
        "sampling_hz": 50,
        "quality": "good",
        "recorder_app_version": "1.0",
        "samples": [{"t": 0, "flex": [1000] * 5, "imu": [0] * 6}]
    }
    is_valid, errors = validator.validate_trial(trial)
    assert not is_valid
    assert any("consent" in e.lower() for e in errors)


def test_validator_accepts_valid_synthetic_dataset():
    """Validates generated synthetic dataset."""
    validator = DatasetValidator()
    dataset_path = os.path.join(os.path.dirname(__file__), "data", "synthetic_dataset.json")
    assert os.path.exists(dataset_path)

    report = validator.validate_dataset_file(dataset_path)
    assert report["total_trials"] == 40
    assert report["invalid_trials"] == 0
    assert report["valid_trials"] == 40


def test_manifest_integrity_and_sha256():
    """Verifies that manifest.json sha256 matches actual model file bytes."""
    model_dir = os.path.join(os.path.dirname(__file__), "models")
    manifest_file = os.path.join(model_dir, "manifest.json")
    model_file = os.path.join(model_dir, "h10_exercise_recognizer.tflite")

    assert os.path.exists(manifest_file)
    assert os.path.exists(model_file)

    with open(manifest_file, "r") as f:
        manifest = json.load(f)

    assert manifest["model_name"] == "h10_exercise_recognizer"
    assert manifest["feature_schema"] == "feat-v1"
    assert manifest["sampling_hz"] == 50.0

    # Verify SHA-256
    sha256 = hashlib.sha256()
    with open(model_file, "rb") as f:
        sha256.update(f.read())
    expected_hash = sha256.hexdigest()
    assert manifest["sha256"] == expected_hash, "Manifest SHA-256 does not match model file!"
