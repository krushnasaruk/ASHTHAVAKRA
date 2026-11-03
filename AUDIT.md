# H10 Flutter App — Comprehensive Codebase Audit & Repair Report
**Project:** ASHTAVAKRA v2 (H10 AI Hand-Rehabilitation Glove Prototype)  
**Status:** COMPLETE (All Tests Passing, 0 Analyzer Issues, Standalone v2 APK Built)  
**Disclaimers:** Prototype Monitoring & Engineering Demonstration Only — Not a Medical Device.

---

## 1. Complete Architecture Inventory

### 1.1 Screens & Routes
| Screen / Route | File Location | Dependencies | Data Wiring Status | Audit Status |
|---|---|---|---|---|
| **Root Shell (`H10PatientApp`)** | `mobile/lib/main.dart` | `DeviceService`, `StorageService`, ThemeNotifier | Dynamic bottom dock with VectorIcon center action; patient avatar derives from real patient pseudonym (`P14`); header formatted cleanly without ellipsis | **PASS** |
| **Today Screen (`TodayScreen`)** | `mobile/lib/screens/s1_today_screen.dart` | `DeviceService`, `StorageService`, `PreflightDialog` | 100% wired to real sessions; displays explicit empty state when storage is unpopulated; care team displays lead prescriber (`plan.setBy`) or mock fixtures in dev mode | **PASS** |
| **Device Connection (`DeviceScreen`)** | `mobile/lib/screens/s2_device_screen.dart` | `DeviceService`, HTTP/WebSocket stream | Wired to real ESP32/simulator socket, battery, RSSI, and calibration status | **PASS** |
| **Calibration Wizard (`CalibrationScreen`)** | `mobile/lib/screens/s3_calibration_screen.dart` | `DeviceService`, `StorageService`, `CalibrationEngine` | Wired to calibration engine; halts and prompts when hardware/simulator is disconnected unless `kUseMockData` is enabled | **PASS** |
| **Exercises Catalog (`ExercisesScreen`)** | `mobile/lib/screens/s4_exercises_screen.dart` | `StorageService`, `ExerciseCode` | Real exercise definitions, wired to launcher | **PASS** |
| **Live Session (`LiveSessionScreen`)** | `mobile/lib/screens/s5_live_session_screen.dart` | `DeviceService`, `StorageService`, `RepetitionDetector`, `ExerciseSignal` | Live streaming wired; synthetic sine wave strictly gated behind compile-time `kUseMockData` flag | **PASS** |
| **Session Summary (`SessionSummaryScreen`)** | `mobile/lib/screens/s6_summary_screen.dart` | `StorageService`, `ConsistencyCalculator`, `FatigueCalculator` | Real metrics calculation; patient pain/fatigue sliders | **PASS** |
| **Progress & Recovery (`ProgressScreen`)** | `mobile/lib/screens/s7_progress_screen.dart` | `StorageService`, `PatientBaseline`, `TrendClassifier` | All metrics dynamically computed: ROM gain vs baseline, adherence %, daily rep bar heights, and kinematics radar polygon; clean empty state when no data | **PASS** |
| **Session History (`HistoryScreen`)** | `mobile/lib/screens/s8_history_screen.dart` | `StorageService`, CSV/JSON export | 100% wired to real stored sessions; empty state present | **PASS** |
| **Settings & Config (`SettingsScreen`)** | `mobile/lib/screens/s9_settings_screen.dart` | `DeviceService`, `StorageService` | Plan parameters, telemetry diagnostics, storage wipe; async gap resolved | **PASS** |
| **TaskProof Verification (`TaskProofScreen`)** | `mobile/lib/screens/s10_taskproof_screen.dart` | `DeviceService`, `StorageService`, Backend API | Real HTTP polling to `/api/taskproof/status`, live camera zone tracking | **PASS** |
| **Interactive Mini-Game (`MiniGameScreen`)** | `mobile/lib/screens/minigame_screen.dart` | `DeviceService`, `StorageService` | Flexion-controlled catch loop; summary computes actual mean & max ROM from reps | **PASS** |

---

### 1.2 Services
| Service | File Location | Dependencies | Data Wiring Status | Audit Status |
|---|---|---|---|---|
| **DeviceService** | `mobile/lib/services/device_service.dart` | `http`, `web_socket_channel`, `PacketDecoder` | Real 30-byte binary & JSON stream parser, reconnect/disconnect, latency & rate counter | **PASS** |
| **StorageService** | `mobile/lib/services/storage_service.dart` | `h10_core` models, `FlagGenerator` | Offline-first session memory, CSV/JSON export, default plan | **PASS** |
| **SyncService** | `mobile/lib/services/sync_service.dart` | `StorageService`, Backend HTTP API | Real sync queue with conflict detection (HTTP 409) | **PASS** |
| **ModelService** | `mobile/lib/services/model_service.dart` | `FeatureExtractor`, manifest JSON | Rule/feature-based gesture classifier for 75-sample windows | **PASS** |

---

### 1.3 Core Models & Domain Logic (`packages/h10_core`)
| Component | File Location | Purpose | Status |
|---|---|---|---|
| `SensorPacket` / `PacketDecoder` | `h10_core/lib/models/sensor_packet.dart` | Dual-schema support: 30-byte binary & JSON with both 5-flex/6-IMU and 3-flex/quaternion schemas | **PASS** |
| `CalibrationRecord` / `Engine` | `h10_core/lib/calibration/calibration_engine.dart` | 2-second stability window SD & median, span >= 300 | **PASS** |
| `Normalizer` | `h10_core/lib/normalization/normalization.dart` | Clamped 0-100% flexion with polarity awareness | **PASS** |
| `RepetitionDetector` | `h10_core/lib/repetition/repetition_detector.dart` | Dual-threshold Schmitt trigger hysteresis state machine | **PASS** |
| `ExerciseSignal` | `h10_core/lib/signals/exercise_signal.dart` | Extracts principal driving signal per exercise | **PASS** |
| `SmoothnessCalculator` | `h10_core/lib/metrics/smoothness.dart` | Dimensionless jerk computation | **PASS** |
| `ConsistencyCalculator` | `h10_core/lib/metrics/consistency.dart` | Combines ROM ratio, timing CV, and smoothness | **PASS** |
| `FatigueCalculator` | `h10_core/lib/metrics/fatigue.dart` | Compares last 3 vs first 3 rep peak amplitudes | **PASS** |
| `PatientBaseline` | `h10_core/lib/recovery/baseline.dart` | Computes initial 3-session baseline | **PASS** |
| `TrendClassifier` | `h10_core/lib/recovery/trend_classifier.dart` | Linear regression slope classification | **PASS** |
| `FlagGenerator` | `h10_core/lib/recovery/flag_generator.dart` | Clinical flag evaluator (`rom_below_plan`, etc.) | **PASS** |
| `SessionQualityGate` | `h10_core/lib/quality/quality_gate.dart` | Connection, calibration age, and flatline checks | **PASS** |

---

### 1.4 Custom Widgets
| Widget | File Location | Description |
|---|---|---|
| `VectorIcon` | `mobile/lib/widgets/vector_icons.dart` | Custom canvas-painted icons (`taskProof`, `judge`, `routines`, `preflight`, `scanner`, `qrCode`, `pinch`). Guaranteed 100% visible on Web and Mobile; immune to font tree shaking |
| `HolographicHandScan` | `mobile/lib/widgets/holographic_hand_scan.dart` | 3D kinematics hand scanner with Okabe-Ito color palette. In 3-channel mode, Ring and Pinky are explicitly labeled `ESTIMATED` |
| `HandVisualization` | `mobile/lib/widgets/hand_visualization.dart` | 2D kinematic joint curl canvas with estimated ring/pinky labeling |
| `FingerBarsWidget` | `mobile/lib/widgets/finger_bars.dart` | Okabe-Ito 5-channel bars with `Estimated` label under Ring & Pinky |
| `CameraZoneTracker` | `mobile/lib/widgets/camera_zone_tracker.dart` | ArUco marker box overlay with Source / Transit / Target zones |
| `RepetitionRing` | `mobile/lib/widgets/repetition_ring.dart` | Circular progress ring with rep target count |
| `QualityStrip` | `mobile/lib/widgets/quality_strip.dart` | Stream health & packet quality indicator |
| `PreflightDialog` | `mobile/lib/widgets/preflight_dialog.dart` | Pre-session diagnostic verification modal |

---

## 2. Verification & Automated Test Results

### 2.1 Static Analysis (`flutter analyze`)
- Command: `cd mobile && flutter analyze`
- **Result:** `No issues found! (ran in 6.8s)`
- **Issues resolved:** 16 issues -> **0 issues**.

### 2.2 Test Suite Execution (`flutter test`)
- `mobile/test`: **7 / 7 tests passed** (including VectorIcon rendering & dual-schema packet decoder)
- `packages/h10_core/test`: **33 / 33 tests passed**
- **Total:** **40 / 40 tests passed** (100% pass rate).

---

## 3. Dummy & Placeholder Remediation

### 3.1 Gated Development Mock Data
Created `mobile/lib/dev/mock_data.dart` behind the compile-time flag:
```dart
const bool kUseMockData = bool.fromEnvironment('MOCK', defaultValue: false);
```
In release and normal builds, `kUseMockData` defaults strictly to `false`.

### 3.2 Fixes by File
| File | Remediation Performed |
|---|---|
| `mobile/lib/dev/mock_data.dart` | New file created for development and mock fixtures behind `kUseMockData` |
| `mobile/lib/screens/s1_today_screen.dart` | Wired Recent Activity to real `storageService.sessions`. Added explicit empty state ("No exercise sessions recorded yet"). Replaced hardcoded care team list with dynamic prescriber (`plan.setBy`) |
| `mobile/lib/screens/s3_calibration_screen.dart` | Removed fallback fake flex values `[1200..]` and `[2800..]`. Added disconnected guard: if hardware/simulator is not streaming, calibration aborts and prompts user to connect |
| `mobile/lib/screens/s5_live_session_screen.dart` | Gated synthetic sine wave generation behind `kUseMockData`. In hardware mode, uses actual device values or zero without fabricating fake data |
| `mobile/lib/screens/s7_progress_screen.dart` | Removed hardcoded `+24%`, `Goal: 8/10 Reps`, `94% Completed`, static stacked bar heights, and static spider chart values. All now calculate dynamically from `filteredSessions` with empty state handling |
| `mobile/lib/screens/minigame_screen.dart` | Replaced hardcoded `75.0` mean ROM with calculated mean and max ROM from `_gameReps` |
| `mobile/lib/main.dart` | Replaced hardcoded patient initials `'KS'` with dynamic pseudonym from `storageService.patientId` (`P14`). Removed unused imports |
| `mobile/lib/widgets/vector_icons.dart` | Made `VectorIconType` public enum. Converted all factories to `const` constructors for performance |
| `mobile/lib/widgets/holographic_hand_scan.dart` | Labeled unmeasured channels (Ring and Pinky) as `ESTIMATED` per requirement |
| `mobile/lib/widgets/finger_bars.dart` | Added explicit `Estimated` label beneath Ring and Pinky finger bars |
| `mobile/packages/h10_core/lib/models/sensor_packet.dart` | Dual-schema parser: accepts both 5-flex/6-IMU protocol and 3-flex/quaternion (`qw, qx, qy, qz`), `grip`, and `button` |
| `mobile/lib/screens/s9_settings_screen.dart` | Resolved `BuildContext` async gap warning with `context.mounted` |

### 3.3 Dummy Pattern Verification (Before vs After)
**Search Command:**
```powershell
python -c "
import os, re
patterns = ['TODO', 'John Doe', 'example.com', 'lorem', 'dummy', 'fake']
matched = []
for root, dirs, files in os.walk('mobile/lib'):
    if 'dev' in root: continue
    for f in files:
        if f.endswith('.dart'):
            with open(os.path.join(root, f), 'r', encoding='utf-8') as fp:
                for idx, line in enumerate(fp, 1):
                    for p in patterns:
                        if re.search(r'\b' + re.escape(p) + r'\b', line, re.I):
                            matched.append(f'{f}:{idx}: {line.strip()}')
print(f'Total matches found outside lib/dev: {len(matched)}')
"
```
- **Before Remediation:** 13 placeholder occurrences identified.
- **After Remediation:** `Total matches found outside lib/dev: 0`.

---

## 4. Sensor & Backend Wiring Verification
1. **JSON Schema Flexibility:** Tested and confirmed that `SensorPacket.fromJson` and `PacketDecoder.decodeJson` successfully parse:
   - Standard 5-flex + 6-axis IMU packet (`flex`, `imu`, `fsr`, `flags`, `battery`).
   - 3-flex + quaternion packet (`flex`: [thumb, index, middle], `imu`: [qw, qx, qy, qz], `grip`, `button`).
2. **Per-Finger Min/Max Calibration:** Stored in `CalibrationRecord` with `openMedians`, `closedMedians`, span, and polarity, and used by `Normalizer.normalizeAll()`.
3. **Ring & Pinky Channels:** Explicitly labeled as `ESTIMATED` across both 2D `FingerBarsWidget` and 3D `HolographicHandScanWidget`.
4. **Disconnect / Reconnect Handling:** `DeviceService` handles socket close/error events cleanly without crashing, marks state as `disconnected` or `degraded`, and prevents stale data from being represented as live.

---

## 5. Feature Checklist & Final PASS/FAIL Table

| Feature | Audit Status | Verification Summary |
|---|---|---|
| **Session & Plan Handling** | **PASS** | Offline-first plan parameters (v1, target reps, ROM bands) loaded and verified |
| **Patient Profile & Pseudonym** | **PASS** | Uses research pseudonym `P-014` (`P14`), no hardcoded developer names |
| **Live Hand Display & Calibration** | **PASS** | 3D holographic hand scan renders Okabe-Ito channels with real live flex or clear idle state |
| **Live Curl & Grip Readings** | **PASS** | 3-CH active flex stream + FSR palmar contact parsed at 50 Hz |
| **Repetition Counting & Hysteresis** | **PASS** | Schmitt trigger hysteresis state machine passes all 8 edge cases |
| **Range of Motion & Fatigue** | **PASS** | Dynamic calculation from rep peaks; fatigue detected after 6 reps if drop > 20% |
| **Alerts & Thresholds** | **PASS** | Real clinical flags evaluated on-device via `FlagGenerator` |
| **Session History & Export** | **PASS** | Reads real stored sessions, exports CSV/JSON, explicit empty state when 0 sessions |
| **Settings & Diagnostics** | **PASS** | Telemetry diagnostics, copy diagnostics bundle, clear storage, 0 async context gaps |
| **Visual Design & Dark/Light Themes** | **PASS** | Full dual-theme toggle (Obsidian Dark & Neo-Rehab Light), custom vector icons with no missing glyphs, bottom navigation dock with scanner icon |
| **Non-Medical Disclaimer** | **PASS** | Mandatory non-medical disclaimer banner preserved in tree and demo labels intact |

---

## 6. How to Run the App

### 6.1 Hardware Mode (Production / Competition Mode)
Connect to ESP32-S3 glove or backend simulator with real telemetry:
```bash
# In mobile directory:
flutter run -d chrome
# Or run on Android device:
flutter run -d <device-id>
```

### 6.2 Mock Mode (Development & Preview Mode)
Run with simulated preview fixtures and development care team:
```bash
# In mobile directory:
flutter run --dart-define=MOCK=true -d chrome
# Or build Android APK with mock data:
flutter build apk --release --dart-define=MOCK=true
```

---

## 7. Build Artifacts
- **Standalone Android APK v2:** Located at `ASHTAVAKRA_v2.apk` in project root (Application ID: `com.asthavakra.v2`, Name: `ASHTAVAKRA v2`).
- **Standalone Android APK v3:** Located at `ASHTAVAKRA_v3.apk` in project root (Application ID: `com.asthavakra.v3`, Name: `ASHTAVAKRA v3`).
- **Web App:** Built and live at `http://127.0.0.1:5050`.

---

## 8. Version 3 Rebuild: Realistic 3D Human Hand & Telemetry Fixes
- **Rebuilt 3D Hand View:** Replaced stick skeleton entirely with a realistic rigged human hand model (`mobile/assets/hand/hand.glb`, MIT licensed, WebXR generic hand profile).
- **Offline Three.js Engine:** Local Three.js r128 (`three.min.js`), `GLTFLoader.js`, and `hand_b64.js` bundled directly in assets for 100% offline operation without CDN dependencies.
- **Three Dynamic Render Modes:**
  - `SKIN`: Warm human skin tone (`#d9a88a`), soft key/fill lighting, and soft warm amber rim light (`#f5a623`).
  - `MESH`: Wireframe overlay (`#e8efef`, 0.55 opacity) that dynamically shifts toward amber as each finger curls.
  - `XRAY`: Translucent skin (0.2 opacity) with an internal amber skeleton (`#ffb347`) and prominent nonclinical notice (`X-RAY STYLE RENDERING, NOT MEDICAL IMAGING.`).
  - Modes switch instantly via top segmented control without page reloads.
- **Anatomical Sensor Mapping & Angles:**
  - Thumb, index, and middle: measured from calibrated curl channels (0.0 to 1.0).
  - Ring and pinky: anatomically estimated from middle channel (`ring = 0.90 * middle`, `pinky = 0.75 * middle`) with clear `EST.` badges (never labeled "RESERVED").
  - Wrist orientation: driven by live IMU quaternion (`qw`, `qx`, `qy`, `qz`).
  - Joint angle constants: MCP = -1.4 rad, PIP = -1.6 rad, DIP = -0.9 rad with 0.25 lerp factor at ~25 Hz throttle.
- **Finger Flexion & FSR Dummy Remediation:**
  - Completely removed hardcoded 38% and 0% default numbers.
  - When disconnected, explicitly displays "NO DATA" or "CONNECT DEVICE" instead of fabricated percentages.
  - "SIMULATED" badge appears only when `kUseMockData` compile-time flag is enabled.
- **Dual-App Phone Installation:**
  - Updated Application ID to `com.asthavakra.v3` and app label to `ASHTAVAKRA v3` so both v2 and v3 can coexist simultaneously on the test phone.
