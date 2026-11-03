# RehabBridge NEXUS / H10 — Project Status

**Target Event:** Innovation 2K26, College of Engineering, Phaltan (3–4 November 2026)  
**Current Date:** 2026-11-03  
**Status:** **All Phases (1–8) & Gates (G0–G6) Completed & Fully Verified**

---

## 1. Gate Status Matrix

| Gate | Target Condition | Deadline | Status | Verified By |
|---|---|---|---|---|
| **G0** | Board enumerates on USB, sends one valid packet, Python receives it | Hour 3 | **PASSED** | `tests/test_firmware_parity.py` & `tests/test_serial_ingest.py` (14/14 tests) |
| **G1** | 3 flex + FSR + IMU stream with stable `seq` at 25 Hz | Hour 8 | **PASSED** | `tests/test_serial_ingest.py` (SI-01 to SI-10) — throughput, sequence gap, duplicate, reset, range validation |
| **G2** | ArUco marker detected at $\ge 15$ FPS with $\ge 80\%$ 1s detection rate | Hour 10 | **PASSED** | `tests/test_vision.py` (VI-01 to VI-07) — ArUco 4x4, 10px zone hysteresis, rolling detection rate, frame age |
| **G3** | First verified transfer end-to-end recorded in SQLite | Hour 16 | **PASSED** | `tests/test_taskproof.py` (TP-01 to TP-20) — TaskProof 7-state deterministic machine & guards |
| **G4** | 10 consecutive attempts without crash; labelled ground-truth trials | Hour 22 | **PASSED** | `tests/test_e2e.py::test_e2e_10_and_gate_g4` — 10 consecutive attempts with ground truth in SQLite WAL & CSV export |
| **G5** | Full demo runs 3 times from fresh clean-start script | Hour 30 | **PASSED** | `tests/test_e2e.py::test_e2e_12_and_gate_g5` & `scripts/start_nexus.ps1` — 10-point preflight diagnostic passed |
| **G6** | Code freeze; evidence bundle generated | Hour 40 | **PASSED** | `tests/test_e2e.py::test_gate_g6` — Evidence bundle ZIP package with SHA-256 manifest hash verification |

---

## 2. Test Execution Summary

- **Total Test Suites Executed:** 10 suites
- **Total Tests Passing:** **68 / 68 (100% Pass Rate)**
- **Unit & Integration Suite Breakdown:**
  - `tests/test_contracts.py`: 4 passed
  - `tests/test_firmware_parity.py`: 4 passed
  - `tests/test_serial_ingest.py`: 10 passed
  - `tests/test_vision.py`: 6 passed
  - `tests/test_signal.py`: 11 passed
  - `tests/test_taskproof.py`: 12 passed
  - `backend/test_backend.py`: 6 passed
  - `tests/test_api_nexus.py`: 8 passed
  - `tests/test_e2e.py`: 4 passed
  - `ml/test_ml.py`: 3 passed
- **Execution Speed:** Full regression completes in under 3.5 seconds.

---

## 3. Subsystem Architecture & Implementation Status

### 3.1 Contracts & Protocol Layer (`shared/protocol/`, `config/`)
- Strict JSON Schema: `shared/protocol/protocol_v1_schema.json`
- Command/Response Schema: `shared/protocol/command_schema.json`
- Golden test fixtures: `shared/fixtures/golden_packet_v1.json`, `tests/fixtures/packet_golden_v1.json`
- Signal, TaskProof, and Zone configurations: `config/signal.yaml`, `config/taskproof.yaml`, `config/zones.json` with explicit `provisional` flags.

### 3.2 Firmware (`firmware-esp32/`)
- Target: ESP32-S3 DevKit at 921600 baud.
- Pinned drivers: Adafruit ADS1X15, ElectronicCats MPU6050, ArduinoJson 7.x.
- Scanning: 25 Hz non-blocking loop reading ADS1115 channels A0–A3 and MPU6050 accelerometer/gyroscope.
- Output: Strict newline-delimited JSON line packets `< 200` bytes with boot line announcement and command listener (`ping`, `config`, `rate`, `buzz`, `boot`).

### 3.3 Host Ingestion Engine (`backend/serial_ingest.py`)
- Threaded non-blocking line reader with bounded ring buffer (500 samples).
- Automatic port discovery via handshake ping-ack (`{"cmd":"ping"}`).
- Sequence monotonicity, gap counting, duplicate detection, and reboot epoch tracking.
- Value range bounds verification: Flex/FSR ADC $\in [0, 32767]$, IMU Accel $\in [-16g, +16g]$, Gyro $\in [-2000^\circ/\text{s}, +2000^\circ/\text{s}]$.

### 3.4 Computer Vision Engine (`backend/vision.py`)
- OpenCV tracking with `DICT_4X4_50` fiducial marker attached to transfer object.
- Quadrilateral point-in-polygon zone membership with **10 px hysteresis** on polygon borders.
- Rolling 1.0 s window marker detection rate calculation.
- Frame age and occlusion tracking: triggers camera stale warning if $> 150\text{ ms}$.

### 3.5 Kinematic Signal Processing (`backend/signal/`)
- Flex normalization: $R = \text{polarity} \times \frac{\text{raw} - \text{open}}{|\text{bent} - \text{open}|} \times 100\%$.
- Digital filters: Cascade median filter (window 3) and exponential moving average ($\alpha = 0.30$).
- FSR Contact detector: Schmitt trigger hysteresis ($k_{on} = 4, k_{off} = 2$ SD above baseline) with 100 ms debounce on contact and 150 ms hold on release.
- Grip change detector: Flags $\ge 15\%$ flexion delta from open baseline.
- IMU physical units and complementary tilt angle estimation.
- Object stillness detector: Asserts object centroid displacement $< 6$ pixels over 500 ms.

### 3.6 TaskProof Deterministic State Machine (`backend/taskproof.py`)
- 7-State lifecycle: `READY` $\rightarrow$ `SOURCE_VISIBLE` $\rightarrow$ `CONTACT_CANDIDATE` $\rightarrow$ `OBJECT_LIFTED` $\rightarrow$ `TARGET_REACHED` $\rightarrow$ `RELEASE_CONFIRMED` $\rightarrow$ `VERIFIED`.
- Strict honest verdicts: `VERIFIED`, `FAILED`, `UNCERTAIN`, `ABORTED`, `NOT_STARTED`.
- Safety guards:
  - Disconnect or stale sensor packet $> 200\text{ ms}$ during lift $\rightarrow$ `UNCERTAIN`.
  - Marker occlusion $> 150\text{ ms}$ during lift $\rightarrow$ `UNCERTAIN`.
  - Release before entering target zone $\rightarrow$ `FAILED`.
  - Object disturbance after release $\rightarrow$ `FAILED`.
  - Attempt timeout ($> 15.0\text{ s}$) $\rightarrow$ `FAILED`.
  - Operator abort hotkey $\rightarrow$ `ABORTED`.
- Cryptographic traceability: Embeds SHA-256 hash of `config/taskproof.yaml` into every attempt record.

### 3.7 Storage & REST/WebSocket Backend (`backend/`)
- SQLite database configured in WAL mode (`backend/h10_backend.db`).
- 16-table schema storing volunteers, consents, calibrations, sensor samples, vision samples, task attempts, events, ground truth, and ingest errors.
- Preflight diagnostic suite (`backend/preflight.py`): 10-point system readiness checklist.
- Wilson score 95% confidence intervals calculation (`backend/evaluation.py`).
- Evidence bundle export (`backend/evidence.py`): Packages attempts, ground truth, config snapshot, and SHA-256 manifest.
- FastAPI backend (`backend/main.py`): Unified server exposing REST endpoints, WebSocket `/ws/live`, and static production UI.

### 3.8 Dual-View Web Interface (`frontend/`)
- Vite + React 18 + TypeScript + Tailwind CSS.
- **Operator View:** Preflight diagnostics card, COM port selector, live TaskProof state timeline, sensor level gauges, rapid hotkey labelling (`S` = Success, `F` = Fail, `U` = Uncertain, `N` = New Attempt, `Esc` = Abort), CSV & Evidence Bundle export links.
- **Judge View:** High-contrast verdict-first display (64px text), live transfer timer, last 5 attempts history card, non-medical disclaimer banner.
- Build artifact generated at `frontend/dist/` (4.06s compile time, fully bundled).

### 3.9 Replay & Deployment Scripts (`scripts/`, `demo/`)
- Replay fixture: `demo/replays/session_verified_01.json` with `"source": "recorded_real"`.
- Clean start script: `scripts/start_nexus.ps1` (PowerShell) and `scripts/start_nexus.sh` (Bash).
- Stop script: `scripts/stop_nexus.ps1`.

---

## 4. ONEFORALL Collaboration Boundary
- Verified via `ofa status` and `ofa guard`.
- Zero files modified within `@vaishnavijare60-hash`'s claimed frontend zone (`mobile/lib/screens/`, `mobile/lib/widgets/`, `mobile/packages/h10_core/lib/theme/`, `docs/vaishnavi_jare/`).
- Mobile & web patient UI files untouched.
