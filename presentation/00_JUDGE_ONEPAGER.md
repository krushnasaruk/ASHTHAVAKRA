# RehabBridge NEXUS / H10 — Judge One-Pager

Stroke survivors and motor-impaired patients require repetitive object manipulation exercises at home to regain hand function. However, current tele-rehabilitation lacks objective verification, making it impossible for clinicians to confirm whether a patient actually performed their prescribed physical exercises correctly.

We built RehabBridge NEXUS, a multi-sensor system combining an instrumented glove, an overhead camera tracking an ArUco fiducial marker, and an automated verdict engine. The system verifies whether a physical transfer object was grasped, lifted, transported across a boundary, and released in the designated target zone.

Unlike conventional apps that merely count isolated finger bends or estimate pose, NEXUS proves the completion of an actual functional object-transfer task with physical contact and spatial displacement.

At 25 Hz, the glove streams flex bend, contact pressure, and IMU motion over USB serial while the camera tracks the object at 15 frames per second. These concurrent data streams feed our deterministic TaskProof state machine, which checks contact, lift, transport, and release guards against predefined thresholds. The engine produces a definitive VERIFIED, FAILED, or UNCERTAIN verdict accompanied by diagnostic reason codes, and immutably records the attempt and metrics to an SQLite database.

This prototype is an engineering demonstration and is not a certified medical device, does not diagnose clinical pathologies, and does not prescribe rehabilitation regimens.

All foundational objectives and Gates G0 through G6 are complete with 68 passing automated tests, verified SQLite event logging, and an active 10-trial validation baseline.
