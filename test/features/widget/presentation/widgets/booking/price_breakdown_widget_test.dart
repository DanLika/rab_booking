import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/l10n/widget_translations.dart';
import 'package:bookbed/features/widget/presentation/widgets/booking/price_breakdown_widget.dart';
import 'package:bookbed/features/widget/presentation/widgets/booking/price_row_widget.dart';

WidgetTranslations get testTranslations => WidgetTranslations.forLanguage('hr');

void main() {
  group('PriceBreakdownWidget', () {
    testWidgets('renders room price row', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdownWidget(
              translations: testTranslations,
              isDarkMode: false,
              nights: 3,
              formattedRoomPrice: '€300.00',
              formattedTotal: '€300.00',
              formattedDeposit: '€60.00',
              depositPercentage: 20,
            ),
          ),
        ),
      );

      // HR translation: "Smještaj (3 noći)"
      expect(find.text('Smještaj (3 noći)'), findsOneWidget);
      expect(find.text('€300.00'), findsWidgets); // Room price and total
    });

    testWidgets('shows singular night for 1 night stay', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdownWidget(
              translations: testTranslations,
              isDarkMode: false,
              nights: 1,
              formattedRoomPrice: '€100.00',
              formattedTotal: '€100.00',
              formattedDeposit: '€20.00',
              depositPercentage: 20,
            ),
          ),
        ),
      );

      // HR translation: "Smještaj (1 noć)"
      expect(find.text('Smještaj (1 noć)'), findsOneWidget);
    });

    testWidgets('renders additional services when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdownWidget(
              translations: testTranslations,
              isDarkMode: false,
              nights: 2,
              formattedRoomPrice: '€200.00',
              additionalServicesTotal: 50.0,
              formattedAdditionalServices: '€50.00',
              formattedTotal: '€250.00',
              formattedDeposit: '€50.00',
              depositPercentage: 20,
            ),
          ),
        ),
      );

      // HR translation: "Dodatne usluge"
      expect(find.text('Dodatne usluge'), findsOneWidget);
      expect(find.text('€50.00'), findsOneWidget);
    });

    testWidgets('hides additional services when zero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdownWidget(
              translations: testTranslations,
              isDarkMode: false,
              nights: 2,
              formattedRoomPrice: '€200.00',
              formattedTotal: '€200.00',
              formattedDeposit: '€40.00',
              depositPercentage: 20,
            ),
          ),
        ),
      );

      // HR translation: "Dodatne usluge"
      expect(find.text('Dodatne usluge'), findsNothing);
    });

    testWidgets('renders total row', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdownWidget(
              translations: testTranslations,
              isDarkMode: false,
              nights: 3,
              formattedRoomPrice: '€300.00',
              formattedTotal: '€350.00',
              formattedDeposit: '€70.00',
              depositPercentage: 20,
            ),
          ),
        ),
      );

      // HR translation: "UKUPNO"
      expect(find.text('UKUPNO'), findsOneWidget);
      expect(find.text('€350.00'), findsOneWidget);
    });

    testWidgets('renders deposit info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdownWidget(
              translations: testTranslations,
              isDarkMode: false,
              nights: 3,
              formattedRoomPrice: '€300.00',
              formattedTotal: '€300.00',
              formattedDeposit: '€90.00',
              depositPercentage: 30,
            ),
          ),
        ),
      );

      // HR translation: "Polog: €90.00 (30%)"
      expect(find.text('Polog: €90.00 (30%)'), findsOneWidget);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdownWidget(
              translations: testTranslations,
              isDarkMode: true,
              nights: 2,
              formattedRoomPrice: '€200.00',
              formattedTotal: '€200.00',
              formattedDeposit: '€40.00',
              depositPercentage: 20,
            ),
          ),
        ),
      );

      expect(find.byType(PriceBreakdownWidget), findsOneWidget);
    });

    testWidgets('contains multiple PriceRowWidgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdownWidget(
              translations: testTranslations,
              isDarkMode: false,
              nights: 2,
              formattedRoomPrice: '€200.00',
              additionalServicesTotal: 50.0,
              formattedAdditionalServices: '€50.00',
              formattedTotal: '€250.00',
              formattedDeposit: '€50.00',
              depositPercentage: 20,
            ),
          ),
        ),
      );

      // Room + Additional Services + Total = 3 PriceRowWidgets
      expect(find.byType(PriceRowWidget), findsNWidgets(3));
    });
  });
}
