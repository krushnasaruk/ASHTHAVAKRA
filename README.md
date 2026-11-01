# ASHTHAVAKRA (H10) — AI-Assisted Hand Rehabilitation Monitoring Prototype

> [!CAUTION]
> **CRITICAL CLINICAL & REGULATORY BOUNDARY**  
> **PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE.**  
> H10 is an experimental research and demonstration prototype for physical therapy monitoring. It is **not** a certified medical device (EU MDR / US FDA). It must **never** diagnose, prescribe, recommend clinical treatments, or predict recovery timelines. All computed metrics and rule-based alerts are descriptive physical telemetry intended exclusively for review by qualified physical therapists. All synthetic/simulated data carries an explicit label throughout every layer.

---

## Overview

**H10 (Ashtavakra)** is a modular, AI-assisted telemetry and rehabilitation monitoring system designed for stroke survivors and individuals recovering fine motor control in their hands and fingers.

The system decodes 5-finger flex sensor curvature and 6-DOF wrist orientation into per-finger Range of Motion (ROM), provides real-time biofeedback during exercises, detects compensatory or fatigued movement patterns, and provides physical therapists with reviewable telemetry records, plan versioning tools, and clinical summary reports.

---

## Repository Structure

```text
H10/
├── mobile/                  Flutter patient mobile application (Android/Web)
│   └── packages/h10_core/   Pure Dart signal math, filters, hysteresis rep detector & models (0 Flutter deps)
├── admin/                   Flutter Web clinician dashboard (overview, patient cohort, plan editor, PDF reports)
├── backend/                 FastAPI REST backend with SQLite persistence, strict PII refusal & idempotent sync
├── ml/                      Exercise recognition pipeline, dataset validation, synthetic data, and Google Colab scripts
├── simulator/               Python device simulator (50 Hz WebSocket stream + HTTP REST API, 8 scenarios)
├── shared/                  Binary & JSON protocol specifications, 10 JSON schemas, and golden test vectors
├── docs/                    Comprehensive 21-document technical documentation suite
├── PROJECT_STATUS.md        Live tracking of objectives, test outputs, and known boundaries
└── IMPLEMENTATION_LOG.md    Detailed engineering decisions and architectural change log
```

---

## Key Features

- **Sensory Glove / Simulator:** 5-channel flex sensing + 6-DOF IMU streaming at 50 Hz over WebSocket (30-byte little-endian binary or fallback JSON).
- **Pure Dart Core Engine (`h10_core`):** Exponential moving average ($\alpha=0.25$), 5-point median filter, 2-stage median calibration with drift detection, hysteresis state machine repetition counting with 300 ms debounce, dimensionless jerk smoothness ($D_J$), consistency score ($0–100$), and fatigue drop index ($\ge 20\%$).
- **Session Quality Gate:** Multi-factor stream health validation checking packet loss ($< 5\%$), decode errors ($< 1\%$), frequency stability ($50 \pm 5\text{ Hz}$), and sensor flatline detection.
- **Mobile Patient App:** Accessible UI with large touch targets ($\ge 48\text{ dp}$), Okabe-Ito color-blind safe palettes, live 2D articulated hand, finger bar gauges, repetition progress ring, hand-control challenge mini-game, and offline local persistence.
- **Clinician Web Dashboard:** Responsive desktop portal (1280px+) with priority movement alert feed, patient cohort search, 5-tab detail view, plan versioning editor, 1-click clinical summary PDF generator (`pdf` / `printing`), and raw telemetry CSV export.
- **FastAPI Backend:** SQLite database, strict PII refusal, idempotent session sync (`200 OK` on duplicate identical submission, `409 Conflict` on altered payload), and plan versioning with non-destructive archiving.
- **Google Colab ML Pipeline:** Machine learning exercise recognition (`feat-v1`, 84 features, `GroupKFold` cross-validation) packaged into standalone Colab training notebooks (`ml/colab/`) and scripts, with TFLite on-device inference behind a feature flag.

---

## Test Verification Suite (54/54 Tests Passed)

All tiers of the system contain automated test suites:
- **Python Simulator Tests (`simulator/test_simulator.py`):** 7/7 passed.
- **Python ML Pipeline Tests (`ml/test_ml.py`):** 3/3 passed.
- **Python Backend API Tests (`backend/test_backend.py`):** 6/6 passed.
- **Pure Dart Core Engine Tests (`mobile/packages/h10_core`):** 33/33 passed (including feature extraction parity $< 10^{-6}$ against Python).
- **Flutter Mobile App Tests (`mobile/test/`):** 4/4 passed.
- **Flutter Clinician Web App Tests (`admin/test/`):** 1/1 passed.

---

## Documentation

For comprehensive engineering details, refer to the documentation in [`docs/`](docs/):
- [`docs/PROJECT_OVERVIEW.md`](docs/PROJECT_OVERVIEW.md) — System purpose, clinical boundaries, and user roles.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — System block diagram and subsystem descriptions.
- [`docs/DEVICE_PROTOCOL.md`](docs/DEVICE_PROTOCOL.md) — WebSocket 30-byte binary packet specification and REST lifecycle.
- [`docs/SIGNAL_PROCESSING.md`](docs/SIGNAL_PROCESSING.md) — Filtering, normalization, and 1D control extraction.
- [`docs/CALIBRATION.md`](docs/CALIBRATION.md) — Two-stage calibration wizard and runtime drift monitoring.
- [`docs/REPETITION_DETECTION.md`](docs/REPETITION_DETECTION.md) — Hysteresis state machine, jerk smoothness, and fatigue index.
- [`docs/QUALITY_GATE.md`](docs/QUALITY_GATE.md) — Three-stage stream quality validation rules.
- [`docs/ML_PIPELINE.md`](docs/ML_PIPELINE.md) — Colab training workflow, GroupKFold cross-validation, and TFLite deployment.
- [`docs/BACKEND_API.md`](docs/BACKEND_API.md) — REST API endpoints, PII rejection, and idempotent sync.
- [`docs/DASHBOARD.md`](docs/DASHBOARD.md) — Clinician portal workflows and PDF report generator.
- [`docs/DEMO_GUIDE.md`](docs/DEMO_GUIDE.md) — Step-by-step end-to-end demonstration guide.

---

## License & Research Boundary

This project is released strictly for research, educational, and demonstration purposes. It is **not** approved for medical diagnosis or clinical treatment.
