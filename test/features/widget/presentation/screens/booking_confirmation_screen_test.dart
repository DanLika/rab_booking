import 'package:bookbed/features/widget/presentation/screens/booking_confirmation_screen.dart';
import 'package:bookbed/shared/widgets/redesign.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Confirmation card formats check-in/check-out dates via Intl;
    // load the locale tables before any test runs.
    await initializeDateFormatting('en');
    await initializeDateFormatting('hr');
  });

  Widget buildScreen() {
    return BookingConfirmationScreen(
      bookingReference: 'BB-TEST-001',
      guestEmail: 'guest@example.com',
      guestName: 'Test Guest',
      checkIn: DateTime(2026, 6),
      checkOut: DateTime(2026, 6, 3),
      totalPrice: 240,
      nights: 2,
      guests: 2,
      propertyName: 'Test Villa',
      paymentMethod: 'on_site',
    );
  }

  group('BookingConfirmationScreen smoke', () {
    setUp(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        ..physicalSize = const Size(900, 1400)
        ..devicePixelRatio = 1.0;
    });

    tearDown(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    testWidgets('renders without throw', (tester) async {
      // No `withL10n` — confirmation uses WidgetTranslations via languageProvider
      // (already overridden to 'en' in createTestWidget).
      await tester.pumpWidget(createTestWidget(child: buildScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      allowOverflow(tester);
      expect(find.byType(BookingConfirmationScreen), findsOneWidget);
    });

    testWidgets('renders Bb* app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(child: buildScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      allowOverflow(tester);

      expect(find.byType(BbAppBar), findsOneWidget);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        createTestWidget(isDarkMode: true, child: buildScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      allowOverflow(tester);

      expect(find.byType(BookingConfirmationScreen), findsOneWidget);
    });
  });
}
