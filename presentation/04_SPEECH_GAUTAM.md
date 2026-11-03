# Glove Mechanics & Validation Speech — Gautam (Physical Engineering)

**Time Slot:** Minute 3:45 – 5:00 (75 seconds)  
**Demo Step Accompanied:** Glove donning, floating guide sleeves demonstration, and live physical object transfer across zones  
**Source Files Relied On:** `docs/gautam/DATA_COLLECTION_PROTOCOL.md`, `docs/gautam/MECHANICS_BRIEF.md`, `docs/VALIDATION_SHEET.csv`, `docs/BOM.csv`, `tests/test_e2e.py`  

---

## Spoken Speech

I am Gautam, responsible for glove mechanics, physical fabrication, and trial validation for RehabBridge NEXUS. I built our sensor mounting assembly using floating fabric channels along each finger, which lets the flex sensors slide freely without puckering or crimping when the hand closes. Under the palm, I backed our contact force sensor with dense foam to ensure light therapeutic touches register reliably against soft skin. I also anchored the ribbon cabling through a rigid wrist terminal block to protect solder connections from repeated movement fatigue. For trial testing, I fabricated a standardized 28-gram foam cube carrying an anti-glare ArUco fiducial marker on top. You will see me put on the glove, grasp the cube in Zone A, lift and transport it across the boundary, and release it cleanly in Zone B. We have verified ten consecutive mechanical bench trials without sensor dislocation, but formal clinical fit testing across different patient hand sizes is our next scheduled milestone. Krushna will now present our generated evaluation report and wrap up our demonstration.

---

## If a judge asks

1. **How do you prevent flex sensors from breaking at the solder joints during repetitive finger bending?**  
   The sensor tips slide within floating textile guide sleeves while the base is anchored to a rigid wrist strain-relief block, preventing bending fatigue as documented in `docs/gautam/MECHANICS_BRIEF.md`.

2. **Have you completed human fit testing across a diverse cohort of patient hands?**  
   No, our current prototype is built on a Medium-Large cotton glove tested on healthy volunteers; clinical fit testing across diverse hand sizes is our next step, outlined in `docs/gautam/DATA_COLLECTION_PROTOCOL.md`.

3. **How many physical transfer attempts have been verified with this hardware setup?**  
   We have recorded ten consecutive successful physical trials in our database with zero mechanical failures, documented in `docs/VALIDATION_SHEET.csv` and confirmed by test `tests/test_e2e.py::test_e2e_10`.
