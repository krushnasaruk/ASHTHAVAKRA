"""
Tests for H10 Simulator.
Verifies determinism, 30-byte binary packet packing, all 8 scenarios, and HTTP API.
"""
import os
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import pytest
from fastapi.testclient import TestClient
from simulator.server import app, engine
from simulator.scenarios import get_scenario
from simulator.engine import pack_binary_packet, SimulatorEngine


client = TestClient(app)


def test_packet_packing_length():
    """Verify that every packed binary frame is exactly 30 bytes."""
    frame = {
        "t": 12345,
        "flex": [1000, 2000, 3000, 4000, 4095],
        "imu": [10, -20, 980, 5, -5, 0],
        "fsr": 100,
        "flags": 9,
        "battery": 88
    }
    b = pack_binary_packet(frame)
    assert len(b) == 30, f"Expected 30 bytes, got {len(b)}"


def test_determinism_across_runs():
    """Verify identical seeds produce identical binary frames byte-for-byte."""
    sc1 = get_scenario("fist_repetitions", seed=123)
    frames1 = sc1.generate_frames()
    
    sc2 = get_scenario("fist_repetitions", seed=123)
    frames2 = sc2.generate_frames()
    
    assert len(frames1) == len(frames2)
    for f1, f2 in zip(frames1, frames2):
        b1 = pack_binary_packet(f1)
        b2 = pack_binary_packet(f2)
        assert b1 == b2, "Packets differ with identical seed!"


def test_all_eight_scenarios_generate():
    """Verify all 8 scenarios instantiate and generate valid frame sequences."""
    scenario_names = [
        "open_hand_rest",
        "fist_repetitions",
        "fast_repetitions",
        "incomplete_repetitions",
        "finger_tapping_index",
        "pinch_series",
        "wrist_rotation",
        "fault_injection"
    ]
    for name in scenario_names:
        sc = get_scenario(name, seed=42)
        frames = sc.generate_frames()
        assert len(frames) > 0, f"Scenario {name} produced 0 frames"
        # Test first frame packing
        b = pack_binary_packet(frames[0])
        assert len(b) == 30


def test_http_api_status_and_info():
    """Verify GET /api/status and GET /api/info adhere to contract."""
    res_status = client.get("/api/status")
    assert res_status.status_code == 200
    data = res_status.json()
    assert data["ok"] is True
    assert data["data"]["simulated"] is True
    assert "battery" in data["data"]
    assert "rate_hz" in data["data"]

    res_info = client.get("/api/info")
    assert res_info.status_code == 200
    info_data = res_info.json()
    assert info_data["ok"] is True
    assert info_data["data"]["protocol"] == 1
    assert info_data["data"]["firmware"] == "1.0.0"
    assert info_data["data"]["haptic_present"] is True


def test_http_api_rate_control():
    """Verify POST /api/control/rate allows 25 and 50 Hz, rejects 100 Hz."""
    res_valid = client.post("/api/control/rate", json={"hz": 25})
    assert res_valid.status_code == 200
    assert res_valid.json()["data"]["rate_hz"] == 25

    res_invalid = client.post("/api/control/rate", json={"hz": 100})
    assert res_invalid.status_code == 200
    assert res_invalid.json()["ok"] is False
    assert res_invalid.json()["error"]["code"] == "UNPROCESSABLE_ENTITY"
    
    # Reset to 50
    client.post("/api/control/rate", json={"hz": 50})


def test_http_api_session_lifecycle():
    """Verify POST /api/session/start and /stop lifecycle."""
    session_id = "test-session-1234"
    
    # Start
    res_start = client.post("/api/session/start", json={"session_id": session_id})
    assert res_start.status_code == 200
    assert res_start.json()["data"]["status"] == "started"
    
    # Duplicate start -> conflict error
    res_conflict = client.post("/api/session/start", json={"session_id": session_id})
    assert res_conflict.status_code == 200
    assert res_conflict.json()["ok"] is False
    assert res_conflict.json()["error"]["code"] == "CONFLICT"
    
    # Stop
    res_stop = client.post("/api/session/stop", json={"session_id": session_id})
    assert res_stop.status_code == 200
    assert res_stop.json()["data"]["status"] == "stopped"


def test_http_api_haptic():
    """Verify POST /api/control/haptic returns acknowledgement."""
    res = client.post("/api/control/haptic", json={"motor": "both", "duration_ms": 200})
    assert res.status_code == 200
    assert res.json()["data"]["acknowledged"] is True
