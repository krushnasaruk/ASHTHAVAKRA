# Project Explanation for Developer — Krushna (Software & System Architecture)

**Role:** Software & Systems Lead  
**Direct System Ownership:** Serial ingestion (`backend/serial_ingest.py`), TaskProof engine (`backend/taskproof.py`), Signal processing (`backend/signal_layer.py`), FastAPI server & SQLite database (`backend/main.py`, `backend/database.py`), React live dashboard (`frontend/src/App.tsx`).

---

## 1. What the Project Is & Why We Built It

RehabBridge NEXUS is a multi-sensor system designed to solve a fundamental flaw in home motor rehabilitation: **conventional tools merely count finger twitches, without verifying if a patient actually performed a functional daily task**. 

We built a dual-modality verification platform combining:
1. An **instrumented sensor glove** measuring 3 finger flexion channels, palmar contact pressure, and hand motion at 25 Hz.
2. An **overhead computer vision camera** tracking an ArUco fiducial marker on a physical object (a 28g foam cube).
3. A **TaskProof state machine** that mathematically verifies whether the object was grasped, lifted, carried across a physical boundary, and placed cleanly in a target zone.

---

## 2. How the Software Application Works

### 2.1 Ingestion & Normalization Pipeline
- **Serial Ingestion (`backend/serial_ingest.py`):** Reads line-delimited JSON packets from the ESP32-S3 at 921600 baud. It maintains a ring buffer, detects sequence number gaps, verifies packet monotonicity, and monitors delivery rate (target: 25 Hz).
- **Signal Filtering (`backend/signal_layer.py`):** Normalizes raw 16-bit ADC values using two-point baseline calibration ($0.0$ flat hand to $1.0$ clenched fist). Applies exponential moving average (EMA) smoothing and Schmitt-trigger hysteresis to palmar force readings to eliminate bounce.

### 2.2 Computer Vision Tracking (`backend/vision.py`)
- Detects OpenCV `DICT_4X4_50` marker ID#0 at 15+ frames per second.
- Maps marker coordinates to physical zones (Zone A start, Zone B target) with 10 px hysteresis at boundary edges.
- Calculates a 1-second rolling marker detection rate and frame age.

### 2.3 Deterministic TaskProof State Machine (`backend/taskproof.py`)
Executes a strict 7-state lifecycle:
$$\text{IDLE} \rightarrow \text{WAITING\_FOR\_GRASP} \rightarrow \text{GRASPED} \rightarrow \text{LIFTED} \rightarrow \text{TRANSPORTING} \rightarrow \text{IN\_TARGET\_ZONE} \rightarrow \text{RELEASED}$$

**The Core Honesty Guard:**
If the camera marker is occluded for $> 500\text{ ms}$, or if sensor telemetry disconnects, the state machine defaults to **`UNCERTAIN`**. It never guesses or awards false success.

### 2.4 Persistence & Live Dashboard
- **SQLite Database (`backend/database.py`):** Uses Write-Ahead Logging (`PRAGMA journal_mode=WAL`) and `NORMAL` synchronous mode for zero dropped writes during rapid consecutive attempts.
- **WebSocket Streaming:** Telemetry is broadcast at 25 Hz to `frontend/src/App.tsx`.
- **Dual-View UI:** Provides an **Operator View** for raw telemetry and preflight diagnostics, and a **Judge View** featuring 64px high-contrast verdict cards readable from across the room.

---

## 3. Your 90-Second Demo & Presentation Script

> "I am Krushna, software and systems architect for RehabBridge NEXUS. Traditional rehabilitation apps rely on uncalibrated approximations: they see a finger twitch and call it an exercise. NEXUS is different because it uses deterministic sensor fusion to prove real-world task completion.
> 
> In our Python backend, I built our serial ingest ring buffer running at 25 Hz, our OpenCV ArUco tracking pipeline, and the TaskProof state machine. The state machine checks four physical guards: contact pressure, vertical lift, transport velocity, and target zone release.
> 
> Our most important architectural principle is honesty. If a patient blocks the camera, or if sensor telemetry drops, the engine refuses to fabricate a result and emits an UNCERTAIN verdict. Every attempt is immutably logged to an SQLite database with SHA-256 configuration hashes.
> 
> During our live demo, I will initiate our preflight diagnostic, start our live stream, and show the state machine verify an object transfer attempt in real time."

---

## 4. Key Judge Questions You Own

1. **How do you prevent false positives when lighting changes or the camera is occluded?**  
   *Answer:* Our vision module in `backend/vision.py` continuously calculates a 1-second rolling detection rate, and test `tests/test_taskproof.py::test_tp_12` verifies that marker occlusion immediately defaults the state machine to an UNCERTAIN verdict.
2. **What guarantees that database writes do not lose telemetry during rapid attempts?**  
   *Answer:* SQLite runs in write-ahead log mode with WAL checkpoints in `backend/database.py`, verified in `tests/test_e2e.py::test_e2e_10` across ten rapid consecutive trials.
3. **Can your software diagnose motor recovery or predict clinical outcomes?**  
   *Answer:* No, our system only verifies completion of a defined mechanical transfer task; clinical diagnosis is explicitly prohibited in `backend/schemas.py` and requires formal clinical trials.

