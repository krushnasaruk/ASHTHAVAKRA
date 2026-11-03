# RehabBridge NEXUS / H10 — Team Presentation Cheat Sheet

## 1. Speaking Order & Live Demo Schedule (Total Time: 10 Minutes)

| Order | Speaker & Role | Time Slot | Live Demo Action Owned |
|:---:|---|:---:|---|
| **1** | **Krushna** (Software & Systems Lead) | 0:00 – 1:15 (75s) | Run preflight check, start serial stream, and monitor TaskProof state transitions. |
| **2** | **Vaishnavi** (Product Design) | 1:15 – 2:30 (75s) | Switch between Operator View and Judge View, inspect high-contrast verdict cards. |
| **3** | **Rajendra** (Electronics & Firmware) | 2:30 – 3:45 (75s) | Verify 25 Hz ADS1115 telemetry, show GPIO 47 status LED, trigger disconnect guard. |
| **4** | **Gautam** (Mechanics & Validation) | 3:45 – 5:00 (75s) | Don glove, demonstrate floating sleeves, perform live object transfer across zones. |
| **5** | **Full Team** (Technical Q&A Defense) | 5:00 – 10:00 (5m) | Field judge technical inquiries adhering strictly to ownership and honest boundaries. |

---

## 2. Three Numbers the Team May Quote

1. **10 out of 10 Verified Bench Attempts (100% Agreement on Tested Set):**  
   - *Source File:* `docs/VALIDATION_SHEET.csv` ($n = 10$).  
   - *Statistical Precision:* 95% Wilson confidence interval is $[0.7225, 1.0000]$.  
   - *Mandatory Statement:* "We are still collecting labelled trials; current count is 10, so this sample is too small to establish clinical diagnostic reliability."

2. **25 Hz Serial Stream Rate (40 ms packet interval):**  
   - *Source File:* `firmware-esp32/include/config.h` and `tests/test_serial_ingest.py` ($n = 10$ test trials, zero sequence packet drops).

3. **₹6,180 Active Prototype Hardware Cost (₹8,400 with Critical Spares):**  
   - *Source File:* `docs/BOM.csv` ($n = 19$ itemized hardware lines).

---

## 3. Honest Lines for Unmeasured or Future Capabilities

- **Clinical accuracy on stroke patients:**  
  "We will not give a clinical accuracy percentage until we have enough labelled patient trials to make it meaningful. Right now we have 10 bench trials with healthy volunteers, documented in `docs/VALIDATION_SHEET.csv`."

- **Grip strength in newtons or joint angles in degrees:**  
  "We have not measured that yet. Our next step is calibration against an external load cell and digital goniometer, tracked under post-hackathon testing in `docs/TEST_RESULTS.md`."

- **Wireless Wi-Fi / Bluetooth battery operation:**  
  "That part is not built yet. What works today is isolated 5V USB-C tethered power and 921600 baud serial communication."

- **Fit across pediatric or spastic hand contractures:**  
  "We have not measured that yet. Our current glove fits hand lengths 17 to 20 cm, and testing with spasticity or contractures is scheduled under our clinical study protocol."

---

## 4. Live Failure Fallback Script

If the physical glove, ADC, or serial port fails during the live presentation, do not panic, apologize, or attempt live wire resoldering. Speak this exact line and proceed:

> *"The live glove is not responding, so I will show a recorded real session, marked REPLAY on screen."*

Toggle the UI data source switch to **Replay Mode** in `frontend/src/App.tsx`, and continue the demonstration using the verified recorded session fixture.

