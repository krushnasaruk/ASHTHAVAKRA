"""
Grip-Change Detector for RehabBridge NEXUS / H10.
Implements Build Specification v3 Section 7.5 and test SG-09.
"""

from collections import deque
from typing import List, Optional, Tuple, Dict, Any


class GripChangeDetector:
    def __init__(
        self,
        grip_delta_pct: float = 15.0,
        window_ms: float = 400.0,
        hold_ms: float = 150.0,
    ):
        self.grip_delta_pct = float(grip_delta_pct)
        self.window_ms = float(window_ms)
        self.hold_ms = float(hold_ms)

        # Buffer of (t_ms, [flex_pct_ch0, ...])
        self.history: deque = deque()
        self._candidate_start_ms: Optional[float] = None
        self._candidate_channels: List[int] = []

    def update(self, flex_pcts: List[float], t_ms: float) -> Tuple[bool, List[int]]:
        """
        Updates detector with current normalized flexion percentages.
        Returns (grip_change_detected, channels_triggered).
        """
        self.history.append((t_ms, list(flex_pcts)))

        # Evict history older than window_ms + hold_ms
        while self.history and (t_ms - self.history[0][0]) > (self.window_ms + self.hold_ms):
            self.history.popleft()

        # Find sample closest to window_ms ago
        baseline_sample = None
        for old_t, old_flex in self.history:
            if (t_ms - old_t) >= self.window_ms:
                baseline_sample = old_flex
            else:
                break

        if baseline_sample is None:
            return False, []

        triggered_channels = []
        for ch, (curr, base) in enumerate(zip(flex_pcts, baseline_sample)):
            delta = abs(curr - base)
            if delta >= self.grip_delta_pct:
                triggered_channels.append(ch)

        if triggered_channels:
            if self._candidate_start_ms is None:
                self._candidate_start_ms = t_ms
                self._candidate_channels = triggered_channels
            elif (t_ms - self._candidate_start_ms) >= self.hold_ms:
                # Confirmed persistent grip change
                res_channels = list(self._candidate_channels)
                self._candidate_start_ms = None
                self._candidate_channels = []
                return True, res_channels
        else:
            self._candidate_start_ms = None
            self._candidate_channels = []

        return False, []

