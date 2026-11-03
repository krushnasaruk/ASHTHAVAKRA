"""
Calibration Engine for RehabBridge NEXUS / H10.
Manages baseline capture for Open Hand, Bent Hand, No-contact FSR, and Contact FSR.
Validates minimum ADC spans and computes repeatability across repeated captures.
"""

import math
import time
from typing import Dict, List, Optional, Tuple, Any
import numpy as np


class ChannelCalibration:
    def __init__(
        self,
        open_median: float,
        bent_median: float,
        open_std: float,
        bent_std: float,
        polarity: int = 1,
        min_span: float = 300.0,
    ):
        self.open_median = float(open_median)
        self.bent_median = float(bent_median)
        self.open_std = float(open_std)
        self.bent_std = float(bent_std)
        self.polarity = polarity  # +1 if bent > open, -1 if bent < open
        self.span = abs(self.bent_median - self.open_median)
        self.min_span = min_span

        if self.span < self.min_span:
            self.valid = False
            self.reason = f"SPAN_TOO_SMALL_{self.span:.1f}_LT_{self.min_span:.1f}"
        else:
            self.valid = True
            self.reason = "OK"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "open_median": round(self.open_median, 1),
            "bent_median": round(self.bent_median, 1),
            "open_std": round(self.open_std, 2),
            "bent_std": round(self.bent_std, 2),
            "span": round(self.span, 1),
            "polarity": self.polarity,
            "valid": self.valid,
            "reason": self.reason,
        }


class CalibrationModel:
    def __init__(
        self,
        channels: List[ChannelCalibration],
        fsr_no_contact_median: float = 0.0,
        fsr_no_contact_std: float = 10.0,
        fsr_contact_median: float = 8000.0,
        fsr_contact_std: float = 100.0,
        profile: str = "demo3",
        volunteer_pseudonym: str = "UNKNOWN",
        repeat_index: int = 1,
    ):
        self.channels = channels
        self.fsr_no_contact_median = float(fsr_no_contact_median)
        self.fsr_no_contact_std = max(1.0, float(fsr_no_contact_std))
        self.fsr_contact_median = float(fsr_contact_median)
        self.fsr_contact_std = max(1.0, float(fsr_contact_std))
        self.profile = profile
        self.volunteer_pseudonym = volunteer_pseudonym
        self.repeat_index = repeat_index
        self.created_at = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

        # Model is valid only if all enabled channels are valid
        self.valid = all(ch.valid for ch in self.channels)
        self.reason = "OK" if self.valid else "; ".join(ch.reason for ch in self.channels if not ch.valid)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "profile": self.profile,
            "volunteer_pseudonym": self.volunteer_pseudonym,
            "repeat_index": self.repeat_index,
            "created_at": self.created_at,
            "valid": self.valid,
            "reason": self.reason,
            "channels": [ch.to_dict() for ch in self.channels],
            "fsr": {
                "no_contact_median": round(self.fsr_no_contact_median, 1),
                "no_contact_std": round(self.fsr_no_contact_std, 2),
                "contact_median": round(self.fsr_contact_median, 1),
                "contact_std": round(self.fsr_contact_std, 2),
            },
        }


class CalibrationCapture:
    """Helper to collect and analyze 2-second capture windows for calibration."""
    def __init__(self, max_std: float = 40.0, min_span: float = 300.0, min_samples: int = 40):
        self.max_std = max_std
        self.min_span = min_span
        self.min_samples = min_samples

    def analyze_window(self, samples: List[float]) -> Tuple[bool, float, float, str]:
        """Returns (valid, median, std, reason)."""
        if len(samples) < self.min_samples:
            return False, 0.0, 0.0, f"INSUFFICIENT_SAMPLES_{len(samples)}"
        arr = np.array(samples, dtype=np.float64)
        median_val = float(np.median(arr))
        std_val = float(np.std(arr))
        if std_val > self.max_std:
            return False, median_val, std_val, f"STD_TOO_HIGH_{std_val:.1f}_GT_{self.max_std:.1f}"
        return True, median_val, std_val, "OK"

