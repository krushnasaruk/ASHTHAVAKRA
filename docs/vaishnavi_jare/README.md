# 🎨 H10 / Asthavakra — Designer Onboarding Guide
**Dedicated Workspace & Guidelines for Vaishnavi Jare (Lead Product & UI/UX Designer)**

Welcome to the **H10 / Asthavakra** project! This guide explains the entire project, our design philosophy, and step-by-step instructions on how you can run, design, and edit the application live in your web browser with instantaneous hot-reload.

> 🌟 **New to the project? Start here!** 👉 **[`START_HERE.md`](./START_HERE.md)** for a super simple, step-by-step guide with zero jargon.

---

## 🌟 1. Project Overview: What is H10 / Asthavakra?

**H10 (Asthavakra)** is an AI-assisted sensor glove and monitoring platform designed for patients recovering from stroke, hand injuries, neurological conditions, and orthopaedic surgery.

### 🧤 The Core Problem We Solve
Patients undergoing hand physical therapy typically perform repetitive home exercises without supervision. They forget the correct form, lack real-time feedback, and doctors have no objective data on whether the patient is actually improving or struggling with fatigue.

### 💡 The H10 Solution
1. **Sensory Glove:** An ESP32 DevKit glove equipped with 5 flex sensors (measuring thumb, index, middle, ring, pinky bending) and an MPU6050 6-axis IMU (measuring hand rotation & tilt).
2. **Patient Mobile/Web App:** Built with **Flutter**, providing real-time visual biofeedback:
   - A live 2D articulated hand that mirrors the patient's fingers in real time.
   - Color-blind safe (Okabe-Ito) finger flexion bars.
   - An intelligent repetition ring detector that counts smooth repetitions and checks target hold times.
   - Gamified mini-games to make rehabilitation engaging.
   - Pain & Fatigue Borg CR-10 post-session sliders.
   - Longitudinal Range of Motion (ROM) and consistency recovery trends.
3. **Clinician Web Dashboard:** A desktop portal for physiotherapists to monitor adherence, tune exercise difficulty, review clinical flags (e.g. fatigue drop, abnormal jerking, pain spikes), and export official 1-page PDF appointment reports.
4. **FastAPI Backend:** Secure, offline-first sync server storing sessions and kinematic telemetry with strict PII (personally identifiable information) refusal.

> [!IMPORTANT]
> **Regulatory Boundary:** H10 is a **research and demonstration monitoring prototype, NOT a medical device**. It never diagnoses disease, prescribes therapy, or predicts clinical recovery dates. It measures physical movement against the patient's **own baseline**.

---

## ⚡ 2. The Flutter Single-Source Superpower (Web = Mobile)

You might be wondering: *"How do I design for the web and then convert it to the mobile app?"*

Here is the best part: **You do not need to convert anything!**
Flutter compiles the **exact same code** to Android, iOS, and Web. 

```
                          ┌───────────────────────┐
                          │   mobile/lib/screens  │
                          │   (Your UI Code)      │
                          └──────────┬────────────┘
                                     │
                 ┌───────────────────┴───────────────────┐
                 ▼                                       ▼
    🌐 Flutter Web Preview                  📱 Android Mobile APK
    (Desktop Chrome Browser)                (Physical Smartphone)
   - Centered 440px phone canvas           - Full-width native screen
   - Instant Hot-Reload (press 'r')        - Touch gestures & sensors
   - Chrome DevTools inspection            - Identical widgets & layout
```

When you edit any screen in `mobile/lib/screens/`, it **instantly updates both the Web preview and the phone application**!

---

## 🛠️ 3. Quick Start: How to Run the App on Your Computer

### Prerequisites
1. **Flutter SDK** installed (version 3.24+).
2. Google Chrome browser.
3. VS Code or Android Studio with Flutter extensions.

### Step 1: Clone the Repository
```bash
git clone https://github.com/krushnasaruk/ASHTHAVAKRA.git
cd ASHTHAVAKRA
```

### Step 2: Run with Instant Hot Reload in Chrome
```bash
cd mobile
flutter run -d chrome
```
* Chrome will launch displaying the app inside our **centered 440px phone frame**.
* Keep the terminal running. Whenever you edit a Dart file in `mobile/lib/screens/` and press `r` in the terminal (or save in VS Code), Chrome will update in less than a second!

### Step 3: Or View the Pre-Built Production Web Server
If you just want to preview without running Flutter build tools:
```powershell
python -m http.server 5050 --directory mobile/build/web
```
Open **[http://localhost:5050](http://localhost:5050)** in your browser.

---

## 📂 4. Where You Can Safely Edit (File Map)

As the Lead UI Designer, your primary workspace is inside the **`mobile/`** directory.

```text
mobile/
├── lib/
│   ├── main.dart                       ← App shell, AppBar (v1 badge), bottom navigation bar
│   ├── screens/
│   │   ├── s1_today_screen.dart        ← Today's plan, adherence bar, device connection status
│   │   ├── s2_device_screen.dart       ← ESP32 Wi-Fi & Simulator connection, live diagnostics
│   │   ├── s3_calibration_screen.dart  ← 2-stage calibration wizard (open hand & fist)
│   │   ├── s4_exercises_screen.dart    ← Exercise library cards (5 clinical exercises)
│   │   ├── s5_live_session_screen.dart ← LIVE session: 2D hand Canvas, rep counter ring
│   │   ├── s6_summary_screen.dart      ← Post-session summary, Borg pain/fatigue sliders
│   │   ├── s7_progress_screen.dart     ← Longitudinal recovery charts & adherence metrics
│   │   ├── s8_history_screen.dart      ← Past session history list & session inspect modal
│   │   ├── s9_settings_screen.dart     ← Patient pseudonym, telemetry CSV export
│   │   └── minigame_screen.dart        ← Gamified falling target catching mini-game
│   └── services/                       ← Data services (DeviceService & StorageService)
└── packages/
    └── h10_core/                       ← Design tokens, theme colors, signal math
        └── lib/theme/tokens.dart       ← Official design tokens (colors, radii, spacing)
```

> [!TIP]
> **Safe Zone:** Feel free to edit anything inside `mobile/lib/screens/` and `mobile/packages/h10_core/lib/theme/tokens.dart`.
> Avoid modifying signal algorithms in `h10_core/lib/` or backend schemas without coordination.

---

## 🎨 5. Design System & Mandatory Rules

### A. The Non-Medical Disclaimer Rule (Mandatory)
Every screen must preserve the persistent amber disclaimer banner at the top:
```text
PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE. For research & demonstration only.
```
* **Background:** `#FEF3C7` (Amber 100)
* **Text Color:** `#92400E` (Amber 900)
* **Icon:** Info outline icon in `#B45309`

### B. Okabe-Ito Color-Blind Safe Palette
We use the internationally recognized **Okabe-Ito color-blind safe palette** so patients with deuteranopia, protanopia, or tritanopia can clearly distinguish all 5 finger channels:

| Finger | Channel Name | Color Code | Color Name |
|---|---|---|---|
| **Thumb** | Flex 0 | `#E69F00` | Warm Orange |
| **Index** | Flex 1 | `#56B4E9` | Sky Blue |
| **Middle** | Flex 2 | `#009E73` | Bluish Green |
| **Ring** | Flex 3 | `#F0E442` | Soft Yellow |
| **Pinky** | Flex 4 | `#0072B2` | Deep Blue |

### C. Design Tokens
All core spacing, typography, and card radii are defined in `tokens.dart`:
* **Primary Brand Color:** `#006A60` (Teal 700 / Deep Clinical Teal)
* **Surface Background:** `#F8FAF9` (Off-White Calm)
* **Card Surface:** `#FFFFFF` (Pure White with `#E2E8F0` border)
* **Corner Radius:** `12.0` px on Cards, `8.0` px on Buttons
* **Minimum Touch Target:** All interactive buttons and sliders must be at least `48 × 48 px` to accommodate patients with limited finger dexterity.

---

## 🤝 6. Team Collaboration with `ONEFORALL` (`ofa`)

We use **ONEFORALL (`ofa`)** to coordinate between contributors and AI agents so nobody steps on your work.

### Your Ownership Zone: `frontend`
Your designated ownership zone covers:
* `mobile/lib/screens/`
* `mobile/lib/widgets/`
* `mobile/packages/h10_core/lib/theme/`

### How to Claim Your Zone Before Working:
```bash
# Claim your zone for 48 hours so other agents don't touch your UI files
ofa claim frontend --user vaishnavijare60-hash --ttl 48
```
When you claim this zone, all AI agents used by other team members (Cursor, Copilot, Claude, Gemini) will automatically receive instructions **never to overwrite your UI files**.

### How to Release When Done:
```bash
ofa release frontend --user vaishnavijare60-hash
```

---

## 📚 7. Companion Documentation in Your Folder

* **[`PRESENTATION_GUIDE.md`](./PRESENTATION_GUIDE.md):** Complete script, slide structure, and elevator pitch for presenting H10 to judges and investors.
* **[`QNA_GUIDE.md`](./QNA_GUIDE.md):** Clinical and technical answers to tough, legitimate questions from judges and physiotherapists.
* **[`LARP.md`](./LARP.md):** The ultimate survival cheat sheet to confidently handle confused, buzzword-heavy, or misinformed judge questions!

