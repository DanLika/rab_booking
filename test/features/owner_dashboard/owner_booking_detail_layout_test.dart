// Overflow guard for the owner booking-detail responsive layouts (audit/128).
//
// Pumps the REAL layout widgets (_DesktopGrid / _TabletGrid / _SingleColumn via
// [buildBookingDetailContentForTest]) across the breakpoint range in light +
// dark, with normal + long-string fixtures that stress the Rows. The new tablet
// 2-col layout (F6) is the focus — it was single-column before.
//
//   * PRIMARY assertion: NO RenderFlex / layout overflow at any size
//     (`tester.takeException`).
//   * Status variants (pending / confirmed-upcoming / confirmed-past /
//     cancelled) exercise every action-button branch incl. the new
//     destructive-soft Odbij/Otkaži (F1).
//
// Hermetic: the action panel (_BDStatusActions) is a ConsumerWidget but reads
// its repository only on tap, so a bare ProviderScope suffices at pump time —
// no Firebase. The cover uses empty images → placeholder, no network.

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
  BookingStatus status = BookingStatus.pending,
  int checkInOffsetDays = 5,
  int checkOutOffsetDays = 8,
  String guest = 'Marko Horvat',
  String property = 'Vila Marina',
  String unit = 'Studio 4',
  String? notes,
}) {
  final DateTime now = DateTime(2026, 7, 8, 14);
  return OwnerBooking(
    booking: BookingModel(
      id: 'bd-test',
      unitId: 'u1',
      checkIn: now.add(Duration(days: checkInOffsetDays)),
      checkOut: now.add(Duration(days: checkOutOffsetDays)),
      status: status,
      createdAt: now.subtract(const Duration(days: 2)),
      totalPrice: 360,
      paidAmount: 72,
      notes: notes,
    ),
    property: PropertyModel(
      id: 'p1',
      name: property,
      description: 'desc',
      location: 'Rab',
      createdAt: now,
    ),
    unit: UnitModel(
      id: 'u1',
      propertyId: 'p1',
      name: unit,
      pricePerNight: 120,
      maxGuests: 2,
      createdAt: now,
    ),
    guestName: guest,
    guestEmail: 'marko.horvat@gmail.com',
    guestPhone: '+385 91 234 5678',
  );
}

const String _long =
    'Apartman-s-pogledom-na-more-i-vrlo-dugackim-imenom-bez-razmaka-koje-mora-elidirati';

const _breakpoints = <({String name, double w, double h})>[
  (name: 'mobile_360', w: 360, h: 800),
  (name: 'mobile_414', w: 414, h: 896),
  (name: 'tablet_600', w: 600, h: 1024), // wide single column (< 2-col min)
  (name: 'tablet_720', w: 720, h: 1024), // 2-col minimum width
  (name: 'tablet_768', w: 768, h: 1024),
  (name: 'tablet_1023', w: 1023, h: 1200),
  (name: 'desktop_1024', w: 1024, h: 1200),
  (name: 'desktop_1280', w: 1280, h: 1000),
  (name: 'desktop_1440', w: 1440, h: 1000),
];

Future<void> _pump(
  WidgetTester tester, {
  required double w,
  required double h,
  required bool dark,
  required OwnerBooking ob,
}) async {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: buildBookingDetailContentForTest(ob, w),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('booking-detail layouts — no overflow across breakpoints', () {
    for (final bp in _breakpoints) {
      for (final dark in const [false, true]) {
        final theme = dark ? 'dark' : 'light';

        testWidgets('${bp.name} $theme — normal pending', (tester) async {
          await _pump(
            tester,
            w: bp.w,
            h: bp.h,
            dark: dark,
            ob: _ob(notes: 'Stižemo oko 21:00, molim ostavite ključ.'),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('${bp.name} $theme — long strings', (tester) async {
          await _pump(
            tester,
            w: bp.w,
            h: bp.h,
            dark: dark,
            ob: _ob(
              guest: 'Marko-Aleksandar Horvat-Petrović',
              property: _long,
              unit: _long,
              notes: '$_long $_long $_long',
            ),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('booking-detail layouts — every status branch, no overflow', () {
    // Exercises approve/reject + destructive-soft cancel/complete (F1) across
    // the tablet 2-col (F6) and desktop grid.
    const variants = <({String name, BookingStatus status, int ci, int co})>[
      (
        name: 'confirmed-upcoming (Otkaži)',
        status: BookingStatus.confirmed,
        ci: 5,
        co: 8,
      ),
      (
        name: 'confirmed-past (Završi)',
        status: BookingStatus.confirmed,
        ci: -5,
        co: -2,
      ),
      (name: 'cancelled', status: BookingStatus.cancelled, ci: 5, co: 8),
      (name: 'completed', status: BookingStatus.completed, ci: -5, co: -2),
    ];
    for (final v in variants) {
      for (final w in const [768.0, 1280.0]) {
        testWidgets('${v.name} @${w.toInt()} — no overflow', (tester) async {
          await _pump(
            tester,
            w: w,
            h: 1200,
            dark: false,
            ob: _ob(
              status: v.status,
              checkInOffsetDays: v.ci,
              checkOutOffsetDays: v.co,
              notes: 'Napomena gosta.',
            ),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
