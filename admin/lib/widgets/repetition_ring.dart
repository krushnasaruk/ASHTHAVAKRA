import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../theme/admin_theme.dart';

class RepetitionRingWidget extends StatelessWidget {
  final int completedReps;
  final int targetReps;
  final RepetitionState state;
  final String elapsedText;
  final double size;

  const RepetitionRingWidget({
    super.key,
    required this.completedReps,
    required this.targetReps,
    required this.state,
    this.elapsedText = '00:00',
    this.size = 170,
  });

  String _stateLabel() {
    switch (state) {
      case RepetitionState.idle:
        return 'WAITING';
      case RepetitionState.rising:
        return 'MOVING';
      case RepetitionState.peakHold:
        return 'HOLDING';
      case RepetitionState.falling:
        return 'RETURNING';
      case RepetitionState.complete:
        return 'DONE';
      case RepetitionState.rejected:
        return 'RESET';
    }
  }

  Color _stateColor() {
    switch (state) {
      case RepetitionState.idle:
        return AdminTheme.textSecondary;
      case RepetitionState.rising:
      case RepetitionState.falling:
        return AdminTheme.cyan;
      case RepetitionState.peakHold:
        return AdminTheme.amber;
      case RepetitionState.complete:
        return AdminTheme.lime;
      case RepetitionState.rejected:
        return AdminTheme.crimson;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = targetReps > 0 ? (completedReps / targetReps).clamp(0.0, 1.0) : 0.0;
    final color = _stateColor();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              activeColor: AdminTheme.textPrimary,
              trackColor: const Color(0xFF222B26),
              strokeWidth: 9.0,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                elapsedText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: Color(0xFF5A6660),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$completedReps',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                  Text(
                    ' / $targetReps',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF161E1A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.3), width: 0.8),
                ),
                child: Text(
                  _stateLabel(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Active arc
    if (progress > 0.0) {
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.activeColor != activeColor;
  }
}
