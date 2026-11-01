# Model A Evaluation Report

## 1. Overview
- **Model Name:** `h10_exercise_recognizer`
- **Architecture:** MLP / Random Forest Baseline
- **Date Trained:** 2026-11-01T16:10:36.917089+00:00
- **Feature Schema:** `feat-v1` (84 features)
- **Data Sources:** Real: 0, Simulated: 0, Synthetic: 40

> [!NOTE]
> All synthetic data is strictly labelled as such. This evaluation report reflects research/demonstration prototype performance only.

## 2. Participant-Level Cross-Validation
- **Number of Folds:** 4
- **Accuracy (mean ± SD):** 1.0000 ± 0.0000
- **Macro-F1 (mean ± SD):** 1.0000 ± 0.0000

## 3. Confusion Matrix
Classes: ['fist_clench', 'finger_tap', 'pinch', 'wrist_rotation', 'rest_or_other']

```json
[
  [
    32,
    0,
    0,
    0,
    0
  ],
  [
    0,
    32,
    0,
    0,
    0
  ],
  [
    0,
    0,
    32,
    0,
    0
  ],
  [
    0,
    0,
    0,
    32,
    0
  ],
  [
    0,
    0,
    0,
    0,
    32
  ]
]
```

## 4. Verification Check
- SHA-256 Hash: `96490476473cc7f40849f3e995442e99fd04da2ee130d986fa5ec247ef50660f`
- Confidence Threshold: 0.70 (Inference below 0.70 emits 'Unable to confidently identify this movement.')
