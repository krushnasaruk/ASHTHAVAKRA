<!-- Generated from commit cabf24c on 2026-11-03. Re-generate after any code change. -->

# Briefing Pack: Developer (Project Lead & System Architect)

**Role:** Software, Ingestion Pipeline, Signal Processing, TaskProof State Machine, Storage, Test Automation  
**Direct Ownership:** `backend/`, `shared/protocol/`, `config/`, `frontend/`, `tests/`, `scripts/`  
**Commits Owned:** `d320c68`, `ead312a`, `cabf24c`

---

## 1. What I Built & Own
- **Host Serial Ingestion Pipeline** ([`backend/serial_ingest.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/serial_ingest.py)): Threaded line reader, auto-port detection with ping-ack, sequence gap/duplicate/reset detection, and ring buffer.
- **Kinematic Signal Processing Layer** ([`backend/signal/`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/signal/)): Two-point calibration, median + EMA cascade ($\alpha=0.30$), Schmitt trigger contact detector, grip delta ($\ge 15\%$), and stillness detector.
- **TaskProof Deterministic State Machine** ([`backend/taskproof.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/taskproof.py)): 7-state verification engine with 200 ms stale sensor guard, 150 ms occlusion guard, and SHA-256 configuration fingerprinting.
- **Backend Services & Storage** ([`backend/main.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/main.py), [`backend/models.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/models.py)): FastAPI REST/WebSocket endpoints, 16 SQLite WAL tables, 10-point preflight diagnostic checker ([`backend/preflight.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/preflight.py)), and evidence packager ([`backend/evidence.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/evidence.py)).
- **Event Dashboard & Web Simulator** ([`frontend/src/App.tsx`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/frontend/src/App.tsx)): Dual-view React dashboard with live WebSocket telemetry, Operator labelling hotkeys, and mobile UI preview.
- **Automated Verification Suite** ([`tests/`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/)): 10 test suites covering 68 unit, integration, and E2E tests.

---

## 2. What Is Working & How I Know
- **G0 Ingestion Parity:** Confirmed by `test_fw_01` and `test_si_01` (valid protocol v1 lines parsed without loss).
- **G1 Throughput & Sequence Stability:** Confirmed by `test_si_03` and `test_si_08` (detects gaps, duplicates, and verifies 25 Hz throughput).
- **G2 ArUco Computer Vision:** Confirmed by `test_vi_01` and `test_vi_02` (marker detected at $\ge 15$ FPS with 10 px zone hysteresis).
- **G3 End-to-End TaskProof:** Confirmed by `test_tp_01` (complete valid transfer awarded `VERIFIED`).
- **G4 10 Consecutive Attempts:** Confirmed by `test_e2e_10` (10 consecutive attempts run without crash; recorded in SQLite WAL and exported to CSV).
- **G5 Preflight Diagnostics:** Confirmed by `test_e2e_12` (10-point diagnostic passes).
- **G6 Evidence Bundle & Code Freeze:** Confirmed by `test_gate_g6` (evidence ZIP generated with SHA-256 manifest hash match).
- **All 68 automated backend tests pass in 1.66 seconds** (`tests/TEST_RESULTS.md`).

---

## 3. What Is NOT Working or Not Finished
- **Wi-Fi Transport Adapter (T2 / Tier 2):** Not yet implemented for live stream. USB serial at 921,600 baud is used exclusively for event stability.
- **On-Device ML Inference (T3 / Tier 3):** Movement classification model is prepared in Colab (`ml/colab/`), but on-device inference is not wired into the live TaskProof loop.
- **Clinical Validation:** Sample size is $n=10$ labelled trials in bench testing. Statistical reliability across diverse patient populations is `NOT YET MEASURED`.

---

## 4. 90-Second Speaking Script
> "Judges, the fundamental problem with assistive rehab tech is trust. Most hackathon projects show you a flex sensor and claim to diagnose stroke recovery or measure joint angles. We refused to make unverified claims.
> 
> What I built is **TaskProof**—a deterministic verification engine. Over USB serial at 921,600 baud, our ESP32-S3 streams digitized 16-bit sensor data at 25 Hz into a multi-threaded Python ingestion pipeline. Simultaneously, an overhead camera tracks an ArUco fiducial marker on the transfer object with 10-pixel border hysteresis.
> 
> Our state machine enforces seven discrete physical transitions: from resting, to contact, to lift, to target arrival, to stillness. If telemetry drops for more than 200 milliseconds, or if the marker is occluded for more than 150 milliseconds during transit, our algorithm never guesses success. It immediately emits an honest `UNCERTAIN` verdict. Every event is written into an ACID-compliant SQLite WAL database with cryptographic SHA-256 configuration hashes.
> 
> I now hand over to Rajendra to walk through the custom hardware and sensor electronics."

---

## 5. Live Demo Steps
1. Open terminal and run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/start_nexus.ps1
   ```
2. Verify browser opens at `http://127.0.0.1:8000`.
3. Check Preflight card: all core checks (`Python`, `OpenCV`, `SQLite WAL`, `Disk Space`) must show green **PASS**.
4. Confirm serial status shows `25 Hz SERIAL` or click **REPLAY** if hardware is disconnected.
5. In Operator View, press `[N]` or click **Start Attempt**.
6. When transfer completes, verify verdict flashes green `VERIFIED` in Judge View.
7. Click **Evidence ZIP** to download the signed evidence package.
8. *If backend fails to connect:* State calmly: "The local server process was halted. I will start the fallback replay service." Run `python -m uvicorn backend.main:app --port 8000` and switch to Replay mode.

---

## 6. Numbers I May Quote vs Must NOT Quote

### Allowed Numbers (Sourced):
- **Baud Rate:** 921,600 baud (`firmware-esp32/platformio.ini`).
- **Sample Rate:** 25 Hz per channel (`config/signal.yaml`).
- **Occlusion Timeout:** 150 ms (`config/taskproof.yaml`).
- **Stale Packet Timeout:** 200 ms (`config/taskproof.yaml`).
- **Stillness Threshold:** Displacement $< 6$ pixels over 500 ms (`config/taskproof.yaml`).
- **Precision / Recall:** 1.0 (100%) on $n=10$ bench attempts, with 95% Wilson confidence interval of $[0.7225, 1.0]$ (`backend/evaluation.py`, `docs/VALIDATION_SHEET.csv`).
- **Total Test Suite:** 68 passing automated tests in 1.66s (`docs/TEST_RESULTS.md`).

### Numbers I Must NOT Quote:
- **"99% Clinical Accuracy":** Prohibited. Clinical accuracy is unmeasured ($n=10$ bench only).
- **Angle in degrees (e.g., "72 degrees of flexion"):** Prohibited. Resistive flex sensors without 3D motion capture provide normalized span percentage, not calibrated clinical joint angles.
- **Battery Life:** Prohibited. Prototype is USB bus-powered; battery sensor is `unsupported`.

---

## 7. Question Ownership & Handoffs

### Questions I Own:
- `SYS-01` (Why USB serial instead of BLE or Wi-Fi?)
- `SYS-02` (Why deterministic TaskProof instead of machine learning?)
- `SYS-03` (Why SQLite with WAL mode?)
- `SYS-04` (How do you handle dropped packets or sequence resets?)
- `VER-01` (What does UNCERTAIN mean and why is it not considered a failure?)
- `EVAL-01` (What is your sample size and confidence interval?)
- `EVAL-02` (How do you measure latency and frame age?)

### Questions I Hand Off:
- Hardware wiring, ADC sampling limits, electrical divider design $\rightarrow$ **Hand off to Rajendra**.
- Glove mechanics, sensor strain relief, physical object design $\rightarrow$ **Hand off to Gautam**.
- Judge View UI, typography, color-blind palette, user flows $\rightarrow$ **Hand off to Vaishnavi**.

---

## 8. Failure Script
> "Judges, the telemetry link just reported a packet loss exceeding our 200-millisecond safety limit. Because this is a zero-fabrication safety system, TaskProof has immediately awarded an `UNCERTAIN` verdict rather than guessing that the patient succeeded. Here in the Operator View, you can see the reason code `STALE_SENSOR_PACKET` logged to the SQLite audit database with timestamp precision. Let me trigger our preflight diagnostic to verify the port status."
