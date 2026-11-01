"""
Script to generate:
1. shared/fixtures/golden_packets.json (binary packet test vectors + JSON packets)
2. shared/fixtures/feature_golden_v1.json (parity reference fixtures for Python & Dart)
"""
import struct
import json
import os
import sys
import numpy as np

# Add repo root to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
from ml.features import extract_window_features, FEATURE_NAMES


def build_binary_packet(timestamp_ms, flex, imu, fsr, flags, battery_pct):
    """
    Format:
    <I (4B uint32 timestamp_ms)
    5H (10B 5x uint16 flex)
    6h (12B 6x int16 imu: ax,ay,az,gx,gy,gz)
    H (2B uint16 fsr)
    B (1B uint8 flags)
    B (1B uint8 battery)
    Total 30 bytes
    """
    return struct.pack(
        "<I5H6hHBB",
        timestamp_ms,
        flex[0], flex[1], flex[2], flex[3], flex[4],
        imu[0], imu[1], imu[2], imu[3], imu[4], imu[5],
        fsr,
        flags,
        battery_pct
    )


def generate_golden_packets():
    fixtures = []
    
    # Vector 1: Standard rest packet
    v1_bytes = build_binary_packet(
        timestamp_ms=1000,
        flex=[1800, 1900, 2000, 1950, 1850],
        imu=[25, -15, 980, 2, -1, 0],
        fsr=0,
        flags=0b00000001,  # calibrated
        battery_pct=95
    )
    fixtures.append({
        "id": "standard_rest",
        "description": "Resting hand pose, calibrated, 95% battery",
        "hex": v1_bytes.hex(),
        "byte_length": len(v1_bytes),
        "expected": {
            "timestamp_ms": 1000,
            "flex": [1800, 1900, 2000, 1950, 1850],
            "imu": [25, -15, 980, 2, -1, 0],
            "fsr": 0,
            "flags": 1,
            "is_calibrated": True,
            "is_low_battery": False,
            "is_session_active": False,
            "is_simulated": False,
            "battery_pct": 95
        }
    })
    
    # Vector 2: Full fist clench, active session, simulated
    v2_bytes = build_binary_packet(
        timestamp_ms=2500,
        flex=[3200, 3400, 3350, 3300, 3100],
        imu=[120, 85, 950, 45, -20, 12],
        fsr=150,
        flags=0b00001101,  # calibrated, session active, simulated
        battery_pct=80
    )
    fixtures.append({
        "id": "fist_active_simulated",
        "description": "Fist flexion, session active, simulated",
        "hex": v2_bytes.hex(),
        "byte_length": len(v2_bytes),
        "expected": {
            "timestamp_ms": 2500,
            "flex": [3200, 3400, 3350, 3300, 3100],
            "imu": [120, 85, 950, 45, -20, 12],
            "fsr": 150,
            "flags": 13,
            "is_calibrated": True,
            "is_low_battery": False,
            "is_session_active": True,
            "is_simulated": True,
            "battery_pct": 80
        }
    })
    
    # Vector 3: Low battery warning and boundary values
    v3_bytes = build_binary_packet(
        timestamp_ms=4294967200,  # Near uint32 max
        flex=[4095, 0, 4095, 0, 2048],
        imu=[-32768, 32767, -1000, 0, -500, 500],
        fsr=4095,
        flags=0b00000010,  # low battery
        battery_pct=8
    )
    fixtures.append({
        "id": "boundary_low_battery",
        "description": "Min/max ADC and IMU ranges, low battery flag",
        "hex": v3_bytes.hex(),
        "byte_length": len(v3_bytes),
        "expected": {
            "timestamp_ms": 4294967200,
            "flex": [4095, 0, 4095, 0, 2048],
            "imu": [-32768, 32767, -1000, 0, -500, 500],
            "fsr": 4095,
            "flags": 2,
            "is_calibrated": False,
            "is_low_battery": True,
            "is_session_active": False,
            "is_simulated": False,
            "battery_pct": 8
        }
    })

    return fixtures


def generate_feature_golden_fixtures():
    np.random.seed(42)
    scenarios = []
    
    # Scenario 1: Steady rest (75 samples)
    s1_samples = []
    for i in range(75):
        s1_samples.append({
            "flex": [1000, 1050, 1020, 1010, 990],
            "imu": [0, 0, 1000, 0, 0, 0]
        })
    s1_feats = extract_window_features(s1_samples)
    scenarios.append({
        "id": "scenario_steady_rest",
        "description": "Constant baseline open hand readings",
        "samples": s1_samples,
        "expected_features": s1_feats
    })
    
    # Scenario 2: Fist flexion trajectory (sinusoidal half wave)
    s2_samples = []
    for i in range(75):
        # 0 to pi half sine
        progress = np.sin(np.pi * i / 74.0)
        flex_val = int(1000 + 1500 * progress)
        s2_samples.append({
            "flex": [flex_val, flex_val + 50, flex_val - 20, flex_val + 10, flex_val - 40],
            "imu": [int(progress * 150), int(progress * -50), int(980 - progress * 50), int(progress * 20), 0, 0]
        })
    s2_feats = extract_window_features(s2_samples)
    scenarios.append({
        "id": "scenario_fist_flexion",
        "description": "Sinusoidal fist flexion wave",
        "samples": s2_samples,
        "expected_features": s2_feats
    })
    
    # Scenario 3: Single index finger tap series (3 pulses)
    s3_samples = []
    for i in range(75):
        # 3 peaks at i=15, 37, 60
        pulse = 0.0
        for center in [15, 37, 60]:
            dist = abs(i - center)
            if dist <= 5:
                pulse += np.cos(np.pi * dist / 10.0)
        idx_flex = int(1000 + 1200 * pulse)
        s3_samples.append({
            "flex": [1000, idx_flex, 1010, 1005, 995],
            "imu": [0, 0, 980, 0, int(pulse * 30), 0]
        })
    s3_feats = extract_window_features(s3_samples)
    scenarios.append({
        "id": "scenario_index_taps",
        "description": "Three index taps with distinct peaks",
        "samples": s3_samples,
        "expected_features": s3_feats
    })
    
    # Scenario 4: Wrist rotation with high angular velocity
    s4_samples = []
    for i in range(75):
        rot_rate = int(450 * np.sin(2 * np.pi * i / 74.0))
        s4_samples.append({
            "flex": [1200, 1220, 1210, 1190, 1205],
            "imu": [int(100 * np.cos(2 * np.pi * i / 74.0)), int(100 * np.sin(2 * np.pi * i / 74.0)), 950, rot_rate, int(rot_rate * 0.2), 0]
        })
    s4_feats = extract_window_features(s4_samples)
    scenarios.append({
        "id": "scenario_wrist_rotation",
        "description": "Continuous rotation about forearm axis",
        "samples": s4_samples,
        "expected_features": s4_feats
    })
    
    return {
        "version": "feat-v1",
        "feature_names": FEATURE_NAMES,
        "tolerance": 1e-6,
        "fixtures": scenarios
    }


def main():
    fixtures_dir = os.path.abspath(os.path.join(os.path.dirname(__file__)))
    
    # Write golden packets
    golden_packets = generate_golden_packets()
    packets_path = os.path.join(fixtures_dir, "golden_packets.json")
    with open(packets_path, "w") as f:
        json.dump(golden_packets, f, indent=2)
    print(f"Generated {len(golden_packets)} packet fixtures to {packets_path}")
    
    # Write feature fixtures
    feature_fixtures = generate_feature_golden_fixtures()
    features_path = os.path.join(fixtures_dir, "feature_golden_v1.json")
    with open(features_path, "w") as f:
        json.dump(feature_fixtures, f, indent=2)
    print(f"Generated {len(feature_fixtures['fixtures'])} feature window fixtures to {features_path}")


if __name__ == "__main__":
    main()
