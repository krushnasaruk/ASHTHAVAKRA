"""
Digital filtering for RehabBridge NEXUS / H10.
Implements EMA, Median, and Compound (Median-then-EMA) filters per Section 7.3.
"""

from collections import deque
from typing import Optional, List
import numpy as np


class ExponentialMovingAverage:
    def __init__(self, alpha: float):
        if not (0.0 < alpha <= 1.0):
            raise ValueError(f"Alpha must be in (0, 1], got {alpha}")
        self.alpha = float(alpha)
        self.state: Optional[float] = None

    def update(self, x: float) -> float:
        if self.state is None:
            self.state = float(x)
        else:
            self.state = self.alpha * float(x) + (1.0 - self.alpha) * self.state
        return self.state

    def reset(self):
        self.state = None


class MedianFilter:
    def __init__(self, window_size: int = 5):
        if window_size < 1 or window_size % 2 == 0:
            # Force odd window size for clear median
            window_size = max(1, window_size if window_size % 2 != 0 else window_size + 1)
        self.window_size = window_size
        self.buffer = deque(maxlen=window_size)

    def update(self, x: float) -> float:
        self.buffer.append(float(x))
        return float(np.median(self.buffer))

    def reset(self):
        self.buffer.clear()


class CompoundFilter:
    """Combines a median pre-filter to suppress spikes, followed by an EMA for smoothing."""
    def __init__(self, median_window: int = 5, ema_alpha: float = 0.15):
        self.median_filter = MedianFilter(window_size=median_window)
        self.ema_filter = ExponentialMovingAverage(alpha=ema_alpha)

    def update(self, x: float) -> float:
        med_out = self.median_filter.update(x)
        return self.ema_filter.update(med_out)

    def reset(self):
        self.median_filter.reset()
        self.ema_filter.reset()

