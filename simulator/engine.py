"""
Simulator streaming engine. Converts scenario frames to 30-byte little-endian packets or JSON frames.
"""
import struct
from typing import Dict, Any, Tuple
from simulator.scenarios import get_scenario, SimulatorScenario


def pack_binary_packet(frame: Dict[str, Any]) -> bytes:
    """
    30 bytes little-endian:
    uint32 timestamp_ms (4B)
    uint16 flex[0..4] (10B)
    int16 imu[0..5] (12B: ax, ay, az, gx, gy, gz)
    uint16 fsr (2B)
    uint8 flags (1B)
    uint8 battery (1B)
    """
    t = int(frame["t"])
    flex = frame["flex"]
    imu = frame["imu"]
    fsr = int(frame.get("fsr", 0))
    flags = int(frame.get("flags", 0b00001001))
    battery = int(frame.get("battery", 90))
    
    # Clip values defensively to valid ranges
    clamped_flex = [max(0, min(65535, int(v))) for v in flex]
    clamped_imu = [max(-32768, min(32767, int(v))) for v in imu]
    clamped_fsr = max(0, min(65535, fsr))
    clamped_flags = max(0, min(255, flags))
    clamped_batt = max(0, min(100, battery))
    
    return struct.pack(
        "<I5H6hHBB",
        t,
        clamped_flex[0], clamped_flex[1], clamped_flex[2], clamped_flex[3], clamped_flex[4],
        clamped_imu[0], clamped_imu[1], clamped_imu[2], clamped_imu[3], clamped_imu[4], clamped_imu[5],
        clamped_fsr,
        clamped_flags,
        clamped_batt
    )


class SimulatorEngine:
    """
    Stateful engine managing scenarios, stream rate, calibration windows,
    and active streaming sessions.
    """
    def __init__(self, default_scenario: str = "open_hand_rest", seed: int = 42):
        self.scenario_name = default_scenario
        self.seed = seed
        self.scenario: SimulatorScenario = get_scenario(default_scenario, seed=seed)
        self.frames = self.scenario.generate_frames()
        self.current_frame_idx = 0
        self.rate_hz = 50
        self.is_session_active = False
        self.active_session_id = None
        self.is_calibrated = True
        self.battery_pct = 95
        self.encoding = "binary"  # "binary" or "json"
        self.haptic_count = 0
        
        # Stored calibration data
        self.calibration_data = {
            "open": [1000, 1000, 1000, 1000, 1000],
            "closed": [3200, 3200, 3200, 3200, 3200],
            "timestamp": "2026-11-01T12:00:00Z"
        }

    def set_scenario(self, name: str, seed: int = None) -> None:
        if seed is not None:
            self.seed = seed
        self.scenario_name = name
        self.scenario = get_scenario(name, seed=self.seed)
        self.frames = self.scenario.generate_frames()
        self.current_frame_idx = 0

    def get_next_frame(self) -> Tuple[bool, Any]:
        """
        Returns (should_drop, payload).
        Payload is bytes (if binary) or dict (if json).
        """
        if not self.frames:
            return False, None
            
        frame = self.frames[self.current_frame_idx]
        self.current_frame_idx = (self.current_frame_idx + 1) % len(self.frames)
        
        should_drop = frame.get("drop", False)
        if should_drop:
            return True, None
            
        # Update session active flag in runtime
        flags = frame["flags"]
        if self.is_session_active:
            flags |= 0b00000100  # bit 2: session active
        else:
            flags &= ~0b00000100
        flags |= 0b00001000  # bit 3: simulated
        frame["flags"] = flags
        
        if self.encoding == "binary":
            return False, pack_binary_packet(frame)
        else:
            return False, frame
