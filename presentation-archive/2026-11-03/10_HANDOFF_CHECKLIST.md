<!-- Generated from commit cabf24c on 2026-11-03. Re-generate after any code change. -->

# RehabBridge NEXUS / H10 — Event Readiness & Handoff Checklist

**Event:** Innovation 2K26, College of Engineering, Phaltan (3–4 November 2026)  
**Rule:** Every team member has an explicit physical and software readiness checklist with an initial sign-off line.

---

## 1. Developer (Project Lead & System Architect)

### What to Have Ready on the Day:
- [ ] Laptop with Python 3.10+ (64-bit), Node.js, and Chrome installed and tested.
- [ ] Local server verified running completely offline with Wi-Fi disabled (`127.0.0.1:8000`).
- [ ] Preflight diagnostic script passing 10/10 checks (`powershell -File scripts/start_nexus.ps1`).
- [ ] Terminal pre-configured with quick hotkeys and clean screen resolution (1080p).
- [ ] Local offline copy of `presentation-docs/` loaded on desktop for immediate reference.

### What to Bring:
- [ ] Host primary laptop + original AC power adapter.
- [ ] Backup laptop with cloned repository and Python dependencies installed.
- [ ] USB flash drive with offline installer wheels and repository git bundle.
- [ ] HDMI/USB-C display adapter for external event monitors.

**Sign-off:** _______________________ (Developer Initials) &nbsp;&nbsp;&nbsp;&nbsp; Date: _____________

---

## 2. Vaishnavi Jare (Product Design & Volunteer UX)

### What to Have Ready on the Day:
- [ ] Chrome browser bookmarked to `http://127.0.0.1:8000` with Judge View toggled to full screen (F11).
- [ ] Patient Mobile UI Preview loaded and tested across all 5 navigation tabs.
- [ ] Pitch presentation slides verified on 16:9 aspect ratio with zero unverified claims.
- [ ] High-contrast color calibration verified on projector/monitor for Okabe-Ito visibility.
- [ ] Volunteer Consent form printed or loaded on tablet for volunteer sign-off.

### What to Bring:
- [ ] Android smartphone / tablet with Flutter patient app pre-installed (`H10_Patient_App_v1.apk`).
- [ ] Hardcopy printed Volunteer Consent forms (10 copies).
- [ ] Laminated slide summary handouts for judges (4 copies).

**Sign-off:** _______________________ (Vaishnavi Jare Initials) &nbsp;&nbsp;&nbsp;&nbsp; Date: _____________

---

## 3. Rajendra (Hardware Electronics & Firmware — Proposed)

### What to Have Ready on the Day:
- [ ] ESP32-S3 DevKit-C flashed with latest firmware from `firmware-esp32/`.
- [ ] I2C bus wiring verified at 400 kHz between ESP32, ADS1115 (`0x48`), and MPU6050 (`0x68`).
- [ ] Resistor divider legs securely soldered on perfboard with zero short circuits.
- [ ] Boot notification verified on serial port monitor at 921,600 baud.
- [ ] Multimeter test points checked: clean 3.3V DC rail on ADC pin.

### What to Bring:
- [ ] Assembled sensor circuit perfboard mounted on glove wrist bracket.
- [ ] Primary 1.5m shielded USB-C data cable + 1 spare USB cable.
- [ ] Emergency hardware kit: Digital multimeter, wire strippers, electrical tape, spare ADS1115 module, spare 10 kΩ resistors.
- [ ] Powered 4-port USB 3.0 hub (in case laptop ports deliver insufficient 5V current).

**Sign-off:** _______________________ (Rajendra Initials) &nbsp;&nbsp;&nbsp;&nbsp; Date: _____________

---

## 4. Gautam (Glove Mechanics & Validation — Proposed)

### What to Have Ready on the Day:
- [ ] Primary instrumented cotton glove with 3 flex sensors seated in floating guide sleeves.
- [ ] Palmar FSR contact sensor firmly adhered over EVA foam buffer pad.
- [ ] Wrist strain relief clamp fastened, preventing cable pull on soldered leads.
- [ ] Standardized transfer cube ($60\times 60\times 60\text{ mm}$ EVA foam, $28\text{ g}$, ArUco ID#0) inspected for flat marker surface.
- [ ] Tabletop mat with clearly demarcated Zone A and Zone B rectangles.
- [ ] Pre-calibrated 10 bench trials logged in `docs/VALIDATION_SHEET.csv`.

### What to Bring:
- [ ] Primary instrumented glove + 1 spare uninstrumented cotton glove for sizing tests.
- [ ] Standardized ArUco transfer cube + 1 backup cube.
- [ ] Overhead camera clamp / mini desktop tripod with gooseneck arm.
- [ ] Roll of velcro straps, 3M double-sided mounting tape, and isopropyl alcohol sanitizing wipes.

**Sign-off:** _______________________ (Gautam Initials) &nbsp;&nbsp;&nbsp;&nbsp; Date: _____________

---

## 5. Team Final Readiness Sign-Off
We, the team members of RehabBridge NEXUS / H10, certify that all statements made in these presentation documents are grounded in our repository code, test records, and hardware measurements. We commit to upholding our claims boundaries: we will never present simulated data as real, claim clinical efficacy without clinical trials, or assert unmeasured degrees of motion.

- **Developer (Project Lead):** ___________________________ Date: ______________
- **Vaishnavi Jare (Designer):** ___________________________ Date: ______________
- **Rajendra (Hardware Lead):** ___________________________ Date: ______________
- **Gautam (Validation Lead):** ___________________________ Date: ______________
