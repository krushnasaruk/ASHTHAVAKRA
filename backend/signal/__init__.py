"""
Signal processing layer for RehabBridge NEXUS / H10.
Pure Python implementations with no hardware I/O.
"""

from .calibration import CalibrationModel, CalibrationCapture
from .normalize import normalize_flexion
from .filters import ExponentialMovingAverage, MedianFilter, CompoundFilter
from .contact import FSRContactDetector
from .grip import GripChangeDetector
from .imu import IMUProcessor
from .stillness import StillnessDetector

__all__ = [
    "CalibrationModel",
    "CalibrationCapture",
    "normalize_flexion",
    "ExponentialMovingAverage",
    "MedianFilter",
    "CompoundFilter",
    "FSRContactDetector",
    "GripChangeDetector",
    "IMUProcessor",
    "StillnessDetector",
]
