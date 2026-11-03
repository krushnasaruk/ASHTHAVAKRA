import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../theme/app_theme.dart';

class RepetitionRingWidget extends StatelessWidget {
  final int completedReps;
  final int targetReps;
  final RepetitionState state;
  final double size;

  const RepetitionRingWidget({
    super.key,
    required this.completedReps,
    required this.targetReps,
    required this.state,
    this.size = 140,
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
        return const Color(H10Tokens.colorSecondaryText);
      case RepetitionState.rising:
      case RepetitionState.falling:
        return const Color(H10Tokens.colorPrimary);
      case RepetitionState.peakHold:
        return const Color(H10Tokens.colorWarning);
      case RepetitionState.complete:
        return const Color(H10Tokens.colorSuccess);
      case RepetitionState.rejected:
        return const Color(H10Tokens.colorError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final progress = targetReps > 0 ? (completedReps / targetReps).clamp(0.0, 1.0) : 0.0;
    final stateColor = _stateColor();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation(
                c.isDark ? const Color(0xFF1E2822) : const Color(0xFFE4E9E6),
              ),
            ),
          ),
          // Active Progress
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation(
                c.isDark ? const Color(0xFFC8F05F) : const Color(0xFF009E73),
              ),
            ),
          ),
          // Inner Count & State
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$completedReps',
                    style: TextStyle(
                      fontSize: size > 90 ? 32 : 22,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    ' / $targetReps',
                    style: TextStyle(
                      fontSize: size > 90 ? 15 : 12,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: stateColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _stateLabel(),
                  style: TextStyle(
                    fontSize: size > 90 ? 9.5 : 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: stateColor,
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

