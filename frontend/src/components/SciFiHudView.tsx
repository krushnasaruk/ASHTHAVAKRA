import React, { useState, useEffect } from "react";
import HolographicHandScan, { FingerAngles } from "./HolographicHandScan";
import WaveformMonitor from "./WaveformMonitor";
import FirmwareTerminal from "./FirmwareTerminal";
import {
  AlertTriangle,
  ChevronLeft,
  ChevronRight,
  Maximize2,
  Volume2,
  VolumeX,
  Radio,
  Sliders,
  Play,
  RotateCcw,
  Zap,
} from "lucide-react";

interface SciFiHudViewProps {
  onSwitchView?: (view: "operator" | "judge" | "mobile_preview") => void;
  telemetry?: any;
  isConnected?: boolean;
}

export default function SciFiHudView({
  onSwitchView,
  telemetry,
  isConnected = false,
}: SciFiHudViewProps) {
  // Finger flex angles (0 - 100%)
  const [fingerAngles, setFingerAngles] = useState<FingerAngles>({
    thumb: 82,
    index: 94,
    middle: 78,
    ring: 65,
    pinky: 55,
  });

  // Sound & visual effects
  const [soundEnabled, setSoundEnabled] = useState(false);
  const [warningMode, setWarningMode] = useState(false);
  const [colorCoded, setColorCoded] = useState(false);
  const [selectedFinger, setSelectedFinger] = useState<number | null>(null);
  const [activeExercise, setActiveExercise] = useState<string>("manual");
  const [scanlinesActive, setScanlinesActive] = useState(true);

  // Patient metadata state
  const [patientName, setPatientName] = useState("JOHN DOE");
  const [crewName, setCrewName] = useState("SULACO / H10");
  const [orderId, setOrderId] = useState("SO. 939");
  const [locationName, setLocationName] = useState("LV - 426");

  // Synthesize subtle sci-fi beep via Web Audio API
  const playSciFiBeep = (freq = 880, type: OscillatorType = "sine") => {
    if (!soundEnabled) return;
    try {
      const audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = type;
      osc.frequency.setValueAtTime(freq, audioCtx.currentTime);
      gain.gain.setValueAtTime(0.04, audioCtx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.12);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start();
      osc.stop(audioCtx.currentTime + 0.12);
    } catch (e) {
      // AudioContext policy
    }
  };

  // Sync with live telemetry if available
  useEffect(() => {
    if (telemetry?.sensor?.flex && telemetry.sensor.flex.length >= 5) {
      setFingerAngles({
        thumb: Math.round(telemetry.sensor.flex[0]),
        index: Math.round(telemetry.sensor.flex[1]),
        middle: Math.round(telemetry.sensor.flex[2]),
        ring: Math.round(telemetry.sensor.flex[3]),
        pinky: Math.round(telemetry.sensor.flex[4]),
      });
    }
  }, [telemetry]);

  // Exercise Animation loop
  useEffect(() => {
    if (activeExercise === "manual") return;

    let step = 0;
    const interval = setInterval(() => {
      step += 0.08;
      if (activeExercise === "clench") {
        // Fist clench & release sinusoidal wave (15% to 95%)
        const s = (Math.sin(step) + 1) / 2;
        const val = 15 + s * 80;
        setFingerAngles({
          thumb: Math.round(val * 0.9),
          index: Math.round(val),
          middle: Math.round(val * 1.02),
          ring: Math.round(val * 0.95),
          pinky: Math.round(val * 0.88),
        });
      } else if (activeExercise === "pinch") {
        // Pinch grip (Thumb + Index close, others neutral)
        const s = (Math.sin(step) + 1) / 2;
        setFingerAngles({
          thumb: Math.round(20 + s * 75),
          index: Math.round(20 + s * 80),
          middle: 30,
          ring: 25,
          pinky: 20,
        });
      } else if (activeExercise === "wave") {
        // Finger wave (propagating phase shift across digits)
        setFingerAngles({
          thumb: Math.round(20 + ((Math.sin(step) + 1) / 2) * 75),
          index: Math.round(20 + ((Math.sin(step + 0.6) + 1) / 2) * 75),
          middle: Math.round(20 + ((Math.sin(step + 1.2) + 1) / 2) * 75),
          ring: Math.round(20 + ((Math.sin(step + 1.8) + 1) / 2) * 75),
          pinky: Math.round(20 + ((Math.sin(step + 2.4) + 1) / 2) * 75),
        });
      }
    }, 60);

    return () => clearInterval(interval);
  }, [activeExercise]);

  const handleFingerChange = (key: keyof FingerAngles, val: number) => {
    setActiveExercise("manual");
    setFingerAngles((prev) => ({ ...prev, [key]: val }));
    playSciFiBeep(600 + val * 5);
  };

  const okabeItoColors = ["#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2"];
  const fingerKeys: (keyof FingerAngles)[] = ["thumb", "index", "middle", "ring", "pinky"];
  const fingerLabels = ["THUMB (T-01)", "INDEX (I-02)", "MIDDLE (M-03)", "RING (R-04)", "PINKY (P-05)"];

  return (
    <div className={`relative min-h-screen bg-[#07080c] text-amber-100 flex flex-col font-sans select-none overflow-x-hidden ${scanlinesActive ? "scanlines" : ""}`}>
      {/* ========================================================================= */}
      {/* 1. TOP HEADER & SCI-FI BRANDING (MATCHING TOP BAR IN REFERENCE IMAGE)     */}
      {/* ========================================================================= */}
      <header className="border-b border-amber-950/80 bg-black/70 backdrop-blur-md px-4 py-2 z-30">
        <div className="flex items-center justify-between">
          {/* Left: Yellow Badge [A] + OBJECT IDENTIFICATION .. 01 */}
          <div className="flex items-center space-x-3">
            <div className="bg-amber-400 text-black px-2 py-0.5 font-hud font-black text-xs tracking-wider rounded-sm shadow-[0_0_8px_rgba(251,191,36,0.6)]">
              A
            </div>
            <div className="text-xs font-hud tracking-[0.2em] text-amber-200 font-bold uppercase flex items-center gap-2">
              <span>OBJECT IDENTIFICATION .. 01</span>
              <span className="text-[10px] text-amber-500 font-tech font-normal">
                [ ASHTHAVAKRA H10 PROTOCOL ]
              </span>
            </div>
          </div>

          {/* Right: Weyland-Yutani Style Wings Logo & Control Icons */}
          <div className="flex items-center space-x-4">
            {/* Weyland-Yutani Style Insignia SVG */}
            <div className="flex items-center space-x-1.5 opacity-90">
              <svg width="34" height="18" viewBox="0 0 34 18" fill="none" className="text-amber-400">
                <path
                  d="M1 2 L7 16 L12 5 L17 16 L22 5 L27 16 L33 2"
                  stroke="#fbbf24"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
                <circle cx="17" cy="16" r="1.5" fill="#fbbf24" />
              </svg>
              <span className="text-[9px] font-hud tracking-widest text-amber-400/80 hidden sm:inline">
                W-Y / NEXUS
              </span>
            </div>

            {/* Top Navigation & Action Icons */}
            <div className="flex items-center space-x-1 border-l border-amber-900/60 pl-3 text-amber-400 text-xs">
              <button
                onClick={() => {
                  playSciFiBeep(750);
                  setActiveExercise("wave");
                }}
                className="p-1 hover:text-amber-200 hover:bg-amber-950/40 rounded"
                title="Previous / Cycle Wave"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <button
                onClick={() => {
                  playSciFiBeep(850);
                  setActiveExercise("clench");
                }}
                className="p-1 hover:text-amber-200 hover:bg-amber-950/40 rounded"
                title="Next / Cycle Clench"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
              <button
                onClick={() => setSoundEnabled(!soundEnabled)}
                className={`p-1 rounded ${soundEnabled ? "text-amber-300" : "text-amber-700 hover:text-amber-400"}`}
                title={soundEnabled ? "Mute HUD Audio" : "Enable HUD Audio"}
              >
                {soundEnabled ? <Volume2 className="w-4 h-4" /> : <VolumeX className="w-4 h-4" />}
              </button>
              <button
                onClick={() => setScanlinesActive(!scanlinesActive)}
                className={`p-1 text-[10px] font-tech border px-1.5 rounded ${
                  scanlinesActive ? "border-amber-500 text-amber-300 bg-amber-950/30" : "border-amber-900 text-amber-700"
                }`}
                title="Toggle CRT Scanline Overlay"
              >
                CRT
              </button>
            </div>
          </div>
        </div>

        {/* Amber Thin Line with "HALF DEVICE", "RES. [ ]", "PLS - 7" (Direct from Image) */}
        <div className="mt-2 pt-1.5 border-t border-amber-900/60 flex items-center justify-between text-[9px] font-tech text-amber-500 tracking-wider">
          <div className="flex items-center space-x-6">
            <span className="hover:text-amber-300 cursor-pointer">HALF DEVICE</span>
            <span className="text-amber-400/90 font-bold">RES. [ 50Hz STREAM ]</span>
            <span className="hidden sm:inline">SERIAL 921K BAUD</span>
          </div>

          <div className="flex items-center space-x-6">
            <span className="text-amber-400 font-bold">PLS - 7</span>
            <span className="cursor-pointer hover:text-amber-300">CODE DIAG</span>
            <span className="text-amber-600">✕</span>
          </div>
        </div>
      </header>

      {/* ========================================================================= */}
      {/* 2. SUB-HEADER METADATA STRIP                                              */}
      {/* ========================================================================= */}
      <div className="border-b border-amber-950/60 bg-black/40 px-6 py-2 flex flex-wrap items-center justify-between text-xs font-tech">
        {/* Left: UNKNOWN OBJECT / REC: 249/13 - 63 */}
        <div>
          <div className="font-hud font-bold text-sm text-amber-300 tracking-widest flex items-center gap-2">
            <span>ASHTHAVAKRA H10 BIO-KINETIC HAND</span>
            {isConnected && (
              <span className="text-[10px] text-emerald-400 font-tech flex items-center gap-1 font-bold">
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
                ONLINE
              </span>
            )}
          </div>
          <div className="text-[10px] text-amber-600 tracking-wider">
            REC: 249/13 - 63 • BIO-METRIC TELEMETRY ENGINE
          </div>
        </div>

        {/* Center Navigation Sections: STAT: OPEN, 01 - MASTER, 02 - MODULE */}
        <div className="flex items-center space-x-6 text-[11px] text-amber-500/80">
          <div className="flex items-center space-x-1.5">
            <span>STAT:</span>
            <span className="text-amber-300 font-bold">OPEN</span>
            <span className="w-2 h-2 bg-amber-400 rounded-sm animate-pulse" />
          </div>

          <div className="flex items-center space-x-1 text-amber-300 font-semibold border-b border-amber-400/50 pb-0.5">
            <span className="text-amber-500">::</span>
            <span>01 - MASTER SECTION</span>
          </div>

          <div className="hidden md:flex items-center space-x-2 text-amber-600">
            <span>02 - MODULE SECTION</span>
            <span className="text-amber-400 font-bold border border-amber-700 px-1 py-0.2 rounded text-[9px]">02</span>
            <span className="text-amber-400 font-bold border border-amber-700 px-1 py-0.2 rounded text-[9px]">03</span>
          </div>
        </div>

        {/* Right: NOTICE CP - 40 / CP - 67 */}
        <div className="text-right text-[10px] text-amber-500/70 font-tech">
          <span>NOTICE. CP - 40 / CP - 67</span>
          <div className="text-[9px] text-amber-700">CP - 48 / NCF</div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 3. MAIN WORKSPACE: CENTER HOLOGRAPHIC SCAN & RIGHT HUD DIAGNOSTIC PANEL   */}
      {/* ========================================================================= */}
      <main className="flex-1 grid grid-cols-1 lg:grid-cols-12 min-h-0 relative">
        {/* ----------------------------------------------------------------------- */}
        {/* LEFT / CENTER STAGE (Cols 1-8): HOLOGRAPHIC HAND SCAN & CONTROLS        */}
        {/* ----------------------------------------------------------------------- */}
        <div className="lg:col-span-8 flex flex-col items-center justify-between p-4 relative min-h-[640px] border-b lg:border-b-0 lg:border-r border-amber-950/80">
          {/* Floating Top Left Mode Indicator */}
          <div className="absolute top-4 left-6 z-10 flex flex-col space-y-1">
            <div className="flex items-center space-x-2">
              <span className="text-2xl font-black text-amber-300 font-hud tracking-tight">
                OBJ: BIO-KINETIC HAND
              </span>
            </div>
            <span className="text-[10px] text-amber-500 font-tech tracking-widest uppercase">
              5-FINGER FLEX CURVATURE + 6-DOF IMU WRIST TELEMETRY
            </span>
          </div>

          {/* Quick Exercise Presets Floating Toolbar (Top Right of hand scan) */}
          <div className="absolute top-4 right-6 z-10 flex flex-wrap gap-1.5 max-w-sm justify-end">
            {[
              { id: "manual", label: "Manual Sliders" },
              { id: "clench", label: "Fist Clench" },
              { id: "pinch", label: "Pinch Grip" },
              { id: "wave", label: "Finger Wave" },
            ].map((ex) => (
              <button
                key={ex.id}
                onClick={() => {
                  setActiveExercise(ex.id);
                  playSciFiBeep(ex.id === "manual" ? 500 : 700);
                }}
                className={`px-2.5 py-1 text-[10px] font-hud uppercase tracking-wider rounded transition-all border ${
                  activeExercise === ex.id
                    ? "bg-amber-400 text-black border-amber-300 font-bold shadow-[0_0_10px_rgba(251,191,36,0.5)]"
                    : "bg-black/60 text-amber-400 border-amber-900/60 hover:border-amber-600 hover:text-amber-200"
                }`}
              >
                {ex.label}
              </button>
            ))}
          </div>

          {/* Center Holographic Hand Rendering */}
          <div className="w-full flex-1 flex items-center justify-center my-4">
            <HolographicHandScan
              fingerAngles={fingerAngles}
              warningState={warningMode}
              colorCoded={colorCoded}
              selectedFinger={selectedFinger}
              onFingerClick={(idx) => {
                setSelectedFinger(idx === selectedFinger ? null : idx);
                playSciFiBeep(800 + idx * 100);
              }}
            />
          </div>

          {/* Interactive 5-Channel Sliders (Bottom of Center Stage) */}
          <div className="w-full max-w-2xl bg-black/75 p-3 rounded-lg border border-amber-900/50 backdrop-blur z-10 space-y-2">
            <div className="flex items-center justify-between text-[11px] font-tech text-amber-400">
              <span className="flex items-center gap-1.5 font-bold tracking-wider">
                <Sliders className="w-3.5 h-3.5" /> 5-CHANNEL FLEX TELEMETRY SLIDERS
              </span>
              <div className="flex items-center space-x-3">
                <button
                  onClick={() => setColorCoded(!colorCoded)}
                  className={`text-[9px] px-2 py-0.5 rounded border transition ${
                    colorCoded ? "bg-amber-400 text-black border-amber-300 font-bold" : "border-amber-800 text-amber-500"
                  }`}
                >
                  {colorCoded ? "Okabe-Ito Colors ON" : "Pure Amber Glow"}
                </button>
                <button
                  onClick={() => {
                    setWarningMode(!warningMode);
                    playSciFiBeep(warningMode ? 440 : 880, "sawtooth");
                  }}
                  className={`text-[9px] px-2 py-0.5 rounded border transition font-bold ${
                    warningMode
                      ? "bg-rose-600 text-white border-rose-400 shadow-[0_0_8px_rgba(244,63,94,0.6)]"
                      : "border-amber-800 text-amber-500 hover:text-amber-300"
                  }`}
                >
                  {warningMode ? "ALARM ACTIVE" : "Toggle Alert"}
                </button>
              </div>
            </div>

            {/* Slider Bars for 5 Digits */}
            <div className="grid grid-cols-5 gap-2 pt-1">
              {fingerKeys.map((key, i) => (
                <div key={key} className="space-y-1">
                  <div className="flex justify-between text-[9px] font-tech text-amber-300/80">
                    <span className="font-bold">{fingerLabels[i].split(" ")[0]}</span>
                    <span className="text-amber-400 font-mono">{fingerAngles[key]}%</span>
                  </div>
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={fingerAngles[key]}
                    onChange={(e) => handleFingerChange(key, Number(e.target.value))}
                    className="w-full h-1.5 bg-amber-950 rounded-lg appearance-none cursor-pointer accent-amber-400"
                  />
                  <div
                    className="h-1 rounded-full opacity-60"
                    style={{ backgroundColor: colorCoded ? okabeItoColors[i] : "#f59e0b" }}
                  />
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* ----------------------------------------------------------------------- */}
        {/* RIGHT HUD PANEL (Cols 9-12): EXACT WARNING, VITAL TELEMETRY & GRAPHS   */}
        {/* ----------------------------------------------------------------------- */}
        <div className="lg:col-span-4 bg-black/60 p-5 flex flex-col space-y-4 overflow-y-auto">
          {/* 1. Large Yellow Hazard Warning Triangle with `!` */}
          <div className="flex items-center space-x-4">
            <div className="relative">
              {/* Glowing Triangle Icon */}
              <div
                className={`w-14 h-14 rounded-lg flex items-center justify-center border-2 ${
                  warningMode
                    ? "border-rose-500 bg-rose-950/40 text-rose-400 hud-box-glow-red"
                    : "border-amber-400 bg-amber-950/30 text-amber-400 hud-box-glow"
                }`}
              >
                <AlertTriangle className="w-9 h-9 stroke-[2.5]" />
              </div>
            </div>

            <div className="flex-1">
              <div className="text-[10px] font-tech text-amber-500 tracking-widest flex items-center justify-between">
                <span>SPECIMEN CODE</span>
                <span className="text-amber-400 font-bold">SO. 939</span>
              </div>
              <h2 className="text-xl font-hud font-black text-amber-300 tracking-wider">
                {warningMode ? "MOTOR FATIGUE" : "ASHTHAVAKRA H10"}
              </h2>
              <p className="text-[9px] font-tech text-amber-600 uppercase tracking-widest">
                AI-ASSISTED REHABILITATION KINEMATICS
              </p>
            </div>
          </div>

          {/* 2. Chip Badges: [LEVEL 0] [LEVEL 2] [ACTIVE] >> SESSION SAVED > */}
          <div className="flex flex-wrap items-center gap-1.5 text-[9px] font-tech">
            <span className="px-1.5 py-0.5 bg-black border border-amber-900/80 text-amber-400 rounded">
              LEVEL 0
            </span>
            <span className="px-1.5 py-0.5 bg-black border border-amber-900/80 text-amber-400 rounded">
              LEVEL 2
            </span>
            <span className="px-1.5 py-0.5 bg-amber-400 text-black font-bold rounded">
              ACTIVE
            </span>
            <span className="text-amber-500 ml-auto font-tech">
              &gt;&gt; SESSION SAVED &gt;
            </span>
          </div>

          {/* 3. Striped Warning Box: WARNING /// (Direct from image) */}
          <div
            className={`p-3 rounded border text-black font-black flex items-center justify-between shadow-lg ${
              warningMode ? "hazard-stripes-danger text-white" : "hazard-stripes"
            }`}
          >
            <div>
              <div className="text-2xl font-hud tracking-[0.2em]">
                {warningMode ? "CRITICAL ///" : "WARNING ///"}
              </div>
              <div className="text-[9px] font-tech tracking-wider opacity-90">
                SO. 249/10.63 - 375.29 BEL
              </div>
            </div>
            <span className="bg-black/80 text-amber-300 px-2 py-1 text-[10px] font-hud rounded border border-amber-400/50">
              [REVIEW]
            </span>
          </div>

          {/* Subtitle: CALL: 01, OBJECT: P37-U */}
          <div className="flex justify-between text-[9px] font-tech text-amber-600 px-1">
            <span>CALL: 01</span>
            <span>OBJECT: P37-U ■ SEC03</span>
          </div>

          {/* 4. Critical Status Box: ✕ INFECTED / ACTIVE REHAB ✕ */}
          <div
            className={`py-2 px-3 rounded border text-center font-hud font-bold tracking-[0.3em] text-sm uppercase transition-all ${
              warningMode
                ? "bg-rose-950/60 border-rose-500 text-rose-300 shadow-[0_0_15px_rgba(244,63,94,0.4)]"
                : "bg-amber-950/40 border-amber-500/80 text-amber-300"
            }`}
          >
            {warningMode ? "✕ FATIGUE DETECTED ✕" : "✕ SYNCHRONIZED ✕"}
          </div>

          {/* 5. Diagnostic Tracking Breakdown Table (Direct from image layout) */}
          <div className="bg-black/75 rounded border border-amber-900/60 p-2.5 font-tech text-[10px] text-amber-300/90 space-y-1">
            <div className="flex items-center justify-between text-amber-500 border-b border-amber-950 pb-1 mb-1">
              <div className="flex items-center space-x-2">
                <span>AUT ■</span>
                <span>MAN</span>
              </div>
              <div className="flex items-center space-x-2">
                <span>TRCK: 001</span>
                <span className="bg-amber-400 text-black font-bold px-1 rounded text-[9px]">354</span>
                <span>STAT: -1</span>
              </div>
            </div>

            {/* 5 Finger Channel Diagnostic Rows */}
            {[
              { code: "DIGIT 01: THUMB", val: "249-1063", tag: "001", active: true },
              { code: "DIGIT 02: INDEX", val: "249-1063", tag: "002", active: true },
              { code: "DIGIT 03: MIDDLE", val: "249-1063", tag: "003", active: true },
              { code: "SCAN: [OK] RING", val: "000-0001", tag: "004", active: false },
              { code: "DIGIT 05: PINKY", val: "249-1063", tag: "005", active: true },
            ].map((row, idx) => (
              <div
                key={idx}
                className="flex items-center justify-between py-0.5 px-1 hover:bg-amber-950/30 rounded"
              >
                <span className={idx === 3 ? "text-amber-500 font-bold" : "text-amber-200"}>
                  {row.code}
                </span>
                <span className="text-amber-500 font-mono text-[9px]">{row.val}</span>
                <span className="text-amber-400 font-mono font-bold text-[9px]">{row.tag}</span>
              </div>
            ))}
          </div>

          {/* 6. Embedded Firmware / Code Telemetry Stream */}
          <div>
            <FirmwareTerminal flexValues={Object.values(fingerAngles)} />
          </div>

          {/* 7. Biomechanical Metrics & Glowing ECG Kinematic Waveform Monitor */}
          <div className="bg-black/60 p-3 rounded border border-amber-900/60">
            <WaveformMonitor
              heartRate={Math.round(85 + (fingerAngles.index / 100) * 20)}
              jerkIndex={38.6}
              romMax={145}
              romMin={96}
              isAlert={warningMode}
            />
          </div>

          {/* View Mode Switching Pills (for Easy Navigation to Operator & Mobile) */}
          <div className="pt-2 border-t border-amber-950/80 flex flex-col space-y-1.5 text-xs font-hud">
            <span className="text-[9px] text-amber-600 font-tech uppercase tracking-wider">
              SWITCH APPLICATION INTERFACE:
            </span>
            <div className="grid grid-cols-2 gap-2">
              <button
                onClick={() => onSwitchView?.("operator")}
                className="py-1.5 px-2 bg-amber-950/50 hover:bg-amber-900/60 border border-amber-700/60 rounded text-amber-300 text-[10px] font-bold transition text-center"
              >
                Operator View
              </button>
              <button
                onClick={() => onSwitchView?.("mobile_preview")}
                className="py-1.5 px-2 bg-amber-950/50 hover:bg-amber-900/60 border border-amber-700/60 rounded text-amber-300 text-[10px] font-bold transition text-center"
              >
                Mobile UI (440px)
              </button>
            </div>
          </div>
        </div>
      </main>

      {/* ========================================================================= */}
      {/* 4. FOOTER: PATIENT METADATA, TELEMETRY GAUGES, BOTTOM BUTTONS             */}
      {/* ========================================================================= */}
      <footer className="border-t border-amber-950/80 bg-black/90 px-6 py-2.5 z-30">
        <div className="flex flex-wrap items-center justify-between gap-4 text-xs font-tech">
          {/* Segmented Telemetry Scale: 10 30 50 70 90 + A+ Progress */}
          <div className="flex items-center space-x-3">
            <div className="flex items-center space-x-2 text-[10px] text-amber-500 font-mono">
              <span>10</span>
              <span>30</span>
              <span>50</span>
              <span>70</span>
              <span className="text-amber-300 font-bold">90</span>
            </div>
            <div className="flex items-center space-x-1">
              <span className="text-amber-400 font-bold text-[10px]">A+</span>
              <div className="w-24 h-2 bg-amber-950 rounded overflow-hidden flex border border-amber-900/60">
                <div className="bg-amber-400 h-full w-[85%]" />
              </div>
            </div>
          </div>

          {/* Patient & Mission Metadata (Movie Lore / Clinical Telemetry) */}
          <div className="flex flex-wrap items-center gap-4 text-[10px] text-amber-400/90 font-tech">
            <div>
              <span className="text-amber-600 mr-1">I PATIENT:</span>
              <span className="font-bold text-amber-200">{patientName}</span>
            </div>
            <div>
              <span className="text-amber-600 mr-1">I CREW:</span>
              <span className="font-bold text-amber-200">{crewName}</span>
            </div>
            <div>
              <span className="text-amber-600 mr-1">I ORDER:</span>
              <span className="font-bold text-amber-200">{orderId}</span>
            </div>
            <div>
              <span className="text-amber-600 mr-1">I LOCATION:</span>
              <span className="font-bold text-amber-200">{locationName}</span>
            </div>
          </div>

          {/* Bottom Action Buttons: SETUP, LOG FILE, OFFLINE */}
          <div className="flex items-center space-x-2 text-[10px] font-hud">
            <span className="text-amber-500 font-tech hidden sm:inline">
              MESSAGE: [ SCANNED ]
            </span>
            <button
              onClick={() => playSciFiBeep(650)}
              className="px-2.5 py-1 bg-amber-950/60 hover:bg-amber-900 border border-amber-700/80 rounded text-amber-300 uppercase tracking-wider"
            >
              SETUP
            </button>
            <button
              onClick={() => playSciFiBeep(700)}
              className="px-2.5 py-1 bg-amber-950/60 hover:bg-amber-900 border border-amber-700/80 rounded text-amber-300 uppercase tracking-wider"
            >
              LOG FILE
            </button>
            <button
              onClick={() => playSciFiBeep(750)}
              className="px-2.5 py-1 bg-amber-400 text-black font-bold rounded uppercase tracking-wider shadow-[0_0_8px_rgba(251,191,36,0.5)]"
            >
              {isConnected ? "LIVE" : "SIMULATED"}
            </button>
          </div>
        </div>

        {/* Mandatory Non-Medical Disclaimer Banner */}
        <div className="mt-2 pt-1 border-t border-amber-950/40 text-center text-[9px] font-tech text-amber-600/80">
          PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE. Ashthavakra H10 is an experimental research telemetry interface for physical therapy monitoring. Not for medical diagnosis or clinical treatment.
        </div>
      </footer>
    </div>
  );
}
