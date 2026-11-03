<!-- Generated from commit cabf24c on 2026-11-03. Re-generate after any code change. -->

# RehabBridge NEXUS / H10 — Comprehensive Consistency Report

**Event:** Innovation 2K26, College of Engineering, Phaltan (3–4 November 2026)  
**Rule:** Explicitly record all discrepancies between specifications, documentation, and source code. Do not silently resolve or conceal contradictions.

---

## 1. Discrepancy Matrix

| Conflict ID | Source A | Source B | Discrepancy & Conflict Analysis | Severity | Recommended Fix |
|---|---|---|---|---|---|
| **CON-01** | `docs/ASSUMPTIONS.md#L14` states: *"Stream rate: 50 Hz"* | `config/signal.yaml` & `backend/serial_ingest.py` enforce: *"sample_rate_hz: 25"* | **Sampling Frequency Mismatch:** Early H10 specifications assumed a 50 Hz stream rate. However, hardware benchmarking of the 4-channel ADS1115 ADC multiplexer showed that settling time limits safe sequential sampling to 25 Hz per channel. | **Major** | Update `docs/ASSUMPTIONS.md` to reflect Decision `D-10` from ADR 06, citing the 25 Hz ADC multiplexer settling limit. |
| **CON-02** | Legacy `docs/HARDWARE_INTEGRATION.md` references *"5 flex channels for all 5 fingers"* | `docs/BOM.csv`, `config/signal.yaml`, and `firmware-esp32/include/config.h` implement `demo3` *(3 flex sensors + 1 FSR)* | **Active Channel Count:** The full long-term H10 specification specifies 5 flex channels. However, the event BOM and 4-channel ADS1115 ADC allow only 3 flex channels (Thumb, Index, Middle) plus 1 FSR channel under profile `demo3`. | **Major** | Clarify in documentation that `demo3` is the active event demonstrator profile, while `full5` is the Tier 2 platform design requiring a second ADC. |
| **CON-03** | Legacy H10 spec listed verdicts as `SUCCESS`, `FAIL`, `INCOMPLETE` | `backend/taskproof.py` & `tests/test_taskproof.py` implement `VERIFIED`, `FAILED`, `UNCERTAIN`, `ABORTED`, `NOT_STARTED` | **Verdict Set Vocabulary:** Older documents used informal binary terms (`SUCCESS`/`FAIL`). TaskProof v3 uses honest verification terminology (`VERIFIED`/`FAILED`/`UNCERTAIN`/`ABORTED`). | **Minor** | Update legacy documentation tables in `docs/REPETITION_DETECTION.md` to align with the canonical TaskProof enum in `backend/taskproof.py`. |
| **CON-04** | `mobile/lib/services/device_service.dart#L40` contains `int batteryPct = 90;` | Non-Negotiable Rule #8 & `docs/BOM.csv` state *"Battery is unsupported, never a number"* | **Hardcoded Battery Placeholder:** The Flutter device service contains a legacy mock battery percentage field (`90%`), which conflicts with rule #8 prohibiting fake battery numbers. | **Critical** | Update `mobile/lib/services/device_service.dart` and `s1_today_screen.dart` to display `Battery: Unsupported (USB Powered)` instead of a numerical percentage. |
| **CON-05** | `docs/ASSUMPTIONS.md#L32` defines pseudonym format as `P-XXX` (e.g. `P-014`) | `backend/main.py#L190` regex accepts `^(V|P)-\d{3,4}$` (allowing `V-101`) | **Pseudonym Prefix Inconsistency:** Initial documents specified `P-` for clinical patients, while the hackathon NEXUS specification introduced `V-` for student volunteers. | **Minor** | Harmonize documentation to state that `V-XXX` designates hackathon volunteers, while `P-XXX` designates clinical patient records. |
| **CON-06** | `docs/TEST_RESULTS.md` recorded 65 backend tests | Actual executed test run contains 68 tests (including 3 in `ml/test_ml.py`) | **Test Count Under-reporting:** The initial test tally omitted the three machine learning dataset integrity tests in `ml/test_ml.py`. | **Minor** | Keep `docs/TEST_RESULTS.md` updated with the exact count of 68 backend/ML tests and 38 Flutter/Dart tests (106 tests total). |

---

## 2. Immediate Recommended Actions Before Judging

1. **Fix Battery Label in Mobile UI (CON-04):** Ensure neither the mobile screen nor the web dashboard displays a numerical battery percentage like `90%`. Replace with `USB Bus Powered`.
2. **Standardize 25 Hz Across All Overview Slides (CON-01):** Ensure all team members quote **25 Hz**, explaining the ADS1115 multiplexer settling time limit, rather than legacy 50 Hz text.
3. **Reiterate the demo3 vs full5 Distinction (CON-02):** When judges ask why pinky and ring fingers are uninstrumented, cite Decision `D-01` and explain that 3 flex + 1 FSR maximizes the 4-channel ADS1115 without signal multiplexer degradation.
