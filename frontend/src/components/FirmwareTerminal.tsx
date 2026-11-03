import React, { useState, useEffect } from "react";

interface FirmwareTerminalProps {
  flexValues: number[];
  samplingRate?: number;
}

export default function FirmwareTerminal({
  flexValues,
  samplingRate = 50,
}: FirmwareTerminalProps) {
  const [packetTick, setPacketTick] = useState(1048);

  useEffect(() => {
    const timer = setInterval(() => {
      setPacketTick((prev) => (prev + 1) % 9999);
    }, 400);
    return () => clearInterval(timer);
  }, []);

  return (
    <div className="bg-black/80 rounded border border-amber-900/50 p-2.5 font-code text-[10px] leading-tight text-amber-200/90 shadow-inner relative overflow-hidden">
      {/* Corner bracket deco */}
      <div className="absolute top-1 right-1 text-amber-600 text-[8px] flex items-center gap-1">
        <span>PKG: #{packetTick}</span>
        <span className="w-1.5 h-1.5 rounded-full bg-amber-400 animate-pulse" />
      </div>

      <div className="space-y-0.5 text-amber-400/80">
        <div>
          <span className="text-amber-600">using </span>
          <span className="text-amber-200">System;</span>
        </div>
        <div>
          <span className="text-amber-600">using </span>
          <span className="text-amber-200">Ashtavakra.Kinematics.Hand;</span>
        </div>
        <div>
          <span className="text-amber-600">using </span>
          <span className="text-amber-200">H10.Core.Filters;</span>
        </div>
      </div>

      <div className="mt-1 text-amber-500/70">
        <span className="text-amber-600">namespace </span>
        <span className="text-amber-300">h10_telemetry</span>
        <span> {"{"}</span>
      </div>

      <div className="pl-2 mt-0.5">
        <span className="text-amber-600">class </span>
        <span className="text-amber-300">KinematicStream</span>
        <span> {"{"}</span>
      </div>

      <div className="pl-4 mt-0.5 text-amber-100">
        <div>
          <span className="text-amber-600">void </span>
          <span className="text-amber-300">OnPacket</span>
          <span className="text-amber-400">(Byte[] payload)</span>
          <span> {"{"}</span>
        </div>
        <div className="pl-2 text-[9px] text-amber-300/90">
          <span className="text-amber-600">Byte </span>
          <span className="text-amber-100">thumb_val = </span>
          <span className="text-amber-400 font-bold">{Math.round(flexValues[0] || 0)};</span>
        </div>
        <div className="pl-2 text-[9px] text-amber-300/90">
          <span className="text-amber-600">float </span>
          <span className="text-amber-100">ema = Filter.Apply(thumb, alpha: 0.25f);</span>
        </div>
        <div className="pl-2 text-[9px] text-amber-500/70">
          <span>// 50Hz Binary Little-Endian Stream OK</span>
        </div>
        <div>{"}"}</div>
      </div>

      <div className="pl-2">{"}"}</div>
      <div className="text-amber-500/70">{"}"}</div>
    </div>
  );
}
