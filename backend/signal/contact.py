"""
FSR Contact Hysteresis Detector for RehabBridge NEXUS / H10.
Implements Build Specification v3 Section 7.4 and tests SG-06 through SG-08.
"""

from typing import Optional, Tuple, Dict, Any
from .filters import CompoundFilter


class FSRContactDetector:
    def __init__(
        self,
        no_contact_median: float = 500.0,
        no_contact_std: float = 30.0,
        k_on: float = 4.0,
        k_off: float = 2.0,
        min_contact_ms: float = 100.0,
        min_release_ms: float = 150.0,
        rail_threshold: float = 31000.0,
        rail_fault_ms: float = 300.0,
        median_window: int = 3,
        ema_alpha: float = 0.30,
    ):
        self.no_contact_median = float(no_contact_median)
        self.no_contact_std = max(1.0, float(no_contact_std))
        self.k_on = float(k_on)
        self.k_off = float(k_off)
        self.min_contact_ms = float(min_contact_ms)
        self.min_release_ms = float(min_release_ms)
        self.rail_threshold = float(rail_threshold)
        self.rail_fault_ms = float(rail_fault_ms)

        self.threshold_on = self.no_contact_median + self.k_on * self.no_contact_std
        self.threshold_off = self.no_contact_median + self.k_off * self.no_contact_std

        self.filter = CompoundFilter(median_window=median_window, ema_alpha=ema_alpha)
        self.contact_state: bool = False
        self.is_faulted: bool = False
        self.fault_reason: str = "OK"

        self._high_start_ms: Optional[float] = None
        self._low_start_ms: Optional[float] = None
        self._rail_start_ms: Optional[float] = None

    def update(self, raw_fsr: Optional[float], fsr_ok: bool, t_ms: float) -> Tuple[bool, bool, Optional[str]]:
        """
        Updates detector state with new sample.
        Returns (contact_state, is_faulted, event_emitted).
        event_emitted can be 'CONTACT_ON', 'CONTACT_OFF', 'FSR_FAULT', or None.
        """
        if not fsr_ok or raw_fsr is None:
            self.is_faulted = True
            self.fault_reason = "FSR_DISCONNECTED"
            return False, True, "FSR_FAULT"

        # Rail check (shorted to rail)
        if raw_fsr >= self.rail_threshold:
            if self._rail_start_ms is None:
                self._rail_start_ms = t_ms
            elif (t_ms - self._rail_start_ms) >= self.rail_fault_ms:
                self.is_faulted = True
                self.fault_reason = "FSR_RAILED"
                return False, True, "FSR_FAULT"
        else:
            self._rail_start_ms = None

        filtered_val = self.filter.update(raw_fsr)
        event_emitted = None

        if not self.contact_state:
            # Check for contact onset
            if filtered_val >= self.threshold_on:
                if self._high_start_ms is None:
                    self._high_start_ms = t_ms
                elif (t_ms - self._high_start_ms) >= self.min_contact_ms:
                    self.contact_state = True
                    self._high_start_ms = None
                    self._low_start_ms = None
                    event_emitted = "CONTACT_ON"
            else:
                self._high_start_ms = None
        else:
            # Check for contact release
            if filtered_val <= self.threshold_off:
                if self._low_start_ms is None:
                    self._low_start_ms = t_ms
                elif (t_ms - self._low_start_ms) >= self.min_release_ms:
                    self.contact_state = False
                    self._low_start_ms = None
                    self._high_start_ms = None
                    event_emitted = "CONTACT_OFF"
            else:
                self._low_start_ms = None

        return self.contact_state, self.is_faulted, event_emitted

