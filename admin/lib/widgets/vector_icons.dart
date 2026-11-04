import 'package:flutter/material.dart';

/// Rock-solid custom vector icons that do NOT depend on external font files
/// or icon tree shaking. Always guaranteed to render 100% sharply on Web and Android.
class VectorIcon extends StatelessWidget {
  final VectorIconType type;
  final double size;
  final Color color;

  const VectorIcon.taskProof({super.key, this.size = 20, this.color = const Color(0xFFC8F05F)})
      : type = VectorIconType.taskProof;

  const VectorIcon.judge({super.key, this.size = 20, this.color = const Color(0xFFC8F05F)})
      : type = VectorIconType.judge;

  const VectorIcon.routines({super.key, this.size = 20, this.color = const Color(0xFFC8F05F)})
      : type = VectorIconType.routines;

  const VectorIcon.preflight({super.key, this.size = 20, this.color = const Color(0xFFC8F05F)})
      : type = VectorIconType.preflight;

  const VectorIcon.scanner({super.key, this.size = 20, this.color = const Color(0xFF121715)})
      : type = VectorIconType.scanner;

  const VectorIcon.qrCode({super.key, this.size = 20, this.color = const Color(0xFFC8F05F)})
      : type = VectorIconType.qrCode;

  const VectorIcon.pinch({super.key, this.size = 20, this.color = const Color(0xFFC8F05F)})
      : type = VectorIconType.pinch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _VectorIconPainter(type, color),
      ),
    );
  }
}

enum VectorIconType {
  taskProof,
  judge,
  routines,
  preflight,
  scanner,
  qrCode,
  pinch,
}

class _VectorIconPainter extends CustomPainter {
  final VectorIconType type;
  final Color color;

  _VectorIconPainter(this.type, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.11).clamp(1.8, 3.2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (type) {
      case VectorIconType.taskProof:
        // Shield outline with checkmark
        final shieldPath = Path()
          ..moveTo(w * 0.5, h * 0.10)
          ..lineTo(w * 0.88, h * 0.22)
          ..lineTo(w * 0.88, h * 0.54)
          ..quadraticBezierTo(w * 0.5, h * 0.94, w * 0.5, h * 0.94)
          ..quadraticBezierTo(w * 0.12, h * 0.54, w * 0.12, h * 0.22)
          ..close();
        canvas.drawPath(shieldPath, strokePaint);

        // Checkmark inside shield
        final checkPath = Path()
          ..moveTo(w * 0.32, h * 0.50)
          ..lineTo(w * 0.46, h * 0.65)
          ..lineTo(w * 0.70, h * 0.36);
        canvas.drawPath(checkPath, strokePaint);
        break;

      case VectorIconType.judge:
        // Gavel angled at 45 degrees
        canvas.save();
        canvas.translate(w * 0.5, h * 0.5);
        canvas.rotate(-0.785398); // -45 deg

        // Hammer head
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(0, -h * 0.22), width: w * 0.54, height: h * 0.26),
            const Radius.circular(2.5),
          ),
          fillPaint,
        );

        // Handle
        final handlePaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = (w * 0.13).clamp(2.0, 3.5)
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(0, -h * 0.08), Offset(0, h * 0.40), handlePaint);
        canvas.restore();
        break;

      case VectorIconType.routines:
        // Dumbbell
        // Left head
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, h * 0.22, w * 0.18, h * 0.56), const Radius.circular(2)),
          fillPaint,
        );
        // Right head
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.70, h * 0.22, w * 0.18, h * 0.56), const Radius.circular(2)),
          fillPaint,
        );
        // Middle bar
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.43, w * 0.44, h * 0.14), const Radius.circular(1.5)),
          fillPaint,
        );
        break;

      case VectorIconType.preflight:
        // Clipboard with check lines
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.18, h * 0.16, w * 0.64, h * 0.76), const Radius.circular(3)),
          strokePaint,
        );
        // Clip top
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.36, h * 0.08, w * 0.28, h * 0.14), const Radius.circular(1.5)),
          fillPaint,
        );
        // Lines
        canvas.drawLine(Offset(w * 0.30, h * 0.40), Offset(w * 0.70, h * 0.40), strokePaint);
        canvas.drawLine(Offset(w * 0.30, h * 0.58), Offset(w * 0.70, h * 0.58), strokePaint);
        canvas.drawLine(Offset(w * 0.30, h * 0.76), Offset(w * 0.54, h * 0.76), strokePaint);
        break;

      case VectorIconType.scanner:
        // 4 Corner Viewfinder Brackets + Center Dot
        final cornerLen = w * 0.28;
        // Top-left
        canvas.drawLine(Offset(w * 0.12, h * 0.12), Offset(w * 0.12 + cornerLen, h * 0.12), strokePaint);
        canvas.drawLine(Offset(w * 0.12, h * 0.12), Offset(w * 0.12, h * 0.12 + cornerLen), strokePaint);
        // Top-right
        canvas.drawLine(Offset(w * 0.88, h * 0.12), Offset(w * 0.88 - cornerLen, h * 0.12), strokePaint);
        canvas.drawLine(Offset(w * 0.88, h * 0.12), Offset(w * 0.88, h * 0.12 + cornerLen), strokePaint);
        // Bottom-left
        canvas.drawLine(Offset(w * 0.12, h * 0.88), Offset(w * 0.12 + cornerLen, h * 0.88), strokePaint);
        canvas.drawLine(Offset(w * 0.12, h * 0.88), Offset(w * 0.12, h * 0.88 - cornerLen), strokePaint);
        // Bottom-right
        canvas.drawLine(Offset(w * 0.88, h * 0.88), Offset(w * 0.88 - cornerLen, h * 0.88), strokePaint);
        canvas.drawLine(Offset(w * 0.88, h * 0.88), Offset(w * 0.88, h * 0.88 - cornerLen), strokePaint);
        // Center cross / dot
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.12, fillPaint);
        break;

      case VectorIconType.qrCode:
        // 3 Corner QR blocks
        canvas.drawRect(Rect.fromLTWH(w * 0.10, h * 0.10, w * 0.34, h * 0.34), strokePaint);
        canvas.drawRect(Rect.fromLTWH(w * 0.19, h * 0.19, w * 0.16, h * 0.16), fillPaint);

        canvas.drawRect(Rect.fromLTWH(w * 0.56, h * 0.10, w * 0.34, h * 0.34), strokePaint);
        canvas.drawRect(Rect.fromLTWH(w * 0.65, h * 0.19, w * 0.16, h * 0.16), fillPaint);

        canvas.drawRect(Rect.fromLTWH(w * 0.10, h * 0.56, w * 0.34, h * 0.34), strokePaint);
        canvas.drawRect(Rect.fromLTWH(w * 0.19, h * 0.65, w * 0.16, h * 0.16), fillPaint);

        canvas.drawRect(Rect.fromLTWH(w * 0.60, h * 0.60, w * 0.26, h * 0.26), fillPaint);
        break;

      case VectorIconType.pinch:
        // Two fingertips meeting in pinch with contact indicator
        canvas.drawCircle(Offset(w * 0.30, h * 0.50), w * 0.18, fillPaint);
        canvas.drawCircle(Offset(w * 0.70, h * 0.50), w * 0.18, fillPaint);
        canvas.drawLine(Offset(w * 0.30, h * 0.50), Offset(w * 0.70, h * 0.50), strokePaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _VectorIconPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}
