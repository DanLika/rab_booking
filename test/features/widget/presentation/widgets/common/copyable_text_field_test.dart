import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/widgets/common/copyable_text_field.dart';

void main() {
  group('CopyableTextField', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CopyableTextField(
              label: 'IBAN',
              value: 'HR1234567890123456789',
              icon: Icons.account_balance,
              isDarkMode: false,
              onCopy: () async {},
            ),
          ),
        ),
      );

      expect(find.text('IBAN'), findsOneWidget);
      expect(find.text('HR1234567890123456789'), findsOneWidget);
    });

    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CopyableTextField(
              label: 'IBAN',
              value: 'HR1234567890123456789',
              icon: Icons.account_balance,
              isDarkMode: false,
              onCopy: () async {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });

    testWidgets('renders copy button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CopyableTextField(
              label: 'Reference',
              value: 'REF123',
              icon: Icons.tag,
              isDarkMode: false,
              onCopy: () async {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.content_copy), findsOneWidget);
    });

    testWidgets('calls onCopy when copy button pressed', (tester) async {
      bool copyPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CopyableTextField(
              label: 'IBAN',
              value: 'HR1234567890123456789',
              icon: Icons.account_balance,
              isDarkMode: false,
              onCopy: () async {
                copyPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.content_copy));
      await tester.pump();

      expect(copyPressed, true);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CopyableTextField(
              label: 'Amount',
              value: '€500.00',
              icon: Icons.euro,
              isDarkMode: true,
              onCopy: () async {},
            ),
          ),
        ),
      );

      expect(find.byType(CopyableTextField), findsOneWidget);
    });

    testWidgets('uses monospace font for IBAN label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CopyableTextField(
              label: 'IBAN',
              value: 'HR1234567890123456789',
              icon: Icons.account_balance,
              isDarkMode: false,
              onCopy: () async {},
            ),
          ),
        ),
      );

      final valueText = tester.widget<Text>(find.text('HR1234567890123456789'));
      expect(valueText.style?.fontFamily, 'monospace');
    });

    testWidgets('does not use monospace for regular labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CopyableTextField(
              label: 'Bank Name',
              value: 'Some Bank',
              icon: Icons.business,
              isDarkMode: false,
              onCopy: () async {},
            ),
          ),
        ),
      );

      final valueText = tester.widget<Text>(find.text('Some Bank'));
      expect(valueText.style?.fontFamily, isNot('monospace'));
    });
  });
}
