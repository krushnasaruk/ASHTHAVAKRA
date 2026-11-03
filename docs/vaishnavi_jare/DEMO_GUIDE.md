# H10 — End-to-End Demonstration Guide

This guide walks through demonstrating the complete H10 rehabilitation system end-to-end using the built-in simulator, mobile app, backend API, and clinician dashboard.

---

## 1. Quick Start Commands

### Step 1: Start the Backend API & Database
```bash
# Terminal 1: Start FastAPI backend (port 8000)
python -m backend.main
```
Verify at `http://127.0.0.1:8000/health`.

### Step 2: Start the Hardware Simulator
```bash
# Terminal 2: Start Simulator on port 8001
python -m simulator.server --port 8001 --scenario fist_repetitions
```
Verify WebSocket at `ws://127.0.0.1:8001/ws/sensors`.

### Step 3: Launch the Clinician Dashboard (Flutter Web)
```bash
# Terminal 3: Launch Clinician Web Portal
cd admin
flutter run -d chrome --web-port 3000
```
Open `http://localhost:3000` in Google Chrome or Microsoft Edge.

### Step 4: Launch the Mobile Patient App
```bash
# Terminal 4: Launch Mobile Application
cd mobile
flutter run
```

---

## 2. Walkthrough Workflow

### 1. Connection & Live Telemetry
1. Open the Mobile Patient App.
2. Tap the **Device** tab.
3. Select **Simulator (Localhost)**. Set port to `8001` and tap **Connect & Stream**.
4. Observe the connection chip change to **STREAMING (50 HZ)** with low packet loss.

### 2. Guided Two-Stage Calibration
1. In the Mobile App, tap **Calibrate Glove**.
2. **Stage 1 (Open Hand):** Hold hand open flat; tap **Capture Open Hand**. Wait 2 seconds for median convergence.
3. **Stage 2 (Closed Fist):** Clench fist firmly; tap **Capture Closed Fist**.
4. Review the computed spans ($> 300$ counts) and polarities. Tap **Save Calibration**.

### 3. Prescribed Exercise Session
1. Tap the **Today** tab.
2. Review prescribed plan: *Fist Clench & Release • 10 reps • 70–100% ROM*.
3. Tap **Start Prescribed Exercise**.
4. Observe the real-time articulated hand visualization, 5 Okabe-Ito finger bars, and repetition progress ring.
5. Perform/simulate repetitions. Observe the hold timer tick down and the rep counter increment upon clean descent.
6. Tap **Finish Session**.
7. In the Summary Screen, log post-exercise pain ($2/10$) and fatigue ($3/10$).
8. Tap **Save Session Record**.

### 4. Clinician Review & Report Export
1. Switch to the **Clinician Dashboard** on your browser (`http://localhost:3000`).
2. **Overview:** View active cohort metrics, today's sessions, and the Priority Flags feed.
3. **Patient List:** Click **View Detail** on patient `P-014`.
4. **Sessions Tab:** Expand the newly completed session to inspect repetition durations, dimensionless jerk smoothness, and fatigue drop index.
5. **Progress & Trends Tab:** Observe the ROM progression bar chart and finger mobility distribution.
6. **Plan Editor Tab:** Tap **Update / Version Plan**, enter a clinical justification (e.g. *"Progressing target ROM by 5%"*), and verify that Version 3 is created with an audit trail.
7. **Export Tab:** Tap **Generate 1-Page Summary PDF**. Observe the generated clinical summary document with complete baseline comparisons and mandatory research prototype disclaimers.
8. Tap **Download Telemetry CSV** to view the raw telemetry records.

