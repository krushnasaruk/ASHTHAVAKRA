import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Holographic / 3D Kinematic Hand Scanner for ASHTHAVAKRA.
/// Computes joint angles, palmar contact pressure, and renders
/// glowing cybernetic skeletal kinematics with Okabe-Ito colors.
class HolographicHandScanWidget extends StatefulWidget {
  final List<double> flexValues; // 0.0 - 100.0 for 5 digits (Thumb..Pinky)
  final double fsrContact;       // 0.0 - 100.0 palmar contact pressure
  final bool isDemo3;            // True: 3-channel active (Thumb, Index, Middle)
  final bool showGlow;
  final bool warningMode;
  final ValueChanged<int>? onFingerSelected;

  const HolographicHandScanWidget({
    super.key,
    required this.flexValues,
    this.fsrContact = 0.0,
    this.isDemo3 = true,
    this.showGlow = true,
    this.warningMode = false,
    this.onFingerSelected,
  });

  @override
  State<HolographicHandScanWidget> createState() => _HolographicHandScanWidgetState();
}

class _HolographicHandScanWidgetState extends State<HolographicHandScanWidget> {
  int? _selectedFinger;

  @override
  Widget build(BuildContext context) {
    const pulse = 0.75;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF070D14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.warningMode
                ? const Color(0xFFFF3366)
                : const Color(0xFF00E5FF).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (widget.warningMode
                      ? const Color(0xFFFF3366)
                      : const Color(0xFF00E5FF))
                  .withOpacity(0.08),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // 1. Grid & Kinematics Canvas
            Positioned.fill(
              child: CustomPaint(
                painter: _HolographicHandPainter(
                  flexValues: widget.flexValues,
                  fsrContact: widget.fsrContact,
                  isDemo3: widget.isDemo3,
                  pulse: pulse,
                  warningMode: widget.warningMode,
                  selectedFinger: _selectedFinger,
                ),
              ),
            ),

                // 2. Status Overlay Pills
                Positioned(
                  top: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B2A).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: widget.isDemo3
                                ? const Color(0xFF00E676)
                                : const Color(0xFF00E5FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isDemo3 ? 'PROFILE: demo3 (3-CH)' : 'PROFILE: full5 (5-CH)',
                          style: const TextStyle(
                            color: Color(0xFFE0E6ED),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Contact Pressure Gauge (FSR)
                Positioned(
                  bottom: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B2A).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.fsrContact > 20
                            ? const Color(0xFF00E676)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 12,
                          color: widget.fsrContact > 20
                              ? const Color(0xFF00E676)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'FSR: ${widget.fsrContact.toStringAsFixed(0)}% (EVA BACKED)',
                          style: TextStyle(
                            color: widget.fsrContact > 20
                                ? const Color(0xFF00E676)
                                : const Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Interactive Tap Targets
                Positioned.fill(
                  child: GestureDetector(
                    onTapUp: (details) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null) return;
                      final local = details.localPosition;
                      final size = box.size;

                      // Map tap column to finger (0 to 4)
                      final col = (local.dx / size.width * 5).floor().clamp(0, 4);
                      setState(() {
                        _selectedFinger = (_selectedFinger == col) ? null : col;
                      });
                      if (widget.onFingerSelected != null) {
                        widget.onFingerSelected!(col);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
  }
}

class _HolographicHandPainter extends CustomPainter {
  final List<double> flexValues;
  final double fsrContact;
  final bool isDemo3;
  final double pulse;
  final bool warningMode;
  final int? selectedFinger;

  _HolographicHandPainter({
    required this.flexValues,
    required this.fsrContact,
    required this.isDemo3,
    required this.pulse,
    required this.warningMode,
    this.selectedFinger,
  });

  // Okabe-Ito colorblind-safe palette
  static const List<Color> fingerColors = [
    Color(0xFFE69F00), // Thumb
    Color(0xFF56B4E9), // Index
    Color(0xFF009E73), // Middle
    Color(0xFFF0E442), // Ring
    Color(0xFF0072B2), // Pinky
  ];

  static const List<String> fingerLabels = [
    'THUMB',
    'INDEX',
    'MIDDLE',
    'RING',
    'PINKY',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw Cybernetic Coordinate Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.04)
      ..strokeWidth = 1.0;

    for (double x = 0; x < w; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 2. Wrist Center & Carpal Arc
    final wristCenter = Offset(w * 0.50, h * 0.82);

    final carpalPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.20 + pulse * 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawArc(
      Rect.fromCircle(center: wristCenter, radius: w * 0.18),
      math.pi * 0.85,
      math.pi * 1.30,
      false,
      carpalPaint,
    );

    // 3. Palmar FSR Pressure Ring
    final fsrRadius = 14.0 + (fsrContact / 100.0) * 12.0;
    final fsrPaint = Paint()
      ..color = (fsrContact > 25 ? const Color(0xFF00E676) : const Color(0xFF00E5FF))
          .withOpacity(0.15 + (fsrContact / 100.0) * 0.40)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.48, h * 0.62), fsrRadius, fsrPaint);

    final fsrBorderPaint = Paint()
      ..color = (fsrContact > 25 ? const Color(0xFF00E676) : const Color(0xFF00E5FF))
          .withOpacity(0.60 + pulse * 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(w * 0.48, h * 0.62), fsrRadius, fsrBorderPaint);

    // 4. Base Kinematic Layout for 5 digits
    final bases = [
      {'dx': -0.26, 'dy': -0.15, 'baseAngle': -2.30, 'lens': [0.12, 0.10, 0.08]}, // Thumb
      {'dx': -0.14, 'dy': -0.28, 'baseAngle': -1.68, 'lens': [0.15, 0.11, 0.09]}, // Index
      {'dx':  0.00, 'dy': -0.32, 'baseAngle': -1.57, 'lens': [0.17, 0.12, 0.10]}, // Middle
      {'dx':  0.13, 'dy': -0.28, 'baseAngle': -1.45, 'lens': [0.15, 0.11, 0.09]}, // Ring
      {'dx':  0.24, 'dy': -0.22, 'baseAngle': -1.28, 'lens': [0.12, 0.09, 0.07]}, // Pinky
    ];

    for (int i = 0; i < 5; i++) {
      final isChannelActive = !isDemo3 || (i < 3); // demo3 instruments Thumb, Index, Middle
      final flexPct = (i < flexValues.length ? flexValues[i] : 0.0).clamp(0.0, 100.0);
      final flexNorm = flexPct / 100.0;
      final curlPerJoint = flexNorm * 0.46; // radians per phalange

      final b = bases[i];
      final mcp = Offset(
        wristCenter.dx + (b['dx'] as double) * w,
        wristCenter.dy + (b['dy'] as double) * h,
      );

      // Metacarpal connector from wrist to MCP
      final metaPaint = Paint()
        ..color = isChannelActive
            ? fingerColors[i].withOpacity(0.35)
            : const Color(0xFF334155).withOpacity(0.25)
        ..strokeWidth = 1.5;
      canvas.drawLine(wristCenter, mcp, metaPaint);

      // Phalange chain: MCP -> PIP -> DIP -> Tip
      final lens = (b['lens'] as List<double>);
      double angle = b['baseAngle'] as double;
      final joints = [mcp];

      for (int j = 0; j < lens.length; j++) {
        final lenPx = lens[j] * h;
        final nextJoint = Offset(
          joints.last.dx + math.cos(angle) * lenPx,
          joints.last.dy + math.sin(angle) * lenPx,
        );
        joints.add(nextJoint);
        angle += curlPerJoint; // curl inward
      }

      // Draw bone segments
      final isSelected = (selectedFinger == i);
      final bonePaint = Paint()
        ..color = !isChannelActive
            ? const Color(0xFF334155).withOpacity(0.30)
            : (isSelected ? Colors.white : fingerColors[i])
                .withOpacity(isSelected ? 0.95 : 0.70 + pulse * 0.20)
        ..strokeWidth = isSelected ? 3.5 : (isChannelActive ? 2.5 : 1.5)
        ..strokeCap = StrokeCap.round;

      for (int k = 0; k < joints.length - 1; k++) {
        canvas.drawLine(joints[k], joints[k + 1], bonePaint);
      }

      // Draw glowing joint nodes
      for (int k = 0; k < joints.length; k++) {
        final isTip = (k == joints.length - 1);
        final nodeRadius = isTip ? 4.5 : 3.0;

        final nodePaint = Paint()
          ..color = !isChannelActive
              ? const Color(0xFF475569)
              : (isTip ? const Color(0xFF00E5FF) : fingerColors[i])
          ..style = PaintingStyle.fill;

        canvas.drawCircle(joints[k], nodeRadius, nodePaint);

        if (isChannelActive && isTip) {
          final haloPaint = Paint()
            ..color = const Color(0xFF00E5FF).withOpacity(0.25 + pulse * 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawCircle(joints[k], nodeRadius + 3.0, haloPaint);
        }
      }

      // Channel Label & Percentage
      final tip = joints.last;
      final labelSpan = TextSpan(
        text: isChannelActive
            ? '${fingerLabels[i]}\n${flexPct.toStringAsFixed(0)}%'
            : '${fingerLabels[i]}\nESTIMATED',
        style: TextStyle(
          color: isChannelActive ? fingerColors[i] : const Color(0xFF64748B),
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      );
      final tp = TextPainter(
        text: labelSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(tip.dx - tp.width / 2, tip.dy - tp.height - 4));
    }
  }

  @override
  bool shouldRepaint(covariant _HolographicHandPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.flexValues != flexValues ||
        oldDelegate.fsrContact != fsrContact ||
        oldDelegate.isDemo3 != isDemo3 ||
        oldDelegate.selectedFinger != selectedFinger;
  }
}
