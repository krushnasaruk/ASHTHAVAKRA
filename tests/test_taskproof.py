"""
Test suite for TaskProof Engine (TP-01 to TP-20).
Validates full state transitions, guards, honest verdicts (VERIFIED, FAILED, UNCERTAIN, ABORTED),
occlusion handling, sensor timeouts, and config hashing.
"""

import time
import pytest

from backend.taskproof import TaskProofEngine, TaskState, TaskVerdict


def make_sample(
    t_ns: int,
    zone: str = "A",
    marker_visible: bool = True,
    det_rate: float = 1.0,
    occlusion_ms: float = 0.0,
    frame_age_ms: float = 10.0,
):
    return {
        "marker_visible": marker_visible,
        "marker_center_px": [200.0, 200.0] if marker_visible else None,
        "zone_membership": zone,
        "detection_rate_1s": det_rate,
        "occlusion_ms": occlusion_ms,
        "frame_age_ms": frame_age_ms,
        "capture_ns": t_ns,
    }


def make_sensor(
    t_ns: int,
    fsr_ok: bool = True,
    adc_ok: bool = True,
    imu_ok: bool = True,
):
    return {
        "v": 1,
        "seq": 100,
        "t_ms": int(t_ns / 1e6),
        "host_monotonic_ns": t_ns,
        "flex": [10000, 10000, 10000],
        "fsr": 5000,
        "imu": [0, 0, 8192, 0, 0, 0],
        "fsr_ok": fsr_ok,
        "adc_ok": adc_ok,
        "imu_ok": imu_ok,
        "flags": 2,
    }


def test_tp_01_and_gate_g3_complete_valid_transfer():
    """TP-01 & Gate G3: Complete valid transfer end-to-end reaches VERIFIED with ordered events."""
    tp = TaskProofEngine()
    start_ns = 1_000_000_000
    tp.start_attempt("att_001", start_ns)

    # 1. READY -> SOURCE_VISIBLE: Zone A held for 550ms with 100% rate
    t_ns = start_ns + 100_000_000
    tp.update(make_sensor(t_ns), make_sample(t_ns, zone="A"), contact_on=False, grip_change=False, object_still=True, now_ns=t_ns)
    t_ns += 550_000_000
    st = tp.update(make_sensor(t_ns), make_sample(t_ns, zone="A"), contact_on=False, grip_change=False, object_still=True, now_ns=t_ns)
    assert st == TaskState.SOURCE_VISIBLE

    # 2. SOURCE_VISIBLE -> CONTACT_CANDIDATE: contact ON + grip change
    t_ns += 100_000_000
    st = tp.update(make_sensor(t_ns), make_sample(t_ns, zone="A"), contact_on=True, grip_change=True, object_still=False, now_ns=t_ns)
    assert st == TaskState.CONTACT_CANDIDATE

    # 3. CONTACT_CANDIDATE -> OBJECT_LIFTED: leaves zone A with contact ON
    t_ns += 200_000_000
    st = tp.update(make_sensor(t_ns), make_sample(t_ns, zone="none"), contact_on=True, grip_change=False, object_still=False, now_ns=t_ns)
    assert st == TaskState.OBJECT_LIFTED

    # 4. OBJECT_LIFTED -> TARGET_REACHED: arrives in zone B and holds for 350ms
    t_ns += 500_000_000
    tp.update(make_sensor(t_ns), make_sample(t_ns, zone="B"), contact_on=True, grip_change=False, object_still=False, now_ns=t_ns)
    t_ns += 350_000_000
    st = tp.update(make_sensor(t_ns), make_sample(t_ns, zone="B"), contact_on=True, grip_change=False, object_still=False, now_ns=t_ns)
    assert st == TaskState.TARGET_REACHED

    # 5. TARGET_REACHED -> RELEASE_CONFIRMED: contact OFF, still in B for 550ms
    t_ns += 100_000_000
    tp.update(make_sensor(t_ns), make_sample(t_ns, zone="B"), contact_on=False, grip_change=False, object_still=True, now_ns=t_ns)
    t_ns += 550_000_000
    st = tp.update(make_sensor(t_ns), make_sample(t_ns, zone="B"), contact_on=False, grip_change=False, object_still=True, now_ns=t_ns)
    assert st == TaskState.RELEASE_CONFIRMED

    # 6. RELEASE_CONFIRMED -> VERIFIED
    t_ns += 40_000_000
    st = tp.update(make_sensor(t_ns), make_sample(t_ns, zone="B"), contact_on=False, grip_change=False, object_still=True, now_ns=t_ns)
    assert st == TaskState.VERIFIED
    assert tp.verdict == TaskVerdict.VERIFIED

    summary = tp.get_summary()
    assert summary["verdict"] == "VERIFIED"
    assert summary["camera_visibility_ratio"] >= 0.8
    assert len(summary["events"]) >= 6


def test_tp_02_transfer_with_wrong_target():
    """TP-02: Transfer to wrong target zone yields FAILED with WRONG_TARGET."""
    tp = TaskProofEngine()
    t_ns = 1_000_000_000
    tp.start_attempt("att_002", t_ns)

    # Fast forward to TARGET_REACHED
    tp.current_state = TaskState.TARGET_REACHED

    # Object leaves zone B to zone A instead of being released in B
    t_ns += 100_000_000
    st = tp.update(make_sensor(t_ns), make_sample(t_ns, zone="A"), contact_on=True, grip_change=False, object_still=False, now_ns=t_ns)
    assert st == TaskState.FAILED
    assert tp.verdict == TaskVerdict.FAILED
    assert "WRONG_TARGET" in tp.reason_codes


def test_tp_03_release_before_target_arrival():
    """TP-03: Release before target arrival yields FAILED with RELEASED_EARLY."""
    tp = TaskProofEngine()
    t_ns = 1_000_000_000
    tp.start_attempt("att_003", t_ns)

    # While in OBJECT_LIFTED (in transit), contact drops
    tp.current_state = TaskState.OBJECT_LIFTED
    t_ns += 100_000_000
    st = tp.update(make_sensor(t_ns), make_sample(t_ns, zone="none"), contact_on=False, grip_change=False, object_still=False, now_ns=t_ns)
    assert st == TaskState.FAILED
    assert "RELEASED_EARLY" in tp.reason_codes


def test_tp_04_object_moved_after_release():
    """TP-04: Object moved after release yields FAILED with OBJECT_MOVED_AFTER_RELEASE."""
    tp = TaskProofEngine()
    t_ns = 1_000_000_000
    tp.start_attempt("att_004", t_ns)

    tp.current_state = TaskState.TARGET_REACHED
    # Contact is released
    tp.update(make_sensor(t_ns), make_sample(t_ns, zone="B"), contact_on=False, grip_change=False, object_still=False, now_ns=t_ns)
    # After 550ms, object is NOT still
    t_ns += 550_000_000
    st = tp.update(make_sensor(t_ns), make_sample(t_ns, zone="B"), contact_on=False, grip_change=False, object_still=False, now_ns=t_ns)
    assert st == TaskState.FAILED
    assert "OBJECT_MOVED_AFTER_RELEASE" in tp.reason_codes


def test_tp_05_false_gesture_no_lift():
    """TP-05: Hand closes in zone A but object never leaves zone A yields FAILED with FALSE_GESTURE."""
    tp = TaskProofEngine()
    t_ns = 1_000_000_000
    tp.start_attempt("att_005", t_ns)

    tp.current_state = TaskState.CONTACT_CANDIDATE
    tp._contact_candidate_ns = t_ns

    # Exceed lift window of 4.0s while remaining in Zone A
    t_ns += 4_500_000_000
    st = tp.update(make_sensor(t_ns), make_sample(t_ns, zone="A"), contact_on=True, grip_change=False, object_still=True, now_ns=t_ns)
    assert st == TaskState.FAILED
    assert "FALSE_GESTURE" in tp.reason_codes


def test_tp_07_marker_occluded_during_lift_yields_uncertain():
    """TP-07: Marker occluded during lift yields UNCERTAIN with MARKER_OCCLUDED, never VERIFIED."""
    tp = TaskProofEngine()
    t_ns = 1_000_000_000
    tp.start_attempt("att_007", t_ns)

    tp.current_state = TaskState.OBJECT_LIFTED
    # Occlusion reported > 150 ms
    t_ns += 100_000_000
    sample = make_sample(t_ns, zone="none", marker_visible=False, occlusion_ms=180.0)
    st = tp.update(make_sensor(t_ns), sample, contact_on=True, grip_change=False, object_still=False, now_ns=t_ns)
    assert st == TaskState.UNCERTAIN
    assert tp.verdict == TaskVerdict.UNCERTAIN
    assert "MARKER_OCCLUDED" in tp.reason_codes


def test_tp_09_fsr_disconnected_mid_attempt_yields_uncertain():
    """TP-09: FSR fault mid-attempt yields UNCERTAIN with FSR_FAULT."""
    tp = TaskProofEngine()
    t_ns = 1_000_000_000
    tp.start_attempt("att_009", t_ns)

    tp.current_state = TaskState.OBJECT_LIFTED
    sensor = make_sensor(t_ns, fsr_ok=False)
    st = tp.update(sensor, make_sample(t_ns, zone="none"), contact_on=True, grip_change=False, object_still=False, now_ns=t_ns)
    assert st == TaskState.UNCERTAIN
    assert "FSR_FAULT" in tp.reason_codes


def test_tp_10_device_disconnect_mid_attempt_yields_uncertain():
    """TP-10: Device disconnect mid-attempt yields UNCERTAIN with DEVICE_DISCONNECTED."""
    tp = TaskProofEngine()
    t_ns = 1_000_000_000
    tp.start_attempt("att_010", t_ns)

    tp.current_state = TaskState.OBJECT_LIFTED
    st = tp.update(None, make_sample(t_ns, zone="none"), contact_on=True, grip_change=False, object_still=False, now_ns=t_ns)
    assert st == TaskState.UNCERTAIN
    assert "DEVICE_DISCONNECTED" in tp.reason_codes


def test_tp_11_camera_stale_frame_yields_uncertain():
    """TP-11: Stale camera frame (>200 ms) yields UNCERTAIN with CAMERA_FRAME_STALE."""
    tp = TaskProofEngine()
    t_ns = 1_000_000_000
    tp.start_attempt("att_011", t_ns)

    sample = make_sample(t_ns, frame_age_ms=250.0)
    st = tp.update(make_sensor(t_ns), sample, contact_on=False, grip_change=False, object_still=True, now_ns=t_ns)
    assert st == TaskState.UNCERTAIN
    assert "CAMERA_FRAME_STALE" in tp.reason_codes


def test_tp_16_stale_sensor_packet_yields_uncertain():
    """TP-16: Stale sensor packet (>200 ms) yields UNCERTAIN with SENSOR_STALE."""
    tp = TaskProofEngine()
    t_ns = 1_000_000_000
    tp.start_attempt("att_016", t_ns)

    # Sensor arrival timestamp 250ms in past
    old_sensor = make_sensor(t_ns - 250_000_000)
    st = tp.update(old_sensor, make_sample(t_ns), contact_on=False, grip_change=False, object_still=True, now_ns=t_ns)
    assert st == TaskState.UNCERTAIN
    assert "SENSOR_STALE" in tp.reason_codes


def test_tp_18_config_hash_present():
    """TP-18: Configuration SHA-256 fingerprint is recorded on attempt."""
    tp = TaskProofEngine()
    assert tp.config_hash != ""
    assert len(tp.config_hash) == 64


def test_tp_20_operator_abort_yields_aborted():
    """TP-20: Operator abort yields ABORTED, not FAILED."""
    tp = TaskProofEngine()
    t_ns = 1_000_000_000
    tp.start_attempt("att_020", t_ns)

    tp.abort("OPERATOR_ABORT", t_ns + 100_000_000)
    assert tp.current_state == TaskState.ABORTED
    assert tp.verdict == TaskVerdict.ABORTED
    assert "OPERATOR_ABORT" in tp.reason_codes
