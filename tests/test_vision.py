"""
Test suite for Vision and ArUco Tracking (VI-01 to VI-07).
Validates marker detection, 10px boundary hysteresis, detection rate, frame age, and camera failure.
"""

import time
import cv2
import numpy as np
import pytest

from backend.vision import VisionEngine, point_in_poly


def generate_aruco_synthetic_image(marker_id: int = 0, size_px: int = 200, canvas_shape=(720, 1280), top_left=(200, 200)):
    """Generate a clean synthetic frame containing an ArUco marker from DICT_4X4_50."""
    canvas = np.ones(canvas_shape, dtype=np.uint8) * 255
    aruco_dict = cv2.aruco.getPredefinedDictionary(cv2.aruco.DICT_4X4_50)
    
    # generateMarker
    if hasattr(cv2.aruco, "generateImageMarker"):
        marker_img = cv2.aruco.generateImageMarker(aruco_dict, marker_id, size_px)
    else:
        marker_img = cv2.aruco.drawMarker(aruco_dict, marker_id, size_px)

    y, x = top_left
    canvas[y:y+size_px, x:x+size_px] = marker_img
    return canvas


def test_vi_01_and_gate_g2_aruco_detection_on_test_image():
    """VI-01 & Gate G2: ArUco detection on generated test image returns expected ID and corners."""
    vision = VisionEngine(target_marker_id=0)
    frame = generate_aruco_synthetic_image(marker_id=0, size_px=100, top_left=(150, 150))
    capture_ns = time.monotonic_ns()

    sample = vision.detect_in_frame(frame, capture_ns)

    assert sample["marker_visible"] is True
    assert sample["marker_center_px"] is not None
    # Center should be near x=200, y=200
    cx, cy = sample["marker_center_px"]
    assert 190 <= cx <= 210
    assert 190 <= cy <= 210
    assert sample["marker_corners_px"] is not None
    assert len(sample["marker_corners_px"]) == 4


def test_vi_02_zone_membership_with_hysteresis():
    """VI-02: Zone boundary test with 10 px hysteresis margin prevents edge chatter."""
    vision = VisionEngine()
    # Zone A: [[100, 100], [300, 100], [300, 300], [100, 300]]
    vision.zone_a = [[100, 100], [300, 100], [300, 300], [100, 300]]
    vision.zone_b = [[500, 100], [700, 100], [700, 300], [500, 300]]

    # 1. Point distinctly inside Zone A: (200, 200)
    # Fake marker detection result by setting _prev_zone
    in_a = point_in_poly((200, 200), vision.zone_a, margin_px=0.0)
    assert in_a is True

    # 2. Point 5px outside the right boundary: x = 305, y = 200
    # Without hysteresis (initial entry), it is outside
    assert point_in_poly((305, 200), vision.zone_a, margin_px=0.0) is False
    # With hysteresis (already in Zone A, 10px buffer), it stays inside
    assert point_in_poly((305, 200), vision.zone_a, margin_px=10.0) is True

    # 3. Point 15px outside: x = 315, y = 200
    # Exceeds 10px hysteresis, leaves Zone A
    assert point_in_poly((315, 200), vision.zone_a, margin_px=10.0) is False


def test_vi_03_detection_rate_calculation():
    """VI-03: Detection rate over rolling 1-second window."""
    vision = VisionEngine(target_marker_id=0)
    marker_frame = generate_aruco_synthetic_image(marker_id=0, size_px=80, top_left=(100, 100))
    empty_frame = np.ones((720, 1280), dtype=np.uint8) * 255

    now_ns = time.monotonic_ns()
    # 8 detections and 2 misses across 10 frames in 1s -> 80% detection rate
    for i in range(8):
        t = now_ns + int(i * 100_000_000)
        vision.detect_in_frame(marker_frame, t)

    for i in range(8, 10):
        t = now_ns + int(i * 100_000_000)
        s = vision.detect_in_frame(empty_frame, t)

    assert s["detection_rate_1s"] == 0.8


def test_vi_04_frame_age_calculation():
    """VI-04: Frame age calculation correct when query occurs after capture."""
    vision = VisionEngine()
    frame = generate_aruco_synthetic_image(marker_id=0, size_px=80, top_left=(100, 100))
    old_ns = time.monotonic_ns() - 150_000_000  # 150 ms ago

    vision.latest_frame = frame
    vision.latest_frame_ns = old_ns
    vision.detect_in_frame(frame, old_ns)

    sample = vision.get_latest_sample()
    assert sample["frame_age_ms"] >= 140.0


def test_vi_05_camera_missing_handling():
    """VI-05: Non-existent camera index fails gracefully."""
    vision = VisionEngine(camera_index=999)
    success = vision.start()
    assert success is False
    assert vision.is_running is False
    sample = vision.get_latest_sample()
    assert sample["camera_connected"] is False


def test_vi_07_aruco_api_available():
    """VI-07: Verify installed OpenCV version supports ArUco DICT_4X4_50."""
    aruco_dict = cv2.aruco.getPredefinedDictionary(cv2.aruco.DICT_4X4_50)
    assert aruco_dict is not None
    assert aruco_dict.bytesList is not None

