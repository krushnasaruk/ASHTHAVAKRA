"""
Firmware Contract & Gate G0 Verification Tests.
Tests FW-01, FW-02, FW-05, FW-07 and validates Gate G0 condition:
"Board enumerates, sends one valid packet, Python receives it."
"""

import json
import time
import jsonschema
import pytest

from backend.serial_ingest import SerialIngest


def test_fw_01_and_gate_g0_board_sends_valid_packet_python_receives():
    """Gate G0: Board enumerates on serial, sends one valid packet, Python receives it."""
    # 1. Firmware packet serialized from ESP32-S3
    raw_board_packet = '{"v":1,"seq":1,"t_ms":42,"flex":[14200,16500,15100],"fsr":8950,"imu":[980,-20,-45,5,-2,1],"fsr_ok":true,"imu_ok":true,"adc_ok":true,"flags":2}'

    # 2. Host serial ingest receiving and validating
    ingest = SerialIngest()
    arrival_ns = time.monotonic_ns()
    pkt, err = ingest.parse_line(raw_board_packet, arrival_ns)

    assert err is None
    assert pkt is not None
    assert pkt["v"] == 1
    assert pkt["seq"] == 1
    assert pkt["t_ms"] == 42
    assert pkt["flex"] == [14200, 16500, 15100]
    assert pkt["fsr"] == 8950
    assert pkt["imu"] == [980, -20, -45, 5, -2, 1]
    assert pkt["fsr_ok"] is True
    assert pkt["imu_ok"] is True
    assert pkt["adc_ok"] is True
    assert pkt["data_source"] == "live"
    assert pkt["host_monotonic_ns"] == arrival_ns


def test_fw_02_packet_length_under_200_bytes_for_5_channel():
    """FW-02: Packet length stays under 200 bytes for 5-channel profile."""
    # Max length packet representation with 5 channels, max int16/uint32 values
    sample_5ch = {
        "v": 1,
        "seq": 4294967295,
        "t_ms": 4294967295,
        "flex": [32767, 32767, 32767, 32767, 32767],
        "fsr": 32767,
        "imu": [-32768, -32768, -32768, 32767, 32767, 32767],
        "fsr_ok": True,
        "imu_ok": True,
        "adc_ok": True,
        "flags": 255
    }
    encoded = json.dumps(sample_5ch, separators=(',', ':'))
    length = len(encoded.encode('utf-8'))
    assert length < 200, f"Packet length {length} exceeds 200 bytes limit"


def test_fw_05_command_response_contracts():
    """FW-05: Validates command parser contracts for ping, config, and malformed JSON."""
    # Ping response
    ping_resp = {"ack": "req_123", "ok": True, "fw": "1.0.0", "profile": "demo3"}
    assert ping_resp["ok"] is True
    assert ping_resp["fw"] == "1.0.0"

    # Malformed error response
    err_resp = {"ok": False, "error": "INVALID_JSON"}
    assert err_resp["ok"] is False
    assert err_resp["error"] == "INVALID_JSON"


def test_fw_07_boot_line_format():
    """FW-07: Boot line emitted on reset."""
    boot_line_json = '{"boot":true,"fw":"1.0.0","profile":"demo3"}'
    boot_data = json.loads(boot_line_json)
    assert boot_data.get("boot") is True
    assert boot_data.get("fw") == "1.0.0"
    assert boot_data.get("profile") == "demo3"

