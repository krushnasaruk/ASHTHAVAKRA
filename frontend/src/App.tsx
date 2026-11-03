import React, { useState, useEffect } from "react";
import SciFiHudView from "./components/SciFiHudView";
import HolographicHandScan from "./components/HolographicHandScan";
import PaytinMobileApp from "./components/PaytinMobileApp";
import {
  Activity,
  AlertTriangle,
  ArrowRight,
  BarChart3,
  Camera,
  Check,
  CheckCircle2,
  ChevronRight,
  Download,
  Dumbbell,
  Eye,
  FileCheck,
  Flame,
  HeartPulse,
  HelpCircle,
  Play,
  Radio,
  RefreshCw,
  RotateCcw,
  ShieldCheck,
  Sliders,
  Smartphone,
  StopCircle,
  Tv,
  UserCheck,
  Wifi,
  X,
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
  const [viewMode, setViewMode] = useState<"scifi_hud" | "operator" | "judge" | "mobile_preview">("mobile_preview");
  const [dataSource, setDataSource] = useState<"live" | "replay" | "simulated">("live");

  // Mobile App Preview Navigation State
  const [mobileTab, setMobileTab] = useState<"today" | "exercises" | "live_session" | "taskproof" | "device" | "progress">("today");
  const [painRating, setPainRating] = useState(2);
  const [fatigueRating, setFatigueRating] = useState(3);
  const [activeExercise, setActiveExercise] = useState("Fist Clench & Release");
  const [isDemo3, setIsDemo3] = useState(true); // Competition active profile (Thumb, Index, Middle + FSR + IMU)
  const [selectedScanFinger, setSelectedScanFinger] = useState<number | null>(null);
  const [liveScanMode, setLiveScanMode] = useState<"3d" | "ring">("3d");

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

          if (data.taskproof && data.taskproof.verdict !== "NOT_STARTED") {
            const v = data.taskproof.verdict;
            const attId = data.taskproof.attempt_id || "att-curr";
            setAttemptHistory((prev) => {
              if (prev.some((a) => a.id === attId)) return prev;
              return [
                {
                  id: attId,
                  verdict: v,
                  reasons: data.taskproof.reason_codes || [],
                  duration: 4.8,
                  time: new Date().toLocaleTimeString(),
                },
                ...prev.slice(0, 4),
              ];
            });
          }
        } catch (e) {
          console.error("Telemetry parse error", e);
        }
      };

      ws.onclose = () => {
        setConnected(false);
        timer = setTimeout(connectWs, 3000);
      };

      ws.onerror = () => {
        setConnected(false);
      };
    };

    connectWs();
    fetchPreflight();

    return () => {
      if (ws) ws.close();
      clearTimeout(timer);
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
      console.warn("Preflight fetch failed", e);
    }
  };

  const showToast = (msg: string) => {
    setHotkeyToast(msg);
    setTimeout(() => setHotkeyToast(null), 2500);
  };

  // Keyboard hotkey handler
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (["input", "textarea"].includes((e.target as HTMLElement)?.tagName.toLowerCase())) {
        return;
      }
      switch (e.key.toUpperCase()) {
        case "S":
          handleLabelGroundTruth("success");
          break;
        case "F":
          handleLabelGroundTruth("failure");
          break;
        case "U":
          handleLabelGroundTruth("uncertain");
          break;
        case "ESCAPE":
          handleAbortAttempt();
          break;
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [telemetry]);

  const handleLabelGroundTruth = async (label: string) => {
    const attemptId = telemetry?.taskproof.attempt_id;
    if (!attemptId) {
      showToast(`Hotkey [${label.toUpperCase()}]: No active attempt ID`);
      return;
    }
    try {
      await fetch(`/api/tasks/${attemptId}/ground-truth`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          attempt_id: attemptId,
          label: label,
          marker_source: "operator_key",
          labeller_pseudonym: "operator_web",
        }),
      });
      showToast(`Marked ${label.toUpperCase()} for ${attemptId}`);
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
        return "bg-purple-600 border-purple-400 text-white";
      case "ABORTED":
        return "bg-slate-700 border-slate-500 text-slate-200";
      default:
        return "bg-slate-800 border-slate-700 text-slate-300";
    }
  };

  // Okabe-Ito color palette
  const okabeItoColors = [
    { name: "Thumb", hex: "#E69F00", val: 82 },
    { name: "Index", hex: "#56B4E9", val: 94 },
    { name: "Middle", hex: "#009E73", val: 78 },
    { name: "Ring", hex: "#E4C41B", val: 65 },
    { name: "Pinky", hex: "#0072B2", val: 55 },
  ];

  const fingerAngles = {
    thumb: telemetry?.sensor?.flex?.[0] ?? 82,
    index: telemetry?.sensor?.flex?.[1] ?? 94,
    middle: telemetry?.sensor?.flex?.[2] ?? 78,
    ring: isDemo3 ? 0 : (telemetry?.sensor?.flex?.[3] ?? 35),
    pinky: isDemo3 ? 0 : (telemetry?.sensor?.flex?.[4] ?? 20),
  };
  const fsrVal = telemetry?.sensor?.fsr ?? 55;

  if (viewMode === "scifi_hud") {
    return (
      <SciFiHudView
        onSwitchView={setViewMode}
        telemetry={telemetry}
        isConnected={connected}
      />
    );
  }

  if (viewMode === "mobile_preview") {
    return (
      <div className="min-h-screen bg-[#ECEFE6] text-[#161C19] flex flex-col font-sans select-none relative overflow-x-hidden">
        {/* Subtle grid pattern background */}
        <div
          className="absolute inset-0 pointer-events-none opacity-40"
          style={{
            backgroundImage: `radial-gradient(#CBD4C0 1.2px, transparent 1.2px)`,
            backgroundSize: "28px 28px",
          }}
        />

        {/* Large watermark outline typography in background like reference image */}
        <div className="absolute top-24 right-8 text-[120px] font-black text-black/[0.03] tracking-widest pointer-events-none select-none font-sans uppercase">
          SECURE
        </div>
        <div className="absolute bottom-12 left-8 text-[140px] font-black text-black/[0.03] tracking-widest pointer-events-none select-none font-sans uppercase">
          TRUSTED
        </div>

        {/* Top Header matching reference image: ✦ ASHTHAVAKRA | Rehabilitation Mobile App | www.ashthavakra.rehab */}
        <header className="relative z-20 px-8 py-4 flex items-center justify-between border-b border-black/[0.06] backdrop-blur-sm">
          {/* Left: Brand logo with star/flower icon */}
          <div className="flex items-center space-x-2">
            <div className="w-6 h-6 rounded-full bg-[#121715] text-[#C8F05F] flex items-center justify-center font-black text-xs shadow-sm">
              ✦
            </div>
            <span className="font-black text-base tracking-tight text-[#121715]">
              ASHTHAVAKRA
            </span>
          </div>

          {/* Center: "Rehabilitation Mobile App" title */}
          <div className="hidden md:block text-xs font-semibold tracking-wider text-[#646E68] uppercase">
            Hand Rehabilitation Mobile App
          </div>

          {/* Right: URL & View switcher controls */}
          <div className="flex items-center space-x-3">
            <span className="hidden sm:inline text-xs font-mono text-[#7A857E]">
              www.ashthavakra.rehab
            </span>

            <div className="flex items-center space-x-1.5 pl-2 border-l border-black/10">
              <button
                onClick={() => setViewMode("scifi_hud")}
                className="text-[11px] font-bold px-3 py-1 rounded-full bg-black/5 hover:bg-black/10 text-[#121715] transition"
              >
                Sci-Fi HUD
              </button>
              <button
                onClick={() => setViewMode("judge")}
                className="text-[11px] font-bold px-3 py-1 rounded-full bg-black/5 hover:bg-black/10 text-[#121715] transition"
              >
                Judge View
              </button>
            </div>
          </div>
        </header>

        {/* Main Body: The Paytin Mobile Experience */}
        <main className="relative z-10 flex-1 p-4 md:p-8 flex items-center justify-center">
          <PaytinMobileApp
            telemetry={telemetry}
            isConnected={connected}
            onTriggerTaskProof={handleStartAttempt}
            onLabelGroundTruth={handleLabelGroundTruth}
            onAbortAttempt={handleAbortAttempt}
          />
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col bg-slate-950 text-slate-100 font-sans">
      {/* Top Header & Mode Toggle */}
      <header className="border-b border-slate-800 bg-slate-900/90 backdrop-blur px-6 py-3 flex items-center justify-between sticky top-0 z-50">
        <div className="flex items-center space-x-3">
          <Activity className="h-6 w-6 text-emerald-400" />
          <div>
            <div className="flex items-center space-x-2">
              <span className="bg-[#173C35] text-white font-black text-xs px-2 py-0.5 rounded tracking-wider border border-emerald-500/50">
                ASHTHAVAKRA
              </span>
              <h1 className="text-base font-bold tracking-tight">RehabBridge NEXUS / H10</h1>
              <span className="text-[10px] bg-slate-800 text-slate-400 px-1.5 py-0.5 rounded border border-slate-700">v3.0.0</span>
            </div>
            <p className="text-[11px] text-slate-400">Hand Rehabilitation Platform • Innovation 2K26</p>
          </div>

          <div className="hidden lg:flex items-center space-x-2 ml-4">
            <span className="text-xs bg-sky-950/80 text-cyan-400 border border-cyan-700/60 px-2.5 py-0.5 rounded-full font-semibold flex items-center gap-1.5 font-mono">
              <span className="w-1.5 h-1.5 rounded-full bg-cyan-400 animate-pulse" />
              ESP32-S3 N16R8 ({isDemo3 ? "3-CH ACTIVE" : "5-CH PLATFORM"})
            </span>
            <span className="text-xs bg-emerald-950/80 text-emerald-300 border border-emerald-700/60 px-2.5 py-0.5 rounded-full font-semibold">
              USB Powered (5V VBUS)
            </span>
          </div>

          {/* Data Source Badge */}
          {dataSource === "live" && (
            <span className="text-xs bg-emerald-950/80 text-emerald-400 border border-emerald-700/60 px-2.5 py-0.5 rounded-full font-semibold flex items-center gap-1.5 ml-2 font-mono">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping" />
              921600 BAUD
            </span>
          )}
        </div>

        {/* View Mode Navigation Switcher */}
        <div className="flex items-center space-x-2">
          <button
            onClick={() => setViewMode("scifi_hud")}
            className="flex items-center space-x-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition border border-amber-600/70 bg-amber-950/40 text-amber-300 hover:bg-amber-900/60 shadow-[0_0_10px_rgba(251,191,36,0.25)]"
          >
            <Radio className="w-4 h-4 text-amber-400" />
            <span>Sci-Fi Holographic HUD</span>
          </button>

          <button
            onClick={() => setViewMode("mobile_preview")}
            className="flex items-center space-x-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition bg-[#C8F05F] text-[#121715] hover:bg-[#b8e64c] shadow-sm"
          >
            <Smartphone className="w-4 h-4" />
            <span>Mobile UI Showcase</span>
          </button>

          <button
            onClick={() => setViewMode(viewMode === "operator" ? "judge" : "operator")}
            className="flex items-center space-x-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition border border-slate-700 bg-slate-800 text-sky-400 hover:bg-slate-700"
          >
            <Tv className="w-4 h-4" />
            <span>{viewMode === "judge" ? "Operator View" : "Judge View"}</span>
          </button>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 p-6 overflow-y-auto">
        <div>
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
                      {telemetry?.vision?.zone_membership || "ZONE_A"}
                    </div>
                  </div>
                </div>

                {/* Last 5 Attempts Card */}
                <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
                  <h3 className="font-bold text-sm text-slate-400 mb-4 tracking-wider uppercase">Last 5 Attempts History</h3>
                  <div className="space-y-2">
                    {attemptHistory.length === 0 ? (
                      <div className="text-slate-500 text-xs">No attempts recorded in this session yet.</div>
                    ) : (
                      attemptHistory.map((att, idx) => (
                        <div
                          key={idx}
                          className="flex items-center justify-between p-3 bg-slate-950 rounded-lg border border-slate-800 text-xs font-mono"
                        >
                          <span className="text-slate-400">{att.id}</span>
                          <span className="text-slate-500">{att.time}</span>
                          <span className={`px-2 py-0.5 rounded font-bold text-[10px] ${getVerdictColor(att.verdict)}`}>
                            {att.verdict}
                          </span>
                        </div>
                      ))
                    )}
                  </div>
                </div>
              </div>
            ) : (
              /* OPERATOR VIEW */
              <div className="max-w-6xl mx-auto grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Left Column: Diagnostics & Preflight */}
                <div className="space-y-6">
                  <div className="bg-slate-900 border border-slate-800 rounded-xl p-5">
                    <h3 className="font-bold text-sm mb-3 flex items-center justify-between">
                      <span className="flex items-center gap-2">
                        <FileCheck className="w-4 h-4 text-emerald-400" />
                        System Preflight Checks
                      </span>
                      <button onClick={fetchPreflight} className="text-slate-400 hover:text-white">
                        <RotateCcw className="w-3.5 h-3.5" />
                      </button>
                    </h3>
                    <div className="space-y-2 text-xs">
                      {preflightChecks.map((chk, i) => (
                        <div key={i} className="flex items-start justify-between p-2 bg-slate-950 rounded border border-slate-800/80">
                          <div>
                            <div className="font-semibold text-slate-200">{chk.name}</div>
                            <div className="text-[10px] text-slate-400">{chk.details}</div>
                          </div>
                          <span
                            className={`px-1.5 py-0.5 rounded text-[10px] font-bold uppercase ${
                              chk.status === "pass"
                                ? "bg-emerald-950 text-emerald-400 border border-emerald-800"
                                : chk.status === "warn"
                                ? "bg-amber-950 text-amber-400 border border-amber-800"
                                : "bg-rose-950 text-rose-400 border border-rose-800"
                            }`}
                          >
                            {chk.status}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>

                {/* Center & Right Columns: TaskProof State & Live Stream */}
                <div className="lg:col-span-2 space-y-6">
                  <div className="bg-slate-900 border border-slate-800 rounded-xl p-5">
                    <div className="flex items-center justify-between mb-4">
                      <div>
                        <span className="text-xs text-slate-400 uppercase font-bold tracking-wider">State Machine Lifecycle</span>
                        <h2 className="text-xl font-black text-sky-400 mt-0.5">{telemetry?.taskproof.state || "READY"}</h2>
                      </div>
                      <div className="flex items-center space-x-2">
                        <button
                          onClick={handleStartAttempt}
                          className="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-600 hover:bg-emerald-500 rounded-lg text-xs font-bold transition"
                        >
                          <Play className="w-3.5 h-3.5" /> Start Attempt
                        </button>
                        <button
                          onClick={handleAbortAttempt}
                          className="flex items-center gap-1.5 px-3 py-1.5 bg-rose-600 hover:bg-rose-500 rounded-lg text-xs font-bold transition"
                        >
                          <StopCircle className="w-3.5 h-3.5" /> Abort (Esc)
                        </button>
                      </div>
                    </div>

                    {/* Sensor Strip */}
                    <div className="grid grid-cols-4 gap-3 text-xs">
                      {["Thumb Flex", "Index Flex", "Middle Flex", "FSR Contact"].map((name, idx) => {
                        const rawVal = telemetry?.sensor?.flex?.[idx] ?? (idx === 3 ? telemetry?.sensor?.fsr : 0);
                        return (
                          <div key={idx} className="bg-slate-950 p-2.5 rounded border border-slate-800">
                            <div className="text-slate-400 text-[11px]">{name}</div>
                            <div className="text-base font-bold mt-0.5 text-slate-200">{rawVal ?? "No data"}</div>
                          </div>
                        );
                      })}
                    </div>

                    {/* Evaluation & Export Actions */}
                    <div className="mt-5 pt-4 border-t border-slate-800 flex items-center justify-between">
                      <div className="text-xs text-slate-400">
                        Exports ground truth trials and SHA-256 verifiable manifest.
                      </div>
                      <div className="flex items-center space-x-2">
                        <a
                          href="/api/export/csv"
                          className="flex items-center gap-1 px-3 py-1.5 bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded text-xs font-semibold"
                        >
                          <Download className="w-3 h-3 text-sky-400" /> CSV
                        </a>
                        <a
                          href="/api/export/bundle"
                          className="flex items-center gap-1 px-3 py-1.5 bg-sky-600 hover:bg-sky-500 rounded text-xs font-semibold"
                        >
                          <Download className="w-3 h-3" /> Evidence ZIP
                        </a>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
      </main>

      {/* Floating Hotkey Action Toast */}
      {hotkeyToast && (
        <div className="fixed bottom-12 right-6 bg-sky-600 text-white px-4 py-2 rounded-lg shadow-xl text-xs font-bold animate-bounce flex items-center gap-2 z-50">
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
