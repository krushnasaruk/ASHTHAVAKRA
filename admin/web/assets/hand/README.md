# 3D Rigged Human Hand Asset (`hand.glb`)

## 1. Model Source & Attribution
- **Origin:** W3C Immersive Web Working Group / WebXR Input Profiles repository
- **Package:** `@webxr-input-profiles/assets` (generic-hand profile)
- **Direct Repository:** [immersive-web/webxr-input-profiles](https://github.com/immersive-web/webxr-input-profiles)
- **Copyright:** Copyright (c) 2019 Amazon, Inc. or its affiliates. All Rights Reserved.
- **Format:** Binary glTF (GLB v2.0), ~94 KB.

## 2. License Terms
Distributed under the **MIT License**:

```text
MIT License

Copyright (c) 2019 Amazon

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice (including the next
paragraph) shall be included in all copies or substantial portions of the
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

## 3. Rig Hierarchy & Joint Mapping
The asset contains 25 bones mapped to human hand anatomy:
- `wrist`: Root wrist orientation node (driven by IMU quaternion: `qw`, `qx`, `qy`, `qz`).
- **Thumb:**
  - `thumb-metacarpal`
  - `thumb-phalanx-proximal`
  - `thumb-phalanx-distal`
  - `thumb-tip`
- **Index Finger (Ch2 Measured):**
  - `index-finger-metacarpal`
  - `index-finger-phalanx-proximal` (MCP: `-t * 1.4` rad)
  - `index-finger-phalanx-intermediate` (PIP: `-t * 1.6` rad)
  - `index-finger-phalanx-distal` (DIP: `-t * 0.9` rad)
  - `index-finger-tip`
- **Middle Finger (Ch3 Measured):**
  - `middle-finger-metacarpal`
  - `middle-finger-phalanx-proximal` (MCP: `-t * 1.4` rad)
  - `middle-finger-phalanx-intermediate` (PIP: `-t * 1.6` rad)
  - `middle-finger-phalanx-distal` (DIP: `-t * 0.9` rad)
  - `middle-finger-tip`
- **Ring Finger (Estimated: `0.9 * middle`):**
  - `ring-finger-metacarpal`
  - `ring-finger-phalanx-proximal` (MCP)
  - `ring-finger-phalanx-intermediate` (PIP)
  - `ring-finger-phalanx-distal` (DIP)
  - `ring-finger-tip`
- **Pinky Finger (Estimated: `0.75 * middle`):**
  - `pinky-finger-metacarpal`
  - `pinky-finger-phalanx-proximal` (MCP)
  - `pinky-finger-phalanx-intermediate` (PIP)
  - `pinky-finger-phalanx-distal` (DIP)
  - `pinky-finger-tip`
- **Mesh:**
  - `r_handMeshNode`: High-fidelity rigged organic human hand skin mesh.

## 4. Offline Independence
- All dependencies (`three.min.js`, `GLTFLoader.js`, `hand.glb`, and `hand_view.html`) reside locally under `assets/hand/`.
- No external CDNs or network calls are executed at runtime.

---

# 3D Anatomical Hand Skeleton Asset (`skeleton.glb`)

## 5. Model Source, Attribution & License
- **Origin & Biomechanical Design:** Derived from anatomical bone geometry profiles of **BodyParts3D** (The Database Center for Life Science, licensed under CC BY-SA 2.1 Japan) and **Z-Anatomy** (open-source anatomical atlas, licensed under CC BY-SA 4.0), parameterized using published human hand anthropometric datasets (Buchholz et al. 1992; Buryanov & Kotiuk 2010).
- **Format:** Binary glTF (GLB v2.0), ~228 KB.
- **Copyright:** Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0).
- **Shapes & Kinematic Rig:** All 27 individual human hand bones feature anatomical diaphysis (shaft) and epiphysis (joint base/head) geometry with bicondylar articulatory curvature, natural inter-carpal spacing, and physiological axes. (Shapes are anatomically parameterized approximations engineered for interactive real-time mobile rendering).
- **Nonclinical Notice:** Engineering demonstration prototype only. This 3D viewer is nonclinical and must not be used for medical diagnosis, clinical evaluation, or surgical planning.

## 6. Comprehensive Bone Measurement Table (27 Bones)
The skeleton contains exactly 27 bones: 8 carpals in two rows, 5 metacarpals, and 14 phalanges. Dimensional measurements are calibrated to normative adult anthropometric reference datasets:

### Carpal Bones (8 Bones, Two Rows)
| Bone Name | Row | Position (x, y, z mm) | Dimension (LxWxH mm) | Articulating Joints |
|:---|:---|:---|:---|:---|
| **Scaphoid** | Proximal | (-14.0, -14.0, 0.0) | 14.0 x 10.0 x 10.0 | Radiocarpal, Midcarpal, Scaphotrapezial |
| **Lunate** | Proximal | (-4.0, -13.5, 0.0) | 12.0 x 11.0 x 9.5 | Radiocarpal, Midcarpal |
| **Triquetrum** | Proximal | (6.0, -14.5, 0.0) | 11.0 x 10.0 x 9.0 | Midcarpal, Pisotriquetral |
| **Pisiform** | Proximal (Palmar) | (7.5, -13.0, 5.0) | 8.0 x 8.5 x 7.5 | Pisotriquetral |
| **Trapezium** | Distal | (-16.0, -4.0, 1.0) | 13.0 x 11.0 x 11.0 | CMC 1, Scaphotrapezial |
| **Trapezoid** | Distal | (-7.5, -4.5, 0.0) | 10.0 x 10.0 x 9.5 | CMC 2, Scaphotrapezoid |
| **Capitate** | Distal | (0.5, -3.5, 0.0) | 15.0 x 14.0 x 12.0 | CMC 3, Midcarpal |
| **Hamate** | Distal | (9.5, -4.0, 0.5) | 13.0 x 13.0 x 11.5 | CMC 4, CMC 5 |

### Metacarpal Bones (5 Bones)
| Bone Name | Finger | Length (mm) | Base Width (mm) | Shaft Width (mm) | Head Width (mm) | Connected Joints |
|:---|:---|:---|:---|:---|:---|:---|
| **Metacarpal 1** | Thumb | 46.2 | 14.5 | 9.2 | 13.8 | CMC 1, MCP 1 |
| **Metacarpal 2** | Index | 68.1 | 14.2 | 8.8 | 13.5 | CMC 2, MCP 2 |
| **Metacarpal 3** | Middle | 64.6 | 14.0 | 8.9 | 13.8 | CMC 3, MCP 3 |
| **Metacarpal 4** | Ring | 58.0 | 12.5 | 7.8 | 12.2 | CMC 4, MCP 4 |
| **Metacarpal 5** | Pinky | 53.7 | 12.0 | 7.2 | 11.5 | CMC 5, MCP 5 |

### Phalanx Bones (14 Bones)
| Bone Name | Finger | Length (mm) | Base Width (mm) | Shaft Width (mm) | Head Width (mm) | Connected Joints |
|:---|:---|:---|:---|:---|:---|:---|
| **Proximal Phalanx** | Thumb | 31.6 | 13.2 | 8.5 | 11.4 | MCP 1, IP |
| **Distal Phalanx** | Thumb | 21.7 | 11.8 | 7.2 | 9.8 | IP |
| **Proximal Phalanx** | Index | 39.8 | 13.1 | 7.8 | 11.2 | MCP 2, PIP 2 |
| **Middle Phalanx** | Index | 22.4 | 11.5 | 6.8 | 9.6 | PIP 2, DIP 2 |
| **Distal Phalanx** | Index | 15.8 | 9.4 | 5.5 | 7.8 | DIP 2 |
| **Proximal Phalanx** | Middle | 44.6 | 13.8 | 8.4 | 11.8 | MCP 3, PIP 3 |
| **Middle Phalanx** | Middle | 26.3 | 12.0 | 7.2 | 10.1 | PIP 3, DIP 3 |
| **Distal Phalanx** | Middle | 17.4 | 9.8 | 5.8 | 8.2 | DIP 3 |
| **Proximal Phalanx** | Ring | 41.3 | 12.8 | 7.6 | 10.9 | MCP 4, PIP 4 |
| **Middle Phalanx** | Ring | 25.7 | 11.2 | 6.5 | 9.4 | PIP 4, DIP 4 |
| **Distal Phalanx** | Ring | 17.3 | 9.2 | 5.4 | 7.9 | DIP 4 |
| **Proximal Phalanx** | Pinky | 32.7 | 11.5 | 6.6 | 9.8 | MCP 5, PIP 5 |
| **Middle Phalanx** | Pinky | 18.1 | 10.1 | 5.8 | 8.4 | PIP 5, DIP 5 |
| **Distal Phalanx** | Pinky | 15.9 | 8.6 | 4.8 | 7.2 | DIP 5 |

**Total Count Verification:** 8 carpal + 5 metacarpal + 14 phalanx = **27 total hand bones**.

## 7. Joint Rotation Constants & Forward Kinematics
- **Metacarpophalangeal (MCP):** \(\theta_{\text{MCP}} = -t \times 1.4\text{ rad}\)
- **Proximal Interphalangeal (PIP):** \(\theta_{\text{PIP}} = -t \times 1.6\text{ rad}\)
- **Distal Interphalangeal (DIP):** \(\theta_{\text{DIP}} = -t \times 0.9\text{ rad}\)
- **Interpolation / Easing:** Lerp factor = 0.25 per frame.
- **Sensor Mapping:** Channels 1–3 (Thumb, Index, Middle) are directly driven by calibrated glove flex sensor data. Channels 4 & 5 (Ring, Pinky) are estimated as \(\text{Ring} = 0.90 \times \text{Middle}\) and \(\text{Pinky} = 0.75 \times \text{Middle}\), clearly tagged as `EST.`


