import React, { useState, useEffect, useRef } from "react";
import {
  Activity,
  AlertTriangle,
  Camera,
  CheckCircle2,
  Download,
  Eye,
  FileCheck,
  Play,
  RotateCcw,
  Sliders,
  StopCircle,
  Tv,
  Wifi,
  XCircle,
} from "lucide-react";

interface PreflightCheck {
  name: string;
  status: "pass" | "warn" | "fail";
  required: boolean;
  details: string;
  hint?: string;
}

interface TelemetryPayload {
  timestamp_ns: number;
  sensor?: {
    seq: number;
    t_ms: number;
    flex: number[];
    fsr: number;
    imu: number[];
    fsr_ok: boolean;
    adc_ok: boolean;
  };
  vision?: {
    marker_visible: boolean;
    marker_center_px?: [number, number];
    zone_membership: string;
    detection_rate_1s: number;
    frame_age_ms: number;
    occlusion_ms: number;
  };
  taskproof: {
    state: string;
    verdict: string;
    reason_codes: string[];
    attempt_id?: string;
  };
  stats: {
    total_packets: number;
    estimated_rate_hz: number;
    dropped_packets: number;
  };
}

export default function App() {
  const [viewMode, setViewMode] = useState<"operator" | "judge">("operator");
  const [dataSource, setDataSource] = useState<"live" | "replay" | "simulated">("live");

  // Telemetry state
  const [telemetry, setTelemetry] = useState<TelemetryPayload | null>(null);
  const [connected, setConnected] = useState(false);
  const [preflightChecks, setPreflightChecks] = useState<PreflightCheck[]>([]);

  // Attempt history
  const [attemptHistory, setAttemptHistory] = useState<
    { id: string; verdict: string; reasons: string[]; duration: number; time: string }[]
  >([]);

  // Hotkey notification
  const [hotkeyToast, setHotkeyToast] = useState<string | null>(null);

  // WebSocket Telemetry hook
  useEffect(() => {
    let ws: WebSocket;
    let timer: any;

    const connectWs = () => {
      const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
      const host = window.location.host;
      const wsUrl = `${protocol}//${host}/ws/live`;

      ws = new WebSocket(wsUrl);

      ws.onopen = () => {
        setConnected(true);
      };

      ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          setTelemetry(data);

          // Update attempt history when verdict triggers
          if (data.taskproof && data.taskproof.verdict !== "NOT_STARTED") {
            const v = data.taskproof.verdict;
            const attId = data.taskproof.attempt_id || "att-curr";
            setAttemptHistory((prev) => {
              if (prev.find((x) => x.id === attId)) return prev;
              return [
                {
                  id: attId,
                  verdict: v,
                  reasons: data.taskproof.reason_codes || [],
                  duration: 4.2,
                  time: new Date().toLocaleTimeString(),
                },
                ...prev.slice(0, 9),
              ];
            });
          }
        } catch (e) {
          console.error(e);
        }
      };

      ws.onclose = () => {
        setConnected(false);
        timer = setTimeout(connectWs, 2000);
      };
    };

    connectWs();
    fetchPreflight();

    return () => {
      if (ws) ws.close();
      if (timer) clearTimeout(timer);
    };
  }, []);

  const fetchPreflight = async () => {
    try {
      const res = await fetch("/api/preflight");
      if (res.ok) {
        const data = await res.json();
        setPreflightChecks(data.checks || []);
      }
    } catch (e) {
      console.error(e);
    }
  };

  // Keyboard shortcut listener for rapid labelling (FE-06)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;

      const key = e.key.toUpperCase();
      const attId = telemetry?.taskproof.attempt_id;

      if (e.key === "Escape") {
        fetch("/api/task/abort", { method: "POST" });
        showToast("Attempt Aborted (ESC)");
      } else if (key === "S" && attId) {
        submitGroundTruth(attId, "success");
        showToast("Marked: SUCCESS (S)");
      } else if (key === "F" && attId) {
        submitGroundTruth(attId, "failure");
        showToast("Marked: FAILURE (F)");
      } else if (key === "U" && attId) {
        submitGroundTruth(attId, "uncertain_expected");
        showToast("Marked: UNCERTAIN (U)");
      } else if (key === "N" && attId) {
        submitGroundTruth(attId, "no_attempt");
        showToast("Marked: NO ATTEMPT (N)");
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [telemetry]);

  const showToast = (msg: string) => {
    setHotkeyToast(msg);
    setTimeout(() => setHotkeyToast(null), 2500);
  };

  const submitGroundTruth = async (attemptId: string, label: string) => {
    try {
      await fetch("/api/task/ground-truth", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          attempt_id: attemptId,
          label: label,
          marker_source: "operator_key",
          labeller_pseudonym: "operator",
        }),
      });
    } catch (e) {
      console.error(e);
    }
  };

  const handleStartAttempt = async () => {
    try {
      await fetch("/api/task/start", { method: "POST" });
      showToast("Started New Attempt");
    } catch (e) {
      console.error(e);
    }
  };

  const handleAbortAttempt = async () => {
    try {
      await fetch("/api/task/abort", { method: "POST" });
      showToast("Aborted Attempt");
    } catch (e) {
      console.error(e);
    }
  };

  const getVerdictColor = (verdict: string) => {
    switch (verdict) {
      case "VERIFIED":
        return "bg-emerald-600 border-emerald-400 text-white";
      case "FAILED":
        return "bg-rose-600 border-rose-400 text-white";
      case "UNCERTAIN":
        return "bg-amber-600 border-amber-400 text-white";
      case "ABORTED":
        return "bg-slate-700 border-slate-500 text-slate-200";
      default:
        return "bg-slate-800 border-slate-700 text-slate-300";
    }
  };

  return (
    <div className="min-h-screen flex flex-col bg-slate-950 text-slate-100">
      {/* Top Header & Mode Toggle */}
      <header className="border-b border-slate-800 bg-slate-900/80 backdrop-blur px-6 py-3 flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <Activity className="h-6 w-6 text-sky-400" />
          <h1 className="text-lg font-bold tracking-tight">RehabBridge NEXUS</h1>
          <span className="text-xs bg-slate-800 text-slate-400 px-2 py-0.5 rounded border border-slate-700">v3.0.0</span>

          {/* Data Source Badge */}
          {dataSource === "live" && (
            <span className="text-xs bg-emerald-950/80 text-emerald-400 border border-emerald-700/60 px-2.5 py-0.5 rounded-full font-semibold flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
              LIVE SERIAL
            </span>
          )}
          {dataSource === "replay" && (
            <span className="text-xs bg-indigo-950 text-indigo-300 border border-indigo-700 px-2.5 py-0.5 rounded-full font-bold">
              REPLAY MODE
            </span>
          )}
          {dataSource === "simulated" && (
            <span className="text-xs bg-purple-950 text-purple-300 border border-purple-700 px-2.5 py-0.5 rounded-full font-bold">
              SIMULATED
            </span>
          )}
        </div>

        {/* View Mode Toggle Button */}
        <div className="flex items-center space-x-2">
          <button
            onClick={() => setViewMode(viewMode === "operator" ? "judge" : "operator")}
            className="flex items-center space-x-1.5 px-3 py-1.5 rounded-md text-xs font-semibold bg-slate-800 hover:bg-slate-700 border border-slate-700 transition"
          >
            <Tv className="w-4 h-4 text-sky-400" />
            <span>Switch to {viewMode === "operator" ? "Judge View" : "Operator View"}</span>
          </button>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 p-6 overflow-y-auto">
        {/* Judge View (FE-08) */}
        {viewMode === "judge" ? (
          <div className="max-w-5xl mx-auto space-y-6">
            {/* Giant Verdict Banner */}
            <div
              className={`p-8 rounded-2xl border-4 text-center shadow-2xl transition-all ${getVerdictColor(
                telemetry?.taskproof.verdict || "NOT_STARTED"
              )}`}
            >
              <div className="text-sm uppercase tracking-widest font-bold opacity-80 mb-2">Current State Verdict</div>
              <div className="text-6xl font-black tracking-tight">{telemetry?.taskproof.verdict || "READY"}</div>
              {telemetry?.taskproof.reason_codes && telemetry.taskproof.reason_codes.length > 0 && (
                <div className="mt-4 text-lg font-mono opacity-90">
                  {telemetry.taskproof.reason_codes.join(" • ")}
                </div>
              )}
            </div>

            {/* Active TaskProof Stage */}
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-6 flex items-center justify-between">
              <div>
                <span className="text-xs uppercase text-slate-400 font-bold tracking-wider">Active Stage</span>
                <div className="text-2xl font-bold text-sky-400 mt-1">{telemetry?.taskproof.state || "READY"}</div>
              </div>
              <div className="text-right">
                <span className="text-xs uppercase text-slate-400 font-bold tracking-wider">Zone Membership</span>
                <div className="text-2xl font-bold text-amber-400 mt-1">
                  Zone {telemetry?.vision?.zone_membership || "none"}
                </div>
              </div>
            </div>

            {/* Recent Verdicts Table */}
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
              <h3 className="text-base font-bold mb-4 flex items-center gap-2">
                <FileCheck className="w-5 h-5 text-sky-400" />
                Recent Verified Attempts
              </h3>
              <div className="divide-y divide-slate-800">
                {attemptHistory.length === 0 ? (
                  <div className="py-6 text-center text-slate-500 text-sm">No attempts executed yet.</div>
                ) : (
                  attemptHistory.slice(0, 5).map((att, idx) => (
                    <div key={idx} className="py-3 flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <span className="font-mono text-xs text-slate-400">{att.time}</span>
                        <span className="font-bold text-sm">{att.id}</span>
                      </div>
                      <span
                        className={`text-xs px-2.5 py-1 rounded font-bold border ${getVerdictColor(att.verdict)}`}
                      >
                        {att.verdict}
                      </span>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        ) : (
          /* Operator View (FE-01 to FE-07) */
          <div className="grid grid-cols-12 gap-6">
            {/* Left Column: Diagnostics & Preflight */}
            <div className="col-span-12 lg:col-span-4 space-y-6">
              {/* Preflight Checklist Card */}
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 shadow-sm">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="font-bold text-sm flex items-center gap-2">
                    <Sliders className="w-4 h-4 text-sky-400" />
                    Preflight System Readiness
                  </h3>
                  <button onClick={fetchPreflight} className="text-xs text-sky-400 hover:underline">
                    Refresh
                  </button>
                </div>
                <div className="space-y-2.5 text-xs">
                  {preflightChecks.map((chk, idx) => (
                    <div key={idx} className="flex items-start justify-between bg-slate-950/60 p-2.5 rounded border border-slate-800/80">
                      <div>
                        <div className="font-semibold">{chk.name}</div>
                        <div className="text-slate-400 text-[11px] mt-0.5">{chk.details}</div>
                      </div>
                      {chk.status === "pass" && <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />}
                      {chk.status === "warn" && <AlertTriangle className="w-4 h-4 text-amber-400 shrink-0" />}
                      {chk.status === "fail" && <XCircle className="w-4 h-4 text-rose-400 shrink-0" />}
                    </div>
                  ))}
                </div>
              </div>

              {/* Ingestion & Telemetry Stats */}
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 text-xs">
                <h3 className="font-bold mb-3 flex items-center gap-2">
                  <Wifi className="w-4 h-4 text-emerald-400" />
                  Stream Ingestion Metrics
                </h3>
                <div className="grid grid-cols-2 gap-3">
                  <div className="bg-slate-950 p-2.5 rounded border border-slate-800">
                    <div className="text-slate-400">Sample Rate</div>
                    <div className="text-lg font-bold text-emerald-400 mt-1">
                      {telemetry?.stats.estimated_rate_hz || 0} Hz
                    </div>
                  </div>
                  <div className="bg-slate-950 p-2.5 rounded border border-slate-800">
                    <div className="text-slate-400">Total Packets</div>
                    <div className="text-lg font-bold text-slate-200 mt-1">{telemetry?.stats.total_packets || 0}</div>
                  </div>
                </div>
              </div>
            </div>

            {/* Right Column: Live TaskProof State & Controls */}
            <div className="col-span-12 lg:col-span-8 space-y-6">
              {/* Active State & Action Buttons */}
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
                <div className="flex flex-col md:flex-row items-center justify-between gap-4">
                  <div>
                    <span className="text-xs uppercase text-slate-400 font-bold">State Machine Status</span>
                    <div className="text-3xl font-extrabold text-sky-400 mt-1">
                      {telemetry?.taskproof.state || "READY"}
                    </div>
                    <div className="text-xs text-slate-400 mt-1">
                      Attempt ID: <span className="font-mono text-slate-200">{telemetry?.taskproof.attempt_id || "None"}</span>
                    </div>
                  </div>

                  {/* Operator Controls */}
                  <div className="flex items-center space-x-3">
                    <button
                      onClick={handleStartAttempt}
                      className="flex items-center gap-1.5 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-lg text-xs font-bold transition"
                    >
                      <Play className="w-4 h-4" /> Start Attempt
                    </button>
                    <button
                      onClick={handleAbortAttempt}
                      className="flex items-center gap-1.5 px-4 py-2 bg-rose-600 hover:bg-rose-500 rounded-lg text-xs font-bold transition"
                    >
                      <StopCircle className="w-4 h-4" /> Abort (Esc)
                    </button>
                  </div>
                </div>

                {/* Hotkey Guide Bar */}
                <div className="mt-5 pt-4 border-t border-slate-800 flex items-center justify-between text-xs text-slate-400">
                  <span>Labelling Hotkeys:</span>
                  <div className="flex items-center space-x-4">
                    <span><kbd className="px-1.5 py-0.5 bg-slate-800 rounded border border-slate-700 text-slate-200 font-bold">S</kbd> Success</span>
                    <span><kbd className="px-1.5 py-0.5 bg-slate-800 rounded border border-slate-700 text-slate-200 font-bold">F</kbd> Failure</span>
                    <span><kbd className="px-1.5 py-0.5 bg-slate-800 rounded border border-slate-700 text-slate-200 font-bold">U</kbd> Uncertain</span>
                    <span><kbd className="px-1.5 py-0.5 bg-slate-800 rounded border border-slate-700 text-slate-200 font-bold">Esc</kbd> Abort</span>
                  </div>
                </div>
              </div>

              {/* Sensor Channel Strip Gauges */}
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-5">
                <h3 className="font-bold text-sm mb-4 flex items-center gap-2">
                  <Activity className="w-4 h-4 text-sky-400" />
                  Live Sensor Channels (Normalized Flexion & Contact)
                </h3>
                <div className="grid grid-cols-4 gap-4 text-xs">
                  {["Thumb Flex", "Index Flex", "Middle Flex", "FSR Contact"].map((name, idx) => {
                    const rawVal = telemetry?.sensor?.flex?.[idx] ?? (idx === 3 ? telemetry?.sensor?.fsr : 0);
                    return (
                      <div key={idx} className="bg-slate-950 p-3 rounded border border-slate-800">
                        <div className="text-slate-400 font-medium">{name}</div>
                        <div className="text-lg font-bold mt-1 text-slate-200">{rawVal ?? "No data"}</div>
                        <div className="w-full bg-slate-800 h-2 rounded-full mt-2 overflow-hidden">
                          <div
                            className="bg-sky-500 h-full transition-all"
                            style={{ width: `${Math.min(100, Math.max(0, ((rawVal || 0) / 25000) * 100))}%` }}
                          />
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Evaluation & Export Actions */}
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 flex items-center justify-between">
                <div>
                  <h4 className="font-bold text-sm">Evidence & Evaluation Bundle</h4>
                  <p className="text-xs text-slate-400 mt-0.5">
                    Exports CSV trial record and SHA-256 verifiable package.
                  </p>
                </div>
                <div className="flex items-center space-x-3">
                  <a
                    href="/api/export/csv"
                    className="flex items-center gap-1.5 px-3 py-1.5 bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded text-xs font-semibold"
                  >
                    <Download className="w-3.5 h-3.5 text-sky-400" /> CSV
                  </a>
                  <a
                    href="/api/export/bundle"
                    className="flex items-center gap-1.5 px-3 py-1.5 bg-sky-600 hover:bg-sky-500 rounded text-xs font-semibold"
                  >
                    <Download className="w-3.5 h-3.5" /> Evidence ZIP
                  </a>
                </div>
              </div>
            </div>
          </div>
        )}
      </main>

      {/* Floating Hotkey Action Toast */}
      {hotkeyToast && (
        <div className="fixed bottom-12 right-6 bg-sky-600 text-white px-4 py-2 rounded-lg shadow-xl text-xs font-bold animate-bounce flex items-center gap-2">
          <CheckCircle2 className="w-4 h-4" />
          {hotkeyToast}
        </div>
      )}

      {/* Mandatory Non-Medical Disclaimer Banner */}
      <footer className="border-t border-slate-800/80 bg-slate-950 px-6 py-2.5 text-center text-xs text-slate-400">
        <span className="font-semibold text-slate-300">DEMONSTRATION PROTOTYPE ONLY:</span> RehabBridge NEXUS / H10 is an engineering demonstration for Innovation 2K26. It is not an FDA-cleared medical device and does not diagnose, treat, or predict clinical recovery.
      </footer>
    </div>
  );
}
