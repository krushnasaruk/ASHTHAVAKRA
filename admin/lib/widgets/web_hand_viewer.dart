import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

enum HandRenderMode { skin, mesh, xray }

class WebHandViewer extends StatelessWidget {
  final List<double> normalizedFlex; // [thumb, index, middle, ring, pinky] in 0-100%
  final double height;
  final bool isConnected;
  final HandRenderMode renderMode;

  const WebHandViewer({
    super.key,
    required this.normalizedFlex,
    this.height = 320,
    this.isConnected = true,
    this.renderMode = HandRenderMode.skin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF070908),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.border, width: 1.0),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radial Vignette
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: RadialGradient(
                center: const Alignment(0, 0.1),
                radius: 0.9,
                colors: [
                  const Color(0xFF141A17).withOpacity(0.4),
                  const Color(0xFF070908),
                ],
              ),
            ),
          ),

          // Custom Biomechanical 2D/3D Kinematic Skeleton Renderer
          CustomPaint(
            size: Size(double.infinity, height),
            painter: _KinematicHandPainter(
              normalizedFlex: normalizedFlex,
              isStreaming: isConnected,
            ),
          ),

          // Top Header Overlay
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.view_in_ar, color: AdminTheme.lime, size: 13),
                    SizedBox(width: 4),
                    Text(
                      '3D HAND MONITOR',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AdminTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isConnected ? AdminTheme.lime.withOpacity(0.12) : const Color(0xFF222624),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isConnected ? AdminTheme.lime.withOpacity(0.3) : AdminTheme.border),
                  ),
                  child: Text(
                    isConnected ? '25 HZ' : 'OFFLINE',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: isConnected ? AdminTheme.lime : AdminTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Nonclinical Notice
          const Positioned(
            bottom: 10,
            child: Text(
              'ENGINEERING DEMONSTRATION • BIOMECHANICAL KINEMATICS',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: Color(0xFF4A5550),
              ),
            ),
          ),
        ],
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
    final cy = size.height * 0.72; // Wrist center

    final bonePaint = Paint()
      ..color = const Color(0xFFC9D0D4)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final yellowShaftPaint = Paint()
      ..color = const Color(0xFFFFD54A)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final ringPaint = Paint()
      ..color = const Color(0xFFF5A623)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final carpalPaint = Paint()
      ..color = const Color(0xFF7A868C)
      ..style = PaintingStyle.fill;

    final skinPaint = Paint()
      ..color = const Color(0xFFD8E4EA).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw 8 Carpal bones in two rows at wrist base
    final carpalOffsets = [
      Offset(cx - 24, cy - 4), Offset(cx - 8, cy - 6), Offset(cx + 8, cy - 6), Offset(cx + 22, cy - 4),
      Offset(cx - 20, cy + 12), Offset(cx - 6, cy + 14), Offset(cx + 8, cy + 14), Offset(cx + 22, cy + 12),
    ];
    for (final pt in carpalOffsets) {
      canvas.drawCircle(pt, 4.5, carpalPaint);
    }

    // Finger parameters
    final fingerConfigs = [
      // Thumb
      {'baseX': cx - 26.0, 'baseY': cy - 8.0, 'angle': -0.75, 'len': [24.0, 18.0, 14.0], 'flex': normalizedFlex.isNotEmpty ? normalizedFlex[0] : 0.0},
      // Index
      {'baseX': cx - 14.0, 'baseY': cy - 18.0, 'angle': -0.15, 'len': [28.0, 20.0, 14.0], 'flex': normalizedFlex.length > 1 ? normalizedFlex[1] : 0.0},
      // Middle
      {'baseX': cx - 0.0, 'baseY': cy - 22.0, 'angle': 0.0, 'len': [32.0, 22.0, 16.0], 'flex': normalizedFlex.length > 2 ? normalizedFlex[2] : 0.0},
      // Ring
      {'baseX': cx + 14.0, 'baseY': cy - 18.0, 'angle': 0.12, 'len': [29.0, 20.0, 14.0], 'flex': normalizedFlex.length > 3 ? normalizedFlex[3] : 0.0},
      // Pinky
      {'baseX': cx + 26.0, 'baseY': cy - 10.0, 'angle': 0.28, 'len': [24.0, 16.0, 12.0], 'flex': normalizedFlex.length > 4 ? normalizedFlex[4] : 0.0},
    ];

    for (final cfg in fingerConfigs) {
      final double baseX = cfg['baseX'] as double;
      final double baseY = cfg['baseY'] as double;
      final double baseAngle = cfg['angle'] as double;
      final List<double> lens = cfg['len'] as List<double>;
      final double flex = isStreaming ? ((cfg['flex'] as double) / 100.0).clamp(0.0, 1.0) : 0.0;

      // Draw Metacarpal (from carpal to knuckle MCP)
      canvas.drawLine(Offset(cx, cy), Offset(baseX, baseY), bonePaint);
      canvas.drawCircle(Offset(baseX, baseY), 4.5, carpalPaint);
      canvas.drawCircle(Offset(baseX, baseY), 5.5, ringPaint);

      // Articulate Phalanx chain with forward kinematics
      double curX = baseX;
      double curY = baseY;
      double curAngle = -1.57 + baseAngle;

      final curls = [flex * 0.85, flex * 1.1, flex * 0.7];

      for (int i = 0; i < 3; i++) {
        curAngle += curls[i] * 0.45;
        final segLen = lens[i] * 1.6;
        final nextX = curX + math.cos(curAngle) * segLen;
        final nextY = curY + math.sin(curAngle) * segLen;

        // Yellow Shaft with glowing highlight
        canvas.drawLine(Offset(curX, curY), Offset(nextX, nextY), yellowShaftPaint);
        // Joint End Epiphysis
        canvas.drawCircle(Offset(nextX, nextY), 3.5, carpalPaint);

        // Amber Joint Ring
        if (i < 2) {
          canvas.drawCircle(Offset(nextX, nextY), 4.5, ringPaint);
        }

        // Translucent Skin Outline envelope around segment
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset((curX + nextX) / 2, (curY + nextY) / 2),
            width: 14.0 * (1.0 - i * 0.15),
            height: (lens[i] * 1.8),
          ),
          skinPaint,
        );

        curX = nextX;
        curY = nextY;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KinematicHandPainter oldDelegate) {
    return true;
  }
}
