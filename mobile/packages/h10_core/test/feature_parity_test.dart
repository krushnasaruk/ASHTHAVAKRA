import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:h10_core/h10_core.dart';

void main() {
  group('Feature Parity Tests (feat-v1 Python vs Dart)', () {
    test('Dart features match Python reference within 1e-6 tolerance on all fixtures', () {
      final fixturesFile = File('../../../shared/fixtures/feature_golden_v1.json');
      expect(fixturesFile.existsSync(), isTrue, reason: 'feature_golden_v1.json must exist');

      final fixtureMap = jsonDecode(fixturesFile.readAsStringSync()) as Map<String, dynamic>;
      final tolerance = (fixtureMap['tolerance'] as num).toDouble();
      final scenarios = fixtureMap['fixtures'] as List;

      for (final scenario in scenarios) {
        final id = scenario['id'] as String;
        final rawSamples = (scenario['samples'] as List).cast<Map<String, dynamic>>();
        final expectedFeatures = (scenario['expected_features'] as List).cast<num>();

        final dartFeatures = FeatureExtractor.extractWindowFeatures(rawSamples);

        expect(dartFeatures.length, equals(84), reason: 'Scenario $id must produce 84 features');
        expect(expectedFeatures.length, equals(84), reason: 'Expected features length must be 84');

        var maxDelta = 0.0;

        for (var i = 0; i < 84; i++) {
          final diff = (dartFeatures[i] - expectedFeatures[i].toDouble()).abs();
          if (diff > maxDelta) {
            maxDelta = diff;
          }
          expect(
            diff,
            lessThanOrEqualTo(tolerance),
            reason: 'Feature index $i in scenario $id exceeded tolerance: Dart=${dartFeatures[i]}, Py=${expectedFeatures[i]}, delta=$diff',
          );
        }
      }
    });
  });
}
