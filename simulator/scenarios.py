"""
Deterministic movement trajectory generator for H10 simulator.
Produces parameterized 50 Hz trajectories for 8 scenarios.
"""
from typing import List, Dict, Any, Generator
import numpy as np


class SimulatorScenario:
    """Base class for deterministic scenarios."""
    def __init__(self, name: str, duration_s: float, sampling_hz: int = 50, seed: int = 42):
        self.name = name
        self.duration_s = duration_s
        self.sampling_hz = sampling_hz
        self.total_samples = int(duration_s * sampling_hz)
        self.seed = seed
        self.rng = np.random.RandomState(seed)

    def generate_frames(self) -> List[Dict[str, Any]]:
        raise NotImplementedError


def smooth_half_sine(t: float, t_start: float, duration: float, amplitude: float = 1.0) -> float:
    """Smooth movement profile between 0 and amplitude."""
    if t < t_start or t > t_start + duration:
        return 0.0
    phase = (t - t_start) / duration
    return amplitude * float(np.sin(np.pi * phase))


def smooth_bell(t: float, t_start: float, duration: float, amplitude: float = 1.0) -> float:
    """Smooth minimum-jerk style bell curve for tap."""
    if t < t_start or t > t_start + duration:
        return 0.0
    phase = (t - t_start) / duration
    # 30 * p^2 * (1 - p)^2 peak at 0.5 is 30 * 0.25 * 0.25 = 1.875
    val = (1.0 - np.cos(2 * np.pi * phase)) / 2.0
    return amplitude * float(val)


class OpenHandRestScenario(SimulatorScenario):
    """Scenario 1: Steady open hand for calibration & quality-gate checks."""
    def __init__(self, duration_s: float = 10.0, seed: int = 42):
        super().__init__("open_hand_rest", duration_s=duration_s, seed=seed)

    def generate_frames(self) -> List[Dict[str, Any]]:
        frames = []
        for i in range(self.total_samples):
            # Baseline open hand: ~1000 ADC with low Gaussian noise (std ~5 ADC counts)
            noise = self.rng.normal(0, 3, 5)
            flex = [int(np.clip(1000 + noise[j], 0, 4095)) for j in range(5)]
            imu = [int(self.rng.normal(0, 2)), int(self.rng.normal(0, 2)), int(980 + self.rng.normal(0, 2)), 0, 0, 0]
            frames.append({
                "t": int(i * 1000 / self.sampling_hz),
                "flex": flex,
                "imu": imu,
                "fsr": 0,
                "flags": 0b00001001,  # bit 0: calibrated, bit 3: simulated
                "battery": 95,
                "simulated": True
            })
        return frames


class FistRepetitionsScenario(SimulatorScenario):
    """Scenario 2: 20 clean fist clenches at moderate speed (rep duration 2.0s, rest 1.0s)."""
    def __init__(self, rep_count: int = 20, seed: int = 42):
        # 20 reps * 3.0s = 60s + 2s initial rest = 62s
        super().__init__("fist_repetitions", duration_s=rep_count * 3.0 + 2.0, seed=seed)
        self.rep_count = rep_count

    def generate_frames(self) -> List[Dict[str, Any]]:
        frames = []
        for i in range(self.total_samples):
            t_sec = i / self.sampling_hz
            # Initial 2.0s rest
            flex_factor = 0.0
            if t_sec >= 2.0:
                cycle_t = (t_sec - 2.0) % 3.0
                rep_idx = int((t_sec - 2.0) // 3.0)
                if rep_idx < self.rep_count and cycle_t < 2.0:
                    # Half-sine pulse peaking at 85% flexion
                    flex_factor = smooth_half_sine(cycle_t, 0.0, 2.0, amplitude=0.85)

            noise = self.rng.normal(0, 5, 5)
            # Map flex_factor (0..1) to ADC: open=1000, closed=3200 (span=2200)
            flex = [int(np.clip(1000 + 2200 * flex_factor + noise[j], 0, 4095)) for j in range(5)]
            # Accel shows slight movement, gyro shows tilt
            ax = int(50 * flex_factor + self.rng.normal(0, 5))
            ay = int(-20 * flex_factor + self.rng.normal(0, 5))
            az = int(980 - 40 * flex_factor + self.rng.normal(0, 5))
            gx = int(self.rng.normal(0, 3))
            gy = int(self.rng.normal(0, 3))
            gz = int(self.rng.normal(0, 3))

            frames.append({
                "t": int(i * 1000 / self.sampling_hz),
                "flex": flex,
                "imu": [ax, ay, az, gx, gy, gz],
                "fsr": int(150 * flex_factor),
                "flags": 0b00001101,  # calibrated, session active, simulated
                "battery": 92,
                "simulated": True
            })
        return frames


class FastRepetitionsScenario(SimulatorScenario):
    """Scenario 3: 15 fast fist clenches (duration 0.35s < min 0.6s). Expected: rejected too fast."""
    def __init__(self, rep_count: int = 15, seed: int = 42):
        # 15 reps * 1.0s = 15s + 2s rest = 17s
        super().__init__("fast_repetitions", duration_s=rep_count * 1.0 + 2.0, seed=seed)
        self.rep_count = rep_count

    def generate_frames(self) -> List[Dict[str, Any]]:
        frames = []
        for i in range(self.total_samples):
            t_sec = i / self.sampling_hz
            flex_factor = 0.0
            if t_sec >= 2.0:
                cycle_t = (t_sec - 2.0) % 1.0
                rep_idx = int((t_sec - 2.0) // 1.0)
                if rep_idx < self.rep_count and cycle_t < 0.35:
                    flex_factor = smooth_half_sine(cycle_t, 0.0, 0.35, amplitude=0.85)

            noise = self.rng.normal(0, 5, 5)
            flex = [int(np.clip(1000 + 2200 * flex_factor + noise[j], 0, 4095)) for j in range(5)]
            frames.append({
                "t": int(i * 1000 / self.sampling_hz),
                "flex": flex,
                "imu": [0, 0, 980, 0, 0, 0],
                "fsr": 0,
                "flags": 0b00001101,
                "battery": 90,
                "simulated": True
            })
        return frames


class IncompleteRepetitionsScenario(SimulatorScenario):
    """Scenario 4: 15 incomplete fist clenches peaking at 50% (< 70% upper threshold). Expected: incomplete."""
    def __init__(self, rep_count: int = 15, seed: int = 42):
        super().__init__("incomplete_repetitions", duration_s=rep_count * 2.5 + 2.0, seed=seed)
        self.rep_count = rep_count

    def generate_frames(self) -> List[Dict[str, Any]]:
        frames = []
        for i in range(self.total_samples):
            t_sec = i / self.sampling_hz
            flex_factor = 0.0
            if t_sec >= 2.0:
                cycle_t = (t_sec - 2.0) % 2.5
                rep_idx = int((t_sec - 2.0) // 2.5)
                if rep_idx < self.rep_count and cycle_t < 1.5:
                    # Peaking at only 50% (below 70% upper threshold)
                    flex_factor = smooth_half_sine(cycle_t, 0.0, 1.5, amplitude=0.50)

            noise = self.rng.normal(0, 5, 5)
            flex = [int(np.clip(1000 + 2200 * flex_factor + noise[j], 0, 4095)) for j in range(5)]
            frames.append({
                "t": int(i * 1000 / self.sampling_hz),
                "flex": flex,
                "imu": [0, 0, 980, 0, 0, 0],
                "fsr": 0,
                "flags": 0b00001101,
                "battery": 88,
                "simulated": True
            })
        return frames


class FingerTappingIndexScenario(SimulatorScenario):
    """Scenario 5: 15 index finger taps. Other 4 fingers stay relaxed at baseline."""
    def __init__(self, rep_count: int = 15, seed: int = 42):
        super().__init__("finger_tapping_index", duration_s=rep_count * 2.0 + 2.0, seed=seed)
        self.rep_count = rep_count

    def generate_frames(self) -> List[Dict[str, Any]]:
        frames = []
        for i in range(self.total_samples):
            t_sec = i / self.sampling_hz
            idx_factor = 0.0
            if t_sec >= 2.0:
                cycle_t = (t_sec - 2.0) % 2.0
                rep_idx = int((t_sec - 2.0) // 2.0)
                if rep_idx < self.rep_count and cycle_t < 1.2:
                    idx_factor = smooth_half_sine(cycle_t, 0.0, 1.2, amplitude=0.80)

            noise = self.rng.normal(0, 4, 5)
            # Only finger 1 (index) moves!
            flex = [
                int(np.clip(1000 + noise[0], 0, 4095)),
                int(np.clip(1000 + 2200 * idx_factor + noise[1], 0, 4095)),
                int(np.clip(1000 + noise[2], 0, 4095)),
                int(np.clip(1000 + noise[3], 0, 4095)),
                int(np.clip(1000 + noise[4], 0, 4095)),
            ]
            frames.append({
                "t": int(i * 1000 / self.sampling_hz),
                "flex": flex,
                "imu": [0, 0, 980, 0, 0, 0],
                "fsr": 0,
                "flags": 0b00001101,
                "battery": 85,
                "simulated": True
            })
        return frames


class PinchSeriesScenario(SimulatorScenario):
    """Scenario 6: 15 thumb-index pinches. Thumb and index flex simultaneously while others rest."""
    def __init__(self, rep_count: int = 15, seed: int = 42):
        super().__init__("pinch_series", duration_s=rep_count * 2.5 + 2.0, seed=seed)
        self.rep_count = rep_count

    def generate_frames(self) -> List[Dict[str, Any]]:
        frames = []
        for i in range(self.total_samples):
            t_sec = i / self.sampling_hz
            pinch_factor = 0.0
            if t_sec >= 2.0:
                cycle_t = (t_sec - 2.0) % 2.5
                rep_idx = int((t_sec - 2.0) // 2.5)
                if rep_idx < self.rep_count and cycle_t < 1.5:
                    pinch_factor = smooth_half_sine(cycle_t, 0.0, 1.5, amplitude=0.82)

            noise = self.rng.normal(0, 4, 5)
            # Thumb (0) and Index (1) flex together
            flex = [
                int(np.clip(1000 + 2200 * pinch_factor + noise[0], 0, 4095)),
                int(np.clip(1000 + 2200 * pinch_factor + noise[1], 0, 4095)),
                int(np.clip(1000 + noise[2], 0, 4095)),
                int(np.clip(1000 + noise[3], 0, 4095)),
                int(np.clip(1000 + noise[4], 0, 4095)),
            ]
            frames.append({
                "t": int(i * 1000 / self.sampling_hz),
                "flex": flex,
                "imu": [0, 0, 980, 0, 0, 0],
                "fsr": int(200 * pinch_factor),
                "flags": 0b00001101,
                "battery": 82,
                "simulated": True
            })
        return frames


class WristRotationScenario(SimulatorScenario):
    """Scenario 7: 10 forearm rotations (+60 deg to -60 deg, gyro active)."""
    def __init__(self, rep_count: int = 10, seed: int = 42):
        super().__init__("wrist_rotation", duration_s=rep_count * 3.0 + 2.0, seed=seed)
        self.rep_count = rep_count

    def generate_frames(self) -> List[Dict[str, Any]]:
        frames = []
        for i in range(self.total_samples):
            t_sec = i / self.sampling_hz
            rot_rate = 0.0
            angle_deg = 0.0
            if t_sec >= 2.0:
                cycle_t = (t_sec - 2.0) % 3.0
                rep_idx = int((t_sec - 2.0) // 3.0)
                if rep_idx < self.rep_count and cycle_t < 2.5:
                    phase = 2 * np.pi * cycle_t / 2.5
                    angle_deg = 60.0 * np.sin(phase)
                    # Derivative of 60*sin(w*t) is 60*w*cos(w*t)
                    w = 2 * np.pi / 2.5
                    rot_rate = 60.0 * w * np.cos(phase)  # deg/s

            noise = self.rng.normal(0, 4, 5)
            # Flex sensors stay neutral
            flex = [int(np.clip(1200 + noise[j], 0, 4095)) for j in range(5)]
            
            # IMU: gyro X in 0.1 deg/s units
            gx = int(rot_rate * 10.0)
            ax = int(1000.0 * np.sin(np.radians(angle_deg)))
            az = int(1000.0 * np.cos(np.radians(angle_deg)))
            
            frames.append({
                "t": int(i * 1000 / self.sampling_hz),
                "flex": flex,
                "imu": [ax, 0, az, gx, 0, 0],
                "fsr": 0,
                "flags": 0b00001101,
                "battery": 80,
                "simulated": True
            })
        return frames


class FaultInjectionScenario(SimulatorScenario):
    """Scenario 8: Fault injection (flatline, out-of-range, packet drop burst)."""
    def __init__(self, duration_s: float = 20.0, seed: int = 42):
        super().__init__("fault_injection", duration_s=duration_s, seed=seed)

    def generate_frames(self) -> List[Dict[str, Any]]:
        frames = []
        for i in range(self.total_samples):
            t_sec = i / self.sampling_hz
            
            # Normal baseline
            flex = [1500, 1500, 1500, 1500, 1500]
            imu = [0, 0, 980, 0, 0, 0]
            flags = 0b00001101
            
            # Period 1: t=3s to 7s -> Flatlined channel 1 (exact constant 1500, 0 noise)
            if 3.0 <= t_sec < 7.0:
                pass  # index 1 has 0 variance
            else:
                flex[1] += int(self.rng.normal(0, 10))

            # Period 2: t=9s to 11s -> Out of range ADC spike on channel 2
            if 9.0 <= t_sec < 11.0:
                flex[2] = 5000  # Exceeds 4095 valid ADC range!
            else:
                flex[2] += int(self.rng.normal(0, 10))
                
            # Period 3: t=13s to 15s -> Simulated packet drop burst (handled by streamer skipping packets)
            # Marked in frame metadata
            drop_packet = (13.0 <= t_sec < 15.0)

            frames.append({
                "t": int(i * 1000 / self.sampling_hz),
                "flex": flex,
                "imu": imu,
                "fsr": 0,
                "flags": flags,
                "battery": 75,
                "simulated": True,
                "drop": drop_packet
            })
        return frames


def get_scenario(name: str, seed: int = 42) -> SimulatorScenario:
    scenarios = {
        "open_hand_rest": OpenHandRestScenario,
        "fist_repetitions": FistRepetitionsScenario,
        "fast_repetitions": FastRepetitionsScenario,
        "incomplete_repetitions": IncompleteRepetitionsScenario,
        "finger_tapping_index": FingerTappingIndexScenario,
        "pinch_series": PinchSeriesScenario,
        "wrist_rotation": WristRotationScenario,
        "fault_injection": FaultInjectionScenario
    }
    if name not in scenarios:
        raise ValueError(f"Unknown scenario '{name}'. Available: {list(scenarios.keys())}")
    return scenarios[name](seed=seed)
