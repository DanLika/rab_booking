// Audit sweep F4.1 + F4.12 — booking-detail UI wiring.
//
// F4.1: _RoundIconButton (mail/call in the guest card) had NO gesture
// wiring — a bare Container. RED before fix: no InkWell with a non-null
// onTap under the 'Email' tooltip. Also asserts the 44px tap box and that
// 'Nazovi' is disabled when the booking has no phone.
//
// F4.12: iCal/OTA bookings (isExternalBooking) rendered a lifecycle badge
// ('Potvrđeno') the owner can't act on. Now they show 'Uvezeno';
// cancelled still wins.

import 'package:bookbed/core/constants/enums.dart';
import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/owner_booking_detail_screen.dart';
import 'package:bookbed/shared/models/booking_model.dart';
import 'package:bookbed/shared/models/property_model.dart';
import 'package:bookbed/shared/models/unit_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

OwnerBooking _ob({
  BookingStatus status = BookingStatus.confirmed,
  String? source,
  String? phone = '+385 91 234 5678',
}) {
  final DateTime now = DateTime(2026, 7, 8, 14, 0);
  return OwnerBooking(
    booking: BookingModel(
      id: 'bd-wire-test',
      unitId: 'u1',
      checkIn: now.add(const Duration(days: 5)),
      checkOut: now.add(const Duration(days: 8)),
      status: status,
      createdAt: now.subtract(const Duration(days: 2)),
      totalPrice: 360,
      paidAmount: 72,
      source: source,
    ),
    property: PropertyModel(
      id: 'p1',
      name: 'Vila Marina',
      description: 'desc',
      location: 'Rab',
      createdAt: now,
    ),
    unit: UnitModel(
      id: 'u1',
      propertyId: 'p1',
      name: 'Studio 4',
      pricePerNight: 120,
      maxGuests: 2,
      createdAt: now,
    ),
    guestName: 'Marko Horvat',
    guestEmail: 'marko.horvat@gmail.com',
    guestPhone: phone,
  );
}

Widget _pumpable(OwnerBooking ob) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: buildBookingDetailContentForTest(ob, 500),
        ),
      ),
    ),
  );
}

/// The InkWell nested under the Tooltip with [message].
Finder _tooltipInkWell(String message) {
  return find.descendant(
    of: find.byWidgetPredicate(
      (Widget w) => w is Tooltip && w.message == message,
    ),
    matching: find.byType(InkWell),
  );
}

void main() {
  testWidgets('F4.1: mail button is tappable (InkWell wired)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_pumpable(_ob()));
    final Finder ink = _tooltipInkWell('Email');
    expect(ink, findsOneWidget);
    expect(tester.widget<InkWell>(ink).onTap, isNotNull);
    // 44px tap box floor.
    expect(tester.getSize(ink).height, greaterThanOrEqualTo(44));
  });

  testWidgets('F4.1: call button disabled without a phone number', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_pumpable(_ob(phone: null)));
    final Finder ink = _tooltipInkWell('Nazovi');
    expect(ink, findsOneWidget);
    expect(tester.widget<InkWell>(ink).onTap, isNull);
  });

  testWidgets('F4.12: iCal booking badges as Uvezeno, not Potvrđeno', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_pumpable(_ob(source: 'ical')));
    expect(find.text('Uvezeno'), findsOneWidget);
    expect(find.text('Potvrđeno'), findsNothing);
  });

  testWidgets('F4.12: cancelled external booking still badges Otkazano', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _pumpable(_ob(source: 'ical', status: BookingStatus.cancelled)),
    );
    expect(find.text('Otkazano'), findsOneWidget);
    expect(find.text('Uvezeno'), findsNothing);
  });

  testWidgets('F4.12: direct booking badge unchanged (Potvrđeno)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_pumpable(_ob()));
    expect(find.text('Potvrđeno'), findsOneWidget);
  });
}
