import React, { useEffect, useState } from "react";

interface WaveformMonitorProps {
  heartRate?: number;
  jerkIndex?: number;
  romMax?: number;
  romMin?: number;
  isAlert?: boolean;
}

export default function WaveformMonitor({
  heartRate = 92,
  jerkIndex = 38.6,
  romMax = 145,
  romMin = 96,
  isAlert = false,
}: WaveformMonitorProps) {
  const [phase, setPhase] = useState(0);

  // Animated pulse phase generator
  useEffect(() => {
    let animId: number;
    const step = () => {
      setPhase((prev) => (prev + 1) % 360);
      animId = requestAnimationFrame(step);
    };
    animId = requestAnimationFrame(step);
    return () => cancelAnimationFrame(animId);
  }, []);

  // Generate SVG path points for the kinematic ECG / flexion wave
  const generatePulsePath = () => {
    const points: string[] = [];
    const width = 280;
    const height = 48;
    const baseline = height * 0.65;

    points.push(`M 0 ${baseline}`);
    for (let x = 0; x <= width; x += 3) {
      // Repeat every 70px
      const cyclePos = (x + phase * 2.2) % 70;
      let y = baseline;

      if (cyclePos > 15 && cyclePos < 22) {
        // Small P wave
        y -= 4;
      } else if (cyclePos >= 22 && cyclePos < 26) {
        // Q dip
        y += 3;
      } else if (cyclePos >= 26 && cyclePos < 33) {
        // Sharp R spike
        y -= 28 + (isAlert ? 10 : 0);
      } else if (cyclePos >= 33 && cyclePos < 38) {
        // S dip
        y += 7;
      } else if (cyclePos >= 42 && cyclePos < 55) {
        // T wave
        y -= 7;
      }
      points.push(`L ${x} ${y}`);
    }
    return points.join(" ");
  };

  // Generate square / sinusoidal cadence wave for bottom
  const generateSquareWave = () => {
    const points: string[] = [];
    const width = 220;
    const height = 30;
    const topY = 6;
    const botY = 24;

    points.push(`M 0 ${botY}`);
    for (let x = 0; x <= width; x += 2) {
      const cycle = (x + phase * 1.5) % 60;
      let y = botY;
      if (cycle < 28) {
        // Smooth rounded crest
        y = topY;
      }
      points.push(`L ${x} ${y}`);
    }
    return points.join(" ");
  };

  const strokeColor = isAlert ? "#f87171" : "#fbbf24";
  const glowColor = isAlert ? "rgba(239, 68, 68, 0.5)" : "rgba(245, 158, 11, 0.5)";

  return (
    <div className="space-y-4 font-mono text-xs text-amber-100/90 select-none">
      {/* 1. Large Primary Biomechanical Telemetry (SYS/DIA style: 145/96) */}
      <div className="grid grid-cols-2 gap-3 items-end pt-2 border-t border-amber-950/60">
        <div>
          <div className="text-[9px] uppercase tracking-wider text-amber-500/70 font-semibold flex items-center justify-between">
            <span>SYS/DIA [FLX/EXT]</span>
          </div>
          <div className="text-4xl font-extrabold tracking-tight text-amber-300 font-hud">
            {romMax}<span className="text-amber-500/70 text-2xl font-normal mx-0.5">/</span>{romMin}
          </div>
          <div className="flex justify-between text-[8px] text-amber-600 tracking-widest mt-0.5">
            <span>ADULT</span>
            <span>DEG (ROM)</span>
          </div>
        </div>

        <div>
          <div className="text-[9px] uppercase tracking-wider text-amber-500/70 font-semibold text-right">
            <span>PR. [102]</span>
          </div>
          <div className="text-4xl font-extrabold tracking-tight text-amber-300 font-hud text-right">
            {jerkIndex.toFixed(1)}
          </div>
          <div className="flex justify-between text-[8px] text-amber-600 tracking-widest mt-0.5">
            <span>UNIT 1 - 5</span>
            <span className="text-amber-400 font-bold">[53]</span>
          </div>
        </div>
      </div>

      {/* 2. Kinematic ECG Pulse Waveform Graph */}
      <div className="relative bg-black/60 rounded border border-amber-900/40 p-2 overflow-hidden">
        {/* Subtle background grid */}
        <div
          className="absolute inset-0 opacity-15 pointer-events-none"
          style={{
            backgroundImage:
              "linear-gradient(to right, #f59e0b 1px, transparent 1px), linear-gradient(to bottom, #f59e0b 1px, transparent 1px)",
            backgroundSize: "14px 14px",
          }}
        />

        <div className="relative h-12 w-full">
          <svg className="w-full h-full" preserveAspectRatio="none" viewBox="0 0 280 48">
            <defs>
              <filter id="ecgGlow" x="-20%" y="-20%" width="140%" height="140%">
                <feGaussianBlur stdDeviation="2" result="blur" />
                <feMerge>
                  <feMergeNode in="blur" />
                  <feMergeNode in="SourceGraphic" />
                </feMerge>
              </filter>
            </defs>
            <path
              d={generatePulsePath()}
              fill="none"
              stroke={strokeColor}
              strokeWidth="1.8"
              strokeLinecap="round"
              strokeLinejoin="round"
              filter="url(#ecgGlow)"
            />
          </svg>
        </div>

        {/* Axis markers (0.2 -, 04 :, 37 :) matching image */}
        <div className="flex justify-between text-[9px] text-amber-600/80 font-tech mt-1 px-1">
          <span>0.2 -</span>
          <span>04 :</span>
          <span>37 :</span>
        </div>
      </div>

      {/* 3. Heartbeat / Cadence & Trend Readout */}
      <div className="flex items-center justify-between pt-1">
        <div>
          <div className="text-[8px] tracking-widest uppercase text-amber-600">
            CADENCE / RATE
          </div>
          <div className="flex items-baseline space-x-2">
            <span className="text-3xl font-extrabold text-amber-300 font-hud">
              {heartRate}
            </span>
            <span className="text-[10px] text-amber-500 font-semibold">BPM / REPS</span>
          </div>
        </div>

        {/* Delta trends: ▲ +17, ▼ -23 */}
        <div className="flex items-center space-x-3 text-[10px] font-tech">
          <div className="flex items-center space-x-1 text-amber-400">
            <span className="text-amber-500">▲</span>
            <span>+17</span>
          </div>
          <div className="flex items-center space-x-1 text-rose-400">
            <span className="text-rose-500">▼</span>
            <span>-23</span>
          </div>
          <span className="text-amber-600 text-xs">...</span>
        </div>
      </div>

      {/* 4. Telemetry Bottom Status & Square Wave */}
      <div className="flex items-center justify-between text-[8px] text-amber-600 pt-1">
        <span>FAULT: 53</span>
        <span>MMHG: 001</span>
        <span>UNIT 1 - 5</span>
        <span className="text-amber-400 font-bold border border-amber-800/80 px-1 py-0.5 rounded text-[7px]">
          [53]
        </span>
      </div>

      {/* 5. Smooth Square Wave Stream (Bottom of right panel in image) */}
      <div className="flex items-center justify-between bg-black/40 p-1.5 rounded border border-amber-950/80">
        <div className="w-36 h-6">
          <svg className="w-full h-full" preserveAspectRatio="none" viewBox="0 0 220 30">
            <path
              d={generateSquareWave()}
              fill="none"
              stroke="#f59e0b"
              strokeWidth="1.6"
              strokeLinejoin="round"
              strokeLinecap="round"
              opacity="0.8"
            />
          </svg>
        </div>
        <div className="flex items-center space-x-2 text-[9px] font-tech text-amber-500">
          <span className="flex items-center gap-0.5">
            <span className="w-1.5 h-1.5 rounded-sm bg-amber-500" /> 0.02
          </span>
          <span className="text-amber-400">▲ 2.53</span>
        </div>
      </div>
    </div>
  );
}
