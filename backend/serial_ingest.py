"""
Host Serial Ingest Module for RehabBridge NEXUS / H10.
Complies with Build Specification v3 Section 5 and test suite SI-01 through SI-10.
Handles port discovery, threaded packet ingestion, JSON line validation,
sequence continuity, reset detection, and ring buffer management.
"""

import json
import logging
import queue
import threading
import time
import uuid
from typing import Callable, Dict, List, Optional, Tuple, Any

import serial
import serial.tools.list_ports

logger = logging.getLogger("nexus.serial_ingest")


class IngestStats:
    def __init__(self):
        self.total_packets: int = 0
        self.valid_packets: int = 0
        self.invalid_lines: int = 0
        self.dropped_packets: int = 0
        self.seq_gaps: int = 0
        self.seq_duplicates: int = 0
        self.reboots_detected: int = 0
        self.range_errors: int = 0
        self.last_seq: Optional[int] = None
        self.last_t_ms: Optional[int] = None
        self.last_arrival_ns: Optional[int] = None
        self.estimated_rate_hz: float = 0.0
        self._window_start_ns: int = time.monotonic_ns()
        self._window_packets: int = 0

    def update_rate(self, arrival_ns: int):
        self._window_packets += 1
        elapsed_s = (arrival_ns - self._window_start_ns) / 1e9
        if elapsed_s >= 1.0:
            self.estimated_rate_hz = self._window_packets / elapsed_s
            self._window_packets = 0
            self._window_start_ns = arrival_ns

    def to_dict(self) -> Dict[str, Any]:
        return {
            "total_packets": self.total_packets,
            "valid_packets": self.valid_packets,
            "invalid_lines": self.invalid_lines,
            "dropped_packets": self.dropped_packets,
            "seq_gaps": self.seq_gaps,
            "seq_duplicates": self.seq_duplicates,
            "reboots_detected": self.reboots_detected,
            "range_errors": self.range_errors,
            "estimated_rate_hz": round(self.estimated_rate_hz, 2),
            "last_seq": self.last_seq,
        }


class SerialIngest:
    def __init__(
        self,
        baud_rate: int = 921600,
        expected_profile: str = "demo3",
        queue_maxsize: int = 500,
        packet_callback: Optional[Callable[[Dict[str, Any]], None]] = None,
        event_callback: Optional[Callable[[str, Dict[str, Any]], None]] = None,
    ):
        self.baud_rate = baud_rate
        self.expected_profile = expected_profile
        self.queue_maxsize = queue_maxsize
        self.packet_queue: queue.Queue = queue.Queue(maxsize=queue_maxsize)
        self.packet_callback = packet_callback
        self.event_callback = event_callback

        self.serial_port: Optional[str] = None
        self.serial_conn: Optional[serial.Serial] = None
        self.is_running: bool = False
        self.is_connected: bool = False
        self.reader_thread: Optional[threading.Thread] = None

        self.stats = IngestStats()
        self.device_epoch: int = 0
        self.firmware_version: Optional[str] = None
        self.device_profile: Optional[str] = None

    @staticmethod
    def list_ports() -> List[Dict[str, str]]:
        """List all available serial COM ports."""
        ports = serial.tools.list_ports.comports()
        return [
            {
                "device": p.device,
                "description": p.description,
                "hwid": p.hwid,
            }
            for p in ports
        ]

    def ping_device(self, port: str, timeout: float = 1.5) -> Tuple[bool, Optional[Dict[str, Any]]]:
        """Send ping command to a candidate port and wait for ACK."""
        try:
            with serial.Serial(port, self.baud_rate, timeout=timeout) as ser:
                ser.reset_input_buffer()
                ping_id = str(uuid.uuid4())[:8]
                cmd = json.dumps({"cmd": "ping", "id": ping_id}) + "\n"
                ser.write(cmd.encode("utf-8"))
                ser.flush()

                start = time.monotonic()
                while time.monotonic() - start < timeout:
                    line = ser.readline().decode("utf-8", errors="ignore").strip()
                    if not line:
                        continue
                    try:
                        data = json.loads(line)
                        if data.get("ack") == ping_id and data.get("ok") is True:
                            return True, data
                    except json.JSONDecodeError:
                        continue
        except Exception as e:
            logger.debug(f"Ping failed on {port}: {e}")
        return False, None

    def auto_detect_port(self) -> Optional[str]:
        """Probe all available ports to locate the RehabBridge NEXUS glove."""
        for p in self.list_ports():
            port_name = p["device"]
            ok, ack = self.ping_device(port_name)
            if ok and ack:
                profile = ack.get("profile")
                if profile == self.expected_profile:
                    logger.info(f"Auto-detected NEXUS glove on {port_name} (fw: {ack.get('fw')})")
                    return port_name
        return None

    def connect(self, port: Optional[str] = None) -> bool:
        """Connect to device on the given or auto-detected port."""
        if self.is_connected:
            self.disconnect()

        target_port = port or self.auto_detect_port()
        if not target_port:
            logger.warning("No compatible serial device detected.")
            return False

        try:
            self.serial_conn = serial.Serial(target_port, self.baud_rate, timeout=1.0)
            self.serial_port = target_port
            self.is_connected = True
            self.is_running = True

            self.stats = IngestStats()
            self.device_epoch += 1

            self.reader_thread = threading.Thread(target=self._reader_loop, daemon=True)
            self.reader_thread.start()
            logger.info(f"Connected to {target_port} at {self.baud_rate} baud.")

            if self.event_callback:
                self.event_callback("DEVICE_CONNECTED", {"port": target_port, "epoch": self.device_epoch})
            return True
        except Exception as e:
            logger.error(f"Failed to connect to {target_port}: {e}")
            self.is_connected = False
            return False

    def disconnect(self):
        """Disconnect and stop ingestion thread."""
        self.is_running = False
        if self.serial_conn and self.serial_conn.is_open:
            try:
                self.serial_conn.close()
            except Exception:
                pass
        if self.reader_thread and self.reader_thread.is_alive():
            self.reader_thread.join(timeout=1.0)
        self.is_connected = False
        self.serial_conn = None
        if self.event_callback:
            self.event_callback("DEVICE_DISCONNECTED", {"port": self.serial_port})

    def parse_line(self, line: str, arrival_ns: int) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
        """Validate and parse a raw JSON line according to protocol v1."""
        line = line.strip()
        if not line:
            return None, "EMPTY_LINE"

        try:
            data = json.loads(line)
        except json.JSONDecodeError:
            self.stats.invalid_lines += 1
            return None, "JSON_SYNTAX_ERROR"

        # Check for device boot line
        if data.get("boot") is True:
            self.stats.reboots_detected += 1
            self.firmware_version = data.get("fw")
            new_profile = data.get("profile")
            if self.device_profile and new_profile != self.device_profile:
                if self.event_callback:
                    self.event_callback("CALIBRATION_PROFILE_MISMATCH", {
                        "expected": self.device_profile,
                        "reconnected": new_profile
                    })
            self.device_profile = new_profile
            self.device_epoch += 1
            if self.event_callback:
                self.event_callback("DEVICE_REBOOT", {"boot": data, "epoch": self.device_epoch})
            return None, "BOOT_LINE"

        # Protocol version verification (SI-02)
        if data.get("v") != 1:
            self.stats.invalid_lines += 1
            return None, "UNKNOWN_PROTOCOL_VERSION"

        # Required fields check
        required_fields = ["seq", "t_ms", "flex", "fsr", "imu", "fsr_ok", "imu_ok", "adc_ok", "flags"]
        for f in required_fields:
            if f not in data:
                self.stats.invalid_lines += 1
                return None, f"MISSING_FIELD_{f.upper()}"

        flex = data["flex"]
        fsr = data["fsr"]
        imu = data["imu"]

        # Range checks (SI-09)
        adc_ok = bool(data["adc_ok"])
        for val in flex:
            if not isinstance(val, (int, float)) or val < 0 or val > 32767:
                self.stats.range_errors += 1
                adc_ok = False
        if fsr is not None and (not isinstance(fsr, (int, float)) or fsr < 0 or fsr > 32767):
            self.stats.range_errors += 1
            adc_ok = False

        seq = data["seq"]
        t_ms = data["t_ms"]

        # Detect reboot by sequence regression or t_ms drop (SI-04)
        if self.stats.last_seq is not None:
            if seq < self.stats.last_seq or (self.stats.last_t_ms is not None and t_ms < self.stats.last_t_ms):
                self.stats.reboots_detected += 1
                self.device_epoch += 1
                if self.event_callback:
                    self.event_callback("DEVICE_RESET_DETECTED", {"seq": seq, "prev_seq": self.stats.last_seq})
            elif seq == self.stats.last_seq:
                self.stats.seq_duplicates += 1
            elif seq > self.stats.last_seq + 1:
                gap = seq - (self.stats.last_seq + 1)
                self.stats.seq_gaps += gap
                self.stats.dropped_packets += gap

        self.stats.last_seq = seq
        self.stats.last_t_ms = t_ms
        self.stats.last_arrival_ns = arrival_ns
        self.stats.total_packets += 1
        self.stats.valid_packets += 1
        self.stats.update_rate(arrival_ns)

        packet = {
            "v": data["v"],
            "seq": seq,
            "t_ms": t_ms,
            "host_monotonic_ns": arrival_ns,
            "device_epoch": self.device_epoch,
            "flex": flex,
            "fsr": fsr,
            "imu": imu,
            "fsr_ok": bool(data["fsr_ok"]),
            "imu_ok": bool(data["imu_ok"]),
            "adc_ok": adc_ok,
            "flags": int(data["flags"]),
            "data_source": "live",
        }
        return packet, None

    def _enqueue_packet(self, packet: Dict[str, Any]):
        """Enqueue packet, dropping oldest if buffer is full (SI-05)."""
        if self.packet_queue.full():
            try:
                self.packet_queue.get_nowait()
                self.stats.dropped_packets += 1
            except queue.Empty:
                pass
        self.packet_queue.put(packet)
        if self.packet_callback:
            self.packet_callback(packet)

    def _reader_loop(self):
        """Background thread reading from serial port."""
        while self.is_running and self.serial_conn and self.serial_conn.is_open:
            try:
                raw_bytes = self.serial_conn.readline()
                arrival_ns = time.monotonic_ns()
                if not raw_bytes:
                    continue

                line = raw_bytes.decode("utf-8", errors="replace").strip()
                packet, err = self.parse_line(line, arrival_ns)
                if packet:
                    self._enqueue_packet(packet)
            except serial.SerialException as e:
                logger.error(f"Serial port exception: {e}")
                self.is_connected = False
                if self.event_callback:
                    self.event_callback("DEVICE_DISCONNECTED", {"reason": str(e)})
                break
            except Exception as e:
                logger.error(f"Unexpected reader exception: {e}")
                time.sleep(0.01)
