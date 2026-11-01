import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h10_core/h10_core.dart';
import 'package:mobile/services/device_service.dart';
import 'package:mobile/services/storage_service.dart';
import 'package:mobile/screens/s1_today_screen.dart';
import 'package:mobile/screens/s3_calibration_screen.dart';
import 'package:mobile/screens/s6_summary_screen.dart';

void main() {
  group('Mobile Screens Unit & Widget Tests', () {
    late DeviceService deviceService;
    late StorageService storageService;

    setUp(() {
      deviceService = DeviceService();
      storageService = StorageService();
    });

    tearDown(() {
      deviceService.dispose();
      storageService.dispose();
    });

    testWidgets('TodayScreen displays adherence, plan target, and status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayScreen(
              deviceService: deviceService,
              storageService: storageService,
              onStartExercise: () {},
              onNavigateDevice: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Start Prescribed Exercise'), findsOneWidget);
      expect(find.text('Fist Clench & Release'), findsWidgets);
      expect(find.text('sessions completed this week'), findsOneWidget);
    });

    testWidgets('CalibrationScreen displays 2-step calibration process', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalibrationScreen(
            deviceService: deviceService,
            storageService: storageService,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Calibration Wizard'), findsOneWidget);
      expect(find.text('STAGE 1: OPEN HAND'), findsOneWidget);
    });

    testWidgets('SessionSummaryScreen displays ratings and saves session', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final started = DateTime.now().subtract(const Duration(minutes: 3));
      const reps = <Repetition>[
        Repetition(
          id: 'rep_1',
          sessionId: 'sess_test_123',
          index: 0,
          startMs: 1000,
          endMs: 2800,
          durationS: 1.8,
          peak: 85.0,
          mean: 60.0,
          min: 10.0,
          rom: 75.0,
          holdS: 0.5,
          smoothness: 12.0,
          quality: RepetitionQuality.good,
          status: RepetitionStatus.complete,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: SessionSummaryScreen(
            sessionId: 'sess_test_123',
            exercise: ExerciseCode.fistClench,
            durationS: 180,
            completedReps: reps,
            meanRom: 85.0,
            maxRom: 85.0,
            consistency: const ConsistencyResult(isAvailable: true, totalScore: 90.0, romRatio: 0.9, timingScore: 0.9, smoothScore: 0.9),
            fatigue: const FatigueResult(isAvailable: false, isFatigueDetected: false, message: 'Need 6 reps'),
            storageService: storageService,
            deviceService: deviceService,
            startedAt: started,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Session Summary'), findsOneWidget);
      expect(find.text('Pain Rating: 2 / 10'), findsOneWidget);
      expect(find.text('Fatigue Rating: 3 / 10'), findsOneWidget);

      final saveButton = find.text('Save Session Record');
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pump();

      // Verify stored session
      expect(storageService.sessions.any((s) => s.id == 'sess_test_123'), isTrue);
    });
  });
}
