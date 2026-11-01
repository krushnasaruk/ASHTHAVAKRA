# H10 Implementation Log

This log records major design and engineering decisions, architectural choices, and changes made throughout development.

## Entry 001 - 2026-11-01: Workspace Initialization and Tooling Setup
- **Context:** Workspace inspected on Windows host. Python 3.14+ installed with FastAPI, Uvicorn, SQLAlchemy, Pydantic, Pytest, Scikit-learn, etc. Git repository initialized.
- **Action:** Created directory structure (`backend/`, `simulator/`, `ml/`, `shared/`, `mobile/`, `admin/`, `docs/`). Initiated download of official Google Dart SDK 3.13.7.
- **Decision:** Followed user instruction `/goal` with explicit directive: ML model local training is bypassed in favor of generating full Google Colab training scripts and notebooks (`ml/colab/`), while providing deterministic mock/fixture models locally so unit and integration tests run fast and deterministically.
- **Decision:** Pure Dart core package `mobile/packages/h10_core` holds all signal math, hysteresis rep detector, calibration validation, metrics, and models without Flutter dependencies to guarantee cross-platform reusability and fast CLI testability.

## Entry 002 - 2026-11-01: Shared Contracts, Simulator, and Core Signal Engine Complete
- **Contracts:** Defined 10 shared JSON schemas, 30-byte little-endian binary packet protocol, and generated golden packet & feature parity test vectors.
- **Simulator:** Built full deterministic ESP32 simulator with 8 clinical & edge-case scenarios, binary/JSON WebSocket streaming, and REST API. Verified 7/7 pytest tests.
- **Pure Dart Core (`h10_core`):** Implemented packet decoder, EMA & median filters, calibration engine with drift detection, hysteresis repetition state machine, dimensionless jerk smoothness, consistency score, fatigue calculator, quality gate, feat-v1 feature extractor, and recovery analytics. Verified 33/33 tests passing with exact Python-Dart feature parity (< 1e-6) and 20/20 repetition sequence test.


## Entry 003 - 2026-11-01: ML Colab Tooling, FastAPI Backend, Mobile App, Clinician Web Portal & Documentation Complete
- **Colab ML Pipeline:** Authored dataset validation with golden consent enforcement, synthetic dataset generator with 40 trials across 4 participants, standalone `ml/colab/train_colab.py` with `GroupKFold` cross-validation, and one-click `ml/colab/H10_Exercise_Recognition_Colab.ipynb` notebook. Verified 3/3 pytest tests.
- **FastAPI Backend:** Built SQLite backend (`backend/`) with strict PII refusal, idempotent session ingestion (200 on duplicate hash, 409 on conflict), plan versioning, soft deletion, and patient isolation. Verified 6/6 pytest tests.
- **Mobile Patient App (`mobile/`):** Implemented Flutter patient app with 4-tab shell, persistent non-medical prototype warning banner, 2D articulated hand CustomPainter, Okabe-Ito finger bars, repetition ring with target hold timer, 2-stage calibration wizard, hand-control challenge mini-game, Borg pain/fatigue rating sliders, and offline local persistence. Verified 4/4 Flutter tests.
- **Clinician Web Dashboard (`admin/`):** Implemented responsive 1280px+ desktop Flutter Web portal with overview metric cards, open flag feed with 1-click review modal, patient cohort table with side filters, 5-tab detail view, plan versioning editor, 1-page clinical summary PDF report generator with `pdf` and `printing`, and raw telemetry CSV exporter. Verified all Flutter tests.
- **Documentation Suite:** Authored all 21 technical documents specified in Section 17 under `docs/` covering architecture, protocols, signal math, repetition detection, quality gate, ML pipeline, ethics, backend schemas, and demonstration guide.
- **Final Verification:** 54 automated tests passed across all tiers with 0 failures. System ready for research and demonstration walkthroughs.

## Entry 004 - 2026-11-01: Mobile Web Execution & Responsive Phone Frame
- **Dual-Target Execution:** Enabled compiling and running the patient mobile application as a Flutter Web application (`build/web` served on local HTTP port 5050).
- **Responsive Phone Canvas:** Added a desktop wrapper in `main.dart` rendering a centered, realistic mobile phone container (440px width with soft drop shadow and border) when viewed on desktop web browsers (> 600px width), while maintaining full-screen native presentation on mobile viewports.
- **Hardware-Free Demonstration Fallbacks:**
  - Added simulated calibration baseline values so the 2-stage calibration wizard can be demonstrated without hardware glove attached.
  - Added sinusoidal hand movement fallback in live session view so the 2D articulated hand visualization, Okabe-Ito finger bars, and repetition counter animate realistically.
  - Added mouse/touch drag slider control in the mini-game screen so the game mode can be played and demonstrated using any input device.
- **Layout Responsiveness:** Resolved all horizontal `RenderFlex` row overflow constraints across `s1_today_screen.dart`, `s2_device_screen.dart`, `s4_exercises_screen.dart`, and `s7_progress_screen.dart`. Verified 100% test pass rate (4/4 mobile widget tests, 33/33 `h10_core` tests, 1/1 admin tests).

