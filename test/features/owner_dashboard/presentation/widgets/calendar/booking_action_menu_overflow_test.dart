// Responsive regression for booking_action_menu.dart name Texts
// (audit/responsive-overflow-a11y-2026-06-20 §2 — the two remaining RenderFlex
// overflow items after the admin DataTable P0 / PR #765).
//
// Guest / platform / unit names sit in width-bounding `Expanded`s with no
// maxLines/overflow, so a long name WRAPS to 2-3 lines and breaks the compact
// bottom-sheet header. Fix = `maxLines: 1, overflow: TextOverflow.ellipsis`.
// Both target classes are public, so we pump them directly:
//   * BookingActionBottomSheet — no providers (bare ProviderScope).
//   * BookingMoveToUnitMenu — needs an `allOwnerUnitsProvider` override.

import 'package:bookbed/core/constants/enums.dart';
import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/owner_dashboard/presentation/providers/owner_calendar_provider.dart';
import 'package:bookbed/features/owner_dashboard/presentation/widgets/calendar/booking_action_menu.dart';
import 'package:bookbed/l10n/app_localizations.dart';
import 'package:bookbed/shared/models/booking_model.dart';
import 'package:bookbed/shared/models/unit_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Long free-text names with no break opportunity near the width — the real
// wrap drivers.
const _longGuest = 'Maximiliana-Konstantina Đurđevković-Pavličić-Anastasijević';
const _longUnit =
    'Apartman s panoramskim pogledom na more, treći kat, sjeverno krilo';

BookingModel _booking({String? source}) {
  final now = DateTime(2026, 7, 8);
  return BookingModel(
    id: 'ba-test',
    unitId: 'u1',
    checkIn: now.add(const Duration(days: 5)),
    checkOut: now.add(const Duration(days: 8)),
    status: BookingStatus.confirmed,
    createdAt: now,
    guestName: _longGuest,
    source: source,
    totalPrice: 360,
    guestCount: 2,
  );
}

UnitModel _unit(String id, String name) => UnitModel(
  id: id,
  propertyId: 'p1',
  name: name,
  pricePerNight: 120,
  maxGuests: 4,
  createdAt: DateTime(2026, 7, 8),
);

void _expectEllipsized(WidgetTester tester, Finder finder, String label) {
  final texts = tester.widgetList<Text>(finder);
  expect(texts, isNotEmpty, reason: 'expected a Text for $label');
  for (final t in texts) {
    expect(t.maxLines, 1, reason: '$label should be maxLines:1');
    expect(
      t.overflow,
      TextOverflow.ellipsis,
      reason: '$label should ellipsize',
    );
  }
}

void main() {
  group('BookingActionBottomSheet header names ellipsize', () {
    testWidgets('external booking @360px — guest + platform single-line', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: BookingActionBottomSheet(
                  booking: _booking(source: 'airbnb'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);

      // Edit 2 (guest name, 18px bold) + Edit 1 (platform name).
      _expectEllipsized(tester, find.text(_longGuest), 'guest name');
      _expectEllipsized(tester, find.text('Airbnb'), 'platform name');

      // Behavioural: the long guest name renders on ONE line — pre-fix it
      // wrapped to multiple lines at this width.
      final h = tester.getSize(find.text(_longGuest)).height;
      expect(
        h,
        lessThan(30),
        reason: 'guest name wrapped (height=$h) instead of ellipsizing',
      );
    });
  });

  group('BookingMoveToUnitMenu names ellipsize', () {
    testWidgets('long guest + unit name @360px', (tester) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allOwnerUnitsProvider.overrideWith(
              (ref) async => [_unit('u2', _longUnit)],
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (ctx) => Scaffold(
                body: BookingMoveToUnitMenu(
                  booking: _booking(),
                  parentContext: ctx,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Edit 5 (move-menu guest name) + Edit 6 (user-defined unit name).
      _expectEllipsized(tester, find.text(_longGuest), 'move-menu guest name');
      _expectEllipsized(tester, find.text(_longUnit), 'unit name');
    });
  });
}
