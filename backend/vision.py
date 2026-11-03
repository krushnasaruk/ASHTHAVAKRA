"""
Vision and ArUco Tracking Module for RehabBridge NEXUS / H10.
Complies with Build Specification v3 Section 6 and test suite VI-01 through VI-07.
Provides threaded video capture, ArUco DICT_4X4_50 marker detection,
Zone A / Zone B quadrilateral membership with 10 px hysteresis,
rolling 1-second detection rate, frame age calculation, and occlusion tracking.
"""

import json
import logging
import os
import threading
import time
from typing import Dict, List, Optional, Tuple, Any

import cv2
import numpy as np

logger = logging.getLogger("nexus.vision")


def point_in_poly(point: Tuple[float, float], poly: List[List[float]], margin_px: float = 0.0) -> bool:
    """Test if point (x, y) is inside polygon with an optional margin in pixels."""
    if len(poly) < 3:
        return False
    pts = np.array(poly, dtype=np.float32)
    pt = (float(point[0]), float(point[1]))

    # If margin is specified, measure signed distance
    # distance > 0 inside, < 0 outside, 0 on edge
    dist = cv2.pointPolygonTest(pts, pt, measureDist=True)
    return dist >= -margin_px


class VisionEngine:
    def __init__(
        self,
        camera_index: int = 0,
        dictionary_name: int = cv2.aruco.DICT_4X4_50,
        zones_config_path: Optional[str] = None,
        target_marker_id: int = 0,
    ):
        self.camera_index = camera_index
        self.dictionary_name = dictionary_name
        self.target_marker_id = target_marker_id
        self.zones_config_path = zones_config_path

        # ArUco detector setup
        self.aruco_dict = cv2.aruco.getPredefinedDictionary(self.dictionary_name)
        self.aruco_params = cv2.aruco.DetectorParameters()
        # Adapt for OpenCV 4.7+ ArucoDetector if available
        if hasattr(cv2.aruco, "ArucoDetector"):
            self.detector = cv2.aruco.ArucoDetector(self.aruco_dict, self.aruco_params)
        else:
            self.detector = None

        # Zones geometry
        self.zone_a: List[List[float]] = [[100, 200], [300, 200], [300, 400], [100, 400]]
        self.zone_b: List[List[float]] = [[500, 200], [700, 200], [700, 400], [500, 400]]
        self.hysteresis_margin_px: float = 10.0
        self.load_zones(zones_config_path)

        # Threaded capture state
        self.cap: Optional[cv2.VideoCapture] = None
        self.is_running: bool = False
        self.capture_thread: Optional[threading.Thread] = None
        self.latest_frame: Optional[np.ndarray] = None
        self.latest_frame_ns: Optional[int] = None
        self.latest_sample: Optional[Dict[str, Any]] = None

        # History for 1-second detection rate calculation
        self._detection_history: List[Tuple[int, bool]] = []  # (timestamp_ns, visible)
        self._prev_zone: str = "none"
        self._last_visible_ns: Optional[int] = None

    def load_zones(self, config_path: Optional[str]):
        """Load Zone A and Zone B polygons from configuration."""
        if not config_path or not os.path.exists(config_path):
            return
        try:
            with open(config_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                if "zone_a" in data and len(data["zone_a"]) >= 3:
                    self.zone_a = data["zone_a"]
                if "zone_b" in data and len(data["zone_b"]) >= 3:
                    self.zone_b = data["zone_b"]
        except Exception as e:
            logger.error(f"Error loading zones from {config_path}: {e}")

    def save_zones(self, config_path: str, zone_a: List[List[float]], zone_b: List[List[float]]):
        """Save updated Zone A and Zone B coordinates."""
        self.zone_a = zone_a
        self.zone_b = zone_b
        data = {
            "source": "operator_calibrated",
            "updated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "zone_a": zone_a,
            "zone_b": zone_b,
            "marker_side_mm": 40.0,
            "homography_calibrated": False,
        }
        with open(config_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)

    def detect_in_frame(self, frame: np.ndarray, capture_ns: int) -> Dict[str, Any]:
        """Process a single video frame for ArUco marker presence and zone location."""
        if frame is None:
            return {
                "marker_visible": False,
                "marker_center_px": None,
                "marker_corners_px": None,
                "zone_membership": "none",
                "detection_rate_1s": 0.0,
                "frame_age_ms": 0.0,
                "occlusion_ms": 0.0,
            }

        # Convert to grayscale
        if len(frame.shape) == 3:
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        else:
            gray = frame

        # Detect markers
        if self.detector is not None:
            corners, ids, _ = self.detector.detectMarkers(gray)
        else:
            corners, ids, _ = cv2.aruco.detectMarkers(gray, self.aruco_dict, parameters=self.aruco_params)

        marker_found = False
        center_px = None
        corners_list = None
        zone = "none"

        if ids is not None and len(ids) > 0:
            for i, marker_id in enumerate(ids.flatten()):
                if marker_id == self.target_marker_id:
                    marker_found = True
                    c = corners[i][0]  # shape (4, 2)
                    cx = float(np.mean(c[:, 0]))
                    cy = float(np.mean(c[:, 1]))
                    center_px = [round(cx, 1), round(cy, 1)]
                    corners_list = c.tolist()
                    break

        now_ns = capture_ns
        if marker_found:
            self._last_visible_ns = now_ns

            # Zone membership test with 10 px hysteresis
            in_a = point_in_poly(
                center_px,
                self.zone_a,
                margin_px=self.hysteresis_margin_px if self._prev_zone == "A" else 0.0
            )
            in_b = point_in_poly(
                center_px,
                self.zone_b,
                margin_px=self.hysteresis_margin_px if self._prev_zone == "B" else 0.0
            )

            if in_a and not in_b:
                zone = "A"
            elif in_b and not in_a:
                zone = "B"
            else:
                zone = "none"
        else:
            zone = "none"

        self._prev_zone = zone

        # Update 1-second detection rate window
        self._detection_history.append((now_ns, marker_found))
        one_sec_ago = now_ns - 1_000_000_000
        self._detection_history = [
            (t, vis) for (t, vis) in self._detection_history if t >= one_sec_ago
        ]
        if self._detection_history:
            rate = sum(1 for (_, vis) in self._detection_history if vis) / len(self._detection_history)
        else:
            rate = 1.0 if marker_found else 0.0

        # Occlusion calculation
        if self._last_visible_ns is not None:
            occlusion_ms = max(0.0, (now_ns - self._last_visible_ns) / 1e6)
        else:
            occlusion_ms = 99999.0

        sample = {
            "marker_visible": marker_found,
            "marker_center_px": center_px,
            "marker_corners_px": corners_list,
            "zone_membership": zone,
            "detection_rate_1s": round(rate, 3),
            "frame_age_ms": 0.0,
            "occlusion_ms": round(occlusion_ms, 1),
            "capture_ns": capture_ns,
        }
        self.latest_sample = sample
        return sample

    def start(self) -> bool:
        """Start threaded camera acquisition."""
        if self.is_running:
            return True

        self.cap = cv2.VideoCapture(self.camera_index)
        if not self.cap or not self.cap.isOpened():
            logger.warning(f"Failed to open camera index {self.camera_index}.")
            self.cap = None
            return False

        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        self.cap.set(cv2.CAP_PROP_FPS, 30)

        self.is_running = True
        self.capture_thread = threading.Thread(target=self._capture_loop, daemon=True)
        self.capture_thread.start()
        logger.info(f"Vision engine started on camera {self.camera_index}.")
        return True

    def stop(self):
        """Stop video capture thread."""
        self.is_running = False
        if self.capture_thread and self.capture_thread.is_alive():
            self.capture_thread.join(timeout=1.0)
        if self.cap:
            try:
                self.cap.release()
            except Exception:
                pass
            self.cap = None

    def _capture_loop(self):
        """Background loop reading frames and tracking markers."""
        while self.is_running and self.cap and self.cap.isOpened():
            ret, frame = self.cap.read()
            capture_ns = time.monotonic_ns()
            if not ret or frame is None:
                time.sleep(0.01)
                continue

            self.latest_frame = frame
            self.latest_frame_ns = capture_ns
            self.detect_in_frame(frame, capture_ns)

    def get_latest_sample(self) -> Dict[str, Any]:
        """Return the latest tracking sample with updated frame age."""
        now_ns = time.monotonic_ns()
        if not self.latest_sample or self.latest_frame_ns is None:
            return {
                "marker_visible": False,
                "marker_center_px": None,
                "marker_corners_px": None,
                "zone_membership": "none",
                "detection_rate_1s": 0.0,
                "frame_age_ms": 9999.0,
                "occlusion_ms": 9999.0,
                "camera_connected": bool(self.cap and self.cap.isOpened()),
            }

        age_ms = (now_ns - self.latest_frame_ns) / 1e6
        sample = dict(self.latest_sample)
        sample["frame_age_ms"] = round(age_ms, 1)
        sample["camera_connected"] = bool(self.cap and self.cap.isOpened())
        return sample

