import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/presentation/widgets/common/error_screen.dart';

void main() {
  group('WidgetErrorScreen', () {
    testWidgets('renders error icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WidgetErrorScreen(
            isDarkMode: false,
            errorMessage: 'Test error',
            onRetry: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders error title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WidgetErrorScreen(
            isDarkMode: false,
            errorMessage: 'Test error',
            onRetry: () {},
          ),
        ),
      );

      expect(find.text('Configuration Error'), findsOneWidget);
    });

    testWidgets('renders custom title when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WidgetErrorScreen(
            isDarkMode: false,
            title: 'Custom Title',
            errorMessage: 'Test error',
            onRetry: () {},
          ),
        ),
      );

      expect(find.text('Custom Title'), findsOneWidget);
      expect(find.text('Configuration Error'), findsNothing);
    });

    testWidgets('renders error message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WidgetErrorScreen(
            isDarkMode: false,
            errorMessage: 'Something went wrong',
            onRetry: () {},
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('renders retry button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WidgetErrorScreen(
            isDarkMode: false,
            errorMessage: 'Test error',
            onRetry: () {},
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('calls onRetry when button is pressed', (tester) async {
      var wasCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: WidgetErrorScreen(
            isDarkMode: false,
            errorMessage: 'Test error',
            onRetry: () {
              wasCalled = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(wasCalled, isTrue);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WidgetErrorScreen(
            isDarkMode: true,
            errorMessage: 'Test error',
            onRetry: () {},
          ),
        ),
      );

      expect(find.byType(WidgetErrorScreen), findsOneWidget);
    });
  });
}
