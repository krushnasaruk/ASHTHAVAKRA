import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';

/// Clean data contract for the 2D hand visualization component.
class HandMovement {
  final double thumb;  // 0.0 - 100.0
  final double index;  // 0.0 - 100.0
  final double middle; // 0.0 - 100.0
  final double ring;   // 0.0 - 100.0
  final double pinky;  // 0.0 - 100.0

  const HandMovement({
    this.thumb = 0.0,
    this.index = 0.0,
    this.middle = 0.0,
    this.ring = 0.0,
    this.pinky = 0.0,
  });

  static const HandMovement open = HandMovement(thumb: 0, index: 0, middle: 0, ring: 0, pinky: 0);
  static const HandMovement partial = HandMovement(thumb: 50, index: 50, middle: 50, ring: 50, pinky: 50);
  static const HandMovement closed = HandMovement(thumb: 100, index: 100, middle: 100, ring: 100, pinky: 100);

  List<double> get asList => [thumb, index, middle, ring, pinky];
}

class HandVisualizationWidget extends StatelessWidget {
  final HandMovement movement;
  final double width;
  final double height;
  final bool showFingerColors;

  const HandVisualizationWidget({
    super.key,
    required this.movement,
    this.width = 240,
    this.height = 280,
    this.showFingerColors = true,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, _, __) {
        return CustomPaint(
          size: Size(width, height),
          painter: _HandPainter(
            movement: movement,
            showFingerColors: showFingerColors,
          ),
        );
      },
    );
  }
}

class _HandPainter extends CustomPainter {
  final HandMovement movement;
  final bool showFingerColors;

  _HandPainter({required this.movement, required this.showFingerColors});

  @override
  void paint(Canvas canvas, Size size) {
    final palmPaint = Paint()
      ..color = const Color(0xFFD8E8E2)
      ..style = PaintingStyle.fill;

    final palmOutline = Paint()
      ..color = const Color(H10Tokens.colorPrimary)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Center and palm dimensions
    final palmWidth = size.width * 0.55;
    final palmHeight = size.height * 0.40;
    final palmRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.65),
        width: palmWidth,
        height: palmHeight,
      ),
      const Radius.circular(20),
    );

    // Draw palm
    canvas.drawRRect(palmRect, palmPaint);
    canvas.drawRRect(palmRect, palmOutline);

    // Finger base attachment points
    final baseOffsets = [
      Offset(size.width * 0.28, size.height * 0.62), // Thumb
      Offset(size.width * 0.38, size.height * 0.45), // Index
      Offset(size.width * 0.48, size.height * 0.43), // Middle
      Offset(size.width * 0.58, size.height * 0.45), // Ring
      Offset(size.width * 0.68, size.height * 0.48), // Pinky
    ];

    // Base angles in radians (pointing generally upward/outward)
    final baseAngles = [
      -math.pi * 0.65, // Thumb angles left
      -math.pi * 0.52, // Index
      -math.pi * 0.50, // Middle
      -math.pi * 0.48, // Ring
      -math.pi * 0.42, // Pinky angles right
    ];

    // Segment lengths
    final segLengths = [
      [size.height * 0.08, size.height * 0.07, size.height * 0.06], // Thumb (shorter)
      [size.height * 0.09, size.height * 0.08, size.height * 0.07], // Index
      [size.height * 0.10, size.height * 0.09, size.height * 0.08], // Middle (longest)
      [size.height * 0.09, size.height * 0.08, size.height * 0.07], // Ring
      [size.height * 0.08, size.height * 0.07, size.height * 0.06], // Pinky
    ];

    final flexValues = movement.asList;

    for (var f = 0; f < 5; f++) {
      final flexPct = (flexValues[f] / 100.0).clamp(0.0, 1.0);
      final fingerColor = showFingerColors
          ? Color(H10Tokens.fingerColors[f])
          : const Color(H10Tokens.colorPrimary);

      final fingerPaint = Paint()
        ..color = fingerColor
        ..strokeWidth = f == 0 ? 10.0 : 8.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final jointPaint = Paint()
        ..color = const Color(H10Tokens.colorPrimary)
        ..style = PaintingStyle.fill;

      // Flexion curls the 3 segments: each joint bends inward by up to ~50 degrees (0.85 rad)
      final curlAngle = flexPct * 0.85;

      var curPoint = baseOffsets[f];
      var curAngle = baseAngles[f];

      // Draw 3 segments per finger
      for (var seg = 0; seg < 3; seg++) {
        final len = segLengths[f][seg];
        // Thumb curls clockwise, other fingers curl clockwise inward
        final bend = (f == 0) ? curlAngle * 0.7 : curlAngle;
        curAngle += bend;

        final nextPoint = Offset(
          curPoint.dx + len * math.cos(curAngle),
          curPoint.dy + len * math.sin(curAngle),
        );

        canvas.drawLine(curPoint, nextPoint, fingerPaint);
        canvas.drawCircle(curPoint, 3.5, jointPaint);
        curPoint = nextPoint;
      }
      // Fingertip
      canvas.drawCircle(curPoint, 4.0, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HandPainter oldDelegate) {
    return oldDelegate.movement.thumb != movement.thumb ||
           oldDelegate.movement.index != movement.index ||
           oldDelegate.movement.middle != movement.middle ||
           oldDelegate.movement.ring != movement.ring ||
           oldDelegate.movement.pinky != movement.pinky ||
           oldDelegate.showFingerColors != showFingerColors;
  }
}
