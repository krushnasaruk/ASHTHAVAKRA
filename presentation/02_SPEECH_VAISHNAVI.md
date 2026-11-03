# Product Design Speech — Vaishnavi Jare (UX & Visual Systems)

**Time Slot:** Minute 1:15 – 2:30 (75 seconds)  
**Demo Step Accompanied:** Preflight indicator inspection, Operator View to Judge View switching, and accessible verdict cards  
**Source Files Relied On:** `frontend/src/App.tsx`, `frontend/src/index.css`, `mobile/packages/h10_core/lib/theme/`, `docs/vaishnavi_jare/DESIGN_BRIEF.md`  

---

## Spoken Speech

I am Vaishnavi Jare, the product designer responsible for user experience and interface accessibility on RehabBridge NEXUS. I designed the complete user interface flow in frontend/src/App.tsx, creating tailored views for both technical operators and evaluators. To support stroke patients with motor challenges, every interactive touch target meets a strict 48 by 48 pixel minimum. Our telemetry displays use the Okabe-Ito colorblind-safe palette, ensuring that finger channels and sensor health never depend on color perception alone. In our Judge View, task outcomes appear as prominent high-contrast cards that pair explicit text labels like VERIFIED or UNCERTAIN directly with distinct geometric symbols. You will see me toggle between the operator dashboard and the judge view, demonstrating our real-time preflight checks, calibration cards, and the post-task evaluation summary. Our interface currently runs on a responsive web dashboard, so patient self-training on native mobile phones remains a future platform milestone. I will now hand over to Rajendra, who will explain the embedded hardware that captures these finger movements.

---

## If a judge asks

1. **Why did you create separate views for operators and judges?**  
   Operators require granular raw ADC values and frame-rate stats for diagnostic monitoring, while evaluators need an uncluttered screen focused on the verified verdict and compliance evidence, implemented via the view toggle in `frontend/src/App.tsx`.

2. **How do you guarantee accessibility for patients with color vision deficiencies or tremors?**  
   We apply the Okabe-Ito color-blind safe palette and enforce a minimum 48 by 48 pixel button hit target in `frontend/src/App.tsx`, pairing every color with an unambiguous text label and icon.

3. **Is this interface accessible directly on a mobile phone today?**  
   The dashboard is responsive with a dedicated 440-pixel mobile preview mode in `frontend/src/App.tsx`, while our native Flutter patient application in `mobile/` is scheduled for the post-hackathon platform release.

