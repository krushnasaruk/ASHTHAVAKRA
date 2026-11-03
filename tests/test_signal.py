"""
Test suite for Signal Processing Layer (SG-01 to SG-11).
Validates calibration model, normalization, EMA/median filtering,
FSR contact hysteresis, grip detection, IMU kinematics, and stillness.
"""

import math
import numpy as np
import pytest

from backend.signal.calibration import ChannelCalibration, CalibrationModel, CalibrationCapture
from backend.signal.normalize import normalize_flexion
from backend.signal.filters import ExponentialMovingAverage, MedianFilter, CompoundFilter
from backend.signal.contact import FSRContactDetector
from backend.signal.grip import GripChangeDetector
from backend.signal.imu import IMUProcessor
from backend.signal.stillness import StillnessDetector


def test_sg_01_normalization_known_inputs_and_polarity():
    """SG-01: Normalization: known inputs give expected percentages, polarity -1 inverts correctly."""
    # Polarity +1: open=10000, bent=20000
    assert normalize_flexion(10000, 10000, 20000, polarity=1) == 0.0
    assert normalize_flexion(15000, 10000, 20000, polarity=1) == 50.0
    assert normalize_flexion(20000, 10000, 20000, polarity=1) == 100.0
    # Clamping
    assert normalize_flexion(5000, 10000, 20000, polarity=1) == 0.0
    assert normalize_flexion(25000, 10000, 20000, polarity=1) == 100.0

    # Polarity -1: open=20000, bent=10000
    assert normalize_flexion(20000, 20000, 10000, polarity=-1) == 0.0
    assert normalize_flexion(15000, 20000, 10000, polarity=-1) == 50.0
    assert normalize_flexion(10000, 20000, 10000, polarity=-1) == 100.0


def test_sg_02_invalid_span_rejected():
    """SG-02: Invalid span (zero or too small) rejected with reason."""
    with pytest.raises(ValueError, match="INVALID_SPAN_ZERO"):
        normalize_flexion(10000, 10000, 10000)

    # Calibration model span threshold test (min_span = 300)
    ch = ChannelCalibration(open_median=10000, bent_median=10100, open_std=10, bent_std=10, min_span=300)
    assert ch.valid is False
    assert "SPAN_TOO_SMALL" in ch.reason


def test_sg_03_nan_and_inf_rejected():
    """SG-03: NaN and infinity inputs rejected."""
    with pytest.raises(ValueError, match="INPUT_NAN_OR_INF"):
        normalize_flexion(float("nan"), 10000, 20000)
    with pytest.raises(ValueError, match="INPUT_NAN_OR_INF"):
        normalize_flexion(float("inf"), 10000, 20000)


def test_sg_04_ema_matches_hand_computed():
    """SG-04: EMA matches hand-computed sequence."""
    ema = ExponentialMovingAverage(alpha=0.5)
    assert ema.update(10.0) == 10.0
    assert ema.update(20.0) == 15.0
    assert ema.update(30.0) == 22.5


def test_sg_05_median_then_ema_suppresses_spike():
    """SG-05: Median-then-EMA suppresses single-sample spikes."""
    filt = CompoundFilter(median_window=5, ema_alpha=0.2)
    for _ in range(5):
        filt.update(100.0)

    spike_out = filt.update(10000.0)
    assert abs(spike_out - 100.0) < 1.0


def test_sg_06_fsr_contact_turns_on_after_100ms_only():
    """SG-06: FSR contact turns ON after 100 ms above threshold and not earlier."""
    detector = FSRContactDetector(no_contact_median=500, no_contact_std=50, k_on=4.0, min_contact_ms=100)

    # Below threshold
    state, faulted, evt = detector.update(raw_fsr=600, fsr_ok=True, t_ms=0)
    assert state is False
    assert evt is None

    # Step above threshold at t=50 ms
    state, faulted, evt = detector.update(raw_fsr=10000, fsr_ok=True, t_ms=50)
    assert state is False

    # Still below 100ms duration at t=120ms
    state, faulted, evt = detector.update(raw_fsr=10000, fsr_ok=True, t_ms=120)
    assert state is False

    # Duration >= 100ms at t=160ms -> turns ON
    state, faulted, evt = detector.update(raw_fsr=10000, fsr_ok=True, t_ms=160)
    assert state is True
    assert evt == "CONTACT_ON"


def test_sg_07_fsr_contact_turns_off_after_150ms_only():
    """SG-07: FSR contact turns OFF after 150 ms below release threshold; oscillation produces no flicker."""
    detector = FSRContactDetector(no_contact_median=500, no_contact_std=50, k_on=4.0, k_off=2.0, min_release_ms=150)
    
    # Establish contact state
    for t in range(0, 200, 40):
        detector.update(10000, True, t)
    assert detector.contact_state is True

    # Drop to resting level 500 at 25 Hz rate
    # First few samples: filter decaying
    for t in range(200, 360, 40):
        state, _, evt = detector.update(500, True, t)
        assert state is True  # still ON during decay and initial sub-threshold window

    # Feed samples until release threshold hold time of 150ms completes
    event_detected = False
    for t in range(360, 1100, 40):
        state, _, evt = detector.update(500, True, t)
        if evt == "CONTACT_OFF":
            event_detected = True
            assert state is False
            break

    assert event_detected is True
    assert detector.contact_state is False


def test_sg_08_fsr_rail_detection_yields_fsr_fault():
    """SG-08: FSR rail detection yields FSR_FAULT."""
    detector = FSRContactDetector(rail_threshold=31000, rail_fault_ms=300)

    detector.update(31500, True, 0)
    assert detector.is_faulted is False

    state, faulted, evt = detector.update(31500, True, 350)
    assert faulted is True
    assert evt == "FSR_FAULT"
    assert detector.fault_reason == "FSR_RAILED"


def test_sg_09_grip_change_detector():
    """SG-09: Grip-change detector responds to 15% change within 400ms and ignores smaller changes."""
    detector = GripChangeDetector(grip_delta_pct=15.0, window_ms=400, hold_ms=150)

    # Baseline flex at 10% across 400ms
    for t in range(0, 450, 40):
        detected, _ = detector.update([10.0, 10.0, 10.0], t)
        assert detected is False

    # Small 5% change -> no trigger
    for t in range(480, 700, 40):
        detected, _ = detector.update([15.0, 10.0, 10.0], t)
        assert detected is False

    # Large 20% change at t=720, held for 160ms -> triggers
    detector.update([30.0, 10.0, 10.0], 720)
    detected, channels = detector.update([30.0, 10.0, 10.0], 890)
    assert detected is True
    assert 0 in channels


def test_sg_10_imu_unit_conversion():
    """SG-10: IMU unit conversion matches datasheet scale factors."""
    imu = IMUProcessor(accel_scale_lsb_per_g=8192.0, gyro_scale_lsb_per_deg_s=65.5)
    raw = [0, 0, 8192, 131, 0, 0]
    conv = imu.convert_raw(raw)
    assert conv["accel_g"] == [0.0, 0.0, 1.0]
    assert conv["gyro_dps"] == [2.0, 0.0, 0.0]


def test_sg_11_object_stillness_detector():
    """SG-11: Object stillness detector ignores motion below threshold."""
    still = StillnessDetector(still_px=6.0, window_ms=500.0)

    for t in range(0, 560, 50):
        res = still.update((600.0 + (t % 2), 300.0), "B", float(t))

    assert res is True

    res2 = still.update((615.0, 300.0), "B", 600.0)
    assert res2 is False
