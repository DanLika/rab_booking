import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/widgets/booking/price_row_widget.dart';

void main() {
  group('PriceRowWidget', () {
    testWidgets('renders label and amount', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PriceRowWidget(
              label: 'Room (3 nights)',
              amount: '€300.00',
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text('Room (3 nights)'), findsOneWidget);
      expect(find.text('€300.00'), findsOneWidget);
    });

    testWidgets('renders with bold style when isBold is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PriceRowWidget(
              label: 'Total',
              amount: '€500.00',
              isDarkMode: false,
              isBold: true,
            ),
          ),
        ),
      );

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('€500.00'), findsOneWidget);
    });

    testWidgets('renders with custom color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PriceRowWidget(
              label: 'Additional Services',
              amount: '€50.00',
              isDarkMode: false,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Additional Services'), findsOneWidget);
      expect(find.text('€50.00'), findsOneWidget);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PriceRowWidget(
              label: 'Room',
              amount: '€100.00',
              isDarkMode: true,
            ),
          ),
        ),
      );

      expect(find.byType(PriceRowWidget), findsOneWidget);
    });

    testWidgets('uses Row layout with spaceBetween', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PriceRowWidget(
              label: 'Test',
              amount: '€10.00',
              isDarkMode: false,
            ),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, MainAxisAlignment.spaceBetween);
    });
  });
}
