"""
Test suite for Serial Ingest (SI-01 to SI-07).
Validates line parsing, sequence continuity, reboot detection, queue overflow, and auto-discovery.
"""

import json
import time
from unittest.mock import MagicMock, patch
import pytest

from backend.serial_ingest import SerialIngest, IngestStats


def test_si_01_parse_valid_lines_and_count_invalid():
    ingest = SerialIngest()
    arrival_ns = time.monotonic_ns()

    valid_line = '{"v":1,"seq":100,"t_ms":4000,"flex":[12000,13000,14000],"fsr":5000,"imu":[1,2,3,4,5,6],"fsr_ok":true,"imu_ok":true,"adc_ok":true,"flags":2}'
    pkt, err = ingest.parse_line(valid_line, arrival_ns)

    assert err is None
    assert pkt is not None
    assert pkt["v"] == 1
    assert pkt["seq"] == 100
    assert pkt["flex"] == [12000, 13000, 14000]
    assert pkt["fsr"] == 5000
    assert ingest.stats.valid_packets == 1
    assert ingest.stats.invalid_lines == 0

    # Malformed JSON
    bad_line = '{"v":1,"seq":101, broken json'
    bad_pkt, bad_err = ingest.parse_line(bad_line, arrival_ns)
    assert bad_pkt is None
    assert bad_err == "JSON_SYNTAX_ERROR"
    assert ingest.stats.invalid_lines == 1


def test_si_02_rejects_unknown_protocol_version():
    ingest = SerialIngest()
    arrival_ns = time.monotonic_ns()

    bad_version_line = '{"v":99,"seq":100,"t_ms":4000,"flex":[12000,13000,14000],"fsr":5000,"imu":[1,2,3,4,5,6],"fsr_ok":true,"imu_ok":true,"adc_ok":true,"flags":0}'
    pkt, err = ingest.parse_line(bad_version_line, arrival_ns)

    assert pkt is None
    assert err == "UNKNOWN_PROTOCOL_VERSION"
    assert ingest.stats.invalid_lines == 1


def test_si_03_detects_sequence_gaps_and_duplicates():
    ingest = SerialIngest()
    t = 1000

    def make_line(seq, t_ms):
        return f'{{"v":1,"seq":{seq},"t_ms":{t_ms},"flex":[10000,10000,10000],"fsr":500,"imu":[0,0,0,0,0,0],"fsr_ok":true,"imu_ok":true,"adc_ok":true,"flags":0}}'

    # Normal seq 1
    ingest.parse_line(make_line(1, t), time.monotonic_ns())
    assert ingest.stats.seq_gaps == 0
    assert ingest.stats.seq_duplicates == 0

    # Duplicate seq 1
    ingest.parse_line(make_line(1, t + 40), time.monotonic_ns())
    assert ingest.stats.seq_duplicates == 1

    # Gap: skip seq 2 and 3, jump to seq 4
    ingest.parse_line(make_line(4, t + 120), time.monotonic_ns())
    assert ingest.stats.seq_gaps == 2
    assert ingest.stats.dropped_packets == 2


def test_si_04_detects_device_reset():
    events = []
    ingest = SerialIngest(event_callback=lambda evt, data: events.append((evt, data)))

    # Initial packets at seq 500, t_ms 20000
    line1 = '{"v":1,"seq":500,"t_ms":20000,"flex":[10000,10000,10000],"fsr":500,"imu":[0,0,0,0,0,0],"fsr_ok":true,"imu_ok":true,"adc_ok":true,"flags":0}'
    ingest.parse_line(line1, time.monotonic_ns())
    assert ingest.device_epoch == 0

    # Device reboot line arrives
    boot_line = '{"boot":true,"fw":"1.0.0","profile":"demo3"}'
    ingest.parse_line(boot_line, time.monotonic_ns())
    assert ingest.stats.reboots_detected == 1
    assert ingest.device_epoch == 1
    assert ingest.firmware_version == "1.0.0"
    assert ingest.device_profile == "demo3"

    # Next packet has seq 1 and t_ms 40 (regression)
    line2 = '{"v":1,"seq":1,"t_ms":40,"flex":[10000,10000,10000],"fsr":500,"imu":[0,0,0,0,0,0],"fsr_ok":true,"imu_ok":true,"adc_ok":true,"flags":0}'
    ingest.parse_line(line2, time.monotonic_ns())
    # Reboot detected from seq regression as well
    assert ingest.stats.reboots_detected == 2
    assert ingest.device_epoch == 2


def test_si_05_queue_overflow_drops_oldest():
    ingest = SerialIngest(queue_maxsize=3)

    for i in range(1, 6):
        line = f'{{"v":1,"seq":{i},"t_ms":{i*40},"flex":[1,2,3],"fsr":0,"imu":[0,0,0,0,0,0],"fsr_ok":true,"imu_ok":true,"adc_ok":true,"flags":0}}'
        pkt, _ = ingest.parse_line(line, time.monotonic_ns())
        ingest._enqueue_packet(pkt)

    assert ingest.packet_queue.qsize() == 3
    assert ingest.stats.dropped_packets == 2

    # Oldest retained packet should be seq 3, 4, 5
    p1 = ingest.packet_queue.get_nowait()
    p2 = ingest.packet_queue.get_nowait()
    p3 = ingest.packet_queue.get_nowait()
    assert p1["seq"] == 3
    assert p2["seq"] == 4
    assert p3["seq"] == 5


def test_si_07_port_auto_detection_picks_device_with_ping_ack():
    ingest = SerialIngest(expected_profile="demo3")

    mock_ports = [
        {"device": "COM3", "description": "Bluetooth Link", "hwid": "BTH"},
        {"device": "COM12", "description": "USB Serial Device", "hwid": "USB\\VID_303A"},
    ]

    def mock_ping(port, timeout=1.5):
        if port == "COM12":
            return True, {"ack": "test", "ok": True, "fw": "1.0.0", "profile": "demo3"}
        return False, None

    with patch.object(SerialIngest, "list_ports", return_value=mock_ports):
        with patch.object(ingest, "ping_device", side_effect=mock_ping):
            chosen = ingest.auto_detect_port()
            assert chosen == "COM12"
