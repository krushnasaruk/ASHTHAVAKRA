"""
H10 Device Simulator HTTP REST API and WebSocket server.
Emulates ESP32 firmware according to Section 5.2 and Section 13.
"""
import asyncio
import time
import uuid
from typing import Dict, Any, Optional
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from simulator.engine import SimulatorEngine


app = FastAPI(
    title="H10 Glove Simulator",
    description="Deterministic ESP32 device simulator for H10 hand rehabilitation prototype",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

engine = SimulatorEngine(default_scenario="open_hand_rest", seed=42)
boot_time = time.time()


def make_response(data: Any = None, error: Any = None, request_id: Optional[str] = None) -> Dict[str, Any]:
    req_id = request_id or str(uuid.uuid4())
    if error:
        return {"ok": False, "error": error, "request_id": req_id}
    return {"ok": True, "data": data, "request_id": req_id}


# --- Request Models ---
class CalibrationCaptureRequest(BaseModel):
    duration_ms: int = Field(default=2000, ge=500, le=10000)
    request_id: Optional[str] = None


class SessionStartRequest(BaseModel):
    session_id: str
    request_id: Optional[str] = None


class SessionStopRequest(BaseModel):
    session_id: str
    request_id: Optional[str] = None


class HapticControlRequest(BaseModel):
    motor: str = Field(default="both")
    duration_ms: int = Field(default=200, ge=50, le=2000)
    request_id: Optional[str] = None


class RateControlRequest(BaseModel):
    hz: int
    request_id: Optional[str] = None


class SimulatorScenarioRequest(BaseModel):
    scenario: str
    seed: Optional[int] = 42
    request_id: Optional[str] = None


# --- HTTP Endpoints ---

@app.get("/api/status")
async def get_status():
    uptime_ms = int((time.time() - boot_time) * 1000)
    return make_response({
        "battery": engine.battery_pct,
        "uptime_ms": uptime_ms,
        "rate_hz": engine.rate_hz,
        "calibrated": engine.is_calibrated,
        "session_active": engine.is_session_active,
        "scenario": engine.scenario_name,
        "simulated": True
    })


@app.get("/api/info")
async def get_info():
    return make_response({
        "firmware": "1.0.0",
        "protocol": 1,
        "device_id": "H10-SIMULATOR-01",
        "fsr_present": False,
        "haptic_present": True,
        "allowed_rates": [25, 50],
        "simulated": True
    })


@app.get("/api/calibration")
async def get_calibration():
    return make_response(engine.calibration_data)


@app.post("/api/calibration/open")
async def calibrate_open(req: CalibrationCaptureRequest):
    if engine.is_session_active:
        return make_response(error={"code": "CONFLICT", "message": "Cannot calibrate while session is active"}, request_id=req.request_id)
    # Simulate capture
    await asyncio.sleep(req.duration_ms / 1000.0 * 0.1)  # fast simulation
    engine.calibration_data["open"] = [1000, 1010, 995, 1005, 990]
    engine.calibration_data["timestamp"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    return make_response({"status": "captured", "values": engine.calibration_data["open"]}, request_id=req.request_id)


@app.post("/api/calibration/fist")
async def calibrate_fist(req: CalibrationCaptureRequest):
    if engine.is_session_active:
        return make_response(error={"code": "CONFLICT", "message": "Cannot calibrate while session is active"}, request_id=req.request_id)
    await asyncio.sleep(req.duration_ms / 1000.0 * 0.1)
    engine.calibration_data["closed"] = [3200, 3210, 3190, 3205, 3185]
    engine.calibration_data["timestamp"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    engine.is_calibrated = True
    return make_response({"status": "captured", "values": engine.calibration_data["closed"]}, request_id=req.request_id)


@app.post("/api/session/start")
async def start_session(req: SessionStartRequest):
    if engine.is_session_active:
        return make_response(error={"code": "CONFLICT", "message": "Session already active"}, request_id=req.request_id)
    engine.is_session_active = True
    engine.active_session_id = req.session_id
    return make_response({"session_id": req.session_id, "status": "started"}, request_id=req.request_id)


@app.post("/api/session/stop")
async def stop_session(req: SessionStopRequest):
    if not engine.is_session_active:
        return make_response(error={"code": "NOT_FOUND", "message": "No active session"}, request_id=req.request_id)
    engine.is_session_active = False
    engine.active_session_id = None
    return make_response({"session_id": req.session_id, "status": "stopped"}, request_id=req.request_id)


@app.post("/api/control/haptic")
async def trigger_haptic(req: HapticControlRequest):
    engine.haptic_count += 1
    return make_response({"acknowledged": True, "motor": req.motor, "duration_ms": req.duration_ms}, request_id=req.request_id)


@app.post("/api/control/rate")
async def set_stream_rate(req: RateControlRequest):
    if req.hz not in [25, 50]:
        return make_response(error={"code": "UNPROCESSABLE_ENTITY", "message": f"Rate {req.hz} Hz not in allowed_rates [25, 50]"}, request_id=req.request_id)
    engine.rate_hz = req.hz
    return make_response({"rate_hz": engine.rate_hz}, request_id=req.request_id)


@app.post("/api/simulator/scenario")
async def switch_scenario(req: SimulatorScenarioRequest):
    try:
        engine.set_scenario(req.scenario, seed=req.seed)
        return make_response({"scenario": req.scenario, "seed": req.seed}, request_id=req.request_id)
    except ValueError as e:
        return make_response(error={"code": "INVALID_SCENARIO", "message": str(e)}, request_id=req.request_id)


# --- WebSocket Stream ---

@app.websocket("/ws/sensors")
async def websocket_sensors(websocket: WebSocket):
    await websocket.accept()
    # 1. Send Hello frame
    hello_frame = {
        "type": "hello",
        "protocol": 1,
        "firmware": "1.0.0",
        "rate_hz": engine.rate_hz,
        "encoding": engine.encoding
    }
    await websocket.send_json(hello_frame)
    
    interval_s = 1.0 / engine.rate_hz
    try:
        while True:
            start_t = time.time()
            drop, payload = engine.get_next_frame()
            if not drop and payload is not None:
                if engine.encoding == "binary":
                    await websocket.send_bytes(payload)
                else:
                    await websocket.send_json(payload)
                    
            elapsed = time.time() - start_t
            sleep_time = max(0.001, interval_s - elapsed)
            await asyncio.sleep(sleep_time)
    except WebSocketDisconnect:
        pass
    except Exception:
        pass
