import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/main.dart';

void main() {
  testWidgets('Clinician Dashboard Web Shell smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const H10ClinicianAdminApp());
    await tester.pumpAndSettle();

    // 1. Mandatory Research Disclaimer Banner Verification
    expect(
      find.text('PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE. Strictly for research and demonstration monitoring. Never diagnose, prescribe, or predict clinical recovery.'),
      findsOneWidget,
    );

    // 2. Clinic Header Verification
    expect(find.text('Neurological & Hand Rehabilitation Research Clinic'), findsOneWidget);
    expect(find.text('Dr. Sarah Adams, PT'), findsOneWidget);

    // 3. Navigation Rail Destinations
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Patients'), findsOneWidget);
    expect(find.text('Audit Log'), findsOneWidget);

    // 4. Overview Metrics Verification
    expect(find.text('Clinical Rehabilitation Overview'), findsOneWidget);
    expect(find.text('ACTIVE PATIENTS'), findsOneWidget);
    expect(find.text('OPEN CLINICAL FLAGS'), findsOneWidget);
    expect(find.text('Priority Movement Flags & Alerts'), findsOneWidget);

    // 5. Navigate to Patients Cohort Tab
    await tester.tap(find.text('Patients'));
    await tester.pumpAndSettle();

    expect(find.text('Enrolled Research Cohort'), findsOneWidget);
    expect(find.text('P-014'), findsOneWidget);
    expect(find.text('P-007'), findsOneWidget);

    // 6. View Patient Detail for P-014
    await tester.tap(find.text('View Detail').first);
    await tester.pumpAndSettle();

    expect(find.text('Patient P-014'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Progress & Trends'), findsOneWidget);
    expect(find.text('Rehabilitation Plan'), findsOneWidget);
    expect(find.text('Export & Raw Data'), findsOneWidget);

    // 7. Test Plan Update Modal and Versioning
    await tester.tap(find.text('Rehabilitation Plan'));
    await tester.pumpAndSettle();

    expect(find.text('Update / Version Plan'), findsOneWidget);
    await tester.tap(find.text('Update / Version Plan'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Update Plan for P-014'), findsOneWidget);
    // Enter justification note
    await tester.enterText(
      find.widgetWithText(TextField, 'Clinical Justification for Plan Modification *'),
      'Progressed active flexion goal by 5% based on clinic visit evaluation.',
    );
    await tester.tap(find.text('Save New Plan Version'));
    await tester.pumpAndSettle();

    // Verify Plan Version 3 is now shown
    expect(find.textContaining('Version 3'), findsOneWidget);

    // 8. Test Export Tab
    await tester.tap(find.text('Export & Raw Data'));
    await tester.pumpAndSettle();

    expect(find.text('Generate 1-Page Summary PDF'), findsOneWidget);
    expect(find.text('Download Telemetry CSV'), findsOneWidget);

    // Click Download CSV
    await tester.tap(find.text('Download Telemetry CSV'));
    await tester.pumpAndSettle();
    expect(find.textContaining('session_id,patient_id,exercise'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // 9. Navigate to Audit Log Tab and verify the logged plan update
    await tester.tap(find.text('Audit Log'));
    await tester.pumpAndSettle();

    expect(find.text('Clinical Action Audit Log'), findsOneWidget);
    expect(find.textContaining('Plan Updated for Patient P-014 (Version 3)'), findsOneWidget);
  });
}
