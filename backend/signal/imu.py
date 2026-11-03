"""
IMU Processing and Kinematics for RehabBridge NEXUS / H10.
Implements Build Specification v3 Section 7.6 and test SG-10.
"""

from collections import deque
import math
from typing import Dict, List, Optional, Tuple, Any
import numpy as np


class IMUProcessor:
    def __init__(
        self,
        accel_scale_lsb_per_g: float = 8192.0,
        gyro_scale_lsb_per_deg_s: float = 65.5,
        tilt_alpha: float = 0.98,
        motion_rms_window_ms: float = 500.0,
    ):
        self.accel_scale = float(accel_scale_lsb_per_g)
        self.gyro_scale = float(gyro_scale_lsb_per_deg_s)
        self.tilt_alpha = float(tilt_alpha)
        self.motion_rms_window_ms = float(motion_rms_window_ms)

        self.pitch_deg: float = 0.0
        self.roll_deg: float = 0.0
        self._last_t_ms: Optional[float] = None
        self._gyro_history: deque = deque()  # (t_ms, gyro_mag)

    def convert_raw(self, raw_imu: List[int]) -> Dict[str, Any]:
        """Convert raw int16 [ax, ay, az, gx, gy, gz] to physical units [g, deg/s]."""
        if len(raw_imu) < 6:
            return {"accel_g": [0.0, 0.0, 0.0], "gyro_dps": [0.0, 0.0, 0.0]}
        ax, ay, az = [float(v) / self.accel_scale for v in raw_imu[:3]]
        gx, gy, gz = [float(v) / self.gyro_scale for v in raw_imu[3:6]]
        return {
            "accel_g": [round(ax, 4), round(ay, 4), round(az, 4)],
            "gyro_dps": [round(gx, 2), round(gy, 2), round(gz, 2)],
        }

    def update(self, raw_imu: List[int], t_ms: float) -> Dict[str, Any]:
        converted = self.convert_raw(raw_imu)
        ax, ay, az = converted["accel_g"]
        gx, gy, gz = converted["gyro_dps"]

        # Gyro magnitude and windowed RMS
        gyro_mag = math.sqrt(gx * gx + gy * gy + gz * gz)
        self._gyro_history.append((t_ms, gyro_mag))

        # Evict old samples from RMS window
        while self._gyro_history and (t_ms - self._gyro_history[0][0]) > self.motion_rms_window_ms:
            self._gyro_history.popleft()

        mags = [m for (_, m) in self._gyro_history]
        motion_rms = float(np.sqrt(np.mean(np.square(mags)))) if mags else 0.0

        # Complementary filter for tilt
        dt_s = 0.04  # default 25 Hz
        if self._last_t_ms is not None and t_ms > self._last_t_ms:
            dt_s = (t_ms - self._last_t_ms) / 1000.0
        self._last_t_ms = t_ms

        accel_pitch = math.degrees(math.atan2(-ax, math.sqrt(ay * ay + az * az)))
        accel_roll = math.degrees(math.atan2(ay, az))

        self.pitch_deg = self.tilt_alpha * (self.pitch_deg + gy * dt_s) + (1.0 - self.tilt_alpha) * accel_pitch
        self.roll_deg = self.tilt_alpha * (self.roll_deg + gx * dt_s) + (1.0 - self.tilt_alpha) * accel_roll

        return {
            "accel_g": [ax, ay, az],
            "gyro_dps": [gx, gy, gz],
            "pitch_deg": round(self.pitch_deg, 2),
            "roll_deg": round(self.roll_deg, 2),
            "motion_energy_rms": round(motion_rms, 2),
        }

