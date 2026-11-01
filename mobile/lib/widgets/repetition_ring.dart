import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';

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
              strokeWidth: 10,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFE4E9E6)),
            ),
          ),
          // Active Progress
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              valueColor: const AlwaysStoppedAnimation(Color(H10Tokens.colorPrimary)),
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
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: Color(H10Tokens.colorPrimary),
                    ),
                  ),
                  Text(
                    ' / $targetReps',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(H10Tokens.colorSecondaryText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: stateColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _stateLabel(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
