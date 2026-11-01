# H10 — Project Overview

> **CRITICAL REGULATORY & CLINICAL BOUNDARY**  
> **PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE.**  
> H10 is a research, demonstration, and rehabilitation monitoring prototype. It is **not** a medical device. It must **never** diagnose, prescribe, recommend clinical treatment, or predict clinical recovery dates. All outputs are descriptive physical telemetry and rule-based heuristic flags for qualified clinician review.

---

## 1. Executive Summary
H10 is an AI-assisted sensorized glove and telemetry system designed to monitor and objectively quantify finger and hand movements during rehabilitation exercises for stroke survivors and individuals with upper-limb motor impairments.

The system addresses three critical gaps in conventional physical therapy:
1. **Subjective & Infrequent Assessment:** Traditional clinic visits occur weekly or monthly; clinic notes rely heavily on subjective visual estimation of range of motion (ROM) and patient recall.
2. **Lack of In-Home Feedback:** Patients performing home exercise programs (HEPs) lack real-time kinematic feedback regarding whether their repetitions achieve target excursion bands or exhibit high fatigue.
3. **Data Disconnect Between Patient and Clinician:** Clinicians lack continuous, verifiable adherence records, repetition quality breakdowns, or early flags for compensatory movements or fatigue-induced strain.

H10 bridges this gap with an end-to-end modular pipeline consisting of:
- **Sensory Glove / Hardware Simulator:** 5 flex sensors (thumb through pinky) + 6-DOF IMU streaming at 50 Hz.
- **Pure Dart Signal Processing Engine (`h10_core`):** Digital filtering, two-stage calibration with drift detection, hysteresis-based repetition segmentation, smoothness and consistency scoring, fatigue drop index, and rule-based clinical flags.
- **Mobile Patient Application (Flutter):** Accessible UI offering visual biofeedback, target pacing, gamified finger control, pain/fatigue logging, and offline persistence.
- **FastAPI Backend & SQLite Database:** Pseudonymized persistence, idempotent sync with conflict detection, versioned rehabilitation plans, and audit logging.
- **Clinician Web Dashboard (Flutter Web):** Comprehensive desktop portal for physical therapists to review cohorts, establish patient baselines, inspect telemetry trends, version plans, acknowledge flags, and export 1-page clinical reports and CSVs.
- **Colab ML Training & Inference:** Standalone reproducible machine learning scripts and Google Colab notebook for exercise recognition (`feat-v1`, 84 features, GroupKFold cross-validation) with TFLite deployment on mobile behind an experimental feature flag.

---

## 2. Product Principles
- **Measure What Sensors Actually Measure:** Raw flex ADC signals measure relative finger flexion curvature; IMU gyroscopes measure angular velocity. H10 normalizes flexion into a calibrated percentage (0–100% ROM) against the patient's own measured open-hand and fist limits. It does not fabricate joint angles in degrees without optical or validated goniometric calibration.
- **Explain Every Metric:** Every computed score (ROM %, smoothness, consistency score, fatigue drop %) reveals its input terms, formulas, and data quality status.
- **Patient's Own Baseline Over Population Norms:** In neuro-rehabilitation, recovery is non-linear and highly individualized. Progress is measured strictly against the patient's own stable baseline.
- **Transparent Rules Over Black-Box Models:** Core repetition counting, quality gates, and clinical safety alerts are computed by deterministic, inspectable rules. Machine learning is isolated to exercise classification behind an optional feature flag.
- **Missing Data Is Never Zero:** Uncalibrated sensors or dropped telemetry frames are surfaced as `unavailable` with explicit explanatory reasons, never silently treated as 0.

---

## 3. System Scope & Boundaries
| Scope Level | Features Included |
|---|---|
| **In Scope (MVP)** | Wi-Fi streaming (ESP32 / Simulator), 30-byte binary & JSON packet decoders, 2-stage calibration, 5 exercises, live biofeedback, repetition counter, dimensionless jerk smoothness, consistency score, fatigue drop index, offline local storage, idempotent backend sync, clinician dashboard, plan versioning, 1-page PDF export, CSV export, Colab ML training scripts. |
| **Phase 2 (Architected)** | 3D hand rendering, tremor-band spectral analysis, bilateral comparison (unaffected reference), fingertip FSR pressure sensing, Bluetooth Low Energy (BLE) transport. |
| **Out of Scope** | Clinical diagnosis, automatic difficulty progression, voice control, multi-clinic tenanting, PII storage, hospital EHR integration. |
