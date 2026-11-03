import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

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
}
