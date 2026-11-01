# 🌸 START HERE — Welcome Vaishnavi! (Super Simple Guide)

Hey Vaishnavi! 👋 Welcome to the team!

You are the **Lead Product & UI/UX Designer** for **H10 (Asthavakra)**.  
Don't worry if you are new to coding, Flutter, or GitHub — **you don't have to write complex code yourself!** Antigravity (the AI assistant) will write and edit the code for you based on your design instructions.

Here is everything you need to know in simple, plain English.

---

## 🧤 1. What is this project in 30 seconds?

* **The Glove:** An ESP32 smart glove with sensors on each finger and wrist that tracks hand movements.
* **The Patient App (Your Focus!):** A mobile and web app that shows the patient an animated hand, counts their exercise repetitions, and tracks recovery after a stroke or hand injury.
* **The Doctor Dashboard:** A website where physiotherapists check how their patient is doing and adjust their exercise targets.

> ⚠️ **One Simple Medical Rule:** Always keep the amber warning banner at the top of the screens:  
> *"PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE."*

---

## 🚀 2. How to See the App Running in 1 Minute

The app is already built and running! You can preview it right now in your web browser:

1. Open Google Chrome and go to:  
   👉 **[http://localhost:5050](http://localhost:5050)**
2. You will see the app running inside a sleek, centered **phone frame** (440px wide).  
   *Notice:* In Flutter, the **Web version and the Phone version use the EXACT same files**. Any design update you make here instantly updates the phone app too!

---

## 🪄 3. How to Design Using Antigravity (No Coding Needed!)

When you open this project in **Antigravity**, you have an AI coding assistant sitting right next to you. You can talk to it in plain English just like talking to a junior developer!

### Examples of Prompts You Can Give Antigravity:
* 💬 *"Antigravity, look at `s1_today_screen.dart`. Make the 'Today's Plan' card look more modern with a soft subtle shadow, 16px rounded corners, and a cleaner font hierarchy."*
* 💬 *"Antigravity, change the button style across all screens so they have a 12px border radius and generous 16px vertical padding for easy tapping."*
* 💬 *"Antigravity, improve the color contrast on `s7_progress_screen.dart` so elderly patients can read the numbers clearly."*
* 💬 *"Antigravity, make the repetition counter circle on `s5_live_session_screen.dart` have a smooth pulsing glow when the rep is completed."*

Antigravity will make the exact edits in the file, and when you refresh your browser, you'll see your design live!

---

## 🎨 4. Design Guidelines to Keep in Mind

1. **Finger Colors (Okabe-Ito Palette):**  
   We use special colors that are 100% visible to color-blind patients:
   * 👍 **Thumb:** Warm Orange (`#E69F00`)
   * ☝️ **Index:** Sky Blue (`#56B4E9`)
   * 🖕 **Middle:** Bluish Green (`#009E73`)
   * 💍 **Ring:** Soft Yellow (`#F0E442`)
   * 🤙 **Pinky:** Deep Blue (`#0072B2`)

2. **Big Tap Targets for Injured Hands:**  
   Patients using this app have stiff or trembling fingers. Make sure buttons, chips, and sliders are **large and easy to press** (at least 48x48 pixels).

3. **Calm, High-Contrast Colors:**  
   Our main brand color is **Deep Clinical Teal** (`#006A60`) on clean off-white backgrounds (`#F8FAF9`). Avoid harsh neon colors.

---

## 📂 5. Where the Screens Live

All the screens you will be designing are in:  
📁 **`mobile/lib/screens/`**

| File Name | What Screen It Is |
|---|---|
| `s1_today_screen.dart` | Today's Plan, streak/adherence, connection badge |
| `s2_device_screen.dart` | Device connection status & live signal diagnostics |
| `s3_calibration_screen.dart` | Step 1 (Open Hand) & Step 2 (Fist) calibration wizard |
| `s4_exercises_screen.dart` | The 5 exercise cards with instructions |
| `s5_live_session_screen.dart` | The live animated hand & repetition ring during exercise |
| `s6_summary_screen.dart` | Post-exercise summary with Pain & Fatigue sliders |
| `s7_progress_screen.dart` | Recovery charts (ROM over time, consistency) |
| `s8_history_screen.dart` | Past sessions history list |
| `minigame_screen.dart` | The falling target catching game |

---

## 🏆 6. Presentation & Judge Survival Guides

We have already prepared complete presentation scripts and cheat sheets for you in this folder:

* 📄 **[`PRESENTATION_GUIDE.md`](./PRESENTATION_GUIDE.md):** Exactly what to say during presentations (30-second pitch, 2-minute pitch, slide-by-slide script, and 60-second live demo steps).
* 📄 **[`QNA_GUIDE.md`](./QNA_GUIDE.md):** Serious, scientific answers for doctors, physiotherapists, and judges who ask deep medical/tech questions.
* 📄 **[`LARP.md`](./LARP.md):** **The Hackathon Survival Cheat Sheet!** A fun, bulletproof guide with witty mic-drop answers for when judges ask silly buzzword questions (like *"Why not Apple Watch?"*, *"Where is the Blockchain?"*, or *"Can this cure Parkinson's?"*).

---

### You got this! 🚀
If you ever feel stuck, just ask Antigravity or ping Krushna!

