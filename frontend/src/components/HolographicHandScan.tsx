import React, { useMemo } from "react";

export interface FingerAngles {
  thumb: number;  // 0 - 100
  index: number;  // 0 - 100
  middle: number; // 0 - 100
  ring: number;   // 0 - 100
  pinky: number;  // 0 - 100
}

interface HolographicHandScanProps {
  fingerAngles: FingerAngles;
  fsrContact?: number; // 0 - 100
  warningState?: boolean;
  colorCoded?: boolean;
  onFingerClick?: (fingerIndex: number) => void;
  selectedFinger?: number | null;
}

export default function HolographicHandScan({
  fingerAngles,
  fsrContact = 45,
  warningState = false,
  colorCoded = false,
  onFingerClick,
  selectedFinger = null,
}: HolographicHandScanProps) {
  // Okabe-Ito color definitions
  const okabeItoColors = ["#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2"];
  const fingerNames = ["THUMB", "INDEX", "MIDDLE", "RING", "PINKY"];

  // Compute 2D kinematics for hand skeleton
  // Hand origin in SVG viewBox (0,0) to (700, 850)
  const wristCenter = { x: 350, y: 640 };

  const fingerKinematics = useMemo(() => {
    // Finger base offsets at MCP joints from wrist center
    const bases = [
      { x: 270, y: 550, baseAngle: -2.35, lens: [45, 38, 32], name: "THUMB", id: 0 },
      { x: 305, y: 440, baseAngle: -1.70, lens: [55, 42, 34], name: "INDEX", id: 1 },
      { x: 350, y: 425, baseAngle: -1.57, lens: [62, 46, 36], name: "MIDDLE", id: 2 },
      { x: 395, y: 440, baseAngle: -1.44, lens: [56, 43, 34], name: "RING", id: 3 },
      { x: 435, y: 475, baseAngle: -1.25, lens: [46, 34, 28], name: "PINKY", id: 4 },
    ];

    const values = [
      fingerAngles.thumb,
      fingerAngles.index,
      fingerAngles.middle,
      fingerAngles.ring,
      fingerAngles.pinky,
    ];

    return bases.map((f, idx) => {
      const flex = Math.min(Math.max(values[idx] || 0, 0), 100) / 100;
      // Joint curl angle based on flexion
      const curlPerJoint = flex * 0.48; // radians per phalange

      const joints: { x: number; y: number }[] = [{ x: f.x, y: f.y }];
      let curAngle = f.baseAngle;

      for (let s = 0; s < f.lens.length; s++) {
        // Bend inward
        if (idx === 0) {
          curAngle += curlPerJoint * 0.7; // Thumb flexes across palm
        } else {
          curAngle += curlPerJoint * (idx < 2 ? 0.3 : -0.2); // slight natural inward curl
        }
        const prev = joints[joints.length - 1];
        // Shorten projected length as it curls in 3D perspective
        const perspectiveScale = 1.0 - flex * 0.35 * (s + 1) / 3;
        const effLen = f.lens[s] * perspectiveScale;
        const nextX = prev.x + Math.cos(curAngle) * effLen;
        const nextY = prev.y + Math.sin(curAngle) * effLen;
        joints.push({ x: nextX, y: nextY });
      }

      return {
        ...f,
        joints,
        flexPercent: Math.round(flex * 100),
        color: colorCoded ? okabeItoColors[idx] : warningState ? "#f87171" : "#fbbf24",
      };
    });
  }, [fingerAngles, colorCoded, warningState]);

  const glowColor = warningState ? "#ef4444" : "#f59e0b";
  const glowRgba = warningState ? "rgba(239, 68, 68, 0.6)" : "rgba(245, 158, 11, 0.6)";

  return (
    <div className="relative w-full h-full flex items-center justify-center select-none overflow-hidden bg-black/40">
      {/* Background Radial Amber/Gold Glow (Volumetric Radiance like the reference image) */}
      <div
        className="absolute w-[440px] h-[480px] rounded-full pointer-events-none blur-[70px] opacity-40 transition-all duration-700"
        style={{
          background: warningState
            ? "radial-gradient(circle, rgba(239,68,68,0.7) 0%, rgba(185,28,28,0.3) 50%, transparent 80%)"
            : "radial-gradient(circle, rgba(251,191,36,0.8) 0%, rgba(217,119,6,0.45) 50%, rgba(120,53,15,0.15) 75%, transparent 90%)",
          top: "42%",
          left: "50%",
          transform: "translate(-50%, -50%)",
        }}
      />

      {/* Main SVG Holographic Hand HUD */}
      <svg
        viewBox="0 0 700 850"
        className="w-full h-full max-h-[85vh] object-contain drop-shadow-[0_0_20px_rgba(245,158,11,0.25)]"
      >
        <defs>
          {/* Amber Glow Filter */}
          <filter id="hudGlow" x="-20%" y="-20%" width="140%" height="140%">
            <feGaussianBlur stdDeviation="3.5" result="blur" />
            <feMerge>
              <feMergeNode in="blur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>

          {/* Intense Bone Core Glow */}
          <filter id="intenseGlow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="8" result="blur1" />
            <feGaussianBlur stdDeviation="3" result="blur2" />
            <feMerge>
              <feMergeNode in="blur1" />
              <feMergeNode in="blur2" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>

          {/* Linear Gradients for Bones */}
          <linearGradient id="amberBoneGrad" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#fffbeb" stopOpacity="0.95" />
            <stop offset="30%" stopColor="#fde68a" stopOpacity="0.9" />
            <stop offset="70%" stopColor="#f59e0b" stopOpacity="0.8" />
            <stop offset="100%" stopColor="#b45309" stopOpacity="0.6" />
          </linearGradient>

          <linearGradient id="amberCoreGrad" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#ffffff" stopOpacity="1" />
            <stop offset="50%" stopColor="#fbbf24" stopOpacity="0.9" />
            <stop offset="100%" stopColor="#d97706" stopOpacity="0.4" />
          </linearGradient>

          <linearGradient id="targetRayGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#f59e0b" stopOpacity="0.05" />
            <stop offset="50%" stopColor="#f59e0b" stopOpacity="0.35" />
            <stop offset="100%" stopColor="#fbbf24" stopOpacity="0.8" />
          </linearGradient>
        </defs>

        {/* ================================================================= */}
        {/* 1. CORNER TARGETING RAYS & HEX BEACONS (MATCHING REFERENCE IMAGE) */}
        {/* ================================================================= */}
        {/* Top-Left Targeting Beams & Hex AO */}
        <g opacity="0.85">
          {/* Hex Beacon AO Top-Left */}
          <polygon
            points="140,260 155,250 170,260 170,278 155,288 140,278"
            fill="none"
            stroke="#f59e0b"
            strokeWidth="1.2"
          />
          <circle cx="155" cy="269" r="3" fill="#f59e0b" />
          <text x="180" y="273" fill="#f59e0b" fontSize="10" fontFamily="'Share Tech Mono', monospace" letterSpacing="2">
            A0
          </text>
          {/* Dotted Ray Lines from Hex toward Hand MCP */}
          {[-8, -4, 0, 4, 8].map((offset, i) => (
            <line
              key={i}
              x1="155"
              y1="269"
              x2={305 + offset * 5}
              y2={440 + offset * 3}
              stroke="#f59e0b"
              strokeWidth="0.8"
              strokeDasharray="2,5"
              opacity={0.3 + (i === 2 ? 0.4 : 0.1)}
            />
          ))}
          {/* Outer corner ray */}
          <line x1="80" y1="210" x2="140" y2="260" stroke="#f59e0b" strokeWidth="0.8" strokeDasharray="1,4" opacity="0.5" />
          <line x1="120" y1="220" x2="155" y2="250" stroke="#f59e0b" strokeWidth="0.8" strokeDasharray="1,4" opacity="0.4" />
        </g>

        {/* Top-Right Targeting Beams & Hex AO */}
        <g opacity="0.85">
          {/* Hex Beacon AO Top-Right */}
          <polygon
            points="530,260 545,250 560,260 560,278 545,288 530,278"
            fill="none"
            stroke="#f59e0b"
            strokeWidth="1.2"
          />
          <circle cx="545" cy="269" r="3" fill="#f59e0b" />
          <text x="570" y="273" fill="#f59e0b" fontSize="10" fontFamily="'Share Tech Mono', monospace" letterSpacing="2">
            A0
          </text>
          {/* Dotted Ray Lines from Hex toward Pinky MCP */}
          {[-8, -4, 0, 4, 8].map((offset, i) => (
            <line
              key={i}
              x1="545"
              y1="269"
              x2={435 + offset * 5}
              y2={475 + offset * 3}
              stroke="#f59e0b"
              strokeWidth="0.8"
              strokeDasharray="2,5"
              opacity={0.3 + (i === 2 ? 0.4 : 0.1)}
            />
          ))}
          {/* Outer corner ray */}
          <line x1="620" y1="210" x2="560" y2="260" stroke="#f59e0b" strokeWidth="0.8" strokeDasharray="1,4" opacity="0.5" />
          <line x1="580" y1="220" x2="545" y2="250" stroke="#f59e0b" strokeWidth="0.8" strokeDasharray="1,4" opacity="0.4" />
        </g>

        {/* Bottom-Left Targeting Beams & Hex AO (CL-1) */}
        <g opacity="0.85">
          <polygon
            points="140,730 155,720 170,730 170,748 155,758 140,748"
            fill="none"
            stroke="#f59e0b"
            strokeWidth="1.2"
          />
          <circle cx="155" cy="739" r="3" fill="#f59e0b" />
          <text x="180" y="743" fill="#f59e0b" fontSize="10" fontFamily="'Share Tech Mono', monospace" letterSpacing="2">
            A0
          </text>
          <text x="100" y="720" fill="#f59e0b" fontSize="10" fontFamily="'Share Tech Mono', monospace" letterSpacing="1">
            CL - 1
          </text>
          {/* Dotted Ray Lines to Wrist */}
          {[-6, -3, 0, 3, 6].map((offset, i) => (
            <line
              key={i}
              x1="155"
              y1="739"
              x2={340 + offset * 6}
              y2={650 + offset * 4}
              stroke="#f59e0b"
              strokeWidth="0.8"
              strokeDasharray="2,5"
              opacity={0.35 + (i === 2 ? 0.35 : 0.1)}
            />
          ))}
          <line x1="80" y1="780" x2="140" y2="740" stroke="#f59e0b" strokeWidth="0.8" strokeDasharray="1,4" opacity="0.4" />
        </g>

        {/* Bottom-Right Targeting Beams & Hex AO (CL-2) */}
        <g opacity="0.85">
          <polygon
            points="530,730 545,720 560,730 560,748 545,758 530,748"
            fill="none"
            stroke="#f59e0b"
            strokeWidth="1.2"
          />
          <circle cx="545" cy="739" r="3" fill="#f59e0b" />
          <text x="570" y="743" fill="#f59e0b" fontSize="10" fontFamily="'Share Tech Mono', monospace" letterSpacing="2">
            A0
          </text>
          <text x="500" y="720" fill="#f59e0b" fontSize="10" fontFamily="'Share Tech Mono', monospace" letterSpacing="1">
            CL - 2
          </text>
          {/* Dotted Ray Lines to Wrist */}
          {[-6, -3, 0, 3, 6].map((offset, i) => (
            <line
              key={i}
              x1="545"
              y1="739"
              x2={360 + offset * 6}
              y2={650 + offset * 4}
              stroke="#f59e0b"
              strokeWidth="0.8"
              strokeDasharray="2,5"
              opacity={0.35 + (i === 2 ? 0.35 : 0.1)}
            />
          ))}
          <line x1="620" y1="780" x2="560" y2="740" stroke="#f59e0b" strokeWidth="0.8" strokeDasharray="1,4" opacity="0.4" />
        </g>

        {/* ================================================================= */}
        {/* 2. HUD TARGETING RETICLES & LABELS (MATCHING REFERENCE IMAGE)     */}
        {/* ================================================================= */}
        {/* Left vertical scale ticks & numbers */}
        <g fill="#92400e" fontSize="11" fontFamily="'Share Tech Mono', monospace">
          {/* Up/Down Arrow Triangles */}
          <polygon points="40,230 46,238 34,238" fill="#f59e0b" />
          <polygon points="40,248 46,240 34,240" fill="#f59e0b" />
          <text x="25" y="210" fill="#fbbf24" fontSize="15" fontWeight="bold">
            +51
          </text>
          <text x="32" y="270" fill="#f59e0b" fontSize="10" letterSpacing="1">
            CNTRL. CHRT
          </text>

          <text x="55" y="340" fill="#d97706">
            +27
          </text>
          <line x1="45" y1="337" x2="52" y2="337" stroke="#f59e0b" strokeWidth="1" />

          <text x="55" y="380" fill="#d97706">
            +35
          </text>
          <line x1="45" y1="377" x2="52" y2="377" stroke="#f59e0b" strokeWidth="1" />

          <text x="55" y="420" fill="#d97706">
            75
          </text>
          <line x1="45" y1="417" x2="52" y2="417" stroke="#f59e0b" strokeWidth="1" />

          <text x="55" y="460" fill="#fbbf24" fontWeight="bold">
            A7
          </text>

          {/* Coordinate callout markers */}
          <text x="120" y="220" fill="#78350f" fontSize="9">
            CL - 1
          </text>
          <text x="510" y="220" fill="#78350f" fontSize="9">
            CL - 2
          </text>
          <text x="135" y="340" fill="#78350f" fontSize="9">
            CAG +15
          </text>
          <text x="510" y="340" fill="#78350f" fontSize="9">
            CAG +15
          </text>
          <text x="165" y="380" fill="#78350f" fontSize="8">
            S +17
          </text>
          <text x="525" y="380" fill="#78350f" fontSize="8">
            S +17
          </text>
          <text x="145" y="400" fill="#78350f" fontSize="8">
            F - 25
          </text>
          <text x="515" y="400" fill="#78350f" fontSize="8">
            S - 17
          </text>
          <text x="165" y="415" fill="#78350f" fontSize="8">
            CAG +15
          </text>
          <text x="500" y="415" fill="#78350f" fontSize="8">
            S +10
          </text>
        </g>

        {/* Top Centered Calibration Bracket `^` */}
        <g stroke="#f59e0b" strokeWidth="1.2" opacity="0.8">
          <polyline points="330,195 350,180 370,195" fill="none" />
          <line x1="350" y1="165" x2="350" y2="175" />
          <line x1="315" y1="180" x2="320" y2="180" />
          <line x1="380" y1="180" x2="385" y2="180" />
        </g>

        {/* Bottom Centered Calibration Bracket `v` */}
        <g stroke="#f59e0b" strokeWidth="1.2" opacity="0.8">
          <polyline points="330,760 350,775 370,760" fill="none" />
          <line x1="350" y1="780" x2="350" y2="790" />
        </g>

        {/* ================================================================= */}
        {/* 3. CENTER HOLOGRAPHIC BIOMECHANICAL SKELETON HAND                */}
        {/* ================================================================= */}
        <g filter="url(#intenseGlow)" className="animate-holo-pulse">
          {/* Volumetric Palmar Core Radiance (mimics the glowing ribcage core in image) */}
          <ellipse
            cx={wristCenter.x}
            cy="520"
            rx="95"
            ry="75"
            fill="url(#amberCoreGrad)"
            opacity="0.35"
          />

          {/* Forearm Distal Radius & Ulna with Holographic Shading */}
          <g opacity="0.9">
            {/* Radius (lateral/thumb side) */}
            <path
              d="M 315 780 C 318 730, 312 680, 320 650 L 338 650 C 330 680, 332 730, 330 780 Z"
              fill="url(#amberBoneGrad)"
              stroke="#fbbf24"
              strokeWidth="1.5"
            />
            {/* Ulna (medial/pinky side) */}
            <path
              d="M 358 780 C 356 730, 360 680, 355 650 L 372 650 C 378 680, 372 730, 374 780 Z"
              fill="url(#amberBoneGrad)"
              stroke="#fbbf24"
              strokeWidth="1.5"
            />
            {/* Interosseous membrane / cybernetic conduits */}
            <line x1="334" y1="670" x2="356" y2="670" stroke="#f59e0b" strokeWidth="1" strokeDasharray="2,3" opacity="0.7" />
            <line x1="332" y1="710" x2="357" y2="710" stroke="#f59e0b" strokeWidth="1" strokeDasharray="2,3" opacity="0.7" />
            <line x1="330" y1="750" x2="358" y2="750" stroke="#f59e0b" strokeWidth="1" strokeDasharray="2,3" opacity="0.7" />
          </g>

          {/* Carpal Bones Cluster (Scaphoid, Lunate, Triquetrum, Pisiform, Trapezium, Trapezoid, Capitate, Hamate) */}
          <g>
            {[
              { cx: 325, cy: 635, rx: 11, ry: 8 },
              { cx: 348, cy: 633, rx: 10, ry: 8 },
              { cx: 368, cy: 637, rx: 9, ry: 7 },
              { cx: 318, cy: 618, rx: 10, ry: 8 },
              { cx: 338, cy: 615, rx: 9, ry: 10 },
              { cx: 358, cy: 616, rx: 10, ry: 9 },
              { cx: 375, cy: 620, rx: 8, ry: 8 },
            ].map((c, i) => (
              <ellipse
                key={i}
                cx={c.cx}
                cy={c.cy}
                rx={c.rx}
                ry={c.ry}
                fill="url(#amberBoneGrad)"
                stroke="#fef08a"
                strokeWidth="1.2"
                opacity="0.95"
              />
            ))}
          </g>

          {/* Metacarpal Rays (5 bones leading to finger bases) */}
          <g>
            {fingerKinematics.map((f, i) => {
              const carpalAnchor = {
                x: 318 + i * 14,
                y: 612 + (i === 0 ? 12 : i === 4 ? 6 : 0),
              };
              const mcp = f.joints[0];
              return (
                <g key={`meta-${i}`}>
                  {/* Bone shaft with realistic taper */}
                  <line
                    x1={carpalAnchor.x}
                    y1={carpalAnchor.y}
                    x2={mcp.x}
                    y2={mcp.y}
                    stroke="url(#amberBoneGrad)"
                    strokeWidth={i === 0 ? 11 : 8.5}
                    strokeLinecap="round"
                  />
                  {/* Inner bone glowing marrow line */}
                  <line
                    x1={carpalAnchor.x}
                    y1={carpalAnchor.y}
                    x2={mcp.x}
                    y2={mcp.y}
                    stroke="#ffffff"
                    strokeWidth="2.5"
                    strokeLinecap="round"
                    opacity="0.85"
                  />
                  {/* Circuit traces running along the metacarpal */}
                  <line
                    x1={carpalAnchor.x + 3}
                    y1={carpalAnchor.y}
                    x2={mcp.x + 3}
                    y2={mcp.y}
                    stroke="#f59e0b"
                    strokeWidth="0.8"
                    strokeDasharray="1,4"
                    opacity="0.6"
                  />
                </g>
              );
            })}
          </g>

          {/* Phalanges (Proximal, Intermediate, Distal) & Articulated Joints */}
          {fingerKinematics.map((f, fIdx) => (
            <g
              key={`finger-${fIdx}`}
              className="cursor-pointer transition-opacity hover:opacity-100"
              onClick={() => onFingerClick?.(fIdx)}
            >
              {/* Draw bone segments between joints */}
              {f.joints.slice(0, -1).map((jStart, sIdx) => {
                const jEnd = f.joints[sIdx + 1];
                const isDistal = sIdx === f.joints.length - 2;
                const strokeW = fIdx === 0 ? 10 - sIdx * 2 : 8.5 - sIdx * 1.8;

                return (
                  <g key={`seg-${sIdx}`}>
                    {/* Outer bone body */}
                    <line
                      x1={jStart.x}
                      y1={jStart.y}
                      x2={jEnd.x}
                      y2={jEnd.y}
                      stroke={colorCoded ? f.color : "url(#amberBoneGrad)"}
                      strokeWidth={strokeW}
                      strokeLinecap="round"
                    />
                    {/* Glowing bone core */}
                    <line
                      x1={jStart.x}
                      y1={jStart.y}
                      x2={jEnd.x}
                      y2={jEnd.y}
                      stroke="#ffffff"
                      strokeWidth={strokeW * 0.3}
                      strokeLinecap="round"
                      opacity="0.9"
                    />
                    {/* Lateral tendon / flex-sensor guide wire */}
                    <line
                      x1={jStart.x + 2}
                      y1={jStart.y + 2}
                      x2={jEnd.x + 2}
                      y2={jEnd.y + 2}
                      stroke={f.color}
                      strokeWidth="1"
                      strokeDasharray="2,3"
                      opacity="0.8"
                    />
                  </g>
                );
              })}

              {/* Draw Joint Knots (MCP, PIP, DIP) */}
              {f.joints.map((joint, jIdx) => {
                const isTip = jIdx === f.joints.length - 1;
                const isMCP = jIdx === 0;
                const radius = isMCP ? 7 : isTip ? 5 : 6;

                return (
                  <g key={`joint-${jIdx}`}>
                    {/* Joint Capsule Outer Ring */}
                    <circle
                      cx={joint.x}
                      cy={joint.y}
                      r={radius + 3}
                      fill="none"
                      stroke={f.color}
                      strokeWidth="1.2"
                      opacity="0.75"
                    />
                    {/* Solid Joint Core */}
                    <circle
                      cx={joint.x}
                      cy={joint.y}
                      r={radius}
                      fill="#ffffff"
                      stroke={f.color}
                      strokeWidth="2"
                    />

                    {/* Fingertip FSR Pressure Sensor Contact Halo */}
                    {isTip && (
                      <g>
                        {/* Radiating concentric pulse circles */}
                        <circle
                          cx={joint.x}
                          cy={joint.y}
                          r={14}
                          fill="none"
                          stroke={f.color}
                          strokeWidth="1"
                          strokeDasharray="3,3"
                          className="animate-pulse"
                          opacity="0.8"
                        />
                        <circle
                          cx={joint.x}
                          cy={joint.y}
                          r={20}
                          fill="none"
                          stroke={f.color}
                          strokeWidth="0.7"
                          opacity="0.4"
                        />
                        {/* FSR Contact Pressure label */}
                        <text
                          x={joint.x + (fIdx <= 1 ? -28 : 10)}
                          y={joint.y - 10}
                          fill={f.color}
                          fontSize="9"
                          fontFamily="'Share Tech Mono', monospace"
                          fontWeight="bold"
                        >
                          {f.flexPercent}%
                        </text>
                      </g>
                    )}
                  </g>
                );
              })}
            </g>
          ))}

          {/* Wrist 6-DOF IMU Orientation Gimbal Ring & Angle Crosshairs */}
          <g opacity="0.85">
            <ellipse
              cx={wristCenter.x}
              cy={wristCenter.y}
              rx="45"
              ry="18"
              fill="none"
              stroke="#fbbf24"
              strokeWidth="1.5"
              strokeDasharray="5,3"
            />
            <ellipse
              cx={wristCenter.x}
              cy={wristCenter.y}
              rx="55"
              ry="22"
              fill="none"
              stroke="#d97706"
              strokeWidth="0.8"
            />
            {/* Gimbal orientation crosshairs */}
            <line x1={wristCenter.x - 65} y1={wristCenter.y} x2={wristCenter.x + 65} y2={wristCenter.y} stroke="#f59e0b" strokeWidth="1" strokeDasharray="3,3" />
            <line x1={wristCenter.x} y1={wristCenter.y - 30} x2={wristCenter.x} y2={wristCenter.y + 30} stroke="#f59e0b" strokeWidth="1" strokeDasharray="3,3" />
            <circle cx={wristCenter.x} cy={wristCenter.y} r="4" fill="#fbbf24" />
            <text
              x={wristCenter.x + 22}
              y={wristCenter.y - 12}
              fill="#fbbf24"
              fontSize="8"
              fontFamily="'Share Tech Mono', monospace"
            >
              IMU: 6-DOF
            </text>
          </g>
        </g>

        {/* Selected Finger Callout Box (if a finger is clicked) */}
        {selectedFinger !== null && fingerKinematics[selectedFinger] && (
          <g transform={`translate(${fingerKinematics[selectedFinger].joints[0].x - 60}, ${fingerKinematics[selectedFinger].joints[0].y - 50})`}>
            <rect width="120" height="36" rx="4" fill="#0d1117" stroke="#fbbf24" strokeWidth="1.2" opacity="0.9" />
            <text x="10" y="16" fill="#fbbf24" fontSize="10" fontFamily="'Orbitron', monospace" fontWeight="bold">
              {fingerNames[selectedFinger]} SENSOR
            </text>
            <text x="10" y="28" fill="#e2e8f0" fontSize="9" fontFamily="'Share Tech Mono', monospace">
              ROM: {fingerKinematics[selectedFinger].flexPercent}% • 50Hz OK
            </text>
          </g>
        )}
      </svg>
    </div>
  );
}
