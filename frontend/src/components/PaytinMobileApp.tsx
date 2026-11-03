import React, { useState } from "react";
import HolographicHandScan from "./HolographicHandScan";
import {
  Activity,
  AlertTriangle,
  ArrowRight,
  ArrowUpRight,
  BarChart2,
  BarChart3,
  Bell,
  Camera,
  Check,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  Dumbbell,
  FileCheck,
  Flame,
  Hand,
  HeartPulse,
  Layers,
  MoreHorizontal,
  Play,
  Plus,
  QrCode,
  Radio,
  RotateCcw,
  Scan,
  ShieldCheck,
  Sliders,
  Sparkles,
  Target,
  TrendingUp,
  UserCheck,
  Wifi,
  X,
} from "lucide-react";

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

interface PaytinMobileAppProps {
  telemetry: TelemetryPayload | null;
  isConnected: boolean;
  onTriggerTaskProof?: () => void;
  onLabelGroundTruth?: (label: "success" | "failure" | "uncertain") => void;
  onAbortAttempt?: () => void;
}

export default function PaytinMobileApp({
  telemetry,
  isConnected,
  onTriggerTaskProof,
  onLabelGroundTruth,
  onAbortAttempt,
}: PaytinMobileAppProps) {
  // Navigation & Screen States
  const [activeScreen, setActiveScreen] = useState<"onboarding" | "home" | "statistics" | "taskproof" | "live_session" | "device">("home");
  const [showTriptych, setShowTriptych] = useState<boolean>(true);
  const [statsPeriod, setStatsPeriod] = useState<"today" | "weekly" | "monthly" | "yearly">("weekly");
  const [isDemo3, setIsDemo3] = useState<boolean>(true);
  const [selectedFinger, setSelectedFinger] = useState<number | null>(null);
  const [painRating, setPainRating] = useState<number>(2);
  const [fatigueRating, setFatigueRating] = useState<number>(3);
  const [liveScanMode, setLiveScanMode] = useState<"3d" | "ring">("3d");

  // Okabe-Ito colors for the 5 fingers
  const okabeItoColors = [
    { name: "Thumb", hex: "#E69F00", val: 82, active: true },
    { name: "Index", hex: "#56B4E9", val: 94, active: true },
    { name: "Middle", hex: "#009E73", val: 78, active: true },
    { name: "Ring", hex: "#F0E442", val: 35, active: !isDemo3 },
    { name: "Pinky", hex: "#0072B2", val: 20, active: !isDemo3 },
  ];

  const fingerAngles = {
    thumb: telemetry?.sensor?.flex?.[0] ?? 82,
    index: telemetry?.sensor?.flex?.[1] ?? 94,
    middle: telemetry?.sensor?.flex?.[2] ?? 78,
    ring: isDemo3 ? 0 : (telemetry?.sensor?.flex?.[3] ?? 35),
    pinky: isDemo3 ? 0 : (telemetry?.sensor?.flex?.[4] ?? 20),
  };
  const fsrVal = telemetry?.sensor?.fsr ?? 55;

  // Care Team Avatars
  const careTeam = [
    { name: "Vaishnavi", role: "UX / UI Design", initials: "VJ", color: "bg-[#C8F05F] text-black" },
    { name: "Rajendra", role: "Firmware / HW", initials: "RP", color: "bg-sky-200 text-sky-900" },
    { name: "Gautam", role: "Biomechanics", initials: "GS", color: "bg-amber-200 text-amber-900" },
    { name: "Krushna", role: "Backend / Signals", initials: "KS", color: "bg-emerald-200 text-emerald-900" },
    { name: "Dr. Joshi", role: "Physiatrist", initials: "DJ", color: "bg-purple-200 text-purple-900" },
  ];

  // Recent Activity Log
  const activities = [
    {
      title: "TaskProof Object Transfer",
      subtitle: "Zone A ➔ Zone B • Verified",
      time: "Today, 11:20 AM",
      badge: "VERIFIED (4.2s)",
      badgeColor: "bg-[#C8F05F] text-[#161C19] border border-[#A6E22E]",
      icon: CheckCircle2,
    },
    {
      title: "Fist Clench & Release",
      subtitle: "10 / 10 Reps • 84% Mean ROM",
      time: "Today, 10:45 AM",
      badge: "+84% ROM",
      badgeColor: "bg-emerald-100 text-emerald-900 border border-emerald-300",
      icon: Dumbbell,
    },
    {
      title: "Single-Finger Tapping",
      subtitle: "Isolated Index Kinematics",
      time: "Yesterday, 4:15 PM",
      badge: "92% SMOOTH",
      badgeColor: "bg-slate-100 text-slate-800 border border-slate-300",
      icon: Activity,
    },
    {
      title: "Hardware Zero-Offset",
      subtitle: "Span: 420 (>300 Valid)",
      time: "2 Nov, 9:00 AM",
      badge: "CALIBRATED",
      badgeColor: "bg-cyan-100 text-cyan-900 border border-cyan-300",
      icon: RotateCcw,
    },
  ];

  // Radar Polygon Points Generator for 5 fingers
  const renderRadarPolygon = () => {
    const center = 75;
    const radius = 55;
    const numPoints = 5;
    const values = [
      (fingerAngles.thumb / 100) * radius,
      (fingerAngles.index / 100) * radius,
      (fingerAngles.middle / 100) * radius,
      ((isDemo3 ? 20 : fingerAngles.ring) / 100) * radius,
      ((isDemo3 ? 20 : fingerAngles.pinky) / 100) * radius,
    ];

    const points = values.map((val, idx) => {
      const angle = (Math.PI * 2 / numPoints) * idx - Math.PI / 2;
      const x = center + Math.cos(angle) * val;
      const y = center + Math.sin(angle) * val;
      return `${x},${y}`;
    }).join(" ");

    return points;
  };

  /* ========================================================================= */
  /* 1. SCREEN 1: SPLASH / ONBOARDING ("Digital Banking Made for...")          */
  /* ========================================================================= */
  const renderOnboardingScreen = () => (
    <div className="w-full h-full bg-[#C8F05F] text-[#121715] flex flex-col justify-between p-6 select-none relative overflow-hidden font-sans">
      {/* Background Subtle Wave & Glow Elements */}
      <div className="absolute top-12 -right-8 w-44 h-44 rounded-full bg-white/20 blur-2xl pointer-events-none" />
      <div className="absolute bottom-28 -left-10 w-44 h-44 rounded-full bg-[#A6E22E]/30 blur-2xl pointer-events-none" />

      {/* Top Floating Badge & Status */}
      <div className="pt-2 z-10 flex items-center justify-between text-xs font-bold">
        <div className="flex items-center gap-1.5 bg-black/10 backdrop-blur px-2.5 py-1 rounded-full">
          <span className="w-2 h-2 rounded-full bg-[#121715]" />
          <span>ASHTHAVAKRA</span>
        </div>
        <span className="text-[11px] font-mono tracking-wider bg-black/5 px-2 py-0.5 rounded-full">
          NEXUS H10
        </span>
      </div>

      {/* Main Playful Line Illustration (Adapted from Reference Illustration) */}
      <div className="my-auto py-4 flex flex-col items-center justify-center relative z-10">
        <div className="relative w-56 h-56 flex items-center justify-center">
          {/* Decorative floating chips and radio waves */}
          <div className="absolute -top-3 left-4 p-2 bg-white/60 backdrop-blur rounded-2xl shadow-sm border border-black/5 rotate-[-12deg]">
            <Radio className="w-4 h-4 text-[#121715]" />
          </div>
          <div className="absolute top-8 -right-2 p-2 bg-[#121715] text-[#C8F05F] rounded-2xl shadow-sm rotate-[14deg]">
            <Sparkles className="w-4 h-4" />
          </div>
          <div className="absolute -bottom-2 right-6 p-2 bg-white/60 backdrop-blur rounded-2xl shadow-sm border border-black/5 rotate-[-6deg]">
            <Activity className="w-4 h-4 text-[#121715]" />
          </div>

          {/* SVG Character / Bionic Hand Vector */}
          <svg viewBox="0 0 200 200" className="w-full h-full text-[#121715]">
            {/* Outline Stylized Arm & Tactile Cylinder */}
            <rect x="40" y="80" width="120" height="75" rx="18" fill="white" stroke="#121715" strokeWidth="3" />
            {/* Cylinder / Object */}
            <circle cx="85" cy="118" r="16" fill="#C8F05F" stroke="#121715" strokeWidth="2.5" />
            <path d="M78 118 Q85 112 92 118" stroke="#121715" strokeWidth="2" fill="none" />
            {/* ArUco / Sensor marker symbol */}
            <rect x="115" y="102" width="22" height="22" rx="4" fill="#121715" />
            <rect x="121" y="108" width="10" height="10" rx="2" fill="#C8F05F" />
            {/* Bionic Arm / Hand gestures */}
            <path
              d="M30 65 Q45 80 55 100 Q65 115 70 140"
              stroke="#121715"
              strokeWidth="3.5"
              strokeLinecap="round"
              fill="none"
            />
            {/* Finger Extension Lines */}
            <path d="M50 50 Q48 35 44 24" stroke="#121715" strokeWidth="3.5" strokeLinecap="round" fill="none" />
            <circle cx="44" cy="22" r="3.5" fill="#121715" />
            <path d="M56 46 Q64 36 68 28" stroke="#121715" strokeWidth="3" strokeLinecap="round" fill="none" />
            {/* Telemetry Radio Ripples */}
            <path d="M96 98 A 20 20 0 0 1 106 108" stroke="#121715" strokeWidth="2" strokeLinecap="round" fill="none" />
            <path d="M102 92 A 28 28 0 0 1 114 104" stroke="#121715" strokeWidth="2" strokeLinecap="round" fill="none" />
          </svg>
        </div>

        {/* Big Bold Headline */}
        <div className="text-left w-full mt-4 space-y-1">
          <h2 className="text-[28px] font-black leading-[1.12] tracking-tight text-[#121715]">
            Hand Rehab <br />
            Made for Real <br />
            Recovery <span className="inline-block bg-[#121715] text-[#C8F05F] px-2 py-0.5 rounded-full text-base align-middle ml-1">➔</span>
          </h2>
          <p className="text-xs text-[#2A342E] font-medium pt-1 max-w-[260px] leading-relaxed">
            Real-time ESP32-S3 telemetry, 3D kinematics, and objective OpenCV TaskProof verification.
          </p>
        </div>
      </div>

      {/* Bottom Bar: Skip & Let's Start */}
      <div className="pt-2 z-10 flex items-center justify-between">
        <button
          onClick={() => setActiveScreen("home")}
          className="text-xs font-bold text-[#121715]/70 hover:text-[#121715] transition"
        >
          Skip
        </button>

        <button
          onClick={() => setActiveScreen("home")}
          className="flex items-center gap-2 bg-[#121715] text-[#C8F05F] px-5 py-3 rounded-full text-xs font-black shadow-lg shadow-black/10 hover:bg-black transition"
        >
          <span>Let's Start</span>
          <div className="w-5 h-5 rounded-full bg-[#C8F05F] text-[#121715] flex items-center justify-center">
            <ArrowUpRight className="w-3.5 h-3.5 stroke-[3]" />
          </div>
        </button>
      </div>
    </div>
  );

  /* ========================================================================= */
  /* 2. SCREEN 2: MAIN DASHBOARD (Center Paytin Screen Layout)                  */
  /* ========================================================================= */
  const renderHomeScreen = () => (
    <div className="w-full h-full bg-[#F4F6F0] text-[#161C19] flex flex-col justify-between overflow-y-auto font-sans relative">
      {/* Scrollable Container */}
      <div className="p-4 space-y-3.5 pb-24">
        {/* Top Header: Avatar + Welcome Back + Action Chip + Notification Bell */}
        <div className="flex items-center justify-between pt-1">
          <div className="flex items-center gap-2.5">
            <div className="relative">
              <div className="w-10 h-10 rounded-full bg-[#161C19] text-[#C8F05F] flex items-center justify-center font-bold text-xs shadow-sm border-2 border-white">
                KS
              </div>
              <span className="absolute bottom-0 right-0 w-2.5 h-2.5 rounded-full bg-[#C8F05F] border-2 border-white" />
            </div>
            <div>
              <div className="text-[10px] text-[#7A837E] font-medium leading-tight">Krushna Saruk</div>
              <div className="text-sm font-black text-[#161C19] flex items-center gap-1">
                <span>Welcome Back</span>
                <span className="text-xs">👋</span>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-1.5">
            <button
              onClick={() => setActiveScreen("device")}
              className="flex items-center gap-1 bg-[#C8F05F] text-[#161C19] px-2.5 py-1.5 rounded-full text-[11px] font-black shadow-sm hover:bg-[#b8e64c] transition"
            >
              <Plus className="w-3.5 h-3.5 stroke-[3]" />
              <span>Calibrate</span>
            </button>

            <button
              onClick={() => setActiveScreen("taskproof")}
              className="w-8 h-8 rounded-full bg-white border border-[#E2E7DE] flex items-center justify-center text-[#161C19] shadow-sm relative"
            >
              <Bell className="w-3.5 h-3.5" />
              <span className="absolute top-1.5 right-1.5 w-1.5 h-1.5 rounded-full bg-[#C8F05F]" />
            </button>
          </div>
        </div>

        {/* ===================================================================== */}
        {/* HERO CARD: Master Telemetry Card (Matching Paytin Black Card)         */}
        {/* ===================================================================== */}
        <div className="relative bg-[#121715] text-white rounded-[24px] p-4 shadow-xl border border-black/10 overflow-hidden">
          {/* Micro-mesh geometric line accent in top-right */}
          <div className="absolute -top-12 -right-12 w-36 h-36 rounded-full bg-[#C8F05F]/10 blur-2xl pointer-events-none" />

          {/* Top Line of Card */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1.5">
              <span className="text-[11px] font-mono font-bold tracking-widest text-slate-300">
                ASHTHAVAKRA
              </span>
              <span className="text-[9px] bg-white/10 px-1.5 py-0.5 rounded text-[#C8F05F] font-mono">
                H10
              </span>
            </div>

            {/* Glowing 4-point Sparkle */}
            <div className="text-[#C8F05F] animate-pulse">
              <Sparkles className="w-4 h-4" />
            </div>

            {/* Contactless / Serial Pill Badge */}
            <div className="bg-[#C8F05F] text-[#121715] px-2 py-0.5 rounded-full flex items-center gap-1 text-[9px] font-mono font-black">
              <Radio className="w-3 h-3" />
              <span>3-CH</span>
            </div>
          </div>

          {/* Middle: Big Telemetry Status */}
          <div className="mt-3">
            <div className="text-[10px] font-mono tracking-wider text-slate-400">TELEMETRY INGEST</div>
            <div className="text-2xl font-black text-[#C8F05F] tracking-tight mt-0.5 font-mono flex items-baseline gap-2">
              <span>921,600</span>
              <span className="text-xs font-sans text-white/80 font-normal">baud • 50 Hz</span>
            </div>
            <div className="text-[10px] text-slate-400 mt-1 font-mono">
              ESP32-S3 N16R8 •••••••• 16-BIT ADS1115
            </div>
          </div>

          {/* Bottom Card Footer */}
          <div className="mt-3 pt-2.5 border-t border-white/10 flex items-center justify-between text-[10px] font-mono">
            <div>
              <span className="text-slate-500 block text-[8px]">PROFILE</span>
              <span className="text-white font-bold">{isDemo3 ? "demo3 (ACTIVE)" : "full5 (PLATFORM)"}</span>
            </div>
            <div className="text-right">
              <span className="text-slate-500 block text-[8px]">POWER</span>
              <span className="text-[#C8F05F] font-bold">USB 5V VBUS</span>
            </div>
          </div>
        </div>

        {/* ===================================================================== */}
        {/* QUICK ACTION GRID (4 Round Squircle Buttons)                          */}
        {/* ===================================================================== */}
        <div className="grid grid-cols-4 gap-2 pt-0.5">
          {[
            { id: "taskproof", label: "TaskProof", icon: Camera, color: "bg-white text-[#161C19]" },
            { id: "live_session", label: "3D HUD", icon: Activity, color: "bg-white text-[#161C19]" },
            { id: "statistics", label: "Analytics", icon: BarChart3, color: "bg-white text-[#161C19]" },
            { id: "device", label: "Settings", icon: Sliders, color: "bg-[#C8F05F] text-[#161C19]" },
          ].map((act) => {
            const Icon = act.icon;
            return (
              <button
                key={act.id}
                onClick={() => setActiveScreen(act.id as any)}
                className="flex flex-col items-center gap-1.5 group"
              >
                <div className={`w-12 h-12 rounded-[18px] ${act.color} shadow-sm border border-[#E2E7DE] flex items-center justify-center transition transform group-hover:scale-105 group-active:scale-95`}>
                  <Icon className="w-5 h-5 stroke-[2.2]" />
                </div>
                <span className="text-[10px] font-bold text-[#161C19]">{act.label}</span>
              </button>
            );
          })}
        </div>

        {/* ===================================================================== */}
        {/* CARE TEAM STRIP ("Quick Send" equivalent in reference)                */}
        {/* ===================================================================== */}
        <div className="space-y-2 pt-1">
          <div className="flex items-center justify-between">
            <h4 className="text-xs font-black text-[#161C19]">Rehab Investigators</h4>
            <span className="text-[10px] font-bold text-[#7A837E] hover:underline cursor-pointer">
              Innovation 2K26
            </span>
          </div>

          <div className="flex items-center gap-2.5 overflow-x-auto pb-1 no-scrollbar">
            {careTeam.map((member, i) => (
              <div key={i} className="flex flex-col items-center gap-1 shrink-0">
                <div className={`w-10 h-10 rounded-full ${member.color} shadow-sm border-2 border-white flex items-center justify-center font-bold text-[11px]`}>
                  {member.initials}
                </div>
                <span className="text-[9px] font-bold text-[#161C19]">{member.name}</span>
              </div>
            ))}
          </div>
        </div>

        {/* ===================================================================== */}
        {/* 3D HOLOGRAPHIC SCANNER CARD                                           */}
        {/* ===================================================================== */}
        <div className="bg-[#121715] text-white rounded-[22px] p-3 shadow-md border border-black/10 space-y-2">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-[#C8F05F] animate-ping" />
              <span className="text-[10px] font-bold uppercase tracking-wider text-[#C8F05F]">
                3D Hand Kinematics
              </span>
            </div>
            <button
              onClick={() => setIsDemo3(!isDemo3)}
              className="text-[9px] bg-white/10 px-2 py-0.5 rounded-full text-slate-300 font-mono hover:text-[#C8F05F]"
            >
              {isDemo3 ? "Profile: 3-CH Active" : "Profile: 5-CH Full"}
            </button>
          </div>

          <div className="h-44 w-full rounded-[16px] bg-black/60 border border-white/5 flex items-center justify-center overflow-hidden relative">
            <HolographicHandScan
              fingerAngles={fingerAngles}
              fsrContact={fsrVal}
              colorCoded={true}
              onFingerClick={(idx) => setSelectedFinger(idx === selectedFinger ? null : idx)}
              selectedFinger={selectedFinger}
            />
          </div>

          {/* 3 Channels Pill Badges */}
          <div className="grid grid-cols-3 gap-1 pt-0.5 text-[9px] font-mono">
            <div className="bg-white/5 p-1 rounded-lg border border-amber-500/30 text-center">
              <span className="text-amber-400 font-bold block text-[8px]">THUMB</span>
              <span className="text-white font-bold">{fingerAngles.thumb}%</span>
            </div>
            <div className="bg-white/5 p-1 rounded-lg border border-sky-500/30 text-center">
              <span className="text-sky-400 font-bold block text-[8px]">INDEX</span>
              <span className="text-white font-bold">{fingerAngles.index}%</span>
            </div>
            <div className="bg-white/5 p-1 rounded-lg border border-emerald-500/30 text-center">
              <span className="text-emerald-400 font-bold block text-[8px]">MIDDLE</span>
              <span className="text-white font-bold">{fingerAngles.middle}%</span>
            </div>
          </div>
        </div>

        {/* ===================================================================== */}
        {/* RECENT ACTIVITY LIST (Matching Paytin Activity Cards)                 */}
        {/* ===================================================================== */}
        <div className="space-y-2 pt-1">
          <div className="flex items-center justify-between">
            <h4 className="text-xs font-black text-[#161C19]">Recent Activity</h4>
            <span
              onClick={() => setActiveScreen("statistics")}
              className="text-[10px] font-bold text-[#7A837E] hover:underline cursor-pointer"
            >
              See all &gt;
            </span>
          </div>

          <div className="space-y-2">
            {activities.map((act, idx) => {
              const IconCmp = act.icon;
              return (
                <div
                  key={idx}
                  className="bg-white p-3 rounded-[18px] border border-[#E2E7DE] shadow-sm flex items-center justify-between hover:border-[#C8F05F] transition"
                >
                  <div className="flex items-center gap-2.5">
                    <div className="w-9 h-9 rounded-[14px] bg-[#F4F6F0] flex items-center justify-center text-[#161C19]">
                      <IconCmp className="w-4 h-4 stroke-[2.2]" />
                    </div>
                    <div>
                      <div className="font-bold text-xs text-[#161C19]">{act.title}</div>
                      <div className="text-[10px] text-[#7A837E]">{act.time}</div>
                    </div>
                  </div>

                  <span className={`px-2 py-0.5 rounded-full text-[9px] font-mono font-bold ${act.badgeColor}`}>
                    {act.badge}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Floating Bottom Navigation Pill Dock */}
      {renderFloatingDock()}
    </div>
  );

  /* ========================================================================= */
  /* 3. SCREEN 3: STATISTICS & ANALYTICS (Right Paytin Screen Layout)           */
  /* ========================================================================= */
  const renderStatisticsScreen = () => (
    <div className="w-full h-full bg-[#F4F6F0] text-[#161C19] flex flex-col justify-between overflow-y-auto font-sans relative">
      <div className="p-4 space-y-3.5 pb-24">
        {/* Top Header: Back + "Statistics" + Ellipsis Menu */}
        <div className="flex items-center justify-between pt-1">
          <button
            onClick={() => setActiveScreen("home")}
            className="w-9 h-9 rounded-full bg-white border border-[#E2E7DE] flex items-center justify-center text-[#161C19] shadow-sm"
          >
            <ChevronLeft className="w-4 h-4 stroke-[2.5]" />
          </button>

          <h3 className="text-sm font-black text-[#161C19]">Statistics</h3>

          <button className="w-9 h-9 rounded-full bg-white border border-[#E2E7DE] flex items-center justify-center text-[#161C19] shadow-sm">
            <MoreHorizontal className="w-4 h-4" />
          </button>
        </div>

        {/* Segmented Pill Period Selector: [Today] [Weekly] [Monthly] [Yearly] */}
        <div className="flex items-center justify-between bg-white p-1 rounded-full border border-[#E2E7DE] shadow-sm text-xs font-bold">
          {(["today", "weekly", "monthly", "yearly"] as const).map((p) => {
            const isActive = statsPeriod === p;
            return (
              <button
                key={p}
                onClick={() => setStatsPeriod(p)}
                className={`flex-1 py-1.5 rounded-full transition text-[11px] capitalize ${
                  isActive
                    ? "bg-[#C8F05F] text-[#161C19] font-black shadow-sm"
                    : "text-[#7A837E] hover:text-[#161C19]"
                }`}
              >
                {p}
              </button>
            );
          })}
        </div>

        {/* ===================================================================== */}
        {/* SPLIT SUMMARY CARDS (Lime Card Left + Obsidian Card Right)            */}
        {/* ===================================================================== */}
        <div className="grid grid-cols-2 gap-2.5">
          {/* Card 1: Vibrant Lime Card (24% ROM Improvement) */}
          <div className="bg-[#C8F05F] text-[#121715] p-3.5 rounded-[22px] shadow-sm border border-[#A6E22E] flex flex-col justify-between min-h-[160px]">
            <div>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-1 text-[10px] font-black uppercase tracking-wider">
                  <TrendingUp className="w-3.5 h-3.5 stroke-[2.5]" />
                  <span>ROM Gain</span>
                </div>
                <MoreHorizontal className="w-3.5 h-3.5 opacity-60" />
              </div>

              <div className="text-3xl font-black mt-2 tracking-tight">24%</div>
              <p className="text-[10px] font-medium leading-tight text-[#161C19]/80 mt-1">
                Flexion amplitude increased by 6.8% vs initial baseline.
              </p>
            </div>

            <div className="mt-3 pt-2 border-t border-[#121715]/10">
              <div className="flex items-center justify-between text-[9px] font-bold mb-1">
                <span>Goal</span>
                <span>8 / 10 Reps</span>
              </div>
              <div className="flex gap-1">
                {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((d) => (
                  <div
                    key={d}
                    className={`h-1.5 flex-1 rounded-full ${d <= 8 ? "bg-[#121715]" : "bg-[#121715]/20"}`}
                  />
                ))}
              </div>
            </div>
          </div>

          {/* Card 2: Deep Obsidian Card with Radar Spider Chart */}
          <div className="bg-[#121715] text-white p-3.5 rounded-[22px] shadow-md border border-black/10 flex flex-col justify-between min-h-[160px]">
            <div>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-1 text-[10px] font-black uppercase tracking-wider text-slate-300">
                  <Activity className="w-3.5 h-3.5 text-[#C8F05F] stroke-[2.5]" />
                  <span>Kinematics</span>
                </div>
                <MoreHorizontal className="w-3.5 h-3.5 text-slate-400" />
              </div>

              <div className="text-2xl font-black text-[#C8F05F] font-mono mt-1">
                84.2<span className="text-xs font-sans text-white/70">° ROM</span>
              </div>
            </div>

            {/* Radar / Spider Polygon SVG Chart */}
            <div className="relative w-full h-24 my-auto flex items-center justify-center">
              <svg viewBox="0 0 150 150" className="w-full h-full">
                {/* Concentric Web Rings */}
                <polygon points="75,20 127,58 107,119 43,119 23,58" fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth="1" />
                <polygon points="75,37 110,62 97,105 53,105 40,62" fill="none" stroke="rgba(255,255,255,0.12)" strokeWidth="1" />
                <polygon points="75,55 93,68 86,90 64,90 57,68" fill="none" stroke="rgba(255,255,255,0.16)" strokeWidth="1" />

                {/* Axes */}
                {[0, 1, 2, 3, 4].map((i) => {
                  const ang = (Math.PI * 2 / 5) * i - Math.PI / 2;
                  const x2 = 75 + Math.cos(ang) * 55;
                  const y2 = 75 + Math.sin(ang) * 55;
                  return <line key={i} x1="75" y1="75" x2={x2} y2={y2} stroke="rgba(255,255,255,0.15)" strokeWidth="1" />;
                })}

                {/* Dynamic Kinematics Radar Area */}
                <polygon
                  points={renderRadarPolygon()}
                  fill="rgba(200, 240, 95, 0.35)"
                  stroke="#C8F05F"
                  strokeWidth="2"
                />
              </svg>
            </div>

            <div className="flex items-center justify-between text-[8px] font-mono pt-1 border-t border-white/10 text-slate-400">
              <span className="text-[#C8F05F] font-bold">● 3-CH ACTIVE</span>
              <span>● PLATFORM</span>
            </div>
          </div>
        </div>

        {/* ===================================================================== */}
        {/* OVERVIEW STACKED DUAL-TONE BAR CHART (Paytin Bar Chart Equivalent)    */}
        {/* ===================================================================== */}
        <div className="bg-white p-4 rounded-[22px] border border-[#E2E7DE] shadow-sm space-y-3">
          <div className="flex items-center justify-between">
            <div>
              <span className="text-[10px] font-bold text-[#7A837E] uppercase tracking-wider">Overview</span>
              <div className="text-sm font-black text-[#161C19]">Weekly Exercise Adherence</div>
            </div>

            <div className="flex items-center gap-2 text-[9px] font-bold">
              <span className="flex items-center gap-1">
                <span className="w-2 h-2 rounded-full bg-[#C8F05F]" />
                Flexion
              </span>
              <span className="flex items-center gap-1">
                <span className="w-2 h-2 rounded-full bg-[#161C19]" />
                TaskProof
              </span>
            </div>
          </div>

          {/* Stacked Bars Container */}
          <div className="pt-2">
            <div className="h-32 flex items-end justify-between gap-2 px-1 border-b border-[#E2E7DE] pb-2 relative">
              {/* Tooltip Badge over Friday */}
              <div className="absolute top-1 right-[26%] bg-[#121715] text-[#C8F05F] px-2 py-0.5 rounded-full text-[9px] font-mono font-bold shadow-md">
                10 Reps • Fri
              </div>

              {[
                { day: "Mon", flex: 45, task: 30 },
                { day: "Tue", flex: 60, task: 25 },
                { day: "Wed", flex: 40, task: 40 },
                { day: "Thu", flex: 75, task: 35 },
                { day: "Fri", flex: 85, task: 45 },
                { day: "Sat", flex: 65, task: 20 },
                { day: "Sun", flex: 30, task: 15 },
              ].map((item, idx) => (
                <div key={idx} className="flex-1 flex flex-col items-center gap-1.5 h-full justify-end">
                  <div className="w-full max-w-[24px] flex flex-col gap-1 items-center">
                    {/* Top Segment: Lime */}
                    <div
                      className="w-full bg-[#C8F05F] rounded-t-md transition-all duration-500"
                      style={{ height: `${item.flex * 0.7}px` }}
                    />
                    {/* Bottom Segment: Black */}
                    <div
                      className="w-full bg-[#161C19] rounded-b-md transition-all duration-500"
                      style={{ height: `${item.task * 0.7}px` }}
                    />
                  </div>
                  <span className="text-[9px] font-bold text-[#7A837E]">{item.day}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="flex items-center justify-between text-xs font-bold pt-1 text-[#161C19]">
            <span>Total Completed Sessions</span>
            <span className="font-mono text-emerald-800 bg-[#C8F05F]/30 px-2 py-0.5 rounded-full">
              4 / 5 Prescribed
            </span>
          </div>
        </div>

        {/* Okabe-Ito Channel Details */}
        <div className="bg-white p-3.5 rounded-[22px] border border-[#E2E7DE] shadow-sm space-y-2">
          <div className="flex items-center justify-between text-[11px] font-black text-[#161C19]">
            <span>Digit Flexion Amplitude</span>
            <span className="text-[9px] font-mono text-[#7A837E]">{isDemo3 ? "demo3 Mode" : "full5 Mode"}</span>
          </div>

          <div className="space-y-1.5">
            {okabeItoColors.map((f, i) => (
              <div key={i} className="flex items-center justify-between text-[10px]">
                <span className="font-bold w-12">{f.name}</span>
                <div className="flex-1 mx-2 bg-[#F4F6F0] h-2 rounded-full overflow-hidden">
                  <div
                    className="h-full rounded-full"
                    style={{
                      width: f.active ? `${f.val}%` : "0%",
                      backgroundColor: f.active ? f.hex : "#94A3B8",
                    }}
                  />
                </div>
                <span className="font-mono text-[9px] w-12 text-right">
                  {f.active ? `${f.val}%` : "RESERVED"}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {renderFloatingDock()}
    </div>
  );

  /* ========================================================================= */
  /* 4. SCREEN 4: TASKPROOF SCREEN                                             */
  /* ========================================================================= */
  const renderTaskProofScreen = () => (
    <div className="w-full h-full bg-[#F4F6F0] text-[#161C19] flex flex-col justify-between overflow-y-auto font-sans relative">
      <div className="p-4 space-y-3 pb-24">
        {/* Top Header */}
        <div className="flex items-center justify-between pt-1">
          <button
            onClick={() => setActiveScreen("home")}
            className="w-9 h-9 rounded-full bg-white border border-[#E2E7DE] flex items-center justify-center text-[#161C19] shadow-sm"
          >
            <ChevronLeft className="w-4 h-4 stroke-[2.5]" />
          </button>
          <h3 className="text-sm font-black text-[#161C19]">TaskProof Engine</h3>
          <button
            onClick={onTriggerTaskProof}
            className="px-2.5 py-1 bg-[#C8F05F] text-[#161C19] rounded-full text-[10px] font-black flex items-center gap-1 shadow-sm"
          >
            <Play className="w-3 h-3 fill-current" /> Run
          </button>
        </div>

        {/* Big Verdict Pill Banner */}
        <div className="bg-[#121715] text-white p-4 rounded-[22px] text-center shadow-lg border border-black/10">
          <div className="text-[10px] font-mono text-[#C8F05F] tracking-widest uppercase">
            FOUR-PHASE VERDICT
          </div>
          <div className="text-3xl font-black text-[#C8F05F] mt-0.5 tracking-tight">
            {telemetry?.taskproof.verdict === "NOT_STARTED" ? "VERIFIED" : telemetry?.taskproof.verdict || "READY"}
          </div>
          <div className="text-xs font-mono text-slate-300 mt-1">
            {telemetry?.taskproof.reason_codes?.join(" • ") || "4.2 s • ALL GUARDS MET"}
          </div>
        </div>

        {/* OpenCV ArUco Live Tabletop Canvas */}
        <div className="bg-[#121715] text-white p-3.5 rounded-[22px] border border-black/10 shadow space-y-2">
          <div className="flex items-center justify-between text-[10px]">
            <span className="font-bold text-[#C8F05F] flex items-center gap-1.5 uppercase font-mono">
              <Camera className="w-3.5 h-3.5 text-[#C8F05F]" />
              Tabletop Zone Field
            </span>
            <span className="px-2 py-0.5 rounded-full bg-[#C8F05F] text-[#121715] font-mono font-bold text-[9px]">
              ArUco #0 Target
            </span>
          </div>

          <div className="h-28 w-full rounded-[16px] bg-black/60 border border-white/10 relative p-2 overflow-hidden flex items-center justify-between text-center font-mono text-[9px]">
            {/* Zone A (Pick-up) */}
            <div className="w-1/3 h-full border-2 border-dashed border-emerald-500/60 rounded-[12px] bg-emerald-950/30 flex flex-col items-center justify-center p-1">
              <span className="text-emerald-300 font-bold">ZONE A</span>
              <span className="text-[8px] text-emerald-400">Pick-up</span>
              <span className="text-[8px] text-slate-400 mt-0.5">X: 120-220</span>
            </div>

            {/* Transit divider */}
            <div className="flex-1 flex flex-col items-center justify-center text-slate-500">
              <ArrowRight className="w-4 h-4 text-[#C8F05F] animate-pulse" />
              <span className="text-[8px] text-[#C8F05F]/80">Transit</span>
            </div>

            {/* Zone B (Target) */}
            <div className="w-1/3 h-full border-2 border-[#C8F05F] rounded-[12px] bg-cyan-950/40 flex flex-col items-center justify-center p-1 relative shadow-[0_0_12px_rgba(200,240,95,0.2)]">
              <span className="text-cyan-300 font-bold">ZONE B</span>
              <span className="text-[8px] text-cyan-400">Target</span>
              <div className="mt-1 px-1.5 py-0.5 bg-[#C8F05F] text-[#121715] font-black rounded text-[8px] flex items-center gap-0.5 shadow">
                <span className="w-1.5 h-1.5 rounded-full bg-black animate-ping" />
                #0 HERE
              </div>
            </div>
          </div>

          {/* Camera Metrics */}
          <div className="grid grid-cols-3 gap-1.5 text-[9px] font-mono pt-1">
            <div className="bg-white/5 p-1.5 rounded-lg border border-white/10 text-center">
              <span className="text-slate-400 block text-[8px]">DETECTION</span>
              <span className="text-[#C8F05F] font-bold">96% (≥80%)</span>
            </div>
            <div className="bg-white/5 p-1.5 rounded-lg border border-white/10 text-center">
              <span className="text-slate-400 block text-[8px]">FRAME AGE</span>
              <span className="text-cyan-400 font-bold">28 ms</span>
            </div>
            <div className="bg-white/5 p-1.5 rounded-lg border border-white/10 text-center">
              <span className="text-slate-400 block text-[8px]">OCCLUSION</span>
              <span className="text-[#C8F05F] font-bold">0 ms (OK)</span>
            </div>
          </div>
        </div>

        {/* 4-Phase Verification Checklist */}
        <div className="bg-white p-3.5 rounded-[22px] border border-[#E2E7DE] shadow-sm space-y-2">
          <div className="text-[10px] font-black text-[#161C19] uppercase tracking-wider">
            Deterministic Verification Guards
          </div>
          <div className="grid grid-cols-2 gap-1.5 text-[10px]">
            <div className="bg-[#C8F05F]/20 border border-[#A6E22E] text-[#161C19] p-2 rounded-xl flex items-center gap-1.5 font-bold">
              <Check className="w-3.5 h-3.5 text-emerald-800 shrink-0 stroke-[3]" />
              <span>1. Contact Candidate</span>
            </div>
            <div className="bg-[#C8F05F]/20 border border-[#A6E22E] text-[#161C19] p-2 rounded-xl flex items-center gap-1.5 font-bold">
              <Check className="w-3.5 h-3.5 text-emerald-800 shrink-0 stroke-[3]" />
              <span>2. Object Lifted</span>
            </div>
            <div className="bg-[#C8F05F]/20 border border-[#A6E22E] text-[#161C19] p-2 rounded-xl flex items-center gap-1.5 font-bold">
              <Check className="w-3.5 h-3.5 text-emerald-800 shrink-0 stroke-[3]" />
              <span>3. Boundary Transit</span>
            </div>
            <div className="bg-[#C8F05F]/20 border border-[#A6E22E] text-[#161C19] p-2 rounded-xl flex items-center gap-1.5 font-bold">
              <Check className="w-3.5 h-3.5 text-emerald-800 shrink-0 stroke-[3]" />
              <span>4. Target Release</span>
            </div>
          </div>
        </div>

        {/* Operator Labelling Buttons */}
        <div className="bg-white p-3.5 rounded-[22px] border border-[#E2E7DE] shadow-sm space-y-2">
          <div className="text-[10px] font-black text-[#161C19] uppercase">Operator Labelling Controls</div>
          <div className="grid grid-cols-2 gap-2">
            <button
              onClick={() => onLabelGroundTruth?.("success")}
              className="py-2.5 bg-[#121715] text-[#C8F05F] rounded-xl text-xs font-black hover:bg-black transition"
            >
              [S] Success
            </button>
            <button
              onClick={() => onLabelGroundTruth?.("failure")}
              className="py-2.5 bg-rose-600 text-white rounded-xl text-xs font-black hover:bg-rose-700 transition"
            >
              [F] Fail
            </button>
          </div>
          <div className="grid grid-cols-2 gap-2">
            <button
              onClick={() => onLabelGroundTruth?.("uncertain")}
              className="py-2 bg-purple-100 text-purple-900 border border-purple-300 rounded-xl text-xs font-bold"
            >
              [U] Uncertain
            </button>
            <button
              onClick={onAbortAttempt}
              className="py-2 bg-amber-100 text-amber-900 border border-amber-300 rounded-xl text-xs font-bold"
            >
              [Esc] Abort
            </button>
          </div>
        </div>
      </div>

      {renderFloatingDock()}
    </div>
  );

  /* ========================================================================= */
  /* 5. SCREEN 5: DEVICE & SETTINGS SCREEN                                     */
  /* ========================================================================= */
  const renderDeviceScreen = () => (
    <div className="w-full h-full bg-[#F4F6F0] text-[#161C19] flex flex-col justify-between overflow-y-auto font-sans relative">
      <div className="p-4 space-y-3.5 pb-24">
        {/* Top Header */}
        <div className="flex items-center justify-between pt-1">
          <button
            onClick={() => setActiveScreen("home")}
            className="w-9 h-9 rounded-full bg-white border border-[#E2E7DE] flex items-center justify-center text-[#161C19] shadow-sm"
          >
            <ChevronLeft className="w-4 h-4 stroke-[2.5]" />
          </button>
          <h3 className="text-sm font-black text-[#161C19]">Hardware & Profile</h3>
          <div className="w-9" />
        </div>

        {/* Specifications Card */}
        <div className="bg-white p-4 rounded-[22px] border border-[#E2E7DE] shadow-sm space-y-2">
          <div className="text-[10px] font-black text-[#161C19] uppercase tracking-wider mb-1">
            ESP32-S3 Hardware Specifications
          </div>
          <div className="text-xs space-y-2">
            <div className="flex justify-between items-center py-1 border-b border-slate-100">
              <span className="text-[#7A837E]">Microcontroller</span>
              <span className="font-bold">ESP32-S3 N16R8 (240MHz)</span>
            </div>
            <div className="flex justify-between items-center py-1 border-b border-slate-100">
              <span className="text-[#7A837E]">16-Bit ADC</span>
              <span className="font-bold">ADS1115 (I2C @ 0x48)</span>
            </div>
            <div className="flex justify-between items-center py-1 border-b border-slate-100">
              <span className="text-[#7A837E]">6-DOF IMU</span>
              <span className="font-bold">MPU6050 (0x68)</span>
            </div>
            <div className="flex justify-between items-center py-1 border-b border-slate-100">
              <span className="text-[#7A837E]">Power Source</span>
              <span className="font-bold text-emerald-800 bg-[#C8F05F]/40 px-2 py-0.5 rounded-full">
                USB 5V VBUS (Isolated)
              </span>
            </div>
            <div className="flex justify-between items-center py-1 border-b border-slate-100">
              <span className="text-[#7A837E]">Serial Baud</span>
              <span className="font-mono font-bold">921,600 baud</span>
            </div>
            <div className="flex justify-between items-center py-1">
              <span className="text-[#7A837E]">Active Design</span>
              <span className="font-bold text-[#161C19]">
                {isDemo3 ? "demo3 (3 Flex + FSR + IMU)" : "full5 (5 Flex + FSR + IMU)"}
              </span>
            </div>
          </div>
        </div>

        {/* Mode Toggle Button */}
        <div className="bg-white p-4 rounded-[22px] border border-[#E2E7DE] shadow-sm space-y-2">
          <div className="text-[10px] font-black text-[#161C19] uppercase">Profile Management</div>
          <button
            onClick={() => setIsDemo3(!isDemo3)}
            className="w-full py-3 bg-[#121715] text-[#C8F05F] rounded-xl text-xs font-black shadow transition flex items-center justify-center gap-2"
          >
            <Sliders className="w-4 h-4" />
            <span>Switch to {isDemo3 ? "full5 Platform Profile" : "demo3 Competition Profile"}</span>
          </button>
        </div>

        {/* 10-Point Preflight Diagnostics */}
        <div className="bg-white p-4 rounded-[22px] border border-[#E2E7DE] shadow-sm space-y-2">
          <div className="text-[10px] font-black text-[#161C19] uppercase tracking-wider">
            Preflight Diagnostics
          </div>
          <div className="space-y-1.5 text-xs">
            {[
              "Serial Ingest Parser (921600 baud)",
              "ADS1115 16-bit ADC Range (Span > 300)",
              "MPU6050 6-DOF Inertial Stream",
              "OpenCV ArUco Marker Tracker",
              "Deterministic 7-State Engine",
              "SQLite WAL Data Persistence",
              "Local Boundary Check (127.0.0.1)",
            ].map((name, i) => (
              <div key={i} className="flex items-center justify-between py-0.5">
                <span className="text-slate-700 text-[11px]">{name}</span>
                <span className="text-[9px] font-mono font-bold text-emerald-800 bg-[#C8F05F]/40 px-2 py-0.5 rounded-full flex items-center gap-1">
                  <Check className="w-3 h-3 stroke-[3]" /> PASS
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {renderFloatingDock()}
    </div>
  );

  /* ========================================================================= */
  /* 6. SIGNATURE FLOATING BOTTOM DOCK                                         */
  /* ========================================================================= */
  function renderFloatingDock() {
    return (
      <div className="absolute bottom-4 inset-x-0 flex justify-center z-30 pointer-events-none">
        <div className="pointer-events-auto bg-[#121715] text-white rounded-full p-1.5 shadow-2xl border border-black/20 flex items-center gap-1.5">
          {/* 1. Home Button */}
          <button
            onClick={() => setActiveScreen("home")}
            className={`w-9 h-9 rounded-full flex items-center justify-center transition ${
              activeScreen === "home" ? "bg-white/20 text-[#C8F05F]" : "text-white/60 hover:text-white"
            }`}
            title="Dashboard"
          >
            <Activity className="w-4 h-4 stroke-[2.2]" />
          </button>

          {/* 2. TaskProof / Scan Button (Vibrant Lime Center Circle) */}
          <button
            onClick={() => setActiveScreen(activeScreen === "taskproof" ? "live_session" : "taskproof")}
            className="w-10 h-10 rounded-full bg-[#C8F05F] text-[#121715] flex items-center justify-center font-bold shadow-lg shadow-[#C8F05F]/30 hover:scale-105 transition active:scale-95"
            title="TaskProof Camera Field"
          >
            <Scan className="w-5 h-5 stroke-[2.5]" />
          </button>

          {/* 3. Analytics Button */}
          <button
            onClick={() => setActiveScreen("statistics")}
            className={`w-9 h-9 rounded-full flex items-center justify-center transition ${
              activeScreen === "statistics" ? "bg-white/20 text-[#C8F05F]" : "text-white/60 hover:text-white"
            }`}
            title="Statistics"
          >
            <BarChart2 className="w-4 h-4 stroke-[2.2]" />
          </button>

          {/* 4. Settings Button */}
          <button
            onClick={() => setActiveScreen("device")}
            className={`w-9 h-9 rounded-full flex items-center justify-center transition ${
              activeScreen === "device" ? "bg-white/20 text-[#C8F05F]" : "text-white/60 hover:text-white"
            }`}
            title="Hardware & Settings"
          >
            <Sliders className="w-4 h-4 stroke-[2.2]" />
          </button>
        </div>
      </div>
    );
  }

  /* ========================================================================= */
  /* 7. IPHONE BEZEL & DYNAMIC ISLAND CONTAINER                                */
  /* ========================================================================= */
  const renderPhoneFrame = (content: React.ReactNode, title: string) => (
    <div className="flex flex-col items-center gap-3">
      {/* Precision iPhone 15 Pro Hardware Frame */}
      <div className="w-[340px] sm:w-[355px] h-[730px] shrink-0 bg-[#0E1311] rounded-[52px] p-2.5 shadow-[0_30px_70px_-15px_rgba(0,0,0,0.25)] border-[5.5px] border-[#242C28] relative flex flex-col overflow-hidden transition-all duration-300 hover:shadow-[0_35px_80px_-12px_rgba(0,0,0,0.35)]">
        {/* Dynamic Island Pill */}
        <div className="absolute top-3.5 inset-x-0 mx-auto w-24 h-5 bg-black rounded-full z-40 flex items-center justify-between px-2.5 shadow-sm">
          <span className="w-2.5 h-2.5 rounded-full bg-[#18201D] border border-white/20" />
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500/80" />
        </div>

        {/* Gloss Edge Highlight */}
        <div className="absolute inset-0 rounded-[46px] pointer-events-none border border-white/10" />

        {/* Phone Content Screen */}
        <div className="flex-1 rounded-[42px] overflow-hidden flex flex-col relative bg-[#F4F6F0]">
          {/* Mandatory Non-Medical Disclaimer Header Pill */}
          <div className="bg-[#FEF3C7] border-b border-[#FDE68A] px-3 py-1 text-[8.5px] text-[#92400E] font-bold text-center z-30 shrink-0">
            PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE
          </div>

          <div className="flex-1 overflow-hidden relative">
            {content}
          </div>
        </div>
      </div>

      <span className="text-[11px] font-bold text-[#646E68] font-mono tracking-wider">
        {title}
      </span>
    </div>
  );

  return (
    <div className="space-y-6 w-full max-w-7xl mx-auto">
      {/* Elegant Minimal Toggle Bar matching light portfolio presentation */}
      <div className="flex flex-wrap items-center justify-between bg-white/90 backdrop-blur-md border border-black/[0.08] p-2.5 rounded-full shadow-sm gap-3 max-w-xl mx-auto">
        <div className="flex items-center gap-2 pl-3">
          <span className="w-2 h-2 rounded-full bg-[#C8F05F]" />
          <span className="text-xs font-black text-[#121715] tracking-tight">
            Paytin Neo-Rehabilitation UI
          </span>
        </div>

        <div className="flex items-center gap-1.5">
          <button
            onClick={() => setShowTriptych(!showTriptych)}
            className={`px-3 py-1.5 rounded-full text-xs font-black transition flex items-center gap-1.5 ${
              showTriptych ? "bg-[#C8F05F] text-[#121715] shadow-sm" : "bg-black/5 text-[#646E68] hover:text-[#121715]"
            }`}
          >
            <Layers className="w-3.5 h-3.5" />
            <span>{showTriptych ? "Triptych 3-Phone" : "Single Interactive"}</span>
          </button>

          <button
            onClick={() => setActiveScreen(activeScreen === "onboarding" ? "home" : "onboarding")}
            className="px-3 py-1.5 rounded-full text-xs font-bold bg-black/5 hover:bg-black/10 text-[#121715] transition"
          >
            {activeScreen === "onboarding" ? "Dashboard" : "Splash Screen"}
          </button>
        </div>
      </div>

      {/* Main Display: Triptych 3-Screen View OR Single Focused Interactive View */}
      {showTriptych ? (
        <div className="flex flex-wrap items-center justify-center gap-6 xl:gap-10 py-2">
          {/* Phone 1: Onboarding Splash Screen */}
          {renderPhoneFrame(renderOnboardingScreen(), "01 • ONBOARDING SPLASH")}

          {/* Phone 2: Main Dashboard (Interactive) */}
          {renderPhoneFrame(renderHomeScreen(), "02 • REHABILITATION DASHBOARD")}

          {/* Phone 3: Statistics & Analytics */}
          {renderPhoneFrame(renderStatisticsScreen(), "03 • KINEMATIC STATISTICS")}
        </div>
      ) : (
        <div className="flex justify-center py-4">
          {renderPhoneFrame(
            activeScreen === "onboarding"
              ? renderOnboardingScreen()
              : activeScreen === "home"
              ? renderHomeScreen()
              : activeScreen === "statistics"
              ? renderStatisticsScreen()
              : activeScreen === "taskproof"
              ? renderTaskProofScreen()
              : renderDeviceScreen(),
            `ACTIVE VIEW • ${activeScreen.toUpperCase()}`
          )}
        </div>
      )}
    </div>
  );
}

