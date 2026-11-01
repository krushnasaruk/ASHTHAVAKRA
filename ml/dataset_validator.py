"""
Validation tool for H10 dataset trials.
Checks:
- Mandatory consent for real data collection
- Allowed exercise labels
- Valid sampling rate & gap detection
- Out-of-bounds sensor values
- Calibration reference presence
- Duplicate trial IDs
"""
from typing import Dict, Any, List, Tuple
import json
import os

ALLOWED_LABELS = {
    "fist_clench",
    "finger_tap",
    "pinch",
    "wrist_rotation",
    "rest_or_other"
}

ALLOWED_SOURCES = {"real", "simulated", "synthetic"}


class DatasetValidationError(Exception):
    pass


class DatasetValidator:
    def __init__(self, expected_hz: float = 50.0, max_gap_ms: int = 100):
        self.expected_hz = expected_hz
        self.max_gap_ms = max_gap_ms

    def validate_trial(self, trial: Dict[str, Any]) -> Tuple[bool, List[str]]:
        errors = []

        # 1. Source and Consent Rule
        source = trial.get("source")
        if source not in ALLOWED_SOURCES:
            errors.append(f"Invalid source '{source}'. Must be one of {ALLOWED_SOURCES}")

        consent = trial.get("consent_given", False)
        if source == "real" and not consent:
            errors.append("POLICY VIOLATION: Real source data collection requires explicit consent_given == True")

        # 2. Exercise label
        label = trial.get("exercise_label")
        if label not in ALLOWED_LABELS:
            errors.append(f"Invalid exercise label '{label}'. Allowed: {ALLOWED_LABELS}")

        # 3. Calibration reference
        if not trial.get("calibration_ref"):
            errors.append("Missing required calibration_ref")

        # 4. Samples validation
        samples = trial.get("samples", [])
        if not samples:
            errors.append("Trial contains 0 samples")
            return False, errors

        prev_t = None
        for idx, s in enumerate(samples):
            t = s.get("t")
            if t is None:
                errors.append(f"Sample {idx} missing timestamp 't'")
                break

            if prev_t is not None:
                if t <= prev_t:
                    errors.append(f"Non-monotonic timestamp at sample {idx}: {t} <= {prev_t}")
                elif (t - prev_t) > self.max_gap_ms:
                    errors.append(f"Sampling gap detected at sample {idx}: {t - prev_t}ms > {self.max_gap_ms}ms")
            prev_t = t

            flex = s.get("flex", [])
            if len(flex) != 5:
                errors.append(f"Sample {idx} flex channel count != 5 (got {len(flex)})")
            else:
                for f_idx, val in enumerate(flex):
                    if val < 0 or val > 4095:
                        errors.append(f"Sample {idx} flex[{f_idx}] out of range: {val}")

            imu = s.get("imu", [])
            if len(imu) != 6:
                errors.append(f"Sample {idx} imu channel count != 6 (got {len(imu)})")

        is_valid = len(errors) == 0
        return is_valid, errors

    def validate_dataset_file(self, file_path: str) -> Dict[str, Any]:
        with open(file_path, "r") as f:
            data = json.load(f)

        trials = data if isinstance(data, list) else [data]
        seen_trial_ids = set()
        report = {
            "file": file_path,
            "total_trials": len(trials),
            "valid_trials": 0,
            "invalid_trials": 0,
            "details": []
        }

        for trial in trials:
            t_id = trial.get("trial_id", "unknown")
            if t_id in seen_trial_ids:
                report["invalid_trials"] += 1
                report["details"].append({"trial_id": t_id, "errors": [f"Duplicate trial_id: {t_id}"]})
                continue
            seen_trial_ids.add(t_id)

            is_valid, errors = self.validate_trial(trial)
            if is_valid:
                report["valid_trials"] += 1
            else:
                report["invalid_trials"] += 1
                report["details"].append({"trial_id": t_id, "errors": errors})

        return report


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Validate H10 dataset trials JSON")
    parser.add_argument("--input", type=str, default="ml/data/synthetic_dataset.json", help="Path to dataset trial JSON")
    args = parser.parse_args()

    validator = DatasetValidator()
    if os.path.exists(args.input):
        res = validator.validate_dataset_file(args.input)
        print(f"Validation Report for {args.input}:")
        print(f"  Total trials: {res['total_trials']}")
        print(f"  Valid trials: {res['valid_trials']}")
        print(f"  Invalid trials: {res['invalid_trials']}")
        if res["invalid_trials"] == 0:
            print("  Result: [PASS] All trials meet strict H10 dataset standards.")
        else:
            print("  Result: [FAIL] Errors detected:")
            for d in res["details"]:
                print(f"    - {d}")
    else:
        print(f"Error: File not found: {args.input}")

