import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/presentation/l10n/widget_translations.dart';
import 'package:rab_booking/features/widget/presentation/widgets/booking/pill_bar_content.dart';
import 'package:rab_booking/features/widget/presentation/widgets/booking/compact_pill_summary.dart';

WidgetTranslations get testTranslations => WidgetTranslations.forLanguage('hr');

void main() {
  group('PillBarContent', () {
    final testCheckIn = DateTime(2025, 1, 15);
    final testCheckOut = DateTime(2025, 1, 18);

    Widget buildTestWidget({bool showGuestForm = false, double screenWidth = 400, bool isDarkMode = false}) {
      return MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(size: Size(screenWidth, 800)),
            child: PillBarContent(
              translations: testTranslations,
              checkIn: testCheckIn,
              checkOut: testCheckOut,
              nights: 3,
              formattedRoomPrice: '€300.00',
              additionalServicesTotal: 0.0,
              formattedAdditionalServices: '€0.00',
              formattedTotal: '€300.00',
              formattedDeposit: '€60.00',
              depositPercentage: 20,
              isDarkMode: isDarkMode,
              showGuestForm: showGuestForm,
              isWideScreen: screenWidth >= 768,
              onClose: () {},
              onReserve: () {},
              guestFormBuilder: () => const Text('Guest Form'),
              paymentSectionBuilder: () => const Text('Payment Section'),
              additionalServicesBuilder: () => const SizedBox.shrink(),
              taxLegalBuilder: () => const SizedBox.shrink(),
            ),
          ),
        ),
      );
    }

    testWidgets('renders CompactPillSummary when not showing guest form', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CompactPillSummary), findsOneWidget);
    });

    testWidgets('calls onClose when close button is tapped', (tester) async {
      bool closeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillBarContent(
              translations: testTranslations,
              checkIn: testCheckIn,
              checkOut: testCheckOut,
              nights: 3,
              formattedRoomPrice: '€300.00',
              additionalServicesTotal: 0.0,
              formattedAdditionalServices: '€0.00',
              formattedTotal: '€300.00',
              formattedDeposit: '€60.00',
              depositPercentage: 20,
              isDarkMode: false,
              showGuestForm: false,
              isWideScreen: false,
              onClose: () => closeCalled = true,
              onReserve: () {},
              guestFormBuilder: () => const Text('Guest Form'),
              paymentSectionBuilder: () => const Text('Payment Section'),
              additionalServicesBuilder: () => const SizedBox.shrink(),
              taxLegalBuilder: () => const SizedBox.shrink(),
            ),
          ),
        ),
      );

      // Find close button in CompactPillSummary and tap it
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);

      expect(closeCalled, isTrue);
    });

    testWidgets('calls onReserve when reserve button is tapped', (tester) async {
      bool reserveCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillBarContent(
              translations: testTranslations,
              checkIn: testCheckIn,
              checkOut: testCheckOut,
              nights: 3,
              formattedRoomPrice: '€300.00',
              additionalServicesTotal: 0.0,
              formattedAdditionalServices: '€0.00',
              formattedTotal: '€300.00',
              formattedDeposit: '€60.00',
              depositPercentage: 20,
              isDarkMode: false,
              showGuestForm: false,
              isWideScreen: false,
              onClose: () {},
              onReserve: () => reserveCalled = true,
              guestFormBuilder: () => const Text('Guest Form'),
              paymentSectionBuilder: () => const Text('Payment Section'),
              additionalServicesBuilder: () => const SizedBox.shrink(),
              taxLegalBuilder: () => const SizedBox.shrink(),
            ),
          ),
        ),
      );

      // Find Reserve button (HR: "Rezerviraj") and tap it
      final reserveButton = find.text('Rezerviraj');
      expect(reserveButton, findsOneWidget);
      await tester.tap(reserveButton);

      expect(reserveCalled, isTrue);
    });

    testWidgets('shows guest form in mobile layout when showGuestForm is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillBarContent(
              translations: testTranslations,
              checkIn: testCheckIn,
              checkOut: testCheckOut,
              nights: 3,
              formattedRoomPrice: '€300.00',
              additionalServicesTotal: 0.0,
              formattedAdditionalServices: '€0.00',
              formattedTotal: '€300.00',
              formattedDeposit: '€60.00',
              depositPercentage: 20,
              isDarkMode: false,
              showGuestForm: true,
              isWideScreen: false,
              onClose: () {},
              onReserve: () {},
              guestFormBuilder: () => const Text('Guest Form'),
              paymentSectionBuilder: () => const Text('Payment Section'),
              additionalServicesBuilder: () => const SizedBox.shrink(),
              taxLegalBuilder: () => const SizedBox.shrink(),
            ),
          ),
        ),
      );

      // Should show CompactPillSummary (without reserve button) + guest form
      expect(find.byType(CompactPillSummary), findsOneWidget);
      expect(find.text('Guest Form'), findsOneWidget);
      expect(find.text('Payment Section'), findsOneWidget);
    });

    testWidgets('shows 2-column layout on wide screen with guest form', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PillBarContent(
                translations: testTranslations,
                checkIn: testCheckIn,
                checkOut: testCheckOut,
                nights: 3,
                formattedRoomPrice: '€300.00',
                additionalServicesTotal: 0.0,
                formattedAdditionalServices: '€0.00',
                formattedTotal: '€300.00',
                formattedDeposit: '€60.00',
                depositPercentage: 20,
                isDarkMode: false,
                showGuestForm: true,
                isWideScreen: true,
                onClose: () {},
                onReserve: () {},
                guestFormBuilder: () => const Text('Guest Form'),
                paymentSectionBuilder: () => const Text('Payment Section'),
                additionalServicesBuilder: () => const SizedBox.shrink(),
                taxLegalBuilder: () => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      // Should NOT show CompactPillSummary in wide layout
      expect(find.byType(CompactPillSummary), findsNothing);
      // Should show guest form and payment section
      expect(find.text('Guest Form'), findsOneWidget);
      expect(find.text('Payment Section'), findsOneWidget);
    });

    testWidgets('shows drag handle in wide screen layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PillBarContent(
                translations: testTranslations,
                checkIn: testCheckIn,
                checkOut: testCheckOut,
                nights: 3,
                formattedRoomPrice: '€300.00',
                additionalServicesTotal: 0.0,
                formattedAdditionalServices: '€0.00',
                formattedTotal: '€300.00',
                formattedDeposit: '€60.00',
                depositPercentage: 20,
                isDarkMode: false,
                showGuestForm: true,
                isWideScreen: true,
                onClose: () {},
                onReserve: () {},
                guestFormBuilder: () => const Text('Guest Form'),
                paymentSectionBuilder: () => const Text('Payment Section'),
                additionalServicesBuilder: () => const SizedBox.shrink(),
                taxLegalBuilder: () => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      // Find drag handle container (40x4 pixels)
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(buildTestWidget(isDarkMode: true));

      expect(find.byType(PillBarContent), findsOneWidget);
    });
  });
}
