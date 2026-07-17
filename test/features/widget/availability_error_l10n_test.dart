// The calendars must tell the guest WHY a range failed, not just that it did.
//
// `AvailabilityCheckResult` already carries errorCode + conflictDate +
// icalSource, and widget_translations.dart already carries a parameterised
// string for every code, in all 4 languages. None of it was reachable: both
// calendars collapsed every outcome into `errorCannotSelectBookedDates`.
//
// #935 wired ONE code (checkError) and left the other five dormant — the same
// "fixed one, left the twins" shape as #948 and #952. This drives the real
// mapper over every enum value so a new code cannot be added without a message.
//
// Why it matters concretely: "Dolazak nije moguć na datum 20. kol 2026." tells
// a guest to shift one day. "Već rezervirano" tells them to give up. Different
// action, lost booking.

import 'package:bookbed/features/widget/data/helpers/availability_checker.dart';
import 'package:bookbed/features/widget/domain/constants/widget_constants.dart';
import 'package:bookbed/features/widget/presentation/l10n/availability_error_l10n.dart';
import 'package:bookbed/features/widget/presentation/l10n/widget_translations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() async {
    // errorBlockedDate & friends format the date through DateFormat.
    await initializeDateFormatting('hr');
    await initializeDateFormatting('en');
  });

  final hr = WidgetTranslations(const Locale('hr'));
  final en = WidgetTranslations(const Locale('en'));
  final conflictDate = DateTime(2026, 8, 20);

  group('every AvailabilityErrorCode maps to its own message', () {
    test('checkError never claims the dates are taken (#935 guard)', () {
      final msg = hr.availabilityErrorText(
        AvailabilityCheckResult.error(ConflictType.booking),
      );
      expect(msg, hr.errorAvailabilityCheck);
      expect(
        msg,
        isNot(hr.errorCannotSelectBookedDates),
        reason: 'a failed check is not a booked date',
      );
    });

    // THE BITE: each of these returned the generic booked line before.
    test('icalConflict names the source', () {
      final msg = hr.availabilityErrorText(
        AvailabilityCheckResult.icalConflict('evt-1', 'Booking.com'),
      );
      expect(msg, contains('Booking.com'));
      expect(msg, isNot(hr.errorCannotSelectBookedDates));
    });

    test('blockedCheckIn names the date — the guest can shift a day', () {
      final msg = hr.availabilityErrorText(
        AvailabilityCheckResult.blockedCheckInConflict('p1', conflictDate),
      );
      expect(msg, hr.errorBlockedCheckIn(_fmt(hr, conflictDate)));
      expect(msg, isNot(hr.errorCannotSelectBookedDates));
    });

    test('blockedCheckOut names the date', () {
      final msg = hr.availabilityErrorText(
        AvailabilityCheckResult.blockedCheckOutConflict('p1', conflictDate),
      );
      expect(msg, hr.errorBlockedCheckOut(_fmt(hr, conflictDate)));
      expect(msg, isNot(hr.errorCannotSelectBookedDates));
    });

    test('blockedDate names the date', () {
      final msg = hr.availabilityErrorText(
        AvailabilityCheckResult.blockedDateConflict('p1', conflictDate),
      );
      expect(msg, hr.errorBlockedDate(_fmt(hr, conflictDate)));
      expect(msg, isNot(hr.errorCannotSelectBookedDates));
    });

    test('bookingConflict uses its own dedicated string', () {
      final msg = hr.availabilityErrorText(
        AvailabilityCheckResult.bookingConflict('bk-1'),
      );
      expect(msg, hr.errorBookingConflict);
    });

    test('no code produces an empty message', () {
      for (final code in AvailabilityErrorCode.values) {
        final msg = hr.availabilityErrorText(
          AvailabilityCheckResult(
            isAvailable: false,
            errorCode: code,
            conflictDate: conflictDate,
            icalSource: 'Airbnb',
          ),
        );
        expect(msg, isNotEmpty, reason: '$code must say something');
      }
    });
  });

  group('degrades safely rather than crashing', () {
    test('icalConflict without a source falls back to the generic line', () {
      final msg = hr.availabilityErrorText(
        const AvailabilityCheckResult(
          isAvailable: false,
          errorCode: AvailabilityErrorCode.icalConflict,
        ),
      );
      expect(msg, hr.errorCannotSelectBookedDates);
    });

    test('blockedDate without a conflictDate falls back', () {
      final msg = hr.availabilityErrorText(
        const AvailabilityCheckResult(
          isAvailable: false,
          errorCode: AvailabilityErrorCode.blockedDate,
        ),
      );
      expect(msg, hr.errorCannotSelectBookedDates);
    });
  });

  test('messages actually localize', () {
    final hrMsg = hr.availabilityErrorText(
      AvailabilityCheckResult.blockedCheckInConflict('p1', conflictDate),
    );
    final enMsg = en.availabilityErrorText(
      AvailabilityCheckResult.blockedCheckInConflict('p1', conflictDate),
    );
    expect(hrMsg, isNot(enMsg), reason: 'hr and en must differ');
  });
}

/// Mirrors the mapper's own `DateFormat.yMMMd(locale)` so the expectation
/// states the format once instead of hardcoding a rendered string.
String _fmt(WidgetTranslations tr, DateTime d) =>
    DateFormat.yMMMd(tr.locale.toString()).format(d);
