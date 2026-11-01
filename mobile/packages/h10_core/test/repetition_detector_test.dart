import 'dart:math' as math;
import 'package:test/test.dart';
import 'package:h10_core/h10_core.dart';

void main() {
  group('RepetitionDetector Hysteresis State Machine Tests', () {
    late RepetitionDetector detector;

    setUp(() {
      detector = RepetitionDetector(
        upperThreshold: 70.0,
        lowerThreshold: 30.0,
        minDurationS: 0.6,
        maxDurationS: 8.0,
        holdBandPct: 5.0,
        minHoldDurationS: 0.5,
        debounceMs: 300,
      );
    });

    test('Test 1: Normal clean repetition completes with correct metrics', () {
      // 2.0s duration (100 samples at 50 Hz, 20ms steps)
      // Signal rises from 0% -> 85% -> holds for 0.6s -> returns to 10%
      Repetition? completed;
      final startMs = 1000;

      for (var i = 0; i <= 100; i++) {
        final t = startMs + (i * 20);
        // Half sine wave from 0 to 85%
        final progress = i / 100.0;
        final signal = 85.0 * math.sin(math.pi * progress);

        final res = detector.processSample(
          signal: signal,
          timestampMs: t,
          sessionId: 'session_01',
        );
        if (res != null) completed = res;
      }

      expect(completed, isNotNull);
      expect(completed!.status, equals(RepetitionStatus.complete));
      expect(completed.peak, closeTo(85.0, 1.0));
      expect(completed.durationS, closeTo(1.54, 0.1));
      expect(detector.completedRepsCount, equals(1));
      expect(detector.rejectedRepsCount, equals(0));
    });

    test('Test 2: Incomplete repetition (stops at 50% < 70% upper threshold)', () {
      Repetition? rejected;
      // Rises to 50% then drops below 30%
      for (var i = 0; i <= 60; i++) {
        final t = 1000 + (i * 20);
        final progress = i / 60.0;
        final signal = 50.0 * math.sin(math.pi * progress);

        final res = detector.processSample(
          signal: signal,
          timestampMs: t,
          sessionId: 'session_01',
        );
        if (res != null) rejected = res;
      }

      expect(rejected, isNotNull);
      expect(rejected!.status, equals(RepetitionStatus.rejected));
      expect(rejected.rejectReason, equals('incomplete'));
      expect(detector.completedRepsCount, equals(0));
      expect(detector.rejectedRepsCount, equals(1));
    });

    test('Test 3: Too-fast repetition (< 0.6s min duration)', () {
      Repetition? rejected;
      // Reaches 80% and returns in 0.35s (17 samples)
      for (var i = 0; i <= 17; i++) {
        final t = 1000 + (i * 20);
        final progress = i / 17.0;
        final signal = 80.0 * math.sin(math.pi * progress);

        final res = detector.processSample(
          signal: signal,
          timestampMs: t,
          sessionId: 'session_01',
        );
        if (res != null) rejected = res;
      }

      expect(rejected, isNotNull);
      expect(rejected!.status, equals(RepetitionStatus.rejected));
      expect(rejected.rejectReason, equals('too_fast'));
      expect(detector.completedRepsCount, equals(0));
      expect(detector.rejectedRepsCount, equals(1));
    });

    test('Test 4: Too-slow repetition (> 8.0s max duration)', () {
      Repetition? rejected;
      // Stays rising for 9.0s (450 samples)
      for (var i = 0; i <= 450; i++) {
        final t = 1000 + (i * 20);
        final signal = 35.0 + (i * 0.05); // slowly creeps above 30%

        final res = detector.processSample(
          signal: signal,
          timestampMs: t,
          sessionId: 'session_01',
        );
        if (res != null) rejected = res;
      }

      expect(rejected, isNotNull);
      expect(rejected!.status, equals(RepetitionStatus.rejected));
      expect(rejected.rejectReason, equals('too_slow'));
    });

    test('Test 5: Oscillation around threshold does not trigger spurious reps', () {
      // Oscillate around lower threshold (28% - 32%) for 50 samples
      for (var i = 0; i < 50; i++) {
        final t = 1000 + (i * 20);
        final signal = 30.0 + 2.0 * math.sin(i.toDouble());
        detector.processSample(signal: signal, timestampMs: t, sessionId: 's1');
      }
      expect(detector.completedRepsCount, equals(0));
    });

    test('Test 6: Debounce ignores second crossing within 300ms', () {
      // Complete first rep at t = 3000
      for (var i = 0; i <= 60; i++) {
        final t = 1000 + (i * 20);
        final s = 80.0 * math.sin(math.pi * (i / 60.0));
        detector.processSample(signal: s, timestampMs: t, sessionId: 's1');
      }
      expect(detector.completedRepsCount, equals(1));

      // Attempt to immediately start another rep at t = 2220 (only 20ms after completion)
      detector.processSample(signal: 40.0, timestampMs: 2220, sessionId: 's1');
      expect(detector.state, equals(RepetitionState.idle), reason: 'Debounce must prevent immediate re-trigger');
    });

    test('Test 7: Interrupted session logs partial repetition', () {
      // Rise to 75% at t = 1500
      for (var i = 0; i <= 30; i++) {
        final t = 1000 + (i * 20);
        final s = 75.0 * (i / 30.0);
        detector.processSample(signal: s, timestampMs: t, sessionId: 's1');
      }
      expect(detector.state, equals(RepetitionState.peakHold));

      // Disconnect / stop session
      final interruptedRep = detector.interrupt(sessionId: 's1', timestampMs: 1650);
      expect(interruptedRep, isNotNull);
      expect(interruptedRep!.status, equals(RepetitionStatus.interrupted));
      expect(interruptedRep.rejectReason, equals('interrupted_session_disconnect'));
      expect(detector.state, equals(RepetitionState.idle));
    });

    test('Test 8: Scripted 20 clean repetitions sequence matches exactly 20', () {
      var completedCount = 0;
      var curTimeMs = 1000;

      for (var rep = 0; rep < 20; rep++) {
        // 2.0s repetition (100 samples)
        for (var i = 0; i <= 100; i++) {
          final t = curTimeMs + (i * 20);
          final progress = i / 100.0;
          final signal = 85.0 * math.sin(math.pi * progress);

          final res = detector.processSample(
            signal: signal,
            timestampMs: t,
            sessionId: 'session_20_reps',
          );
          if (res != null && res.status == RepetitionStatus.complete) {
            completedCount++;
          }
        }
        curTimeMs += 2020; // 2.02s elapsed

        // 1.0s rest (50 samples at 0% flexion)
        for (var r = 0; r < 50; r++) {
          final t = curTimeMs + (r * 20);
          detector.processSample(
            signal: 0.0,
            timestampMs: t,
            sessionId: 'session_20_reps',
          );
        }
        curTimeMs += 1000;
      }

      expect(completedCount, equals(20), reason: 'Must complete exactly 20 repetitions');
      expect(detector.completedRepsCount, equals(20));
      expect(detector.rejectedRepsCount, equals(0));
    });
  });
}
