# Project Explanation for Gautam — Glove Mechanics & Physical Validation

**Role:** Glove Mechanics & Trial Validation Lead  
**Direct System Ownership:** Sensor glove mechanical mounting, floating guide channels, palmar FSR EVA backing, physical ArUco transfer cube fabrication, volunteer physical protocol, bench trials (`docs/VALIDATION_SHEET.csv`).

---

## 1. What the Project Is & What Mechanics You Built

RehabBridge NEXUS requires a wearable glove that can endure repeated hand grasping motions without physical damage, while enabling an overhead camera to track a standardized physical object.

You designed and fabricated:
- **Floating Sensor Guide Sleeves:** Textile channels along the dorsal fingers allowing bend sensors to slide freely during flexion, preventing sensor buckling and solder crimping.
- **Palmar FSR Mount with EVA Foam Buffer:** A rigid foam buffer beneath the Interlink FSR 402 sensor that provides a firm reaction surface, allowing light therapeutic touches ($0.5\text{ N}$) to trigger contact against soft human skin.
- **Wrist Strain Relief Terminal Block:** An FR4/3D-printed anchor on the wrist strap that clamps incoming ribbon cabling, withstanding $25\text{ N}$ pull forces without stressing soldered pins.
- **Standardized Transfer Object:** A $60\text{ mm} \times 60\text{ mm} \times 60\text{ mm}$ lightweight ($28\text{ g}$) EVA foam cube equipped with a matte-laminated OpenCV ArUco marker ID#0 on top to eliminate lighting glare.

---

## 2. Why the Glove Was Mechanically Built This Way

### 2.1 The Problem with Glued Flex Sensors
When a human finger flexes, dorsal skin stretches by up to 25%. If flex sensors are glued firmly along the entire finger, the sensor is forced into compression, causing severe buckling, puckering, and eventual solder fatigue cracking.
- **Our Solution:** Floating distal tips. The base of each sensor is anchored at the metacarpal joint, but the distal tip slides freely inside low-friction guide channels as the finger flexes.

### 2.2 Why Palmar EVA Foam Backing is Essential
Human palm tissue is soft and compliant. Without a rigid backing, pressing against an object merely depresses skin tissue without generating sufficient localized pressure across the FSR sensing disc.
- **Our Solution:** We inserted a high-density 3mm EVA foam disc beneath the FSR. This ensures that even a weak therapeutic grasp ($\approx 0.5\text{ N}$) reliably registers contact closure.

### 2.3 Physical Trial Validation (10/10 Consecutive Bench Attempts)
You conducted 10 consecutive bench transfer attempts documented in `docs/VALIDATION_SHEET.csv`. Every trial was tracked by the TaskProof state machine and verified against operator keypress ground truth with zero sensor dislocations or wire pull-outs (`tests/test_e2e.py::test_e2e_10`).

---

## 3. Your 90-Second Demo & Presentation Script

> "I am Gautam, responsible for glove mechanics, physical fabrication, and trial validation for RehabBridge NEXUS. Sensor gloves frequently fail on the bench because repetitive bending shears delicate sensor joints.
> 
> When fingers curl, the skin stretches by up to twenty-five percent. If you glue a bend sensor down, it buckles and breaks. To eliminate this, I constructed floating textile guide channels. The sensor tips slide freely inside these channels as the finger flexes, completely preventing mechanical crimping and extending sensor life.
> 
> Under the palm, I backed our contact force sensor with dense EVA foam. Without that buffer, the sensor would sink into soft skin and miss light grasps. With our foam buffer, even a delicate 0.5-newton therapeutic touch registers reliably.
> 
> For our transfer task, I built a lightweight 28-gram foam block fitted with an anti-glare ArUco marker. I have verified ten consecutive labelled trials through the complete system without a single mechanical jam. During our live demo, you will see me don the glove and physically transfer the cube across our active zones."

---

## 4. Key Judge Questions You Own

1. **How do you prevent flex sensors from breaking at the solder joints during repetitive finger bending?**  
   *Answer:* The sensor tips slide within floating textile guide sleeves while the base is anchored to a rigid wrist strain-relief block, preventing bending fatigue as documented in `docs/gautam/PROJECT_EXPLANATION_GAUTAM.md`.
2. **Have you completed human fit testing across a diverse cohort of patient hands?**  
   *Answer:* No, our current prototype is built on a Medium-Large cotton glove tested on healthy volunteers; clinical fit testing across diverse hand sizes is our next step, outlined in `docs/gautam/DATA_COLLECTION_PROTOCOL.md`.
3. **How many physical transfer attempts have been verified with this hardware setup?**  
   *Answer:* We have recorded ten consecutive successful physical trials in our database with zero mechanical failures, documented in `docs/VALIDATION_SHEET.csv` and confirmed by test `tests/test_e2e.py::test_e2e_10`.
