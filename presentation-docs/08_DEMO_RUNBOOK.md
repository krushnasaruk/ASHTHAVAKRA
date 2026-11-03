<!-- Generated from commit cabf24c on 2026-11-03. Re-generate after any code change. -->

# RehabBridge NEXUS / H10 — Live Demonstration Runbook

**Event:** Innovation 2K26, College of Engineering, Phaltan (3–4 November 2026)  
**Total Allocated Time:** 11 Minutes (1m Pitch + 2m Demo + 7m Defense + 1m Close)  
**Execution Lead:** Developer (Software) & Gautam (Physical Glove)

---

## 1. Pre-Demo Setup Checklist (T-Minus 15 Minutes)

### 1.1 Hardware Table Rigging (Rajendra & Gautam)
- [ ] Place tabletop mat with printed Zone A (Left) and Zone B (Right).
- [ ] Mount USB webcam on overhead gooseneck clamp approximately 40–50 cm directly above the mat.
- [ ] Inspect glove wiring harness: verify no pinched ribbon wires or loose solder joints.
- [ ] Confirm transfer cube (60mm EVA foam, ArUco Marker ID#0) is clean and matte face is free of tape smudge.
- [ ] Plug ESP32-S3 USB cable into laptop USB 3.0 port. Verify green status LED illuminates.
- [ ] Keep backup hardware box on table: spare USB cable, spare ADS1115, spare FSR, and 100% alcohol sanitizing wipes.

### 1.2 Host Laptop Readiness (Developer)
- [ ] Laptop connected to AC power adapter (disable battery saver throttling).
- [ ] Open PowerShell in repository root: `C:\Users\Krushna\OneDrive\Documents\projects for github\asthavakra`.
- [ ] Ensure no orphan Python or Uvicorn instances are running on port 8000:
  ```powershell
  powershell -ExecutionPolicy Bypass -File scripts/stop_nexus.ps1
  ```
- [ ] Open Google Chrome to `http://127.0.0.1:8000`.

---

## 2. System Launch Command & Preflight Criteria

### Launch Command:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/start_nexus.ps1
```
*Expected Terminal Output:*
```text
[NEXUS] Starting RehabBridge NEXUS Unified Platform...
[NEXUS] Port 8000 cleared.
[NEXUS] Launching FastAPI backend server on 127.0.0.1:8000...
[NEXUS] Running 10-point system preflight diagnostics...
[NEXUS] Preflight Overall Status: PASS
[NEXUS] System Ready! Serving Web UI at http://127.0.0.1:8000
```

### Preflight Pass Criteria (Must be 100% Verified Before Judges Step In):
1. **Python Environment:** Python $\ge 3.10$ 64-bit (`PASS`).
2. **OpenCV ArUco Library:** OpenCV 4.x/5.x with `DICT_4X4_50` (`PASS`).
3. **Glove Hardware Link:** Physical COM port enumerated with ping-ack ACK (`PASS` or `WARN: Offline Simulator Ready`).
4. **Zones Geometry:** Zone A and Zone B polygons loaded with $\ge 4$ vertices (`PASS`).
5. **SQLite WAL Database:** Read/write accessibility with WAL journal enabled (`PASS`).
6. **Disk Space:** Free storage $\ge 500\text{ MB}$ (`PASS`).
7. **Network Security:** Server bound exclusively to local loopback `127.0.0.1` (`PASS`).

---

## 3. Minute-by-Minute Live Execution Script

| Time | Stage | Speaking & Action | Lead |
|---|---|---|---|
| **0:00 – 0:45** | **The Pitch & Problem** | Developer opens: "Judges, stroke patients need hundreds of daily hand exercise reps, but therapists currently have zero proof of home compliance. Existing projects claim to diagnose recovery using cheap flex sensors. We refused to make unverified claims. We built TaskProof—a deterministic physical verification engine." | Developer |
| **0:45 – 1:15** | **Hardware Architecture** | Rajendra shows glove hardware: "Our glove routes 3 flex sensors and a palmar FSR through a 16-bit external ADS1115 ADC over I2C at 25 Hz, streaming via USB serial at 921,600 baud. Gautam will now put on the glove." | Rajendra |
| **1:15 – 2:00** | **Live Transfer Attempt #1 (Success)** | Gautam places block in Zone A. Operator presses `[N]`. Gautam grasps, lifts, transfers to Zone B, and releases. Block remains still for 500 ms. Judge View flashes green: **`VERIFIED` (4.2 s)**. | Gautam |
| **2:00 – 2:45** | **Live Occlusion Attempt #2 (Honest Failure)** | Gautam starts Attempt #2. Mid-air, Gautam cups his hand over the marker. The screen immediately shifts to purple: **`UNCERTAIN` (`MARKER_OCCLUDED`)**. Developer explains: "Notice our system never guesses. Insufficient sensor proof yields an honest uncertain verdict." | Developer & Gautam |
| **2:45 – 3:15** | **UI & Accessibility** | Vaishnavi points to Judge View: "In a noisy hall, judges see high-contrast 64px typography readable from 3 meters. Patients see our Okabe-Ito color-blind safe palette and 48px touch targets, with a permanent non-medical disclaimer banner." | Vaishnavi |
| **3:15 – 3:30** | **Evidence Export** | Developer clicks **Evidence ZIP**: "With one click, our platform packages all raw attempts, timestamps, and SHA-256 cryptographic manifests into an auditable evidence bundle." | Developer |
| **3:30 – 10:30** | **Technical Cross-Examination** | Team answers judges' questions according to the `05_QA_BANK.md` and `06_HARD_QUESTIONS.md` protocols. | All |
| **10:30 – 11:00** | **Close & Roadmap** | Developer closes on the CDSCO Class B regulatory roadmap and clinical protocol requirements. | Developer |

---

## 4. Live Fallback Sequence (Hardware or Camera Failure)

If a camera driver crashes, an FSR wire detaches, or the COM port refuses to enumerate during the live demonstration:

### Step 1: Immediate Honest Statement (Developer)
> "Judges, our physical USB serial link has encountered a connection fault. Rather than stalling or fabricating a reading, our system has immediately defaulted to an honest safety state. Let me activate our authenticated Replay Mode."

### Step 2: Transition to Replay Mode
1. In the top navigation of the React web UI, click **REPLAY MODE**.
2. Point out to the judges:
   - The unclosable blue **`REPLAY MODE`** badge appears on the screen.
   - The database tags incoming attempts with `data_source: recorded_real`.
   - The system is feeding actual recorded frames from `demo/replays/session_verified_01.json`—a real recorded bench attempt, not synthetic sine waves.
3. Show the TaskProof state machine stepping through the real recorded transfer sequence.
4. Open the Preflight Diagnostics dialog to isolate the physical COM port status live in front of the judges.
