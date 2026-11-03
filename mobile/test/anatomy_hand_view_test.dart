import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/anatomy_hand_view.dart';

void main() {
  group('AnatomyHandView Widget & Biomechanical Tests', () {
    testWidgets('AnatomyHandView mounts with 4:5 portrait aspect ratio and safe framing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnatomyHandView(
              normalizedFlex: [45.0, 60.0, 75.0, 67.5, 56.25],
              imu: [1000, 0, 0, 0],
              isConnected: true,
            ),
          ),
        ),
      );

      // Verify widget builds and renders AspectRatio of 4:5
      final aspectRatioFinder = find.byWidgetPredicate(
        (widget) => widget is AspectRatio && (widget.aspectRatio - (4.0 / 5.0)).abs() < 0.001,
      );
      expect(aspectRatioFinder, findsOneWidget);

      // Verify headless test fallback text is rendered when WebViewPlatform is headless
      expect(find.text('3D ANATOMICAL SKELETON (WEBGL)'), findsOneWidget);
    });

    testWidgets('AnatomyHandView handles disconnected state cleanly with neutral pose', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnatomyHandView(
              normalizedFlex: [],
              imu: null,
              isConnected: false,
            ),
          ),
        ),
      );

      expect(find.byType(AnatomyHandView), findsOneWidget);
      expect(find.text('3D ANATOMICAL SKELETON (WEBGL)'), findsOneWidget);
    });

    testWidgets('AnatomyHandView supports fullscreen modal mode with close button', (tester) async {
      bool closed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnatomyHandView(
              normalizedFlex: const [10.0, 20.0, 30.0],
              isConnected: true,
              isFullScreen: true,
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(closed, isTrue);
    });
  });
}
