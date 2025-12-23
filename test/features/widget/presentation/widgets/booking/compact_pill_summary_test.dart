import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/l10n/widget_translations.dart';
import 'package:bookbed/features/widget/presentation/widgets/booking/compact_pill_summary.dart';

WidgetTranslations get testTranslations => WidgetTranslations.forLanguage('en');

void main() {
  group('CompactPillSummary', () {
    final testCheckIn = DateTime(2024, 1, 15);
    final testCheckOut = DateTime(2024, 1, 18);

    testWidgets('renders close button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactPillSummary(
              translations: testTranslations,
              checkIn: testCheckIn,
              checkOut: testCheckOut,
              nights: 3,
              formattedRoomPrice: '€300.00',
              additionalServicesTotal: 0,
              formattedAdditionalServices: '€0.00',
              formattedTotal: '€300.00',
              formattedDeposit: '€60.00',
              depositPercentage: 20,
              isDarkMode: false,
              showReserveButton: true,
              onClose: () {},
              onReserve: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('renders date range with calendar icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactPillSummary(
              translations: testTranslations,
              checkIn: testCheckIn,
              checkOut: testCheckOut,
              nights: 3,
              formattedRoomPrice: '€300.00',
              additionalServicesTotal: 0,
              formattedAdditionalServices: '€0.00',
              formattedTotal: '€300.00',
              formattedDeposit: '€60.00',
              depositPercentage: 20,
              isDarkMode: false,
              showReserveButton: true,
              onClose: () {},
              onReserve: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    });

    testWidgets('renders nights badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactPillSummary(
              translations: testTranslations,
              checkIn: testCheckIn,
              checkOut: testCheckOut,
              nights: 3,
              formattedRoomPrice: '€300.00',
              additionalServicesTotal: 0,
              formattedAdditionalServices: '€0.00',
              formattedTotal: '€300.00',
              formattedDeposit: '€60.00',
              depositPercentage: 20,
              isDarkMode: false,
              showReserveButton: true,
              onClose: () {},
              onReserve: () {},
            ),
          ),
        ),
      );

      expect(find.text('3 nights'), findsOneWidget);
    });

    testWidgets('renders Reserve button when showReserveButton is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactPillSummary(
              translations: testTranslations,
              checkIn: testCheckIn,
              checkOut: testCheckOut,
              nights: 3,
              formattedRoomPrice: '€300.00',
              additionalServicesTotal: 0,
              formattedAdditionalServices: '€0.00',
              formattedTotal: '€300.00',
              formattedDeposit: '€60.00',
              depositPercentage: 20,
              isDarkMode: false,
              showReserveButton: true,
              onClose: () {},
              onReserve: () {},
            ),
          ),
        ),
      );

      expect(find.text('Reserve'), findsOneWidget);
    });

    testWidgets('hides Reserve button when showReserveButton is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactPillSummary(
              translations: testTranslations,
              checkIn: testCheckIn,
              checkOut: testCheckOut,
              nights: 3,
              formattedRoomPrice: '€300.00',
              additionalServicesTotal: 0,
              formattedAdditionalServices: '€0.00',
              formattedTotal: '€300.00',
              formattedDeposit: '€60.00',
              depositPercentage: 20,
              isDarkMode: false,
              showReserveButton: false,
              onClose: () {},
              onReserve: () {},
            ),
          ),
        ),
      );

      expect(find.text('Reserve'), findsNothing);
    });

    testWidgets('calls onClose when close button tapped', (tester) async {
      bool closeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactPillSummary(
              translations: testTranslations,
              checkIn: testCheckIn,
              checkOut: testCheckOut,
              nights: 3,
              formattedRoomPrice: '€300.00',
              additionalServicesTotal: 0,
              formattedAdditionalServices: '€0.00',
              formattedTotal: '€300.00',
              formattedDeposit: '€60.00',
              depositPercentage: 20,
              isDarkMode: false,
              showReserveButton: true,
              onClose: () => closeCalled = true,
              onReserve: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(closeCalled, isTrue);
    });

    testWidgets('calls onReserve when Reserve button tapped', (tester) async {
      bool reserveCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactPillSummary(
              translations: testTranslations,
              checkIn: testCheckIn,
              checkOut: testCheckOut,
              nights: 3,
              formattedRoomPrice: '€300.00',
              additionalServicesTotal: 0,
              formattedAdditionalServices: '€0.00',
              formattedTotal: '€300.00',
              formattedDeposit: '€60.00',
              depositPercentage: 20,
              isDarkMode: false,
              showReserveButton: true,
              onClose: () {},
              onReserve: () => reserveCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Reserve'));
      expect(reserveCalled, isTrue);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactPillSummary(
              translations: testTranslations,
              checkIn: testCheckIn,
              checkOut: testCheckOut,
              nights: 3,
              formattedRoomPrice: '€300.00',
              additionalServicesTotal: 0,
              formattedAdditionalServices: '€0.00',
              formattedTotal: '€300.00',
              formattedDeposit: '€60.00',
              depositPercentage: 20,
              isDarkMode: true,
              showReserveButton: true,
              onClose: () {},
              onReserve: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CompactPillSummary), findsOneWidget);
    });
  });
}
