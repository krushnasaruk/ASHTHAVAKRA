"""
Stillness detection for RehabBridge NEXUS / H10.
Implements Build Specification v3 Section 7.7 and test SG-11.
"""

from collections import deque
import math
from typing import List, Optional, Tuple


class StillnessDetector:
    def __init__(self, still_px: float = 6.0, window_ms: float = 500.0):
        self.still_px = float(still_px)
        self.window_ms = float(window_ms)
        self.history: deque = deque()  # (t_ms, (x, y), zone)

    def update(self, center_px: Optional[Tuple[float, float]], zone: str, t_ms: float) -> bool:
        """
        Updates detector with marker center and zone.
        Returns True if marker has been still (< still_px displacement) and in same zone for >= window_ms.
        """
        if center_px is None:
            self.history.clear()
            return False

        self.history.append((t_ms, center_px, zone))

        # Evict samples older than window_ms
        while self.history and (t_ms - self.history[0][0]) > self.window_ms:
            self.history.popleft()

        # Requires history spanning at least window_ms
        if not self.history or (t_ms - self.history[0][0]) < (self.window_ms - 50.0):
            return False

        first_pt = self.history[0][1]
        first_zone = self.history[0][2]

        for _, pt, z in self.history:
            if z != first_zone:
                return False
            dx = pt[0] - first_pt[0]
            dy = pt[1] - first_pt[1]
            dist = math.sqrt(dx * dx + dy * dy)
            if dist > self.still_px:
                return False

        return True
