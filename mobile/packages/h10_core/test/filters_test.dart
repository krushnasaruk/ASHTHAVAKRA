import 'package:test/test.dart';
import 'package:h10_core/h10_core.dart';

void main() {
  group('Filter Tests', () {
    test('EmaFilter smoothly tracks step input', () {
      final ema = EmaFilter(alpha: 0.25);
      // Initial value
      expect(ema.process(100.0), equals(100.0));

      // Step change to 0
      final step1 = ema.process(0.0);
      expect(step1, equals(75.0)); // 0.25*0 + 0.75*100 = 75

      final step2 = ema.process(0.0);
      expect(step2, equals(56.25)); // 0.25*0 + 0.75*75 = 56.25
    });

    test('MedianFilter suppresses single-sample spikes', () {
      final median = MedianFilter(windowSize: 5);
      // Feed 0, 0, 100 (spike), 0, 0
      expect(median.process(0.0), equals(0.0));
      expect(median.process(0.0), equals(0.0));
      expect(median.process(100.0), equals(0.0)); // sorted [0, 0, 100] -> median 0
      expect(median.process(0.0), equals(0.0));
      expect(median.process(0.0), equals(0.0));
    });
  });
}
