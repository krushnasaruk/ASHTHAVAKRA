import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h10_core/h10_core.dart';
import 'package:mobile/main.dart';
import 'package:mobile/widgets/vector_icons.dart';

void main() {
  testWidgets('H10 Patient App navigation smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const H10PatientApp());
    await tester.pump();

    // Verify mandatory non-medical disclaimer banner is visible
    expect(
      find.text('PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE. For research & demonstration only.'),
      findsOneWidget,
    );

    // Verify main app title
    expect(find.text('Hand Rehab'), findsOneWidget);

    // Verify bottom navigation bar destinations
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Exercises'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Device'), findsOneWidget);

    // Switch to Exercises tab
    await tester.tap(find.text('Exercises'));
    await tester.pumpAndSettle();

    // Verify Exercises tab content
    expect(find.text('Fist Clench & Release'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Single-Finger Tapping'), 200);
    expect(find.text('Single-Finger Tapping'), findsOneWidget);

    // Switch to Progress tab
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();

    // Verify Progress tab content
    expect(find.text('Last 2 Weeks'), findsOneWidget);

    // Switch to Device tab
    await tester.tap(find.text('Device'));
    await tester.pumpAndSettle();

    // Verify Device tab content
    expect(find.text('CONNECTION SOURCE'), findsOneWidget);
    expect(find.text('Simulator (Localhost)'), findsOneWidget);
  });

  testWidgets('H10 Patient App theme toggle test (Dark and Light modes)', (WidgetTester tester) async {
    await tester.pumpWidget(const H10PatientApp());
    await tester.pump();

    // Verify initial theme toggle icon exists
    expect(find.byTooltip('Switch to Light Theme'), findsOneWidget);

    // Tap to switch to Light Theme
    await tester.tap(find.byTooltip('Switch to Light Theme'));
    await tester.pumpAndSettle();

    // Verify switched to Light mode
    expect(H10PatientApp.themeNotifier.value, ThemeMode.light);
    expect(find.byTooltip('Switch to Dark Theme'), findsOneWidget);

    // Tap to switch back to Dark Theme
    await tester.tap(find.byTooltip('Switch to Dark Theme'));
    await tester.pumpAndSettle();

    expect(H10PatientApp.themeNotifier.value, ThemeMode.dark);
    expect(find.byTooltip('Switch to Light Theme'), findsOneWidget);
  });

  testWidgets('VectorIcon renders all types sharply without missing glyphs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              VectorIcon.taskProof(),
              VectorIcon.judge(),
              VectorIcon.routines(),
              VectorIcon.preflight(),
              VectorIcon.scanner(),
              VectorIcon.qrCode(),
              VectorIcon.pinch(),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(VectorIcon), findsNWidgets(7));
  });

  test('PacketDecoder decodes 3-channel flex and quaternion IMU schema', () {
    final decoder = PacketDecoder();
    const jsonStr = '{"v":1,"t":5000,"flex":[1200,1800,2100],"imu":[1000,0,0,0],"grip":850,"button":1,"battery":95}';
    final packet = decoder.decodeJson(jsonStr);

    expect(packet.timestampMs, 5000);
    expect(packet.flex.length, 5);
    expect(packet.flex[0], 1200);
    expect(packet.flex[1], 1800);
    expect(packet.flex[2], 2100);
    expect(packet.flex[3], 0); // Ring estimated/padded
    expect(packet.flex[4], 0); // Pinky estimated/padded
    expect(packet.fsr, 850);
    expect(packet.batteryPct, 95);
    expect(packet.isCalibrated, true);
  });
}
