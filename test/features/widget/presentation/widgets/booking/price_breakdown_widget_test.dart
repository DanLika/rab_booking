import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/presentation/widgets/booking/price_breakdown_widget.dart';
import 'package:rab_booking/features/widget/presentation/widgets/booking/price_row_widget.dart';

void main() {
  group('PriceBreakdownWidget', () {
    testWidgets('renders room price row', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdownWidget(
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

      expect(find.text('Room (3 nights)'), findsOneWidget);
      expect(find.text('€300.00'), findsWidgets); // Room price and total
    });

    testWidgets('shows singular night for 1 night stay', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdownWidget(
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

      expect(find.text('Room (1 night)'), findsOneWidget);
    });

    testWidgets('renders additional services when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdownWidget(
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

      expect(find.text('Additional Services'), findsOneWidget);
      expect(find.text('€50.00'), findsOneWidget);
    });

    testWidgets('hides additional services when zero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdownWidget(
              isDarkMode: false,
              nights: 2,
              formattedRoomPrice: '€200.00',
              additionalServicesTotal: 0,
              formattedTotal: '€200.00',
              formattedDeposit: '€40.00',
              depositPercentage: 20,
            ),
          ),
        ),
      );

      expect(find.text('Additional Services'), findsNothing);
    });

    testWidgets('renders total row', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdownWidget(
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

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('€350.00'), findsOneWidget);
    });

    testWidgets('renders deposit info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdownWidget(
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

      expect(find.text('Deposit: €90.00 (30%)'), findsOneWidget);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdownWidget(
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
