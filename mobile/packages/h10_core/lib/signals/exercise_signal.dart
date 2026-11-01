import 'dart:math' as math;

enum ExerciseCode {
  fistClench,
  fingerTap,
  pinch,
  wristRotation,
  handControlGame
}

extension ExerciseCodeExtension on ExerciseCode {
  String get rawValue {
    switch (this) {
      case ExerciseCode.fistClench: return 'fist_clench';
      case ExerciseCode.fingerTap: return 'finger_tap';
      case ExerciseCode.pinch: return 'pinch';
      case ExerciseCode.wristRotation: return 'wrist_rotation';
      case ExerciseCode.handControlGame: return 'hand_control_game';
    }
  }

  static ExerciseCode fromString(String val) {
    switch (val) {
      case 'fist_clench': return ExerciseCode.fistClench;
      case 'finger_tap': return ExerciseCode.fingerTap;
      case 'pinch': return ExerciseCode.pinch;
      case 'wrist_rotation': return ExerciseCode.wristRotation;
      case 'hand_control_game': return ExerciseCode.handControlGame;
      default: return ExerciseCode.fistClench;
    }
  }
}

/// Computes the 1D exercise drive signal from normalized finger flexions and IMU readings.
class ExerciseSignalExtractor {
  double _wristAngleDeg = 0.0;
  int? _lastGyroTimestampMs;

  void reset() {
    _wristAngleDeg = 0.0;
    _lastGyroTimestampMs = null;
  }

  /// Extracts the scalar control signal (0-100% or degrees) for the active exercise.
  double extractSignal({
    required ExerciseCode exercise,
    required List<double> normalizedFlex, // 5 fingers (0-100%)
    required List<int> imu, // [ax, ay, az, gx, gy, gz]
    int targetFingerIndex = 1, // index finger default for tap
    int timestampMs = 0,
  }) {
    switch (exercise) {
      case ExerciseCode.fistClench:
        // Mean of all 5 normalized fingers
        return normalizedFlex.reduce((a, b) => a + b) / 5.0;

      case ExerciseCode.fingerTap:
        // Target finger flexion
        final idx = math.max(0, math.min(4, targetFingerIndex));
        return normalizedFlex[idx];

      case ExerciseCode.pinch:
        // Min(thumb, index)
        final thumb = normalizedFlex[0];
        final index = normalizedFlex[1];
        return math.min(thumb, index);

      case ExerciseCode.wristRotation:
        // Forearm rotation integration: gx in units of 0.1 deg/s
        if (_lastGyroTimestampMs != null) {
          final dtSec = (timestampMs - _lastGyroTimestampMs!) / 1000.0;
          if (dtSec > 0 && dtSec < 0.2) {
            final rateDegPerSec = imu[3] / 10.0;
            _wristAngleDeg += rateDegPerSec * dtSec;
          }
        }
        _lastGyroTimestampMs = timestampMs;
        return _wristAngleDeg.abs();

      case ExerciseCode.handControlGame:
        final idx = math.max(0, math.min(4, targetFingerIndex));
        return normalizedFlex[idx];
    }
  }
}
