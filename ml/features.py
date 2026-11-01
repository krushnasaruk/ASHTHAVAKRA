"""
Reference feature extraction engine for H10 (feat-v1 schema).
Provides exact deterministic computation of 84 features across 7 channels.
"""
from typing import List, Dict, Any
import numpy as np


FEATURE_NAMES = [
    "flex_thumb_mean", "flex_thumb_std", "flex_thumb_min", "flex_thumb_max", "flex_thumb_range", "flex_thumb_median", "flex_thumb_rms", "flex_thumb_mean_diff", "flex_thumb_mean_abs_diff", "flex_thumb_slope", "flex_thumb_peak_count", "flex_thumb_energy",
    "flex_index_mean", "flex_index_std", "flex_index_min", "flex_index_max", "flex_index_range", "flex_index_median", "flex_index_rms", "flex_index_mean_diff", "flex_index_mean_abs_diff", "flex_index_slope", "flex_index_peak_count", "flex_index_energy",
    "flex_middle_mean", "flex_middle_std", "flex_middle_min", "flex_middle_max", "flex_middle_range", "flex_middle_median", "flex_middle_rms", "flex_middle_mean_diff", "flex_middle_mean_abs_diff", "flex_middle_slope", "flex_middle_peak_count", "flex_middle_energy",
    "flex_ring_mean", "flex_ring_std", "flex_ring_min", "flex_ring_max", "flex_ring_range", "flex_ring_median", "flex_ring_rms", "flex_ring_mean_diff", "flex_ring_mean_abs_diff", "flex_ring_slope", "flex_ring_peak_count", "flex_ring_energy",
    "flex_pinky_mean", "flex_pinky_std", "flex_pinky_min", "flex_pinky_max", "flex_pinky_range", "flex_pinky_median", "flex_pinky_rms", "flex_pinky_mean_diff", "flex_pinky_mean_abs_diff", "flex_pinky_slope", "flex_pinky_peak_count", "flex_pinky_energy",
    "accel_mag_mean", "accel_mag_std", "accel_mag_min", "accel_mag_max", "accel_mag_range", "accel_mag_median", "accel_mag_rms", "accel_mag_mean_diff", "accel_mag_mean_abs_diff", "accel_mag_slope", "accel_mag_peak_count", "accel_mag_energy",
    "gyro_mag_mean", "gyro_mag_std", "gyro_mag_min", "gyro_mag_max", "gyro_mag_range", "gyro_mag_median", "gyro_mag_rms", "gyro_mag_mean_diff", "gyro_mag_mean_abs_diff", "gyro_mag_slope", "gyro_mag_peak_count", "gyro_mag_energy"
]


def count_peaks(x: np.ndarray, prominence_ratio: float = 0.05) -> float:
    """
    Deterministic peak counter.
    A sample x[i] is a peak if x[i] > x[i-1] and x[i] >= x[i+1],
    and prominence (height above min of immediate valley) >= prominence_ratio * range.
    """
    n = len(x)
    if n < 3:
        return 0.0
    val_range = float(np.max(x) - np.min(x))
    prominence_thresh = max(1.0, val_range * prominence_ratio)
    
    count = 0
    for i in range(1, n - 1):
        if x[i] > x[i - 1] and x[i] >= x[i + 1]:
            prom = x[i] - min(x[i - 1], x[i + 1])
            if prom >= prominence_thresh:
                count += 1
    return float(count)


def extract_channel_features(x: np.ndarray) -> List[float]:
    """
    Computes 12 deterministic metrics for a 1D sequence of length N.
    """
    n = len(x)
    if n == 0:
        return [0.0] * 12
    
    x = np.asarray(x, dtype=np.float64)
    mean_val = float(np.mean(x))
    std_val = float(np.std(x, ddof=0))
    min_val = float(np.min(x))
    max_val = float(np.max(x))
    range_val = float(max_val - min_val)
    median_val = float(np.median(x))
    energy_val = float(np.mean(x ** 2))
    rms_val = float(np.sqrt(energy_val))
    
    if n > 1:
        diffs = np.diff(x)
        mean_diff_val = float(np.mean(diffs))
        mean_abs_diff_val = float(np.mean(np.abs(diffs)))
        
        # Linear slope
        t = np.arange(n, dtype=np.float64)
        t_bar = (n - 1.0) / 2.0
        t_diff = t - t_bar
        var_t = np.sum(t_diff ** 2)
        slope_val = float(np.sum(t_diff * (x - mean_val)) / var_t)
    else:
        mean_diff_val = 0.0
        mean_abs_diff_val = 0.0
        slope_val = 0.0
        
    peak_count_val = count_peaks(x)
    
    return [
        mean_val,
        std_val,
        min_val,
        max_val,
        range_val,
        median_val,
        rms_val,
        mean_diff_val,
        mean_abs_diff_val,
        slope_val,
        peak_count_val,
        energy_val
    ]


def extract_window_features(window_samples: List[Dict[str, Any]]) -> List[float]:
    """
    Extracts 84 feat-v1 features from a list of 75 sample dicts.
    Each sample dict contains:
      - 'flex': [5 ints/floats]
      - 'imu': [ax, ay, az, gx, gy, gz]
    """
    n = len(window_samples)
    if n == 0:
        return [0.0] * 84
    
    # 7 channels: flex[0..4], accel_mag, gyro_mag
    ch_data = [[] for _ in range(7)]
    for s in window_samples:
        flex = s["flex"]
        for f_idx in range(5):
            ch_data[f_idx].append(float(flex[f_idx]))
            
        imu = s["imu"]
        ax, ay, az, gx, gy, gz = imu[0], imu[1], imu[2], imu[3], imu[4], imu[5]
        accel_mag = np.sqrt(ax * ax + ay * ay + az * az)
        gyro_mag = np.sqrt(gx * gx + gy * gy + gz * gz)
        ch_data[5].append(float(accel_mag))
        ch_data[6].append(float(gyro_mag))
        
    features = []
    for ch_idx in range(7):
        ch_arr = np.array(ch_data[ch_idx], dtype=np.float64)
        ch_feats = extract_channel_features(ch_arr)
        features.extend(ch_feats)
        
    return features

