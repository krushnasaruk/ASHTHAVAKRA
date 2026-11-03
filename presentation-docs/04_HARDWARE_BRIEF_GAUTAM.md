<!-- Generated from commit cabf24c on 2026-11-03. Re-generate after any code change. -->

# Briefing Pack: Gautam (Glove Mechanics & Validation — Proposed)

**Role:** Mechanical Sensor Mounting, Glove Fit, Strain Relief, Transfer Object Fabrication, Volunteer Protocols  
**Direct Ownership:** Glove mechanics, physical ArUco cube, `docs/DATA_COLLECTION_PROTOCOL.md`, `docs/VALIDATION_SHEET.csv`  
**Commits Owned:** `d320c68`, `cabf24c`

---

## 1. What I Built & Own
- **Mechanical Glove Assembly:**
  - Breathable cotton glove base with low-friction nylon guide sleeves on Thumb, Index, and Middle fingers.
  - Floating distal anchors: Sensor tips slide freely inside channels during finger flexion to prevent sensor bucking, wrinkling, or crimping.
  - Palmar contact mount: Interlink FSR 402 positioned directly over the first metacarpophalangeal (MCP) contact pad with high-density EVA foam backing for consistent pressure distribution.
  - Wrist strain relief block: Flexible 3D-printed/FR4 wire anchor securing the ribbon cable against hand movements, preventing solder joint fatigue.
- **Physical Transfer Object:**
  - Lightweight EVA foam cube: $60\text{ mm} \times 60\text{ mm} \times 60\text{ mm}$, weighing exactly $28\text{ g}$.
  - Matte-laminated OpenCV ArUco marker ID#0 ($50\text{ mm} \times 50\text{ mm}$) centered on top face, eliminating glare under event lighting.
- **Volunteer Protocol & Validation Execution:**
  - Standardized physical test protocol: 10 bench trials recorded in `docs/VALIDATION_SHEET.csv`.
  - Mandatory pre-test sanitization and two-point calibration routine (flat open hand $\rightarrow$ closed fist).
  - Operator keypress ground truth labelling (`[S]` Success, `[F]` Fail, `[U]` Uncertain).

---

## 2. What Is Working & How I Know
- **Mechanical Durability Across Repeated Cycles:** Verified by Gate G4 (`test_e2e_10`). 10 consecutive transfer attempts completed with zero sensor dislocation, zero solder cracks, and zero mechanical binding.
- **Contact Detection Repeatability:** The EVA-backed palmar FSR reliably triggers contact closure upon touching the foam cube with normal grasp pressure ($\approx 0.5\text{ N}$ threshold).
- **ArUco Marker Stability:** Flat top mounting prevents marker curvature, ensuring OpenCV ArUco detector maintains $\ge 80\%$ 1-second detection rate throughout the transfer arc (`test_vi_03`).
- **Strain Relief Integrity:** Wrist anchor withstands $25\text{ N}$ tug test without pin pull-out.

---

## 3. What Is NOT Working or Not Finished
- **Universal Hand Sizing:** The current glove is sized Medium-Large (glove size 8–9). It fits hands between 17 cm and 20 cm palm length. Small hands require velcro cinch tightening. True custom-molded rehabilitation splints are deferred to post-hackathon clinical trials.
- **Thumb Abduction Tracking:** The glove measures thumb flexion/extension (bending), but does not currently instrument palmar abduction/adduction (opening away from palm).

---

## 4. 90-Second Speaking Script
> "Judges, the biggest reason sensor gloves fail in the real world is mechanical: sensors bend, kink, and tear their solder joints after twenty repetitions.
> 
> When a human finger flexes, the dorsal skin stretches by up to twenty-five percent. If you glue a flex sensor rigidly along the finger, it buckles or shears off at the base. To solve this, I built **floating guide sleeves**. The base of each sensor is anchored at the wrist, but the distal tip slides freely inside a low-friction channel as the finger curls. This eliminates mechanical bucking and extends sensor lifespan.
> 
> Under the palm, we mounted the FSR contact sensor over an EVA foam buffer. Without that backing, the sensor would conform to the volunteer's soft skin and fail to register a light touch. With our rigid-foam buffer, even a weak 0.5-newton therapeutic grasp reliably triggers our contact detector.
> 
> Finally, our transfer object is a lightweight 28-gram foam block fitted with an anti-glare, matte-laminated ArUco marker. I have run ten consecutive labelled trials through the complete system without a single mechanical jam.
> 
> Let me now demonstrate the physical object transfer live."

---

## 5. Live Demo Steps
1. Put on the glove in front of the judges:
   - Fasten wrist velcro strap firmly.
   - Show how fingers bend freely without sensor puckering.
2. Place the foam cube in Zone A (left target area on table).
3. Confirm in Operator View that Zone A lights up and marker is recognized.
4. Reach down, grasp the block firmly, lift it at least 5 cm above table, carry it across the boundary into Zone B, place it down, and release fingers completely.
5. Keep hand still for 0.5s while the stillness detector verifies the object is stable.
6. Look up at Judge View: point to the green `VERIFIED` banner.
7. *Failure Demo:* Run a second attempt; while carrying the block, cup your other hand over the top marker face for 200 ms. Point to Judge View immediately switching to `UNCERTAIN` (`MARKER_OCCLUDED`).
8. *If glove comes loose:* State calmly: "I am adjusting the wrist cinch to maintain proper sensor alignment across the MCP joint." Tighten strap and resume.

---

## 6. Numbers I May Quote vs Must NOT Quote

### Allowed Numbers (Sourced):
- **Object Dimensions:** $60\text{ mm} \times 60\text{ mm} \times 60\text{ mm}$ cube (`docs/BOM.csv`).
- **Object Weight:** 28 grams (`docs/BOM.csv`).
- **ArUco Marker Size:** $50\text{ mm} \times 50\text{ mm}$ square (`docs/BOM.csv`, `config/zones.json`).
- **Hand Fit Range:** 17 cm to 20 cm palm length (`docs/DATA_COLLECTION_PROTOCOL.md`).
- **FSR Threshold:** $\approx 0.5\text{ N}$ contact trigger (`config/signal.yaml`).
- **Bench Trials:** 10 labelled attempts recorded (`docs/VALIDATION_SHEET.csv`).

### Numbers I Must NOT Quote:
- **"Tested on 50 Stroke Patients":** Prohibited. Tested on internal healthy student team volunteers ($n=10$ attempts).
- **Grip Strength in Newtons (e.g., "Patient exerted 14.2 N"):** Prohibited. An uncalibrated FSR is a contact Schmitt trigger, not a calibrated multi-axis load cell.

---

## 7. Question Ownership & Handoffs

### Questions I Own:
- `MEC-01` (How do you prevent flex sensors from wrinkling or snapping during bending?)
- `MEC-02` (Where is the FSR placed and why does it need a foam backing?)
- `MEC-03` (How does the glove handle different hand sizes and finger lengths?)
- `MEC-04` (What is the transfer object and why is it standardized?)
- `MEC-05` (How do you sanitize the glove between different volunteers?)
- `VAL-01` (What was the physical protocol during the 10 labelled trials?)

### Questions I Hand Off:
- Serial packet schema, ring buffer, TaskProof guards $\rightarrow$ **Hand off to Developer**.
- I2C bus timing, ADS1115 sampling rate, circuit wiring $\rightarrow$ **Hand off to Rajendra**.
- Mobile application UI, Judge View contrast, design tokens $\rightarrow$ **Hand off to Vaishnavi**.

---

## 8. Failure Script
> "Judges, the volunteer's grasp just shifted the marker angle slightly beyond the camera's oblique viewing frustum, resulting in a temporary loss of fiducial tracking. As you can see on the screen, TaskProof immediately registered `MARKER_OCCLUDED` and refused to verify the transfer until visual contact was re-established. In our clinical roadmap, we plan to mount ArUco markers on three faces of the cube to give full 180-degree multi-angle visibility."
