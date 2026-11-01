# Assumptions and Design Defaults

This document records all baseline assumptions, design defaults, and operational parameters for H10 Build Specification v2 in accordance with Section 1.5 and Section 19.

## 1. Regulatory and Medical Disclaimer
- H10 is a research, demonstration, and rehabilitation monitoring prototype.
- It is NOT a medical device.
- It must NEVER diagnose, prescribe, or make treatment or clinical recovery predictions.
- All numbers, flags, and consistency metrics are exploratory assistive metrics requiring qualified clinician/physiotherapist interpretation.

## 2. Default Configuration Values (Section 19)
| Parameter | Default Value | Rationale |
|---|---|---|
| Stream rate | 50 Hz | Default hardware stream rate. |
| Repetition upper threshold | 70% | High-flexion point for hysteresis state machine. |
| Repetition lower threshold | 30% | Low-flexion point for rep completion/return. |
| Repetition min duration | 0.6 s | Reject accidental jerks/fast noise. |
| Repetition max duration | 8.0 s | Upper bound on single rep. |
| Hold threshold band | ±5% of peak | Repetition hold window. |
| Hold min duration | 0.5 s | Minimum hold duration to count hold. |
| Debounce interval | 300 ms | Ignore double-crossings within 300 ms. |
| Fatigue drop threshold | 20% | Relative drop between first 3 and last 3 reps peak flexion. |
| Calibration min span | 300 ADC counts | Reject unresponsive sensor or bad placement. |
| Calibration max noise (SD) | 40 ADC counts | Threshold for steady open/fist capture window. |
| Calibration maximum age | 14 days | Stale calibration triggers recalibration flag. |
| Calibration drift tolerance | 15% of span | Shift in baseline open value triggers drift warning. |
| Display filter | EMA α = 0.25 | Balances responsiveness and visual smoothness at 30 fps. |
| Detection filter | EMA α = 0.15 | Smooths noisy signals for hysteresis rep counting. |
| Model confidence threshold | 0.70 | Below 0.70 emits "Unable to confidently identify this movement." |
| Pain & Fatigue scale | 0–10 numeric | Integer rating required post-session. |
| Stop instruction | "Stop if you feel sharp pain. Rest as needed." | Displayed on live session screen. |
| Patient pseudonym format | `P-XXX` (e.g. `P-014`) | Refuses personally identifiable information (PII). |
| Model Training Execution | Google Colab scripts | Per user directive, Colab training pipeline scripts & notebooks generated to avoid long local training delays; on-device mock/fixture models supplied for integration tests. |
| Report format | PDF from backend-provided JSON | Generated via PDF package in clinician dashboard. |
| Real data consent | Strictly mandatory | Tooling blocks recording if consent flag is false. |

