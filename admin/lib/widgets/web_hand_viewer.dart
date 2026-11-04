import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';
import 'hand_view_platform_stub.dart'
    if (dart.library.html) 'hand_view_platform_web.dart';
import 'holographic_hand_scan.dart';

/// All available hand visualization modes and skins matching the mobile patient app.
enum HandRenderMode {
  skin,        // Realistic 3D Human Hand Model with skin & flesh texture (hand.glb)
  mesh,        // 3D Polygonal Wireframe Mesh on realistic hand
  xray,        // 3D Translucent X-Ray with glowing joints
  skeleton,    // 3D 27-Bone Anatomical Osteology Skeleton (anatomy.html / skeleton.glb)
  holographic, // Glowing Cybernetic Kinematic HUD Scanner (Okabe-Ito colors + FSR)
}

/// 3D Interactive Multi-Skin Hand WebGL & Kinematic Viewer for Admin Cockpit.
///
/// Seamlessly supports all hand representations from the mobile app:
/// 1. Realistic 3D Human Hand Mesh (Skin, Mesh, X-Ray) from assets/hand/hand_view.html
/// 2. 27-Bone Anatomical Hand Skeleton from assets/hand/anatomy.html
/// 3. Cybernetic Holographic Kinematics Scanner with palmar FSR pressure field
class WebHandViewer extends StatefulWidget {
  final List<double> normalizedFlex; // [thumb, index, middle, ring, pinky] in 0-100%
  final double? height;
  final bool isConnected;
  final HandRenderMode renderMode;
  final List<int>? imu;
  final double fsrContact;
  final bool showControls;

  const WebHandViewer({
    super.key,
    required this.normalizedFlex,
    this.height = 320,
    this.isConnected = true,
    this.renderMode = HandRenderMode.skin,
    this.imu,
    this.fsrContact = 0.0,
    this.showControls = true,
  });

  @override
  State<WebHandViewer> createState() => _WebHandViewerState();
}

class _WebHandViewerState extends State<WebHandViewer> {
  Timer? _telemetryBridgeTimer;
  Timer? _modeTimer1;
  Timer? _modeTimer2;
  DateTime _lastPacketTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 25 Hz telemetry packet dispatcher bridge
    _telemetryBridgeTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (mounted && widget.isConnected) {
        _dispatchFramePayload();
      }
    });

    // Ensure mode is applied once web iframe initializes
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyRenderMode();
        _modeTimer1 = Timer(const Duration(milliseconds: 250), _applyRenderMode);
        _modeTimer2 = Timer(const Duration(milliseconds: 700), _applyRenderMode);
      });
    }
  }

  void _applyRenderMode() {
    if (!mounted) return;
    if (widget.renderMode == HandRenderMode.skin ||
        widget.renderMode == HandRenderMode.mesh ||
        widget.renderMode == HandRenderMode.xray) {
      _sendRenderMode(widget.renderMode.name);
    }
  }

  @override
  void didUpdateWidget(covariant WebHandViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.renderMode != widget.renderMode) {
      _applyRenderMode();
    }
    _dispatchFramePayload();
  }

  @override
  void dispose() {
    _telemetryBridgeTimer?.cancel();
    _modeTimer1?.cancel();
    _modeTimer2?.cancel();
    super.dispose();
  }

  void _dispatchFramePayload() {
    final now = DateTime.now();
    if (now.difference(_lastPacketTime).inMilliseconds < 30) return;
    _lastPacketTime = now;

    final flex = widget.normalizedFlex;
    final thumb = (flex.isNotEmpty ? flex[0] : 0.0) / 100.0;
    final index = (flex.length > 1 ? flex[1] : 0.0) / 100.0;
    final middle = (flex.length > 2 ? flex[2] : 0.0) / 100.0;
    final ring = flex.length > 3 ? (flex[3] / 100.0) : (middle * 0.90);
    final pinky = flex.length > 4 ? (flex[4] / 100.0) : (middle * 0.75);

    double qw = 1.0, qx = 0.0, qy = 0.0, qz = 0.0;
    if (widget.imu != null && widget.imu!.length >= 4) {
      qw = widget.imu![0] / 1000.0;
      qx = widget.imu![1] / 1000.0;
      qy = widget.imu![2] / 1000.0;
      qz = widget.imu![3] / 1000.0;
    }

    final payload = jsonEncode({
      'action': 'setFrame',
      'data': {
        'curl': {
          'thumb': thumb.clamp(0.0, 1.0),
          'index': index.clamp(0.0, 1.0),
          'middle': middle.clamp(0.0, 1.0),
          'ring': ring.clamp(0.0, 1.0),
          'pinky': pinky.clamp(0.0, 1.0),
        },
        'imu': {
          'qw': qw,
          'qx': qx,
          'qy': qy,
          'qz': qz,
        },
      },
      'curl': {
        'thumb': thumb.clamp(0.0, 1.0),
        'index': index.clamp(0.0, 1.0),
        'middle': middle.clamp(0.0, 1.0),
        'ring': ring.clamp(0.0, 1.0),
        'pinky': pinky.clamp(0.0, 1.0),
      },
      'imu': {
        'qw': qw,
        'qx': qx,
        'qy': qy,
        'qz': qz,
      },
    });

    // Broadcasts frame to all mounted Three.js webgl iframes
    postPlatformMessage(payload);
  }

  void _sendRenderMode(String mode) {
    final payload = jsonEncode({'action': 'setRenderMode', 'mode': mode});
    postPlatformMessage(payload, 'admin-hand-realistic-3d');
  }

  void _sendAction(String action) {
    final payload = jsonEncode({'action': action});
    postPlatformMessage(payload);
  }

  @override
  Widget build(BuildContext context) {
    final isHolographic = widget.renderMode == HandRenderMode.holographic;

    final content = Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF040605),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2822), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background vignette
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, 0.05),
                radius: 0.95,
                colors: [
                  Color(0xFF0E1412),
                  Color(0xFF040605),
                ],
              ),
            ),
          ),

          // 1. WebGL 3D Hand Views & Holographic Scanner on Web
          if (kIsWeb)
            Positioned.fill(
              child: Stack(
                children: [
                  // Realistic 3D Human Hand (Skin, Mesh, X-Ray) from hand.glb
                  Offstage(
                    offstage: widget.renderMode == HandRenderMode.skeleton || isHolographic,
                    child: buildPlatformHandView(
                      viewType: 'admin-hand-realistic-3d',
                      assetUrl: 'assets/hand/hand_view.html',
                    ),
                  ),

                  // 27-Bone Anatomical Skeleton from anatomy.html
                  Offstage(
                    offstage: widget.renderMode != HandRenderMode.skeleton,
                    child: buildPlatformHandView(
                      viewType: 'admin-hand-anatomy-3d',
                      assetUrl: 'assets/hand/anatomy.html',
                    ),
                  ),

                  // Cybernetic Holographic Kinematics Scanner
                  if (isHolographic)
                    Positioned.fill(
                      child: HolographicHandScanWidget(
                        flexValues: widget.normalizedFlex,
                        fsrContact: widget.fsrContact,
                        isDemo3: true,
                      ),
                    ),
                ],
              ),
            ),

          // 2. Biomechanical Painter (Fallback for VM tests or non-web)
          if (!kIsWeb)
            Positioned.fill(
              child: isHolographic
                  ? HolographicHandScanWidget(
                      flexValues: widget.normalizedFlex,
                      fsrContact: widget.fsrContact,
                      isDemo3: true,
                    )
                  : CustomPaint(
                      painter: _KinematicHandPainter(
                        normalizedFlex: widget.normalizedFlex,
                        isStreaming: widget.isConnected,
                      ),
                    ),
            ),

          // 3. Top HUD Status Header Overlay
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.isConnected ? AdminTheme.lime : AdminTheme.crimson,
                        shape: BoxShape.circle,
                        boxShadow: widget.isConnected
                            ? [
                                BoxShadow(
                                  color: AdminTheme.lime.withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '3D HAND MONITOR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AdminTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AdminTheme.lime.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AdminTheme.lime.withOpacity(0.3)),
                      ),
                      child: const Text(
                        '3D HUD: ON',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: AdminTheme.lime,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.isConnected ? const Color(0xFF16201B) : const Color(0xFF222624),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: widget.isConnected ? AdminTheme.lime.withOpacity(0.3) : AdminTheme.border,
                        ),
                      ),
                      child: Text(
                        widget.isConnected ? '25 HZ SENSOR STREAM' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: widget.isConnected ? AdminTheme.lime : AdminTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Clinician Camera & Orientation Controls Overlay
          if (widget.showControls)
            Positioned(
              left: 12,
              bottom: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHudButton(
                    icon: Icons.flip_camera_android,
                    label: 'PALM / BACK',
                    onTap: () => _sendAction('togglePalmBack'),
                  ),
                  const SizedBox(width: 6),
                  _buildHudButton(
                    icon: Icons.refresh,
                    label: 'RESET VIEW',
                    onTap: () => _sendAction('resetView'),
                  ),
                  const SizedBox(width: 6),
                  _buildHudButton(
                    icon: Icons.layers_clear,
                    label: 'CLEAR SELECTION',
                    onTap: () => _sendAction('clearSelection'),
                  ),
                ],
              ),
            ),

          // 5. Anatomical Specs Pill
          Positioned(
            right: 12,
            bottom: 44,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF141A17).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF26332C)),
                ),
                child: Text(
                  widget.renderMode == HandRenderMode.skeleton
                      ? '27 BONES • CARPALS + PHALANGES'
                      : (isHolographic
                          ? '27 BONES • CYBERNETIC KINEMATICS'
                          : '27 BONES • 3D RIG & SKIN'),
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AdminTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return content;
  }

  Widget _buildHudButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF141C18).withOpacity(0.88),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2B3A32)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: AdminTheme.lime),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AdminTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KinematicHandPainter extends CustomPainter {
  final List<double> normalizedFlex;
  final bool isStreaming;

  _KinematicHandPainter({
    required this.normalizedFlex,
    required this.isStreaming,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.76;

    final bonePaint = Paint()
      ..color = const Color(0xFFC9D0D4)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final yellowShaftPaint = Paint()
      ..color = const Color(0xFFFFD54A)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final ringPaint = Paint()
      ..color = const Color(0xFFF5A623)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final carpalPaint = Paint()
      ..color = const Color(0xFF8B9B9D)
      ..style = PaintingStyle.fill;

    // 8 Carpal Bones representation
    final carpalOffsets = [
      Offset(cx - 30, cy + 18), Offset(cx - 10, cy + 18), Offset(cx + 10, cy + 18), Offset(cx + 30, cy + 18),
      Offset(cx - 32, cy - 2),  Offset(cx - 12, cy - 2),  Offset(cx + 12, cy - 2),  Offset(cx + 32, cy - 2),
    ];
    for (final pt in carpalOffsets) {
      canvas.drawCircle(pt, 5.0, carpalPaint);
    }

    // 5 Metacarpals & Phalanges
    final fingerBases = [
      Offset(cx - 48, cy - 12), // Thumb
      Offset(cx - 24, cy - 22), // Index
      Offset(cx, cy - 28),      // Middle
      Offset(cx + 24, cy - 22), // Ring
      Offset(cx + 46, cy - 12), // Pinky
    ];

    final fingerAngles = [-0.55, -0.15, 0.0, 0.15, 0.40];
    final lengths = [24.0, 32.0, 36.0, 32.0, 26.0];

    for (int i = 0; i < 5; i++) {
      final flex = (normalizedFlex.length > i ? normalizedFlex[i] : 0.0) / 100.0;
      final base = fingerBases[i];
      final angle = fingerAngles[i];
      final len = lengths[i];

      // Metacarpal shaft
      final mcp = Offset(
        base.dx + math.sin(angle) * len * 1.2,
        base.dy - math.cos(angle) * len * 1.2,
      );
      canvas.drawLine(base, mcp, bonePaint);
      canvas.drawCircle(mcp, 3.2, ringPaint);

      // Proximal Phalanx
      final bend = flex * 1.3;
      final pip = Offset(
        mcp.dx + math.sin(angle - bend * 0.4) * len,
        mcp.dy - math.cos(angle - bend * 0.4) * len,
      );
      canvas.drawLine(mcp, pip, yellowShaftPaint);
      canvas.drawCircle(pip, 3.0, ringPaint);

      // Middle Phalanx
      final dip = Offset(
        pip.dx + math.sin(angle - bend * 0.8) * (len * 0.75),
        pip.dy - math.cos(angle - bend * 0.8) * (len * 0.75),
      );
      canvas.drawLine(pip, dip, yellowShaftPaint);
      canvas.drawCircle(dip, 2.5, ringPaint);

      // Distal Phalanx
      final tip = Offset(
        dip.dx + math.sin(angle - bend * 1.2) * (len * 0.55),
        dip.dy - math.cos(angle - bend * 1.2) * (len * 0.55),
      );
      canvas.drawLine(dip, tip, bonePaint);
      canvas.drawCircle(tip, 2.0, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _KinematicHandPainter oldDelegate) {
    return oldDelegate.normalizedFlex != normalizedFlex || oldDelegate.isStreaming != isStreaming;
  }
}
