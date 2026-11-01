# 🎤 H10 / Asthavakra — Project Presentation Guide
**Speaker Blueprint & Stage Guide for Vaishnavi Jare**

This guide provides everything you need to deliver an engaging, professional, and memorable presentation of the H10 rehabilitation platform to judges, clinicians, and tech evaluators.

---

## ⏱️ 1. The Pitches

### A. The 30-Second Elevator Pitch
> *"Over 100 million people worldwide suffer from hand motor impairment after strokes or trauma. Rehabilitation requires thousands of repetitive finger movements at home, but without real-time feedback, over 70% of patients give up due to frustration, fatigue, or uncertainty.  
> **H10 (Asthavakra)** is an AI-assisted sensor glove and clinical monitoring platform. It uses 5-channel flex sensing and an IMU to decode individual finger movements at 50 Hz, gives patients live, accessible biofeedback with an articulated 2D hand and smart repetition counting, and sends longitudinal recovery trends to their physiotherapist. We bridge the gap between hospital therapy and home recovery."*

---

### B. The 2-Minute Competition Pitch
> *"Imagine losing the ability to grip a cup of water, button your shirt, or hold the hand of someone you love. This is the daily reality for millions recovering from strokes, arthritis, and orthopedic trauma.
>
> Physiotherapists prescribe rigorous home exercise regimens, but at home, patients are left in the dark. Did I bend my index finger enough? Am I straining? Did I do 10 reps or 5? Doctors only see them once a month, relying on fuzzy memory.
>
> That is why we built **H10 (Asthavakra)**.
>
> H10 combines a lightweight 5-finger flex and IMU glove with an accessible, human-centered rehabilitation app:
>
> 1. **Zero Guesswork Biofeedback:** The moment the patient slips on the glove, our Flutter app renders a live 2D articulated hand mirroring their exact fingers, color-coded with an Okabe-Ito color-blind safe palette.
> 2. **Hysteresis Repetition Counting:** Instead of noisy step-counters, we built a dual-threshold hysteresis state machine that counts complete reps, enforces hold times, and filters out tremors so patients never get cheated or frustrated.
> 3. **Patient-First Experience:** We gamified rehabilitation with target-matching challenges and collect post-exercise Borg CR-10 pain and fatigue ratings.
> 4. **Clinician Telemetry:** Every session syncs to a web dashboard where doctors see objective Range of Motion trends, consistency scores, and automated flags for abnormal fatigue or pain spikes.
>
> As a designer, every pixel was crafted for patients with limited dexterity—from 48px touch targets to high-contrast typography and calm clinical colors. H10 doesn't just count reps; it restores autonomy."*

---

## 📊 2. The 5-Minute Slide-by-Slide Structure

| Slide | Title | Visuals on Screen | What Vaishnavi Says (Key Points) |
|:---:|---|---|---|
| **1** | **Hook & Problem** | Photo of patient struggling with traditional therapy; "70% non-adherence" | Start with the emotional reality. Patients feel isolated at home; clinicians have zero objective visibility between monthly visits. |
| **2** | **Introducing H10** | High-res photo/mockup of ESP32 glove and phone app | Introduce H10 (Asthavakra). Explain the hardware (5 flex + IMU) and the patient-first mobile experience. State clearly: *"Research prototype, not a medical device."* |
| **3** | **Live Biofeedback & Articulation** | Screen recording or live phone preview of 2D articulated hand & finger bars | **Designer Spotlight:** Explain how real-time visual mirroring stimulates neuroplasticity. Highlight the **Okabe-Ito color-blind safe palette** so all channels are distinct. |
| **4** | **Smart Repetition & Fatigue Engine** | Repetition ring with hold timer; Borg CR-10 slider | Explain our dual-threshold hysteresis algorithm. It doesn't trigger on jitter or tremor; it rewards true Range of Motion. Highlight the fatigue detection index. |
| **5** | **Gamification & Adherence** | Hand-Control Challenge mini-game catching falling targets | Show how therapy transforms into play. Patients flex specific target fingers to catch objects, building fine-motor isolation. |
| **6** | **The Clinician Portal** | Screenshot of Flutter Web dashboard with 1-page PDF summary export | Show the other side: physiotherapists get longitudinal ROM recovery curves, consistency metrics, and 1-click clinical flags. |
| **7** | **Architecture & Privacy** | Simple architecture diagram (ESP32 $\rightarrow$ Flutter $\rightarrow$ FastAPI $\rightarrow$ SQLite) | Emphasize offline-first architecture. It works completely without internet; no patient PII is stored; pseudonyms only. |
| **8** | **Conclusion & Vision** | Photo of confident patient; summary tagline | *"Restoring hand mobility, one repetition at a time."* Thank the judges and invite them to try the live demo! |

---

## 🎯 3. Designer Highlights (What Makes Your Perspective Stand Out)

When speaking as the **Lead Designer**, emphasize these 5 UX innovations that engineers often overlook:

1. **Cognitive Load Reduction for Elderly & Stroke Patients:**
   - Traditional medical software is cluttered with complex graphs and scary numbers.
   - H10 uses **glanceable, clear visual metaphors**: a circular repetition progress ring, an articulated hand, and simple status chips.
2. **Accessible Interaction Design (WCAG AAA):**
   - Patients recovering from motor trauma experience tremors and low dexterity.
   - We enforced **48 × 48 px minimum touch targets**, generous tap padding, and high-contrast text (`#006A60` on `#F8FAF9`) that meets WCAG AAA standards.
3. **Okabe-Ito Color-Blind Safe Architecture:**
   - Over 8% of men have color vision deficiencies. Red/green bars are dangerous in healthcare.
   - Every single finger channel uses an **empirically validated color-blind safe palette** (Orange, Sky Blue, Bluish Green, Yellow, Deep Blue).
4. **Emotional Safety & Non-Medical Clarity:**
   - Patients are easily discouraged if an app says *"You performed poorly"*.
   - We measure progress strictly against the patient's **own historical baseline**, celebrating consistency rather than comparing them to an arbitrary "normal" person.
5. **Dual Web & Mobile Fluidity:**
   - Designed responsive containers that preserve a crisp, realistic 440px phone canvas on desktop browsers while filling native smartphone displays seamlessly.

---

## 📱 4. Live Demo Walkthrough Script (Click-by-Click)

Have the web app open at `http://localhost:5050` or running live in Chrome. Follow this exact 60-second walkthrough:

1. **Step 1: The Today Screen (`s1_today_screen.dart`)**
   - *Action:* Point to the top banner and the Today's Plan card.
   - *Say:* *"Here is the patient's daily dashboard. They immediately see their prescribed exercise ('Fist Clench & Release'), target of 10 reps, weekly adherence bar, and device status."*
2. **Step 2: Start Prescribed Exercise (`s5_live_session_screen.dart`)**
   - *Action:* Tap the big green button: **Start Prescribed Exercise**.
   - *Say:* *"Notice the live 2D articulated hand and Okabe-Ito finger bars. As the patient bends their fingers, the hand animates in real time. Watch the central repetition ring: as flexion crosses 70%, the ring fills up, holds for 0.5 seconds, and awards rep 1 with haptic feedback!"*
3. **Step 3: Post-Session Summary (`s6_summary_screen.dart`)**
   - *Action:* Tap **Finish Session** $\rightarrow$ Confirm.
   - *Say:* *"After exercising, we capture validated Borg CR-10 ratings for both Pain and Fatigue using smooth sliders. This gives therapists critical context on tolerance."*
4. **Step 4: Gamified Challenge (`minigame_screen.dart`)**
   - *Action:* Navigate to Exercises tab $\rightarrow$ tap Start on **Hand Control Challenge**.
   - *Say:* *"For variety and neuro-rehabilitation, we gamified finger control. The patient flexes their fingers to catch falling targets, turning tedious therapy into an engaging challenge!"*
5. **Step 5: Progress & Recovery (`s7_progress_screen.dart`)**
   - *Action:* Tap the **Progress** tab on the bottom bar.
   - *Say:* *"Finally, patients review their recovery over the last 2 weeks or 6 weeks. They see their Range of Motion improvements and consistency score without complex medical jargon."*

