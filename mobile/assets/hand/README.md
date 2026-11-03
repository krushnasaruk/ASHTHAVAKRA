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

