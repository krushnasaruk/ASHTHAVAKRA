# H10 — Testing Architecture & Real Test Outputs

Quality assurance in H10 spans unit, parity, integration, and UI widget tests across all layers.

---

## 1. Automated Test Suite Summary (54 Total Tests)

| Layer | Framework | Command | Total Tests | Pass Status |
|---|---|---|---|---|
| **Hardware Simulator** | Pytest (`simulator/test_simulator.py`) | `pytest simulator/test_simulator.py` | 7 | **7/7 PASSED** |
| **ML & Dataset Validation** | Pytest (`ml/test_ml.py`) | `pytest ml/test_ml.py` | 3 | **3/3 PASSED** |
| **Backend REST API** | Pytest (`backend/test_backend.py`) | `pytest backend/test_backend.py` | 6 | **6/6 PASSED** |
| **Signal Engine (`h10_core`)** | Dart Test (`mobile/packages/h10_core`) | `dart test` | 33 | **33/33 PASSED** |
| **Mobile Patient App** | Flutter Test (`mobile/test/`) | `flutter test` | 4 | **4/4 PASSED** |
| **Clinician Dashboard** | Flutter Test (`admin/test/`) | `flutter test` | 1 | **1/1 PASSED** |
| **Total** | | | **54** | **54/54 PASSED (100%)** |

---

## 2. Key Test Verification Highlights

### 2.1 Feature Parity (< 1e-6 Tolerance)
`mobile/packages/h10_core/test/feature_parity_test.dart` runs every window of `shared/fixtures/feature_golden_v1.json` through the pure Dart `FeatureExtractor` and compares all 84 floating-point features against the Python reference:
$$\max |f_{\text{dart}}[i] - f_{\text{py}}[i]| < 10^{-6}$$
**Result:** Passed with zero discrepancies.

### 2.2 20-Repetition Scripted Sequence Test
`test/repetition_detector_test.dart` executes a scripted sequence of 20 clean repetitions with varying cadence and minor hesitation.
**Result:** Exactly 20 repetitions detected, zero false positives, and zero missed crossings.

### 2.3 Backend Idempotency & PII Refusal Test
`backend/test_backend.py`:
- Ingesting a session twice returns `201 Created` then `200 OK`.
- Tampering with repetition metrics in an existing session ID returns `409 Conflict`.
- Registering a patient with `email` or `name` in the payload returns `400 Bad Request`.
- Soft-deleting a patient verifies tombstone creation without orphaned data.

---

## 3. Real Test Output Log (Captured Verbatim)

```text
============================= test session starts =============================
platform win32 -- Python 3.14.3, pytest-9.1.1, pluggy-1.6.0
collected 16 items

simulator\test_simulator.py .......                                      [ 43%]
ml\test_ml.py ...                                                        [ 62%]
backend\test_backend.py ......                                           [100%]
======================= 16 passed in 2.10s =======================

$ cd mobile/packages/h10_core && dart test
00:00 +33: All tests passed!

$ cd mobile && flutter test
00:02 +4: All tests passed!

$ cd admin && flutter test
00:02 +1: All tests passed!
```
