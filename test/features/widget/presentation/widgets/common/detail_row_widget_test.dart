import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/presentation/widgets/common/detail_row_widget.dart';

void main() {
  group('DetailRowWidget', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailRowWidget(
              label: 'Check-in',
              value: '15.01.2025',
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text('Check-in'), findsOneWidget);
      expect(find.text('15.01.2025'), findsOneWidget);
    });

    testWidgets('displays label on left and value on right', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailRowWidget(
              label: 'Guest',
              value: 'John Doe',
              isDarkMode: false,
            ),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.mainAxisAlignment, MainAxisAlignment.spaceBetween);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailRowWidget(
              label: 'Email',
              value: 'test@example.com',
              isDarkMode: true,
            ),
          ),
        ),
      );

      expect(find.byType(DetailRowWidget), findsOneWidget);
    });

    testWidgets('applies highlighted style when isHighlighted is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailRowWidget(
              label: 'Total',
              value: '€500.00',
              isDarkMode: false,
              isHighlighted: true,
            ),
          ),
        ),
      );

      final valueText = tester.widget<Text>(find.text('€500.00'));
      expect(valueText.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('applies normal style when isHighlighted is false',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailRowWidget(
              label: 'Nights',
              value: '5',
              isDarkMode: false,
            ),
          ),
        ),
      );

      final valueText = tester.widget<Text>(find.text('5'));
      expect(valueText.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('adds vertical padding when hasPadding is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailRowWidget(
              label: 'Test',
              value: 'Value',
              isDarkMode: false,
              hasPadding: true,
            ),
          ),
        ),
      );

      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('no extra padding when hasPadding is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailRowWidget(
              label: 'Test',
              value: 'Value',
              isDarkMode: false,
            ),
          ),
        ),
      );

      // Should still render correctly
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
    });

    testWidgets('applies custom valueFontWeight', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailRowWidget(
              label: 'Guest',
              value: 'Jane Doe',
              isDarkMode: false,
              valueFontWeight: FontWeight.w400,
            ),
          ),
        ),
      );

      final valueText = tester.widget<Text>(find.text('Jane Doe'));
      expect(valueText.style?.fontWeight, FontWeight.w400);
    });

    testWidgets('highlighted overrides custom valueFontWeight', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailRowWidget(
              label: 'Total',
              value: '€1000.00',
              isDarkMode: false,
              isHighlighted: true,
              valueFontWeight: FontWeight.w400, // Should be ignored
            ),
          ),
        ),
      );

      final valueText = tester.widget<Text>(find.text('€1000.00'));
      // Highlighted always uses bold (w700), not custom weight
      expect(valueText.style?.fontWeight, FontWeight.w700);
    });
  });
}
