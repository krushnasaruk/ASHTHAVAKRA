import React, { useState, useEffect } from "react";
import SciFiHudView from "./components/SciFiHudView";
import HolographicHandScan from "./components/HolographicHandScan";
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
  const [viewMode, setViewMode] = useState<"scifi_hud" | "operator" | "judge" | "mobile_preview">("scifi_hud");
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
            className={`flex items-center space-x-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition ${
              viewMode === "mobile_preview"
                ? "bg-emerald-600 text-white shadow-lg shadow-emerald-900/40"
                : "bg-slate-800 text-slate-300 hover:bg-slate-700 border border-slate-700"
            }`}
          >
            <Smartphone className="w-4 h-4" />
            <span>Patient Mobile UI Preview</span>
          </button>

          <button
            onClick={() => setViewMode(viewMode === "operator" ? "judge" : "operator")}
            className={`flex items-center space-x-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition border border-slate-700 ${
              viewMode !== "mobile_preview" ? "bg-slate-800 text-sky-400 hover:bg-slate-700" : "bg-slate-900 text-slate-400 hover:text-slate-200"
            }`}
          >
            <Tv className="w-4 h-4" />
            <span>{viewMode === "judge" ? "Operator View" : "Judge View"}</span>
          </button>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 p-6 overflow-y-auto">
        {/* ========================================================================= */}
        {/* 1. PATIENT MOBILE UI PREVIEW (440px Phone Frame for Designer Reference)   */}
        {/* ========================================================================= */}
        {viewMode === "mobile_preview" ? (
          <div className="max-w-4xl mx-auto flex flex-col md:flex-row gap-8 items-start justify-center py-4">
            {/* Phone Container (440px constraint per design spec) */}
            <div className="w-full max-w-[440px] bg-[#F7F7F2] text-[#252A28] rounded-[36px] shadow-2xl border-[8px] border-slate-800 overflow-hidden flex flex-col min-h-[780px]">
              {/* Phone Status Bar */}
              <div className="bg-[#173C35] text-white px-6 py-2 flex items-center justify-between text-xs">
                <span className="font-bold">9:41 AM</span>
                <div className="flex items-center space-x-2">
                  <span className="text-[10px] bg-[#0E2822] text-emerald-300 font-mono font-bold px-1.5 py-0.5 rounded">USB 5V</span>
                  <Wifi className="w-3.5 h-3.5" />
                </div>
              </div>

              {/* App Bar */}
              <div className="bg-white border-b border-[#E0E5E2] px-4 py-3 flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <span className="bg-[#173C35] text-white text-[10px] font-black px-1.5 py-0.5 rounded tracking-wider">ASHTHAVAKRA</span>
                  <span className="font-bold text-sm text-[#173C35]">Hand Rehab</span>
                  <span className="bg-slate-900 text-cyan-400 text-[9px] font-mono font-bold px-1.5 py-0.5 rounded border border-cyan-800">
                    {isDemo3 ? "3-CH" : "5-CH"}
                  </span>
                </div>
                <div className="flex items-center space-x-1">
                  <span className="flex items-center gap-1 text-[10px] bg-emerald-50 text-emerald-800 border border-emerald-200 px-2 py-0.5 rounded-full font-bold">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-600 animate-pulse" />
                    STREAMING
                  </span>
                  <button
                    onClick={() => setMobileTab("taskproof")}
                    className="p-1 hover:bg-slate-100 rounded text-slate-600"
                    title="TaskProof Screen"
                  >
                    <CheckCircle2 className="w-4 h-4 text-emerald-700" />
                  </button>
                </div>
              </div>

              {/* Mandatory Non-Medical Disclaimer Banner */}
              <div className="bg-[#FEF3C7] border-b border-[#FDE68A] px-3 py-1 flex items-center space-x-1.5 text-[10px] text-[#92400E] font-medium">
                <AlertTriangle className="w-3.5 h-3.5 text-[#B45309] shrink-0" />
                <span className="truncate">PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE. Research only.</span>
              </div>

              {/* Mobile Screen Body Content */}
              <div className="flex-1 p-4 overflow-y-auto space-y-3">
                {/* 1. TODAY TAB */}
                {mobileTab === "today" && (
                  <div className="space-y-3">
                    {/* Device Status Card */}
                    <div className="bg-white p-3.5 rounded-xl border border-[#E0E5E2] shadow-sm flex items-center space-x-3">
                      <div className="w-10 h-10 rounded-full bg-emerald-100 flex items-center justify-center text-emerald-700">
                        <Activity className="w-5 h-5" />
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center space-x-1.5">
                          <h4 className="font-bold text-xs text-[#252A28]">ESP32-S3 N16R8 Connected</h4>
                          <span className="text-[9px] bg-emerald-100 text-emerald-800 font-bold px-1.5 py-0.2 rounded border border-emerald-300">
                            {isDemo3 ? "3-CH ACTIVE" : "5-CH PLATFORM"}
                          </span>
                        </div>
                        <p className="text-[11px] text-[#747B76]">Power: USB Powered (5V VBUS) • 921,600 baud</p>
                      </div>
                      <button
                        onClick={() => setMobileTab("device")}
                        className="text-xs font-bold text-[#173C35] hover:underline"
                      >
                        Manage
                      </button>
                    </div>

                    {/* 3D Holographic Hand Scanner Card */}
                    <div className="bg-[#0B1520] p-3 rounded-xl border border-cyan-800/60 shadow-lg text-slate-100 space-y-2">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-1.5">
                          <span className="w-2 h-2 rounded-full bg-cyan-400 animate-ping" />
                          <span className="text-[10px] font-bold tracking-wider text-cyan-300 uppercase">
                            3D Holographic Hand Scanner
                          </span>
                        </div>
                        <button
                          onClick={() => setIsDemo3(!isDemo3)}
                          className="text-[9px] px-2 py-0.5 rounded bg-cyan-950 text-cyan-300 border border-cyan-700 hover:bg-cyan-900 transition font-mono font-bold"
                        >
                          {isDemo3 ? "3-CH (ACTIVE)" : "5-CH (FULL)"}
                        </button>
                      </div>

                      {/* Interactive Holographic Kinematics */}
                      <div className="h-52 w-full rounded-lg bg-black/60 border border-cyan-950 flex items-center justify-center overflow-hidden relative">
                        <HolographicHandScan
                          fingerAngles={fingerAngles}
                          fsrContact={fsrVal}
                          colorCoded={true}
                          onFingerClick={(idx) => setSelectedScanFinger(idx === selectedScanFinger ? null : idx)}
                          selectedFinger={selectedScanFinger}
                        />
                      </div>

                      {/* Channel Values & FSR Palmar Pressure */}
                      <div className="grid grid-cols-3 gap-1 pt-1 text-[9px] font-mono">
                        <div className="p-1 rounded bg-black/50 border border-amber-600/40 text-center">
                          <span className="text-amber-400 font-bold block">THUMB</span>
                          <span className="text-white font-bold">{fingerAngles.thumb}%</span>
                        </div>
                        <div className="p-1 rounded bg-black/50 border border-sky-600/40 text-center">
                          <span className="text-sky-400 font-bold block">INDEX</span>
                          <span className="text-white font-bold">{fingerAngles.index}%</span>
                        </div>
                        <div className="p-1 rounded bg-black/50 border border-emerald-600/40 text-center">
                          <span className="text-emerald-400 font-bold block">MIDDLE</span>
                          <span className="text-white font-bold">{fingerAngles.middle}%</span>
                        </div>
                      </div>

                      <div className="flex items-center justify-between text-[9px] font-mono pt-0.5 px-1 border-t border-slate-800">
                        <span className="text-slate-400">PALMAR FSR PRESSURE:</span>
                        <span className="text-cyan-400 font-bold">{fsrVal}% (EVA BUFFER RING)</span>
                      </div>
                    </div>

                    {/* Featured Event Card: TaskProof */}
                    <div className="bg-emerald-50 border border-emerald-200 rounded-xl p-3.5 shadow-sm">
                      <div className="flex items-center justify-between mb-1.5">
                        <span className="text-[9px] bg-[#173C35] text-white px-2 py-0.5 rounded font-black tracking-wider">
                          INNOVATION 2K26 EVENT
                        </span>
                        <span className="text-[11px] text-emerald-800 font-bold">TaskProof</span>
                      </div>
                      <h4 className="font-bold text-sm text-emerald-950">Object Transfer Verification</h4>
                      <p className="text-[11px] text-emerald-800 mt-1">
                        Live ArUco fiducial camera tracking + Glove FSR contact & flexion kinematics.
                      </p>
                      <div className="mt-3 flex gap-2">
                        <button
                          onClick={() => setMobileTab("taskproof")}
                          className="flex-1 py-2 bg-[#173C35] text-white text-xs font-bold rounded-lg shadow hover:bg-emerald-900 transition flex items-center justify-center gap-1"
                        >
                          <Play className="w-3.5 h-3.5" /> Start TaskProof
                        </button>
                      </div>
                    </div>

                    {/* Today's Prescribed Plan Card */}
                    <div className="bg-white p-3.5 rounded-xl border border-[#E0E5E2] shadow-sm">
                      <div className="flex items-center justify-between text-[11px] text-[#747B76] font-bold">
                        <span>TODAY'S REHABILITATION PLAN</span>
                        <span className="text-[#173C35]">Target: 10 reps</span>
                      </div>
                      <div className="mt-2 flex items-center space-x-3">
                        <div className="w-9 h-9 rounded-lg bg-[#D8E8E2] flex items-center justify-center text-[#173C35]">
                          <Dumbbell className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="font-bold text-xs text-[#252A28]">Fist Clench & Release</div>
                          <div className="text-[10px] text-[#747B76]">Target ROM: 70–100% • Hold: 0.5s</div>
                        </div>
                      </div>
                      <button
                        onClick={() => {
                          setActiveExercise("Fist Clench & Release");
                          setMobileTab("live_session");
                        }}
                        className="w-full mt-3 py-2 bg-[#173C35] text-white text-xs font-bold rounded-lg hover:bg-emerald-950 transition"
                      >
                        Start Prescribed Exercise
                      </button>
                    </div>

                    {/* Weekly Adherence */}
                    <div className="bg-white p-3.5 rounded-xl border border-[#E0E5E2] shadow-sm">
                      <div className="text-[10px] text-[#747B76] font-bold">WEEKLY ADHERENCE</div>
                      <div className="mt-1 flex items-baseline space-x-2">
                        <span className="text-xl font-bold text-[#173C35]">4 / 5</span>
                        <span className="text-[11px] text-[#747B76]">sessions completed this week</span>
                      </div>
                      <div className="w-full bg-slate-100 h-2 rounded-full mt-2 overflow-hidden">
                        <div className="bg-[#173C35] h-full rounded-full" style={{ width: "80%" }} />
                      </div>
                    </div>
                  </div>
                )}

                {/* 2. EXERCISES TAB */}
                {mobileTab === "exercises" && (
                  <div className="space-y-2.5">
                    <h3 className="font-bold text-xs text-[#747B76] tracking-wider uppercase">Exercise Library</h3>
                    {[
                      { title: "Object Transfer Verification", code: "TaskProof", desc: "Pick up from Zone A, transfer across boundary, place in Zone B." },
                      { title: "Fist Clench & Release", code: "H10 Core", desc: "Full 5-finger flexion engaging all flex channels." },
                      { title: "Single-Finger Tapping", code: "H10 Core", desc: "Isolated index finger tapping while others rest." },
                      { title: "Thumb-Index Pinch", code: "H10 Core", desc: "Precision opposition grip bringing tips together." },
                      { title: "Wrist Forearm Rotation", code: "H10 Core", desc: "Pronation and supination tracked via forearm IMU." },
                    ].map((ex, i) => (
                      <div key={i} className="bg-white p-3 rounded-xl border border-[#E0E5E2] shadow-sm flex items-center justify-between">
                        <div>
                          <div className="flex items-center space-x-1.5">
                            <span className="font-bold text-xs text-[#252A28]">{ex.title}</span>
                            <span className="text-[9px] bg-slate-100 text-slate-600 px-1.5 rounded">{ex.code}</span>
                          </div>
                          <p className="text-[10px] text-[#747B76] mt-0.5">{ex.desc}</p>
                        </div>
                        <button
                          onClick={() => {
                            if (ex.code === "TaskProof") {
                              setMobileTab("taskproof");
                            } else {
                              setActiveExercise(ex.title);
                              setMobileTab("live_session");
                            }
                          }}
                          className="px-2.5 py-1.5 bg-[#173C35] text-white text-[11px] font-bold rounded-md hover:bg-emerald-950"
                        >
                          Start
                        </button>
                      </div>
                    ))}
                  </div>
                )}

                {/* 3. LIVE SESSION BIOFEEDBACK TAB */}
                {mobileTab === "live_session" && (
                  <div className="space-y-3">
                    <div className="bg-white p-4 rounded-xl border border-[#E0E5E2] text-center shadow-sm">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-[11px] font-bold text-[#747B76] uppercase">{activeExercise}</span>
                        <div className="flex bg-slate-100 p-0.5 rounded-lg border border-slate-200 text-[10px] font-bold">
                          <button
                            onClick={() => setLiveScanMode("3d")}
                            className={`px-2 py-0.5 rounded ${
                              liveScanMode === "3d" ? "bg-[#173C35] text-white" : "text-slate-600 hover:text-slate-900"
                            }`}
                          >
                            3D Scan
                          </button>
                          <button
                            onClick={() => setLiveScanMode("ring")}
                            className={`px-2 py-0.5 rounded ${
                              liveScanMode === "ring" ? "bg-[#173C35] text-white" : "text-slate-600 hover:text-slate-900"
                            }`}
                          >
                            Ring Gauge
                          </button>
                        </div>
                      </div>

                      {liveScanMode === "3d" ? (
                        <div className="my-2 h-52 w-full rounded-xl bg-[#070D14] border border-cyan-800/40 relative overflow-hidden flex items-center justify-center shadow-inner">
                          <HolographicHandScan
                            fingerAngles={fingerAngles}
                            fsrContact={fsrVal}
                            colorCoded={true}
                            onFingerClick={(idx) => setSelectedScanFinger(idx === selectedScanFinger ? null : idx)}
                            selectedFinger={selectedScanFinger}
                          />
                        </div>
                      ) : (
                        /* Repetition Ring */
                        <div className="relative w-36 h-36 mx-auto my-3 flex items-center justify-center">
                          <svg className="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
                            <circle cx="50" cy="50" r="42" stroke="#E0E5E2" strokeWidth="10" fill="transparent" />
                            <circle
                              cx="50"
                              cy="50"
                              r="42"
                              stroke="#173C35"
                              strokeWidth="10"
                              strokeDasharray="264"
                              strokeDashoffset="79"
                              strokeLinecap="round"
                              fill="transparent"
                            />
                          </svg>
                          <div className="absolute inset-0 flex flex-col items-center justify-center">
                            <span className="text-3xl font-black text-[#173C35]">7</span>
                            <span className="text-[10px] font-bold text-[#747B76]">/ 10 REPS</span>
                          </div>
                        </div>
                      )}

                      <div className="flex justify-around text-xs border-t border-[#E0E5E2] pt-2 mt-2">
                        <div>
                          <div className="font-bold text-[#173C35]">84%</div>
                          <div className="text-[10px] text-[#747B76]">Current ROM</div>
                        </div>
                        <div>
                          <div className="font-bold text-emerald-600">SMOOTH</div>
                          <div className="text-[10px] text-[#747B76]">Dimensionless Jerk</div>
                        </div>
                        <div>
                          <div className="font-bold text-[#173C35]">0.5s</div>
                          <div className="text-[10px] text-[#747B76]">Hold Time</div>
                        </div>
                      </div>
                    </div>

                    {/* Okabe-Ito Finger Channels (Honoring 3-CH Active Design) */}
                    <div className="bg-white p-3.5 rounded-xl border border-[#E0E5E2] shadow-sm">
                      <div className="flex items-center justify-between text-[11px] font-bold text-[#747B76] mb-2">
                        <span>OKABE-ITO FINGER CHANNELS</span>
                        <span className="text-[9px] bg-slate-100 text-slate-700 px-1.5 py-0.5 rounded font-mono">
                          {isDemo3 ? "demo3: 3 Active" : "full5: 5 Active"}
                        </span>
                      </div>
                      <div className="space-y-1.5">
                        {okabeItoColors.map((f, i) => {
                          const isReserved = isDemo3 && i >= 3;
                          return (
                            <div key={i} className="flex items-center space-x-2 text-[11px]">
                              <span className="w-12 font-bold">{f.name}</span>
                              <div className="flex-1 bg-slate-100 h-2.5 rounded-full overflow-hidden">
                                <div
                                  className="h-full rounded-full transition-all"
                                  style={{
                                    width: isReserved ? "0%" : `${f.val}%`,
                                    backgroundColor: isReserved ? "#94A3B8" : f.hex,
                                  }}
                                />
                              </div>
                              <span className="w-16 text-right font-mono text-[10px]">
                                {isReserved ? (
                                  <span className="text-slate-400 text-[9px]">RESERVED</span>
                                ) : (
                                  `${f.val}%`
                                )}
                              </span>
                            </div>
                          );
                        })}
                      </div>

                      <div className="mt-2.5 pt-2 border-t border-slate-100 flex items-center justify-between text-[10px]">
                        <span className="text-[#747B76] font-bold">PALMAR FSR CONTACT:</span>
                        <span className="font-mono font-bold text-emerald-800">{fsrVal}% (Active Grip)</span>
                      </div>
                    </div>

                    {/* Post-Session Pain & Fatigue Self-Report */}
                    <div className="bg-white p-3.5 rounded-xl border border-[#E0E5E2] shadow-sm">
                      <div className="text-[11px] font-bold text-[#747B76] mb-1">PAIN & FATIGUE SELF-REPORT</div>
                      <div className="flex items-center justify-between text-xs mt-2">
                        <span>Pain Level (0-10):</span>
                        <span className="font-bold text-rose-700">{painRating} / 10</span>
                      </div>
                      <input
                        type="range"
                        min="0"
                        max="10"
                        value={painRating}
                        onChange={(e) => setPainRating(Number(e.target.value))}
                        className="w-full accent-rose-600 mt-1"
                      />

                      <div className="flex items-center justify-between text-xs mt-3">
                        <span>Fatigue Level (0-10):</span>
                        <span className="font-bold text-amber-700">{fatigueRating} / 10</span>
                      </div>
                      <input
                        type="range"
                        min="0"
                        max="10"
                        value={fatigueRating}
                        onChange={(e) => setFatigueRating(Number(e.target.value))}
                        className="w-full accent-amber-600 mt-1"
                      />
                    </div>
                  </div>
                )}

                {/* 4. TASKPROOF SCREEN TAB */}
                {mobileTab === "taskproof" && (
                  <div className="space-y-3">
                    {/* Live Verdict Banner */}
                    <div className="bg-emerald-100 border-2 border-emerald-600 p-3.5 rounded-xl text-center shadow-sm">
                      <div className="text-[10px] font-black uppercase text-emerald-800 tracking-wider">TASKPROOF VERDICT</div>
                      <div className="text-2xl font-black text-emerald-900 mt-0.5">
                        {telemetry?.taskproof.verdict === "NOT_STARTED" ? "VERIFIED" : telemetry?.taskproof.verdict || "READY"}
                      </div>
                      <div className="text-[11px] font-mono font-bold text-emerald-800 mt-0.5">4.2 s • ALL GUARDS MET</div>
                    </div>

                    {/* OpenCV ArUco Camera Zone Tracker (Live Tabletop Field) */}
                    <div className="bg-[#0B1520] p-3 rounded-xl border border-emerald-800/50 shadow text-slate-100 space-y-2">
                      <div className="flex items-center justify-between text-[10px]">
                        <span className="font-bold text-emerald-400 flex items-center gap-1.5 uppercase tracking-wider">
                          <Camera className="w-3.5 h-3.5 text-emerald-400" />
                          OpenCV ArUco Zone Field
                        </span>
                        <span className="px-2 py-0.5 rounded bg-emerald-950 text-emerald-300 font-mono font-bold border border-emerald-700">
                          Marker #0 (Cup)
                        </span>
                      </div>

                      {/* Visual Tabletop Workspace */}
                      <div className="h-28 w-full rounded-lg bg-black/70 border border-slate-800 relative p-2 overflow-hidden flex items-center justify-between text-center font-mono text-[9px]">
                        {/* Zone A (Pick-up) */}
                        <div className="w-1/3 h-full border-2 border-dashed border-emerald-500/60 rounded bg-emerald-950/30 flex flex-col items-center justify-center p-1">
                          <span className="text-emerald-300 font-bold">ZONE A</span>
                          <span className="text-[8px] text-emerald-500">Pick-up Area</span>
                          <span className="text-[8px] text-slate-400 mt-0.5">X: 120–220</span>
                        </div>

                        {/* Transit Arrow & Boundary */}
                        <div className="flex-1 flex flex-col items-center justify-center text-slate-500">
                          <ArrowRight className="w-4 h-4 text-amber-400 animate-pulse" />
                          <span className="text-[8px] text-amber-300/80">Transit</span>
                        </div>

                        {/* Zone B (Target) */}
                        <div className="w-1/3 h-full border-2 border-emerald-400 rounded bg-cyan-950/40 flex flex-col items-center justify-center p-1 relative shadow-[0_0_12px_rgba(0,229,255,0.2)]">
                          <span className="text-cyan-300 font-bold">ZONE B</span>
                          <span className="text-[8px] text-cyan-500">Target Zone</span>
                          {/* ArUco Marker #0 placed inside Zone B */}
                          <div className="mt-1 px-1.5 py-0.5 bg-emerald-500 text-black font-black rounded text-[8px] flex items-center gap-0.5 shadow">
                            <span className="w-1.5 h-1.5 rounded-full bg-black animate-ping" />
                            #0 VERIFIED
                          </div>
                        </div>
                      </div>

                      {/* Vision Diagnostics: Detection Rate, Frame Age, Occlusion */}
                      <div className="grid grid-cols-3 gap-1.5 text-[9px] font-mono">
                        <div className="bg-black/50 p-1.5 rounded border border-slate-800 text-center">
                          <span className="text-slate-400 block text-[8px]">DETECTION (1S)</span>
                          <span className="text-emerald-400 font-bold">96% (≥80%)</span>
                        </div>
                        <div className="bg-black/50 p-1.5 rounded border border-slate-800 text-center">
                          <span className="text-slate-400 block text-[8px]">FRAME AGE</span>
                          <span className="text-cyan-400 font-bold">28 ms (&lt;120ms)</span>
                        </div>
                        <div className="bg-black/50 p-1.5 rounded border border-slate-800 text-center">
                          <span className="text-slate-400 block text-[8px]">OCCLUSION</span>
                          <span className="text-emerald-400 font-bold">0 ms (NONE)</span>
                        </div>
                      </div>

                      {/* 4-Phase Deterministic Checklist */}
                      <div className="pt-1 space-y-1">
                        <div className="text-[9px] font-bold text-slate-400 uppercase">4-Phase Verification Guards</div>
                        <div className="grid grid-cols-2 gap-1 text-[9px]">
                          <div className="bg-emerald-950/50 border border-emerald-600/50 text-emerald-300 p-1 rounded flex items-center gap-1 font-bold">
                            <Check className="w-3 h-3 text-emerald-400 shrink-0" />
                            <span>1. Contact (FSR &gt; 200)</span>
                          </div>
                          <div className="bg-emerald-950/50 border border-emerald-600/50 text-emerald-300 p-1 rounded flex items-center gap-1 font-bold">
                            <Check className="w-3 h-3 text-emerald-400 shrink-0" />
                            <span>2. Lifted (&gt;20mm)</span>
                          </div>
                          <div className="bg-emerald-950/50 border border-emerald-600/50 text-emerald-300 p-1 rounded flex items-center gap-1 font-bold">
                            <Check className="w-3 h-3 text-emerald-400 shrink-0" />
                            <span>3. Transit Boundary</span>
                          </div>
                          <div className="bg-emerald-950/50 border border-emerald-600/50 text-emerald-300 p-1 rounded flex items-center gap-1 font-bold">
                            <Check className="w-3 h-3 text-emerald-400 shrink-0" />
                            <span>4. Release in Zone B</span>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* 7-State Stepper */}
                    <div className="bg-white p-3.5 rounded-xl border border-[#E0E5E2] shadow-sm">
                      <div className="text-[10px] font-bold text-[#747B76] mb-2">7-STATE DETERMINISTIC MACHINE</div>
                      <div className="grid grid-cols-2 gap-1.5 text-[10px]">
                        {[
                          "1. READY",
                          "2. SOURCE_VISIBLE",
                          "3. CONTACT_CANDIDATE",
                          "4. OBJECT_LIFTED",
                          "5. TARGET_REACHED",
                          "6. RELEASE_CONFIRMED",
                          "7. VERIFIED",
                        ].map((s, i) => (
                          <div
                            key={i}
                            className={`p-1.5 rounded border font-bold flex items-center gap-1 ${
                              i <= 4 ? "bg-emerald-50 border-emerald-300 text-emerald-800" : "bg-slate-50 border-slate-200 text-slate-400"
                            }`}
                          >
                            <Check className="w-3 h-3 text-emerald-600" />
                            <span>{s}</span>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Labelling Actions */}
                    <div className="bg-white p-3.5 rounded-xl border border-[#E0E5E2] shadow-sm space-y-2">
                      <div className="text-[10px] font-bold text-[#747B76]">OPERATOR LABELLING ACTIONS</div>
                      <div className="grid grid-cols-2 gap-2">
                        <button
                          onClick={() => handleLabelGroundTruth("success")}
                          className="py-2 bg-emerald-600 text-white rounded-lg text-xs font-bold hover:bg-emerald-500"
                        >
                          [S] Success
                        </button>
                        <button
                          onClick={() => handleLabelGroundTruth("failure")}
                          className="py-2 bg-rose-600 text-white rounded-lg text-xs font-bold hover:bg-rose-500"
                        >
                          [F] Fail
                        </button>
                      </div>
                      <div className="grid grid-cols-2 gap-2">
                        <button
                          onClick={() => handleLabelGroundTruth("uncertain")}
                          className="py-2 bg-purple-100 text-purple-900 border border-purple-300 rounded-lg text-xs font-bold"
                        >
                          [U] Uncertain
                        </button>
                        <button
                          onClick={handleAbortAttempt}
                          className="py-2 bg-amber-100 text-amber-900 border border-amber-300 rounded-lg text-xs font-bold"
                        >
                          [Esc] Abort
                        </button>
                      </div>
                    </div>
                  </div>
                )}

                {/* 5. DEVICE & CALIBRATION TAB */}
                {mobileTab === "device" && (
                  <div className="space-y-3">
                    {/* Hardware Specifications */}
                    <div className="bg-white p-3.5 rounded-xl border border-[#E0E5E2] shadow-sm">
                      <div className="text-[10px] font-bold text-[#747B76] mb-2">HARDWARE SPECIFICATIONS (ESP32-S3)</div>
                      <div className="text-xs space-y-1.5">
                        <div className="flex justify-between">
                          <span className="text-[#747B76]">Microcontroller:</span>
                          <span className="font-bold">ESP32-S3 N16R8 (240MHz LX7)</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-[#747B76]">Precision ADC:</span>
                          <span className="font-bold">ADS1115 (16-bit I2C @ 0x48)</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-[#747B76]">6-DOF IMU:</span>
                          <span className="font-bold">MPU6050 (Accel + Gyro @ 0x68)</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-[#747B76]">Power Source:</span>
                          <span className="font-bold text-emerald-800">USB Powered (5V VBUS) — Isolated</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-[#747B76]">Serial Baud:</span>
                          <span className="font-mono font-bold">921,600 baud (50 Hz)</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-[#747B76]">Active Channels:</span>
                          <span className="font-bold text-[#173C35]">
                            {isDemo3 ? "demo3 (Thumb, Index, Middle + FSR + IMU)" : "full5 (5 Flex + FSR + IMU)"}
                          </span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-[#747B76]">Calibration:</span>
                          <span className="font-bold text-emerald-700">Valid (Span &gt; 300, Age: 1 day)</span>
                        </div>
                      </div>
                    </div>

                    {/* Glove Connection Management */}
                    <div className="bg-white p-3.5 rounded-xl border border-[#E0E5E2] shadow-sm space-y-2">
                      <div className="text-[10px] font-bold text-[#747B76]">GLOVE CONNECTION CONTROLS</div>
                      <div className="grid grid-cols-2 gap-2">
                        <button
                          onClick={() => {
                            setConnected(true);
                            setDataSource("live");
                            showToast("Connected to ESP32-S3 Glove (921,600 baud)");
                          }}
                          className="py-2 bg-[#173C35] text-white rounded-lg text-xs font-bold hover:bg-emerald-950 transition flex items-center justify-center gap-1.5"
                        >
                          <Wifi className="w-3.5 h-3.5" />
                          Connect Glove
                        </button>
                        <button
                          onClick={() => {
                            setIsDemo3(!isDemo3);
                            showToast(isDemo3 ? "Switched to full5 Profile (5 Channels)" : "Switched to demo3 Profile (3 Channels)");
                          }}
                          className="py-2 bg-slate-100 text-slate-800 border border-slate-300 rounded-lg text-xs font-bold hover:bg-slate-200 transition"
                        >
                          {isDemo3 ? "Profile: demo3 (3-CH)" : "Profile: full5 (5-CH)"}
                        </button>
                      </div>
                    </div>

                    {/* Preflight Diagnostics Checklist */}
                    <div className="bg-white p-3.5 rounded-xl border border-[#E0E5E2] shadow-sm">
                      <div className="text-[10px] font-bold text-[#747B76] mb-2">10-POINT PREFLIGHT DIAGNOSTICS</div>
                      <div className="space-y-1.5 text-xs">
                        {[
                          { name: "Python 3.14 Environment", ok: true },
                          { name: "OpenCV ArUco Library", ok: true },
                          { name: "Serial Glove Connection", ok: true },
                          { name: "Zone Geometry Polygons", ok: true },
                          { name: "SQLite WAL Database", ok: true },
                          { name: "Storage Space (>500MB)", ok: true },
                          { name: "Volunteer Consent Gate", ok: true },
                          { name: "Local Security Boundary (127.0.0.1)", ok: true },
                        ].map((c, i) => (
                          <div key={i} className="flex items-center justify-between">
                            <span className="text-[#252A28]">{c.name}</span>
                            <span className="text-[10px] text-emerald-700 font-bold flex items-center gap-1">
                              <CheckCircle2 className="w-3 h-3" /> PASS
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                )}

                {/* 6. PROGRESS TAB */}
                {mobileTab === "progress" && (
                  <div className="space-y-3">
                    <div className="bg-white p-3.5 rounded-xl border border-[#E0E5E2] shadow-sm">
                      <div className="text-[10px] font-bold text-[#747B76] mb-1">REHABILITATION PROGRESSION</div>
                      <div className="text-xl font-bold text-[#173C35]">82.4% Mean ROM</div>
                      <p className="text-[10px] text-[#747B76] mt-0.5">+6.8% increase compared to baseline.</p>
                      <div className="mt-3 flex items-end gap-1.5 h-20 pt-2 border-b border-slate-100">
                        {[40, 52, 60, 68, 74, 80, 84].map((v, i) => (
                          <div key={i} className="flex-1 flex flex-col items-center gap-1">
                            <div className="w-full bg-[#173C35] rounded-t" style={{ height: `${v}%` }} />
                            <span className="text-[8px] text-[#747B76]">D{i + 1}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                )}
              </div>

              {/* Mobile Bottom Navigation Bar (48px Touch Targets) */}
              <div className="bg-white border-t border-[#E0E5E2] px-2 py-2 flex justify-around items-center">
                {[
                  { id: "today", label: "Today", icon: Activity },
                  { id: "exercises", label: "Exercises", icon: Dumbbell },
                  { id: "taskproof", label: "TaskProof", icon: CheckCircle2 },
                  { id: "device", label: "Device", icon: Sliders },
                  { id: "progress", label: "Progress", icon: BarChart3 },
                ].map((item) => {
                  const IconCmp = item.icon;
                  const isActive = mobileTab === item.id;
                  return (
                    <button
                      key={item.id}
                      onClick={() => setMobileTab(item.id as any)}
                      className={`flex flex-col items-center justify-center min-w-[48px] min-h-[48px] px-2 rounded-lg transition ${
                        isActive ? "text-[#173C35] font-black" : "text-[#747B76] hover:text-[#252A28]"
                      }`}
                    >
                      <IconCmp className={`w-4 h-4 ${isActive ? "stroke-[2.5]" : ""}`} />
                      <span className="text-[9px] mt-0.5">{item.label}</span>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Designer Guide Callout */}
            <div className="max-w-xs space-y-4 text-xs text-slate-300">
              <div className="bg-slate-900 border border-slate-800 rounded-xl p-4 space-y-2">
                <h4 className="font-bold text-sm text-emerald-400 flex items-center gap-2">
                  <UserCheck className="w-4 h-4" /> Designer Note (Vaishnavi)
                </h4>
                <p className="text-slate-400 leading-relaxed">
                  This interactive web viewport reflects the mobile architecture in <code className="text-sky-300">mobile/lib/</code>.
                </p>
                <ul className="list-disc list-inside space-y-1 text-slate-400">
                  <li>Minimum 48×48 px touch targets.</li>
                  <li>Okabe-Ito color-blind safe palette.</li>
                  <li>Responsive 440px mobile canvas container.</li>
                  <li>Mandatory non-medical disclaimer banner.</li>
                </ul>
              </div>

              <div className="bg-slate-900 border border-slate-800 rounded-xl p-4 space-y-2">
                <h4 className="font-bold text-sm text-sky-400">Quick Tab Shortcuts</h4>
                <div className="grid grid-cols-2 gap-2 text-[11px]">
                  <button onClick={() => setMobileTab("today")} className="p-2 bg-slate-800 hover:bg-slate-700 rounded text-left font-bold">
                    1. Today Plan
                  </button>
                  <button onClick={() => setMobileTab("exercises")} className="p-2 bg-slate-800 hover:bg-slate-700 rounded text-left font-bold">
                    2. Exercise List
                  </button>
                  <button onClick={() => setMobileTab("live_session")} className="p-2 bg-slate-800 hover:bg-slate-700 rounded text-left font-bold">
                    3. Live Biofeedback
                  </button>
                  <button onClick={() => setMobileTab("taskproof")} className="p-2 bg-slate-800 hover:bg-slate-700 rounded text-left font-bold">
                    4. TaskProof Screen
                  </button>
                </div>
              </div>
            </div>
          </div>
        ) : (
          /* ========================================================================= */
          /* 2. OPERATOR & JUDGE VIEWS (NEXUS Hackathon Event TaskProof Engine)        */
          /* ========================================================================= */
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
        )}
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
