"""
TaskProof State Machine for RehabBridge NEXUS / H10.
Complies with Build Specification v3 Section 8 and test suite TP-01 through TP-20.
Verifies an object transfer task deterministically using multi-modal sensor & vision evidence.
Emits honest verdicts: VERIFIED, FAILED, UNCERTAIN, ABORTED.
"""

from enum import Enum
import hashlib
import json
import logging
import os
import time
from typing import Dict, List, Optional, Tuple, Any

import yaml

logger = logging.getLogger("nexus.taskproof")


class TaskState(str, Enum):
    DISCONNECTED = "DISCONNECTED"
    NOT_STARTED = "NOT_STARTED"
    READY = "READY"
    SOURCE_VISIBLE = "SOURCE_VISIBLE"
    CONTACT_CANDIDATE = "CONTACT_CANDIDATE"
    OBJECT_LIFTED = "OBJECT_LIFTED"
    TARGET_REACHED = "TARGET_REACHED"
    RELEASE_CONFIRMED = "RELEASE_CONFIRMED"
    VERIFIED = "VERIFIED"
    FAILED = "FAILED"
    UNCERTAIN = "UNCERTAIN"
    ABORTED = "ABORTED"


class TaskVerdict(str, Enum):
    NOT_STARTED = "NOT_STARTED"
    VERIFIED = "VERIFIED"
    FAILED = "FAILED"
    UNCERTAIN = "UNCERTAIN"
    ABORTED = "ABORTED"


class TaskEvent:
    def __init__(self, from_state: str, to_state: str, host_monotonic_ns: int, reason: str, evidence: Optional[Dict[str, Any]] = None):
        self.from_state = from_state
        self.to_state = to_state
        self.host_monotonic_ns = host_monotonic_ns
        self.reason = reason
        self.evidence = evidence or {}

    def to_dict(self) -> Dict[str, Any]:
        return {
            "from_state": self.from_state,
            "to_state": self.to_state,
            "host_monotonic_ns": self.host_monotonic_ns,
            "reason": self.reason,
            "evidence": self.evidence,
        }


class TaskProofEngine:
    def __init__(self, config_path: Optional[str] = None):
        self.config_path = config_path or os.path.join(os.path.dirname(os.path.dirname(__file__)), "config", "taskproof.yaml")
        self.config: Dict[str, Any] = {}
        self.config_hash: str = ""
        self.load_config()

        self.current_state: TaskState = TaskState.READY
        self.verdict: TaskVerdict = TaskVerdict.NOT_STARTED
        self.reason_codes: List[str] = []
        self.events: List[TaskEvent] = []

        # Attempt timing
        self.attempt_id: Optional[str] = None
        self.attempt_start_ns: Optional[int] = None
        self.attempt_end_ns: Optional[int] = None

        # Tracking state helpers
        self._source_visible_start_ns: Optional[int] = None
        self._target_arrival_ns: Optional[int] = None
        self._contact_candidate_ns: Optional[int] = None
        self._contact_off_ns: Optional[int] = None
        self._release_confirmed_ns: Optional[int] = None

        # Evidence counters
        self._total_frame_count: int = 0
        self._visible_frame_count: int = 0
        self._last_marker_seen_ns: Optional[int] = None
        self._last_contact_on_ns: Optional[int] = None
        self._last_grip_change_ns: Optional[int] = None

    def load_config(self):
        """Loads taskproof configuration and calculates SHA-256 fingerprint."""
        if os.path.exists(self.config_path):
            with open(self.config_path, "r", encoding="utf-8") as f:
                content = f.read()
                self.config = yaml.safe_load(content)
                self.config_hash = hashlib.sha256(content.encode("utf-8")).hexdigest()
        else:
            self.config = {
                "timers": {
                    "attempt_timeout_s": {"value": 20.0},
                    "lift_window_s": {"value": 4.0},
                    "source_visible_hold_ms": {"value": 500},
                    "target_reached_hold_ms": {"value": 300},
                    "release_confirmed_hold_ms": {"value": 500},
                },
                "thresholds": {
                    "min_source_detection_rate": {"value": 0.80},
                    "max_occlusion_ms": {"value": 150},
                    "max_frame_age_ms": {"value": 200},
                    "max_sensor_packet_age_ms": {"value": 200},
                    "min_attempt_camera_visibility": {"value": 0.80},
                    "contact_grip_max_separation_s": {"value": 1.0},
                }
            }
            self.config_hash = hashlib.sha256(json.dumps(self.config).encode("utf-8")).hexdigest()

    def get_timer(self, name: str, default: float) -> float:
        try:
            return float(self.config["timers"][name]["value"])
        except Exception:
            return default

    def get_threshold(self, name: str, default: float) -> float:
        try:
            return float(self.config["thresholds"][name]["value"])
        except Exception:
            return default

    def _transition(self, to_state: TaskState, now_ns: int, reason: str, evidence: Optional[Dict[str, Any]] = None):
        """Logs and commits a state transition."""
        evt = TaskEvent(
            from_state=self.current_state.value,
            to_state=to_state.value,
            host_monotonic_ns=now_ns,
            reason=reason,
            evidence=evidence or {}
        )
        self.events.append(evt)
        self.current_state = to_state

        if to_state in [TaskState.VERIFIED, TaskState.FAILED, TaskState.UNCERTAIN, TaskState.ABORTED]:
            self.attempt_end_ns = now_ns
            self.verdict = TaskVerdict(to_state.value)
            if reason and reason not in self.reason_codes:
                self.reason_codes.append(reason)

    def start_attempt(self, attempt_id: str, now_ns: int):
        """Initializes a new task verification attempt."""
        self.attempt_id = attempt_id
        self.attempt_start_ns = now_ns
        self.attempt_end_ns = None
        self.current_state = TaskState.READY
        self.verdict = TaskVerdict.NOT_STARTED
        self.reason_codes = []
        self.events = []

        self._source_visible_start_ns = None
        self._target_arrival_ns = None
        self._contact_candidate_ns = None
        self._contact_off_ns = None
        self._release_confirmed_ns = None

        self._total_frame_count = 0
        self._visible_frame_count = 0
        self._last_marker_seen_ns = None
        self._last_contact_on_ns = None
        self._last_grip_change_ns = None

        self._transition(TaskState.READY, now_ns, "ATTEMPT_STARTED", {"attempt_id": attempt_id})

    def abort(self, reason: str = "OPERATOR_ABORT", now_ns: Optional[int] = None):
        """Operator or user aborts active attempt."""
        n_ns = now_ns or time.monotonic_ns()
        self._transition(TaskState.ABORTED, n_ns, reason)

    def update(
        self,
        sensor_pkt: Optional[Dict[str, Any]],
        vision_sample: Optional[Dict[str, Any]],
        contact_on: bool,
        grip_change: bool,
        object_still: bool,
        now_ns: int,
    ) -> TaskState:
        """
        Step the state machine with synchronous sensor & vision inputs.
        """
        if self.current_state in [TaskState.VERIFIED, TaskState.FAILED, TaskState.UNCERTAIN, TaskState.ABORTED]:
            return self.current_state

        attempt_timeout_ns = int(self.get_timer("attempt_timeout_s", 20.0) * 1e9)
        max_frame_age_ms = self.get_threshold("max_frame_age_ms", 200.0)
        max_sensor_age_ms = self.get_threshold("max_sensor_packet_age_ms", 200.0)
        max_occlusion_ms = self.get_threshold("max_occlusion_ms", 150.0)

        # 1. Device and sensor health integrity checks
        if sensor_pkt is None:
            self._transition(TaskState.UNCERTAIN, now_ns, "DEVICE_DISCONNECTED")
            return self.current_state

        if not sensor_pkt.get("adc_ok", True):
            self._transition(TaskState.UNCERTAIN, now_ns, "ADC_FAULT")
            return self.current_state

        if not sensor_pkt.get("fsr_ok", True):
            self._transition(TaskState.UNCERTAIN, now_ns, "FSR_FAULT")
            return self.current_state

        # Check sensor packet freshness
        sensor_age_ms = (now_ns - sensor_pkt.get("host_monotonic_ns", now_ns)) / 1e6
        if sensor_age_ms > max_sensor_age_ms:
            self._transition(TaskState.UNCERTAIN, now_ns, "SENSOR_STALE", {"sensor_age_ms": sensor_age_ms})
            return self.current_state

        # 2. Vision health integrity checks
        if vision_sample is None:
            self._transition(TaskState.UNCERTAIN, now_ns, "CAMERA_MISSING")
            return self.current_state

        frame_age_ms = vision_sample.get("frame_age_ms", 0.0)
        if frame_age_ms > max_frame_age_ms:
            self._transition(TaskState.UNCERTAIN, now_ns, "CAMERA_FRAME_STALE", {"frame_age_ms": frame_age_ms})
            return self.current_state

        # Accumulate visibility stats
        self._total_frame_count += 1
        marker_vis = vision_sample.get("marker_visible", False)
        if marker_vis:
            self._visible_frame_count += 1
            self._last_marker_seen_ns = now_ns

        zone = vision_sample.get("zone_membership", "none")
        det_rate = vision_sample.get("detection_rate_1s", 0.0)

        # Occlusion check: if marker missing > 150 ms during critical transfer states
        occlusion_ms = vision_sample.get("occlusion_ms", 0.0)
        if self.current_state in [TaskState.CONTACT_CANDIDATE, TaskState.OBJECT_LIFTED]:
            if occlusion_ms > max_occlusion_ms:
                self._transition(TaskState.UNCERTAIN, now_ns, "MARKER_OCCLUDED", {"occlusion_ms": occlusion_ms})
                return self.current_state

        # Track contact and grip events
        if contact_on:
            self._last_contact_on_ns = now_ns
        if grip_change:
            self._last_grip_change_ns = now_ns

        # 3. Overall attempt timeout check
        if self.attempt_start_ns is not None:
            elapsed_ns = now_ns - self.attempt_start_ns
            if elapsed_ns >= attempt_timeout_ns:
                # If adequate evidence was collected, fail with TIMEOUT, else UNCERTAIN
                if self._total_frame_count >= 10:
                    self._transition(TaskState.FAILED, now_ns, "TIMEOUT", {"elapsed_s": elapsed_ns / 1e9})
                else:
                    self._transition(TaskState.UNCERTAIN, now_ns, "TIMEOUT_INSUFFICIENT_EVIDENCE")
                return self.current_state

        # ==========================================
        # 4. State Transition Logic
        # ==========================================

        # READY -> SOURCE_VISIBLE
        if self.current_state == TaskState.READY:
            min_det_rate = self.get_threshold("min_source_detection_rate", 0.80)
            hold_ms = self.get_timer("source_visible_hold_ms", 500.0)

            if zone == "A" and det_rate >= min_det_rate:
                if self._source_visible_start_ns is None:
                    self._source_visible_start_ns = now_ns
                elif (now_ns - self._source_visible_start_ns) >= int(hold_ms * 1e6):
                    self._transition(TaskState.SOURCE_VISIBLE, now_ns, "SOURCE_ZONE_A_CONFIRMED", {"det_rate": det_rate})
            else:
                self._source_visible_start_ns = None

        # SOURCE_VISIBLE -> CONTACT_CANDIDATE
        elif self.current_state == TaskState.SOURCE_VISIBLE:
            max_separation_s = self.get_threshold("contact_grip_max_separation_s", 1.0)
            if contact_on and self._last_grip_change_ns is not None:
                separation_s = abs(now_ns - self._last_grip_change_ns) / 1e9
                if separation_s <= max_separation_s:
                    self._contact_candidate_ns = now_ns
                    self._transition(TaskState.CONTACT_CANDIDATE, now_ns, "CONTACT_AND_GRIP_DETECTED", {"separation_s": separation_s})

        # CONTACT_CANDIDATE -> OBJECT_LIFTED or FAILED
        elif self.current_state == TaskState.CONTACT_CANDIDATE:
            lift_window_ns = int(self.get_timer("lift_window_s", 4.0) * 1e9)
            if self._contact_candidate_ns is not None:
                elapsed_candidate_ns = now_ns - self._contact_candidate_ns
                if elapsed_candidate_ns > lift_window_ns:
                    # Lift window expired without marker moving out of A
                    if zone == "A":
                        self._transition(TaskState.FAILED, now_ns, "FALSE_GESTURE")
                    else:
                        self._transition(TaskState.FAILED, now_ns, "NO_LIFT")
                    return self.current_state

            # If contact drops before leaving zone A
            if not contact_on:
                self._transition(TaskState.FAILED, now_ns, "RELEASED_EARLY", {"zone": zone})
                return self.current_state

            # Successful lift: marker leaves zone A while contact remains ON
            if zone != "A" and contact_on:
                self._transition(TaskState.OBJECT_LIFTED, now_ns, "OBJECT_LIFTED_OUT_OF_A", {"zone": zone})

        # OBJECT_LIFTED -> TARGET_REACHED or FAILED
        elif self.current_state == TaskState.OBJECT_LIFTED:
            # If contact dropped before reaching target zone B
            if not contact_on:
                self._transition(TaskState.FAILED, now_ns, "RELEASED_EARLY", {"zone": zone})
                return self.current_state

            # Reached target zone B
            if zone == "B":
                hold_target_ns = int(self.get_timer("target_reached_hold_ms", 300.0) * 1e6)
                if self._target_arrival_ns is None:
                    self._target_arrival_ns = now_ns
                elif (now_ns - self._target_arrival_ns) >= hold_target_ns:
                    self._transition(TaskState.TARGET_REACHED, now_ns, "TARGET_ZONE_B_REACHED", {"zone": zone})
            else:
                self._target_arrival_ns = None

        # TARGET_REACHED -> RELEASE_CONFIRMED or FAILED
        elif self.current_state == TaskState.TARGET_REACHED:
            # Must remain in zone B
            if zone != "B":
                self._transition(TaskState.FAILED, now_ns, "WRONG_TARGET", {"zone": zone})
                return self.current_state

            # Detect contact release
            if not contact_on:
                if self._contact_off_ns is None:
                    self._contact_off_ns = now_ns

                release_hold_ns = int(self.get_timer("release_confirmed_hold_ms", 500.0) * 1e6)
                elapsed_release_ns = now_ns - self._contact_off_ns

                if elapsed_release_ns >= release_hold_ns:
                    if object_still:
                        self._release_confirmed_ns = now_ns
                        self._transition(TaskState.RELEASE_CONFIRMED, now_ns, "RELEASE_CONFIRMED_STILL")
                    else:
                        self._transition(TaskState.FAILED, now_ns, "OBJECT_MOVED_AFTER_RELEASE")
                        return self.current_state

        # RELEASE_CONFIRMED -> VERIFIED
        elif self.current_state == TaskState.RELEASE_CONFIRMED:
            # Quality & Freshness check
            vis_ratio = float(self._visible_frame_count) / max(1, self._total_frame_count)
            min_vis = self.get_threshold("min_attempt_camera_visibility", 0.80)

            if vis_ratio < min_vis:
                self._transition(TaskState.UNCERTAIN, now_ns, "LOW_DETECTION_RATE", {"vis_ratio": vis_ratio})
            else:
                self._transition(TaskState.VERIFIED, now_ns, "ALL_GUARDS_VERIFIED", {
                    "visibility_ratio": round(vis_ratio, 3),
                    "total_frames": self._total_frame_count
                })

        return self.current_state

    def get_summary(self) -> Dict[str, Any]:
        """Summarizes completed attempt metrics for database and reports."""
        vis_ratio = float(self._visible_frame_count) / max(1, self._total_frame_count)
        duration_s = 0.0
        if self.attempt_start_ns and self.attempt_end_ns:
            duration_s = (self.attempt_end_ns - self.attempt_start_ns) / 1e9

        return {
            "attempt_id": self.attempt_id,
            "verdict": self.verdict.value,
            "reason_codes": self.reason_codes,
            "duration_s": round(duration_s, 3),
            "camera_visibility_ratio": round(vis_ratio, 3),
            "config_hash": self.config_hash,
            "event_count": len(self.events),
            "events": [e.to_dict() for e in self.events],
        }

