import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/presentation/widgets/common/info_card_widget.dart';

void main() {
  group('InfoCardWidget', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCardWidget(
              message: 'Your booking is pending',
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text('Your booking is pending'), findsOneWidget);
    });

    testWidgets('renders info icon by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCardWidget(
              message: 'Test message',
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('renders custom icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCardWidget(
              message: 'Warning message',
              isDarkMode: false,
              icon: Icons.warning_amber_rounded,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('renders title when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCardWidget(
              message: 'Description text',
              title: 'Important Title',
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text('Important Title'), findsOneWidget);
      expect(find.text('Description text'), findsOneWidget);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCardWidget(
              message: 'Dark mode message',
              isDarkMode: true,
            ),
          ),
        ),
      );

      expect(find.byType(InfoCardWidget), findsOneWidget);
    });

    testWidgets('uses Row layout for icon and content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCardWidget(
              message: 'Test',
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('wraps content in Container with decoration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCardWidget(
              message: 'Test',
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('title is bold and message is not', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCardWidget(
              message: 'Description',
              title: 'Bold Title',
              isDarkMode: false,
            ),
          ),
        ),
      );

      final titleText = tester.widget<Text>(find.text('Bold Title'));
      expect(titleText.style?.fontWeight, FontWeight.w700);

      final messageText = tester.widget<Text>(find.text('Description'));
      expect(messageText.style?.fontWeight, isNot(FontWeight.w700));
    });
  });
}
