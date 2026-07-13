// Guards two money-display bugs found during the 2026-07-13 PROD widget E2E:
//
// 1. BankTransferDetailsCard was fed `remainingAmount`, so a guest who chose
//    a 10% deposit (€15 of €150) was instructed to wire €135 — the remaining
//    balance — instead of the deposit that actually confirms the booking.
// 2. The deposit row label hardcoded "(20%)" in all four languages while the
//    owner's configured percentage is per-unit (10% on the live test unit),
//    and the row rendered even when the deposit was €0.00.

import 'package:bookbed/features/widget/domain/models/booking_details_model.dart';
import 'package:bookbed/features/widget/presentation/screens/booking_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BookingDetailsModel _booking({
  required double depositAmount,
  required double paidAmount,
  required double remainingAmount,
}) {
  return BookingDetailsModel(
    bookingId: 'test-booking-id',
    bookingReference: 'BK-TEST12345678',
    propertyName: 'villa Test',
    unitName: 'Unit 1',
    guestName: 'Testko Provjera',
    guestEmail: 'guest@example.com',
    checkIn: '2026-07-27T00:00:00.000Z',
    checkOut: '2026-07-29T00:00:00.000Z',
    nights: 2,
    guestCount: const GuestCount(adults: 1),
    totalPrice: 150,
    depositAmount: depositAmount,
    remainingAmount: remainingAmount,
    paidAmount: paidAmount,
    paymentStatus: 'pending',
    paymentMethod: 'bank_transfer',
    status: 'pending',
    bankDetails: const BankDetails(
      bankName: 'Test Bank',
      accountHolder: 'Test Owner',
      iban: 'HR9312345678901234567',
      swift: 'TESTHR2X',
    ),
  );
}

Future<void> _pump(WidgetTester tester, BookingDetailsModel booking) async {
  tester.view.physicalSize = const Size(1440, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: BookingDetailsScreen(booking: booking),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('bank card asks for the unpaid deposit, not the remaining '
      'balance', (tester) async {
    await _pump(
      tester,
      _booking(depositAmount: 15, paidAmount: 0, remainingAmount: 135),
    );

    // Deposit outstanding -> the wire amount is the deposit.
    expect(find.text('€15.00'), findsWidgets);
    // The remaining €135 appears in the payment summary row, but must NOT be
    // the highlighted "Amount to Pay" of the bank card. Count occurrences:
    // exactly one (the summary row), not two.
    expect(find.text('€135.00'), findsOneWidget);
  });

  testWidgets('bank card falls back to the remaining balance once the '
      'deposit is paid', (tester) async {
    await _pump(
      tester,
      _booking(depositAmount: 15, paidAmount: 15, remainingAmount: 135),
    );

    // Deposit settled -> the bank card now asks for the remainder, so €135
    // shows twice: summary row + bank card.
    expect(find.text('€135.00'), findsNWidgets(2));
  });

  testWidgets('deposit row label derives the percentage from the amounts', (
    tester,
  ) async {
    await _pump(
      tester,
      _booking(depositAmount: 15, paidAmount: 0, remainingAmount: 135),
    );

    // Default test locale resolves to Croatian ("Polog") — assert on the
    // derived percentage, which is what the bug was about.
    expect(find.textContaining('(10%)'), findsOneWidget);
    expect(find.textContaining('(20%)'), findsNothing);
  });

  testWidgets('deposit row is hidden when no deposit is configured', (
    tester,
  ) async {
    await _pump(
      tester,
      _booking(depositAmount: 0, paidAmount: 0, remainingAmount: 150),
    );

    expect(find.textContaining('Polog'), findsNothing);
    expect(find.textContaining('%)'), findsNothing);
  });
}
