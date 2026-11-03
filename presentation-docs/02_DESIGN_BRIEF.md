<!-- Generated from commit cabf24c on 2026-11-03. Re-generate after any code change. -->

# Briefing Pack: Vaishnavi Jare (Product Design & Volunteer UX)

**Role:** Product Design, Screen Flows, Visual Hierarchy, Accessibility, Volunteer Journey  
**Direct Ownership:** `mobile/lib/screens/`, `mobile/lib/widgets/`, `mobile/packages/h10_core/lib/theme/`, `docs/vaishnavi_jare/`  
**Commits Owned:** `ead312a`, `cabf24c`

---

## 1. What I Built & Own
- **Mobile Patient Application UI** ([`mobile/lib/screens/`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/mobile/lib/screens/)):
  - S1 Today Screen: Prescription, adherence progress bar, and NEXUS event task card.
  - S4 Exercise Library: Fist Clench, Finger Tap, Pinch, Wrist Rotation, and TaskProof Object Transfer.
  - S5 Live Biofeedback Session: Real-time repetition ring, target flexion arcs, and dimensionless jerk smoothness indicator.
  - S10 TaskProof Screen: Dual-view interface with live 25 Hz WebSocket telemetry.
- **Design System & Tokens** ([`mobile/packages/h10_core/lib/theme/design_tokens.dart`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/mobile/packages/h10_core/lib/theme/design_tokens.dart)):
  - 4-point spacing grid (`space4` to `space32`).
  - Strict minimum touch target constraint: $\ge 48 \times 48\text{ px}$.
  - Responsive 440px canvas container on desktop web viewports.
- **Accessible Color-Blind Palette (Okabe-Ito):**
  - Dedicated palette for 5 finger channels (Thumb: `#E69F00`, Index: `#56B4E9`, Middle: `#009E73`, Ring: `#E4C41B`, Pinky: `#0072B2`).
- **High-Contrast Judge View:**
  - 64px bold verdict typography readable from 3 meters away.
  - Live elapsed stopwatch timer and reason code tags.
- **Mandatory Non-Medical Disclaimer Banner:**
  - High-visibility warning strip preserved across all screens: `"PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE."`

---

## 2. What Is Working & How I Know
- **Mobile Widget & Screen Tests:** Confirmed by `mobile/test/widget_test.dart` and `mobile/test/mobile_integration_test.dart` (**4 / 4 PASSED**).
- **Static Analysis Compliance:** `dart analyze mobile/` passes with **0 errors and 0 warnings** (Exit code 0).
- **Responsive Layout:** LayoutBuilder constraints enforce clean 440px phone container on wide screens without horizontal overflow.
- **Touch Target Integrity:** Every button, tab, chip, and hotkey maintains a minimum $48\times 48\text{ px}$ clickable area for stroke survivors with limited fine motor dexterity.

---

## 3. What Is NOT Working or Not Finished
- **Tablet Landscape Split-Pane:** A dedicated two-column view for widescreen iPad/Android tablets is planned in Tier 3, but currently defaults to centered 440px container mode.
- **Native Haptic Feedback:** Vibrational motor feedback on the smartphone is simulated via UI animations and buzzer tones on the glove, not yet triggered natively in Flutter on iOS/Android.

---

## 4. 90-Second Speaking Script
> "Judges, as the product designer, my mandate was simple: make a complex engineering system usable by two very different humans—a post-stroke patient with motor impairment, and a busy clinical judge at a hackathon.
> 
> For the patient, traditional rehabilitation apps fail because buttons are too small or confusing. Every single interactive target in our app is strictly 48 by 48 pixels or larger. Because hand therapy patients experience tremors and spasticity, accidental taps must be prevented. 
> 
> Furthermore, up to 8% of men have color vision deficiencies. We implemented the barrier-free **Okabe-Ito color-blind safe palette** for our finger channels, ensuring each digit is distinguishable regardless of dichromacy. Across every screen, we maintain a mandatory non-medical disclaimer banner.
> 
> For you, the judges, we designed the **Judge View**. In a noisy, crowded event hall, you shouldn't have to squint at tiny graphs. When Gautam completes the transfer, our screen transitions to a massive, high-contrast 64-pixel verdict banner showing green `VERIFIED` with the exact elapsed time and cryptographic audit proof. 
> 
> Let me show you the live interface."

---

## 5. Live Demo Steps
1. In the web interface ([`http://127.0.0.1:8000`](http://127.0.0.1:8000)), click **"Patient Mobile UI Preview"**.
2. Show the judges the responsive 440px phone container and point out the top amber non-medical disclaimer strip.
3. Tap on the **Exercises** tab: point out the exercise library cards and the featured **Object Transfer Verification** task.
4. Tap on **TaskProof**: show the 7-state horizontal machine stepper.
5. In the top bar, click **"Switch to Judge View"**: highlight the massive high-contrast verdict banner and 5-attempt audit card.
6. *If the screen does not update:* State calmly: "Our local WebSocket link is synchronizing. Let me trigger our preflight diagnostics modal to verify connection." Tap the preflight clipboard icon in the top right.

---

## 6. Numbers I May Quote vs Must NOT Quote

### Allowed Numbers (Sourced):
- **Minimum Touch Target:** $48 \times 48\text{ px}$ (`mobile/packages/h10_core/lib/theme/design_tokens.dart`).
- **Canvas Width:** Max 440px (`mobile/lib/main.dart#L49`).
- **Judge View Typography:** 48–64px bold font (`mobile/lib/screens/s10_taskproof_screen.dart`, `frontend/src/App.tsx`).
- **Okabe-Ito Channels:** 5 color-blind safe channels (`design_tokens.dart#L20`).
- **Pain & Fatigue Scale:** 0–10 numeric discrete integers (`s10_taskproof_screen.dart`).

### Numbers I Must NOT Quote:
- **"100% User Satisfaction":** Prohibited. Formal usability testing has not been run ($n=0$ outside internal team).
- **"Clinical Reduction in Spasticity":** Prohibited. Product does not measure spasticity or make therapeutic claims.

---

## 7. Question Ownership & Handoffs

### Questions I Own:
- `DES-01` (Why does the Judge View look different from the Operator View?)
- `DES-02` (How do you ensure accessibility for stroke patients with poor motor control?)
- `DES-03` (What is the Okabe-Ito palette and why did you choose it?)
- `DES-04` (Why is the non-medical disclaimer banner permanent and unclosable?)
- `DES-05` (How does the UI prevent accidental touches during a tremor?)

### Questions I Hand Off:
- Serial baud rate, packet drop handling, SQLite schema $\rightarrow$ **Hand off to Developer**.
- Circuit pinout, ADC resolution, voltage divider design $\rightarrow$ **Hand off to Rajendra**.
- Glove mechanical durability, sensor mounting $\rightarrow$ **Hand off to Gautam**.

---

## 8. Failure Script
> "Judges, the visual stream is currently awaiting telemetry from the host process. Notice that our UI immediately renders an honest `NO DATA` state and displays the exact reason: 'Glove disconnected'. We intentionally refuse to show placeholder numbers or fake smooth curves. Our preflight diagnostic tool is built directly into the AppBar to isolate whether the fault is in the camera or serial bus."
