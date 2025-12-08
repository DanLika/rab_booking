import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/widgets/booking/guest_form/phone_field.dart';

void main() {
  group('PhoneField', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders phone text field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneField(
              controller: controller,
              isDarkMode: false,
              dialCode: '+385',
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('renders phone icon prefix', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneField(
              controller: controller,
              isDarkMode: false,
              dialCode: '+385',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
    });

    testWidgets('shows label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneField(
              controller: controller,
              isDarkMode: false,
              dialCode: '+385',
            ),
          ),
        ),
      );

      expect(find.text('Phone Number *'), findsOneWidget);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneField(
              controller: controller,
              isDarkMode: true,
              dialCode: '+1',
            ),
          ),
        ),
      );

      expect(find.byType(PhoneField), findsOneWidget);
    });

    testWidgets('accepts text input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneField(
              controller: controller,
              isDarkMode: false,
              dialCode: '+385',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '991234567');
      expect(controller.text, contains('99'));
    });

    testWidgets('uses different dial codes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneField(
              controller: controller,
              isDarkMode: false,
              dialCode: '+1',
            ),
          ),
        ),
      );

      expect(find.byType(PhoneField), findsOneWidget);
    });
  });
}
