"""
Generates synthetic multi-participant dataset for testing ML validation and training pipelines.
All records are explicitly labelled as source='synthetic'.
"""
import json
import os
import uuid
import numpy as np


def generate_synthetic_trials(num_participants: int = 4, trials_per_class: int = 2) -> list:
    np.random.seed(42)
    classes = ["fist_clench", "finger_tap", "pinch", "wrist_rotation", "rest_or_other"]
    trials = []

    for p_idx in range(num_participants):
        p_id = f"P-SIM-00{p_idx + 1}"
        for cls in classes:
            for tr_idx in range(trials_per_class):
                trial_id = str(uuid.uuid4())
                session_id = str(uuid.uuid4())
                samples = []
                num_samples = 150  # 3 seconds at 50 Hz

                for i in range(num_samples):
                    t = i * 20
                    progress = np.sin(np.pi * (i % 75) / 74.0)
                    
                    if cls == "fist_clench":
                        flex = [int(1000 + 2000 * progress + np.random.normal(0, 5)) for _ in range(5)]
                        imu = [0, 0, 980, 0, 0, 0]
                    elif cls == "finger_tap":
                        flex = [
                            1000,
                            int(1000 + 2000 * progress + np.random.normal(0, 5)),
                            1000, 1000, 1000
                        ]
                        imu = [0, 0, 980, 0, 0, 0]
                    elif cls == "pinch":
                        flex = [
                            int(1000 + 1800 * progress),
                            int(1000 + 1800 * progress),
                            1000, 1000, 1000
                        ]
                        imu = [0, 0, 980, 0, 0, 0]
                    elif cls == "wrist_rotation":
                        flex = [1200] * 5
                        imu = [int(100 * progress), 0, 980, int(300 * progress), 0, 0]
                    else:  # rest_or_other
                        flex = [int(1000 + np.random.normal(0, 3)) for _ in range(5)]
                        imu = [0, 0, 980, 0, 0, 0]

                    samples.append({
                        "t": t,
                        "flex": [max(0, min(4095, v)) for v in flex],
                        "imu": imu,
                        "fsr": 0
                    })

                trials.append({
                    "participant_id": p_id,
                    "session_id": session_id,
                    "trial_id": trial_id,
                    "exercise_label": cls,
                    "movement_phase": "peak",
                    "source": "synthetic",
                    "consent_given": True,
                    "calibration_ref": f"cal_{p_id}",
                    "device_firmware": "1.0.0",
                    "sampling_hz": 50,
                    "quality": "good",
                    "recorder_app_version": "1.0.0",
                    "samples": samples
                })

    return trials


def main():
    out_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "data"))
    os.makedirs(out_dir, exist_ok=True)
    out_file = os.path.join(out_dir, "synthetic_dataset.json")
    
    trials = generate_synthetic_trials()
    with open(out_file, "w") as f:
        json.dump(trials, f, indent=2)
    print(f"Generated {len(trials)} synthetic trials to {out_file}")


if __name__ == "__main__":
    main()
