# Developer Speech — Krushna (Software & System Architecture)

**Time Slot:** Minute 0:00 – 1:15 (75 seconds)  
**Demo Step Accompanied:** Preflight diagnostic check, serial stream startup, and live TaskProof state machine execution  
**Source Files Relied On:** `backend/serial_ingest.py`, `backend/signal_layer.py`, `backend/taskproof.py`, `backend/database.py`, `frontend/src/App.tsx`, `tests/test_taskproof.py`  

---

## Spoken Speech

I am Krushna, the software and systems architect for RehabBridge NEXUS. I built the high-speed serial ingest in backend/serial_ingest.py, our signal filtering pipeline, and the deterministic TaskProof state machine in backend/taskproof.py. I also developed the FastAPI backend, SQLite database persistence, and the telemetry processing layer that coordinates glove data with computer vision. Our core architectural rule is measurement honesty: if the camera view is occluded for more than half a second, the engine refuses to guess and yields an UNCERTAIN verdict rather than a false success. You will see me run our preflight diagnostic, initiate an attempt, and show the state machine transition cleanly from grasp to release as live telemetry records to SQLite. Our software mathematically verifies task completion and movement smoothness, but it cannot measure clinical recovery outcomes or muscle force in newtons. I will now hand over to Vaishnavi, who designed the user interfaces that make these technical telemetry streams clear and accessible.

---

## If a judge asks

1. **How do you prevent false positives when lighting changes or the camera is blocked?**  
   Our vision module in `backend/vision.py` continuously calculates a one-second rolling detection rate, and test `tests/test_taskproof.py::test_tp_12` proves that marker occlusion immediately defaults the state machine to an UNCERTAIN verdict.

2. **What guarantees that your database writes do not lose telemetry during rapid attempts?**  
   SQLite operates in write-ahead log mode with WAL checkpoints configured in `backend/database.py`, verified in `tests/test_e2e.py::test_e2e_10` across ten rapid consecutive trials.

3. **Can your software diagnose motor recovery or predict clinical outcomes?**  
   No, our system only verifies completion of a defined mechanical transfer task; clinical diagnosis is explicitly prohibited in `backend/schemas.py` and requires formal clinical trials.
