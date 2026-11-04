import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/main.dart';

void main() {
  testWidgets('Clinician Admin Monitoring System Web Dashboard comprehensive test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const H10ClinicianAdminApp());
    await tester.pumpAndSettle();

    // 1. Mandatory Research Disclaimer Banner Verification
    expect(
      find.text('PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE. Strictly for clinical research and demonstration monitoring. Never diagnose, prescribe, or predict recovery.'),
      findsOneWidget,
    );

    // 2. Header and Navigation Rail Tabs
    expect(find.text('ASHTAVAKRA'), findsOneWidget);
    expect(find.text('CLINICIAN MONITORING SYSTEM'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Live Cockpit'), findsOneWidget);
    expect(find.text('TaskProof™'), findsOneWidget);
    expect(find.text('Audit & PDF'), findsOneWidget);

    // 3. Overview Screen Metrics Verification
    expect(find.text('CLINICAL REHABILITATION OVERVIEW'), findsOneWidget);
    expect(find.text('ENROLLED COHORT'), findsOneWidget);
    expect(find.text('ACTIVE STREAMS'), findsOneWidget);
    expect(find.text('COHORT ADHERENCE'), findsOneWidget);
    expect(find.text('CLINICAL FLAGS'), findsOneWidget);

    // 4. Test Navigation to Live Cockpit
    await tester.tap(find.text('Live Cockpit'));
    await tester.pumpAndSettle();
    expect(find.text('LIVE CLINIC TELEMETRY COCKPIT'), findsOneWidget);
    expect(find.text('3D KINEMATIC HAND MONITOR'), findsOneWidget);

    // 5. Test Navigation to TaskProof Screen
    await tester.tap(find.text('TaskProof™'));
    await tester.pumpAndSettle();
    expect(find.text('TASKPROOF™ SENSOR FUSION VERIFICATION'), findsOneWidget);
    expect(find.text('TASKPROOF 7-STATE PHYSICAL EXECUTION PIPELINE'), findsOneWidget);

    // 6. Test Navigation to Audit & Export Screen
    await tester.tap(find.text('Audit & PDF'));
    await tester.pumpAndSettle();
    expect(find.text('CLINICAL AUDIT LOG & DATA EXPORT'), findsOneWidget);
    expect(find.text('Generate 1-Page Summary PDF'), findsOneWidget);
    expect(find.text('Download CSV Telemetry'), findsOneWidget);

    // 7. Test Patient Detail Navigation
    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Patient P-014').first);
    await tester.pumpAndSettle();
    expect(find.text('PATIENT P-014'), findsOneWidget);
    expect(find.textContaining('ACTIVE REHABILITATION PRESCRIPTION'), findsOneWidget);
    expect(find.text('Modify Prescription'), findsOneWidget);

    // 8. Test Modify Prescription Modal
    await tester.tap(find.text('Modify Prescription'));
    await tester.pumpAndSettle();
    expect(find.textContaining('UPDATE PRESCRIPTION — PATIENT P-014'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
