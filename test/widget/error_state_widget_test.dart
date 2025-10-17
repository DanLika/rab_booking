import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/shared/widgets/error_state_widget.dart';

void main() {
  group('ErrorStateWidget Tests', () {
    testWidgets('should render error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Test error message',
            ),
          ),
        ),
      );

      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('should display default error icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Error',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should display custom icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Error',
              icon: Icons.warning,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('should not display retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Error',
            ),
          ),
        ),
      );

      expect(find.text('Pokušaj ponovo'), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('should display retry button when onRetry is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Error',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Pokušaj ponovo'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should call onRetry when retry button is tapped', (tester) async {
      var retryCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Error',
              onRetry: () => retryCallCount++,
            ),
          ),
        ),
      );

      expect(retryCallCount, 0);

      await tester.tap(find.text('Pokušaj ponovo'));
      await tester.pump();

      expect(retryCallCount, 1);
    });

    testWidgets('should center content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Error',
            ),
          ),
        ),
      );

      final center = tester.widget<Center>(find.byType(Center).first);
      expect(center, isNotNull);
    });

    testWidgets('should have proper spacing between elements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Error',
              onRetry: () {},
            ),
          ),
        ),
      );

      // Verify SizedBox widgets for spacing
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should display multi-line error messages correctly', (tester) async {
      const longMessage = 'This is a very long error message that should wrap to multiple lines when displayed';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: longMessage,
            ),
          ),
        ),
      );

      expect(find.text(longMessage), findsOneWidget);
    });
  });
}
