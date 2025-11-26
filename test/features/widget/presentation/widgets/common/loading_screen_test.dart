import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/presentation/widgets/common/loading_screen.dart';

void main() {
  group('WidgetLoadingScreen', () {
    testWidgets('renders loading indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WidgetLoadingScreen(isDarkMode: false),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders loading message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WidgetLoadingScreen(isDarkMode: false),
        ),
      );

      expect(find.text('Loading booking widget...'), findsOneWidget);
    });

    testWidgets('renders custom message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WidgetLoadingScreen(
            isDarkMode: false,
            message: 'Custom loading...',
          ),
        ),
      );

      expect(find.text('Custom loading...'), findsOneWidget);
      expect(find.text('Loading booking widget...'), findsNothing);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WidgetLoadingScreen(isDarkMode: true),
        ),
      );

      expect(find.byType(WidgetLoadingScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('uses Scaffold with proper background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WidgetLoadingScreen(isDarkMode: false),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
