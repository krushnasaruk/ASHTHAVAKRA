import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/main.dart';

void main() {
  testWidgets('Clinician Admin Monitoring System Mobile-Inspired Web Dashboard test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const H10ClinicianAdminApp());
    await tester.pumpAndSettle();

    // 1. Mandatory Research Disclaimer Banner Verification
    expect(
      find.text('PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE. Strictly for clinical research and demonstration monitoring. Never diagnose, prescribe, or predict recovery.'),
      findsOneWidget,
    );

    // 2. Mobile App Bar Verification (Screenshot 1)
    expect(find.text('ASHTAVAKRA'), findsWidgets);
    expect(find.text('v3'), findsOneWidget);
    expect(find.text('Hand Rehab'), findsOneWidget);
    expect(find.text('3-CH'), findsOneWidget);
    expect(find.text('Prescribe'), findsOneWidget);

    // 3. Floating Bottom Dock Items (Screenshot 1)
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Live HUD'), findsOneWidget);
    expect(find.text('TaskProof'), findsOneWidget);
    expect(find.text('Audit & PDF'), findsOneWidget);

    // 4. Master Telemetry Hero Card (Screenshot 1)
    expect(find.text('TELEMETRY STREAM'), findsOneWidget);
    expect(find.text('921,600'), findsOneWidget);
    expect(find.text('BAUD'), findsOneWidget);
    expect(find.text('ESP32-S3 N16R8 • 16-BIT ADS1115'), findsOneWidget);

    // 5. Four Squircle Quick Action Buttons (Screenshot 1)
    expect(find.text('TaskProof™'), findsOneWidget);
    expect(find.text('Judge View'), findsOneWidget);
    expect(find.text('Live Stream'), findsOneWidget);
    expect(find.text('Preflight'), findsOneWidget);

    // 6. Enrolled Cohort
    expect(find.text('ENROLLED COHORT'), findsOneWidget);
    expect(find.text('Patient P-014'), findsWidgets);

    // 7. Test Navigation to Live HUD (Screenshot 3)
    await tester.tap(find.text('Live HUD'));
    await tester.pump(const Duration(milliseconds: 100));

    // Check Live HUD Elements (Screenshot 3)
    expect(find.textContaining('Stop'), findsOneWidget);
    expect(find.text('3D HUD: ON'), findsOneWidget);
    expect(find.text('FINGER FLEXION'), findsOneWidget);
    expect(find.text('PALMAR FSR CONTACT'), findsOneWidget);
    expect(find.text('Thumb'), findsOneWidget);
    expect(find.text('Index'), findsOneWidget);
    expect(find.text('Middle'), findsOneWidget);

    // 8. Test Navigation to TaskProof Screen
    await tester.tap(find.text('TaskProof'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('TASKPROOF™ SENSOR FUSION VERIFICATION'), findsOneWidget);
    expect(find.text('TASKPROOF 7-STATE PHYSICAL EXECUTION PIPELINE'), findsOneWidget);

    // 9. Test Navigation to Audit & Export Screen
    await tester.tap(find.text('Audit & PDF'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('CLINICAL AUDIT LOG & DATA EXPORT'), findsOneWidget);
    expect(find.text('Generate 1-Page Summary PDF'), findsOneWidget);
    expect(find.text('Download CSV Telemetry'), findsOneWidget);

    // 10. Test Prescribe Action Modal
    await tester.tap(find.text('Prescribe'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('UPDATE PRESCRIPTION — PATIENT P-014'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 100));
  });
}
