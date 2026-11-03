"""
Contract verification tests for RehabBridge NEXUS / H10.
Validates protocol schemas, golden fixtures, and configuration files.
"""

import json
import os
import yaml
import pytest
import jsonschema

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def test_protocol_v1_schema_validates_golden_packet():
    schema_path = os.path.join(BASE_DIR, "shared", "protocol", "protocol_v1_schema.json")
    fixture_path = os.path.join(BASE_DIR, "shared", "fixtures", "golden_packet_v1.json")

    with open(schema_path, "r", encoding="utf-8") as f:
        schema = json.load(f)

    with open(fixture_path, "r", encoding="utf-8") as f:
        fixture = json.load(f)

    packet = fixture["packet"]
    # Should validate without error
    jsonschema.validate(instance=packet, schema=schema)
    assert packet["v"] == 1
    assert len(packet["flex"]) == 3
    assert len(packet["imu"]) == 6
    assert packet["fsr_ok"] is True


def test_protocol_v1_schema_rejects_invalid_packets():
    schema_path = os.path.join(BASE_DIR, "shared", "protocol", "protocol_v1_schema.json")
    with open(schema_path, "r", encoding="utf-8") as f:
        schema = json.load(f)

    # 1. Unknown version
    bad_v = {
        "v": 2, "seq": 1, "t_ms": 100, "flex": [1000, 1000, 1000],
        "fsr": 100, "imu": [0, 0, 0, 0, 0, 0],
        "fsr_ok": True, "imu_ok": True, "adc_ok": True, "flags": 0
    }
    with pytest.raises(jsonschema.ValidationError):
        jsonschema.validate(instance=bad_v, schema=schema)

    # 2. Missing required field (e.g. fsr_ok)
    missing_field = {
        "v": 1, "seq": 1, "t_ms": 100, "flex": [1000, 1000, 1000],
        "fsr": 100, "imu": [0, 0, 0, 0, 0, 0],
        "imu_ok": True, "adc_ok": True, "flags": 0
    }
    with pytest.raises(jsonschema.ValidationError):
        jsonschema.validate(instance=missing_field, schema=schema)

    # 3. Flex out of bounds (< 3 channels)
    bad_flex = {
        "v": 1, "seq": 1, "t_ms": 100, "flex": [1000, 1000],
        "fsr": 100, "imu": [0, 0, 0, 0, 0, 0],
        "fsr_ok": True, "imu_ok": True, "adc_ok": True, "flags": 0
    }
    with pytest.raises(jsonschema.ValidationError):
        jsonschema.validate(instance=bad_flex, schema=schema)


def test_config_signal_yaml_structure():
    config_path = os.path.join(BASE_DIR, "config", "signal.yaml")
    with open(config_path, "r", encoding="utf-8") as f:
        cfg = yaml.safe_load(f)

    for section in ["calibration", "filters", "contact", "grip", "imu", "stillness"]:
        assert section in cfg, f"Missing section: {section}"
        for param, details in cfg[section].items():
            assert "value" in details, f"Param {param} missing 'value'"
            assert "unit" in details, f"Param {param} missing 'unit'"
            assert "status" in details, f"Param {param} missing 'status'"
            assert details["status"] in ["provisional", "measured"]


def test_config_taskproof_yaml_structure():
    config_path = os.path.join(BASE_DIR, "config", "taskproof.yaml")
    with open(config_path, "r", encoding="utf-8") as f:
        cfg = yaml.safe_load(f)

    for section in ["timers", "thresholds"]:
        assert section in cfg, f"Missing section: {section}"
        for param, details in cfg[section].items():
            assert "value" in details, f"Param {param} missing 'value'"
            assert "unit" in details, f"Param {param} missing 'unit'"
            assert "status" in details, f"Param {param} missing 'status'"
            assert details["status"] in ["provisional", "measured"]

