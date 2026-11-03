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
      find.text('PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE. Strictly for research and engineering demonstration.'),
      findsOneWidget,
    );

    // 2. Admin Dashboard Scratch Canvas Verification
    expect(find.text('ADMIN DASHBOARD'), findsOneWidget);
  });
}
