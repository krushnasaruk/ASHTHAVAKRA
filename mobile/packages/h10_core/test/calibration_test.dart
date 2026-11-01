import 'package:test/test.dart';
import 'package:h10_core/h10_core.dart';

void main() {
  group('CalibrationEngine & Normalizer Tests', () {
    const engine = CalibrationEngine(minSpanThreshold: 300, maxStabilitySd: 40.0, driftToleranceRatio: 0.15);

    test('Computes exact median and population standard deviation', () {
      final dataOdd = [10.0, 20.0, 30.0];
      expect(CalibrationEngine.median(dataOdd), equals(20.0));

      final dataEven = [10.0, 20.0, 30.0, 40.0];
      expect(CalibrationEngine.median(dataEven), equals(25.0));

      // Population SD of [10, 20, 30]: mean=20, sqDiffs=[100, 0, 100], var=200/3=66.6667, sd=8.1649658
      final sd = CalibrationEngine.standardDeviation([10.0, 20.0, 30.0]);
      expect(sd, closeTo(8.165, 0.001));
    });

    test('Detects unstable capture window when noise exceeds maxStabilitySd', () {
      // 100 samples across 2s: 4 fingers steady at 1000, 1 finger noisy (SD > 40)
      final samples = <List<int>>[];
      for (var i = 0; i < 100; i++) {
        samples.add([
          1000,
          1000 + (i % 2 == 0 ? 50 : -50), // noisy finger 1: delta 100 -> SD ~50 > 40
          1000,
          1000,
          1000,
        ]);
      }

      final eval = engine.evaluateCaptureWindow(samples);
      expect(eval['is_stable'], isFalse);
      expect((eval['unstable_fingers'] as List).length, equals(1));
    });

    test('Validates span >= 300 and detects polarity', () {
      // Normal positive polarity (closed > open, span = 2000 >= 300)
      final recordValid = engine.buildRecord(
        id: 'cal_01',
        openMedians: [1000, 1000, 1000, 1000, 1000],
        openSds: [5, 5, 5, 5, 5],
        closedMedians: [3000, 3000, 3000, 3000, 3000],
        closedSds: [5, 5, 5, 5, 5],
      );
      expect(recordValid.isValid, isTrue);
      expect(recordValid.fingers[0].polarity, equals(1));
      expect(recordValid.fingers[0].span, equals(2000));

      // Inverted polarity (closed < open, span = 1500 >= 300)
      final recordInverted = engine.buildRecord(
        id: 'cal_02',
        openMedians: [2500, 2500, 2500, 2500, 2500],
        openSds: [5, 5, 5, 5, 5],
        closedMedians: [1000, 1000, 1000, 1000, 1000],
        closedSds: [5, 5, 5, 5, 5],
      );
      expect(recordInverted.isValid, isTrue);
      expect(recordInverted.fingers[0].polarity, equals(-1));

      // Rejects span < 300
      final recordShort = engine.buildRecord(
        id: 'cal_03',
        openMedians: [1000, 1000, 1000, 1000, 1000],
        openSds: [5, 5, 5, 5, 5],
        closedMedians: [1150, 3000, 3000, 3000, 3000], // finger 0 span is only 150 < 300
        closedSds: [5, 5, 5, 5, 5],
      );
      expect(recordShort.isValid, isFalse);
      expect(recordShort.fingers[0].isValid, isFalse);
      expect(recordShort.fingers[0].rejectReason, contains('minimum threshold'));
    });

    test('Normalizes flexion percentage with clamping and polarity awareness', () {
      final record = engine.buildRecord(
        id: 'cal_01',
        openMedians: [1000, 1000, 1000, 1000, 1000],
        openSds: [5, 5, 5, 5, 5],
        closedMedians: [3000, 3000, 3000, 3000, 3000],
        closedSds: [5, 5, 5, 5, 5],
      );

      // Midpoint: 2000 -> 50%
      final normMid = Normalizer.normalizeFinger(raw: 2000, calibration: record.fingers[0]);
      expect(normMid, equals(50.0));

      // At open: 1000 -> 0%
      final normOpen = Normalizer.normalizeFinger(raw: 1000, calibration: record.fingers[0]);
      expect(normOpen, equals(0.0));

      // At closed: 3000 -> 100%
      final normClosed = Normalizer.normalizeFinger(raw: 3000, calibration: record.fingers[0]);
      expect(normClosed, equals(100.0));

      // Beyond bounds: clamped to 0 and 100
      expect(Normalizer.normalizeFinger(raw: 500, calibration: record.fingers[0]), equals(0.0));
      expect(Normalizer.normalizeFinger(raw: 3500, calibration: record.fingers[0]), equals(100.0));
    });

    test('Drift check triggers warning when deviation exceeds 15% of span', () {
      final record = engine.buildRecord(
        id: 'cal_01',
        openMedians: [1000, 1000, 1000, 1000, 1000],
        openSds: [5, 5, 5, 5, 5],
        closedMedians: [3000, 3000, 3000, 3000, 3000], // span = 2000, 15% is 300
        closedSds: [5, 5, 5, 5, 5],
      );

      // Drift within tolerance: shift of 100 ADC (< 300 allowed)
      final okSamples = List.generate(50, (_) => [1100, 1100, 1100, 1100, 1100]);
      final okCheck = engine.checkDrift(record: record, oneSecOpenSamples: okSamples);
      expect(okCheck['drift_detected'], isFalse);

      // Drift exceeding tolerance: shift of 350 ADC (> 300 allowed)
      final driftSamples = List.generate(50, (_) => [1350, 1050, 1020, 1010, 1000]);
      final driftCheck = engine.checkDrift(record: record, oneSecOpenSamples: driftSamples);
      expect(driftCheck['drift_detected'], isTrue);
      expect(driftCheck['status'], equals('recalibration_recommended'));
    });
  });
}
