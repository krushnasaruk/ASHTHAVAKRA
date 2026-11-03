"""
Flexion percentage normalization for RehabBridge NEXUS / H10.
Implements Build Specification v3 Section 7.2 and tests SG-01 to SG-03.
"""

import math
from typing import Optional, Union


def normalize_flexion(
    raw_val: Union[int, float],
    open_val: float,
    bent_val: float,
    polarity: int = 1,
) -> float:
    """
    Normalizes a raw ADC reading to 0-100% flexion.
    Formula: flexion_pct = clamp(100 * polarity * (raw - open) / abs(bent - open), 0, 100)
    """
    if not isinstance(raw_val, (int, float)) or math.isnan(raw_val) or math.isinf(raw_val):
        raise ValueError("INPUT_NAN_OR_INF")
    if math.isnan(open_val) or math.isnan(bent_val) or math.isinf(open_val) or math.isinf(bent_val):
        raise ValueError("CALIBRATION_NAN_OR_INF")

    span = abs(float(bent_val) - float(open_val))
    if span < 1e-6:
        raise ValueError("INVALID_SPAN_ZERO")

    if polarity == 0:
        polarity = 1 if bent_val > open_val else -1

    ratio = float(polarity) * (float(raw_val) - float(open_val)) / span
    pct = 100.0 * ratio
    return max(0.0, min(100.0, pct))
