import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/utils/date_normalizer.dart';

void main() {
  group('DateNormalizer', () {
    group('normalize', () {
      test('removes time components from DateTime', () {
        final date = DateTime(2024, 6, 15, 14, 30, 45, 123);
        final normalized = DateNormalizer.normalize(date);

        expect(normalized.year, 2024);
        expect(normalized.month, 6);
        expect(normalized.day, 15);
        expect(normalized.hour, 0);
        expect(normalized.minute, 0);
        expect(normalized.second, 0);
        expect(normalized.millisecond, 0);
      });

      test('preserves already normalized date', () {
        final date = DateTime(2024, 6, 15);
        final normalized = DateNormalizer.normalize(date);

        expect(normalized, date);
      });

      test('handles midnight correctly', () {
        final date = DateTime(2024, 6, 15, 0, 0, 0, 0);
        final normalized = DateNormalizer.normalize(date);

        expect(normalized, date);
      });

      test('handles end of day correctly', () {
        final date = DateTime(2024, 6, 15, 23, 59, 59, 999);
        final normalized = DateNormalizer.normalize(date);

        expect(normalized.day, 15);
        expect(normalized.hour, 0);
      });
    });

    group('fromTimestamp', () {
      test('converts Timestamp to normalized DateTime', () {
        final timestamp = Timestamp.fromDate(DateTime(2024, 6, 15, 14, 30));
        final result = DateNormalizer.fromTimestamp(timestamp);

        expect(result, isNotNull);
        expect(result!.year, 2024);
        expect(result.month, 6);
        expect(result.day, 15);
        expect(result.hour, 0);
        expect(result.minute, 0);
      });

      test('returns null for null timestamp', () {
        final result = DateNormalizer.fromTimestamp(null);
        expect(result, isNull);
      });
    });

    group('fromTimestampRequired', () {
      test('converts Timestamp to normalized DateTime', () {
        final timestamp = Timestamp.fromDate(DateTime(2024, 6, 15, 14, 30));
        final result = DateNormalizer.fromTimestampRequired(timestamp);

        expect(result.year, 2024);
        expect(result.month, 6);
        expect(result.day, 15);
        expect(result.hour, 0);
      });
    });

    group('isSameDay', () {
      test('returns true for same day different times', () {
        final date1 = DateTime(2024, 6, 15, 10, 0);
        final date2 = DateTime(2024, 6, 15, 18, 30);

        expect(DateNormalizer.isSameDay(date1, date2), isTrue);
      });

      test('returns true for identical dates', () {
        final date1 = DateTime(2024, 6, 15);
        final date2 = DateTime(2024, 6, 15);

        expect(DateNormalizer.isSameDay(date1, date2), isTrue);
      });

      test('returns false for different days', () {
        final date1 = DateTime(2024, 6, 15);
        final date2 = DateTime(2024, 6, 16);

        expect(DateNormalizer.isSameDay(date1, date2), isFalse);
      });

      test('returns false for same day different months', () {
        final date1 = DateTime(2024, 6, 15);
        final date2 = DateTime(2024, 7, 15);

        expect(DateNormalizer.isSameDay(date1, date2), isFalse);
      });

      test('returns false for same day different years', () {
        final date1 = DateTime(2024, 6, 15);
        final date2 = DateTime(2025, 6, 15);

        expect(DateNormalizer.isSameDay(date1, date2), isFalse);
      });
    });

    group('isToday', () {
      test('returns true for today', () {
        final today = DateTime.now();
        expect(DateNormalizer.isToday(today), isTrue);
      });

      test('returns true for today with different time', () {
        final now = DateTime.now();
        final todayMorning = DateTime(now.year, now.month, now.day, 8, 0);
        expect(DateNormalizer.isToday(todayMorning), isTrue);
      });

      test('returns false for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(DateNormalizer.isToday(yesterday), isFalse);
      });

      test('returns false for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(DateNormalizer.isToday(tomorrow), isFalse);
      });
    });

    group('isPast', () {
      test('returns true for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(DateNormalizer.isPast(yesterday), isTrue);
      });

      test('returns true for old date', () {
        final oldDate = DateTime(2020, 1, 1);
        expect(DateNormalizer.isPast(oldDate), isTrue);
      });

      test('returns false for today', () {
        final today = DateTime.now();
        expect(DateNormalizer.isPast(today), isFalse);
      });

      test('returns false for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(DateNormalizer.isPast(tomorrow), isFalse);
      });
    });

    group('isFuture', () {
      test('returns true for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(DateNormalizer.isFuture(tomorrow), isTrue);
      });

      test('returns true for far future', () {
        final future = DateTime(2030, 1, 1);
        expect(DateNormalizer.isFuture(future), isTrue);
      });

      test('returns false for today', () {
        final today = DateTime.now();
        expect(DateNormalizer.isFuture(today), isFalse);
      });

      test('returns false for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(DateNormalizer.isFuture(yesterday), isFalse);
      });
    });

    group('daysBetween', () {
      test('returns correct days for same day', () {
        final date = DateTime(2024, 6, 15);
        expect(DateNormalizer.daysBetween(date, date), 0);
      });

      test('returns correct days for consecutive days', () {
        final date1 = DateTime(2024, 6, 15);
        final date2 = DateTime(2024, 6, 16);
        expect(DateNormalizer.daysBetween(date1, date2), 1);
      });

      test('returns correct days for week', () {
        final date1 = DateTime(2024, 6, 15);
        final date2 = DateTime(2024, 6, 22);
        expect(DateNormalizer.daysBetween(date1, date2), 7);
      });

      test('returns positive regardless of order', () {
        final date1 = DateTime(2024, 6, 15);
        final date2 = DateTime(2024, 6, 22);
        expect(DateNormalizer.daysBetween(date2, date1), 7);
      });

      test('ignores time components', () {
        final date1 = DateTime(2024, 6, 15, 23, 59);
        final date2 = DateTime(2024, 6, 16, 0, 1);
        expect(DateNormalizer.daysBetween(date1, date2), 1);
      });
    });

    group('nightsBetween', () {
      test('returns 0 for same day', () {
        final date = DateTime(2024, 6, 15);
        expect(DateNormalizer.nightsBetween(date, date), 0);
      });

      test('returns 1 for consecutive days', () {
        final checkIn = DateTime(2024, 6, 15);
        final checkOut = DateTime(2024, 6, 16);
        expect(DateNormalizer.nightsBetween(checkIn, checkOut), 1);
      });

      test('returns correct nights for week stay', () {
        final checkIn = DateTime(2024, 6, 15);
        final checkOut = DateTime(2024, 6, 22);
        expect(DateNormalizer.nightsBetween(checkIn, checkOut), 7);
      });

      test('returns 0 if checkOut before checkIn', () {
        final checkIn = DateTime(2024, 6, 20);
        final checkOut = DateTime(2024, 6, 15);
        expect(DateNormalizer.nightsBetween(checkIn, checkOut), 0);
      });

      test('ignores time components', () {
        final checkIn = DateTime(2024, 6, 15, 15, 0); // 3 PM check-in
        final checkOut = DateTime(2024, 6, 17, 10, 0); // 10 AM check-out
        expect(DateNormalizer.nightsBetween(checkIn, checkOut), 2);
      });
    });

    group('dateRange', () {
      test('returns empty list for invalid range', () {
        final start = DateTime(2024, 6, 20);
        final end = DateTime(2024, 6, 15);
        expect(DateNormalizer.dateRange(start, end), isEmpty);
      });

      test('returns single date for same start and end', () {
        final date = DateTime(2024, 6, 15);
        final result = DateNormalizer.dateRange(date, date);

        expect(result.length, 1);
        expect(DateNormalizer.isSameDay(result.first, date), isTrue);
      });

      test('returns correct range for multiple days', () {
        final start = DateTime(2024, 6, 15);
        final end = DateTime(2024, 6, 18);
        final result = DateNormalizer.dateRange(start, end);

        expect(result.length, 4); // 15, 16, 17, 18
        expect(result[0].day, 15);
        expect(result[1].day, 16);
        expect(result[2].day, 17);
        expect(result[3].day, 18);
      });

      test('normalizes dates before generating range', () {
        final start = DateTime(2024, 6, 15, 14, 30);
        final end = DateTime(2024, 6, 17, 10, 0);
        final result = DateNormalizer.dateRange(start, end);

        expect(result.length, 3);
        for (final date in result) {
          expect(date.hour, 0);
          expect(date.minute, 0);
        }
      });
    });

    group('bookingNights', () {
      test('returns empty list for same day', () {
        final date = DateTime(2024, 6, 15);
        expect(DateNormalizer.bookingNights(date, date), isEmpty);
      });

      test('returns empty list for invalid range', () {
        final checkIn = DateTime(2024, 6, 20);
        final checkOut = DateTime(2024, 6, 15);
        expect(DateNormalizer.bookingNights(checkIn, checkOut), isEmpty);
      });

      test('returns check-in date only for 1 night stay', () {
        final checkIn = DateTime(2024, 6, 15);
        final checkOut = DateTime(2024, 6, 16);
        final result = DateNormalizer.bookingNights(checkIn, checkOut);

        expect(result.length, 1);
        expect(result[0].day, 15);
      });

      test('excludes checkout day (3 night stay)', () {
        final checkIn = DateTime(2024, 6, 15);
        final checkOut = DateTime(2024, 6, 18);
        final result = DateNormalizer.bookingNights(checkIn, checkOut);

        // Jan 1 to Jan 3: nights are Jan 1, Jan 2 (NOT Jan 3)
        expect(result.length, 3);
        expect(result[0].day, 15);
        expect(result[1].day, 16);
        expect(result[2].day, 17);
        // Day 18 should NOT be in the list
        expect(result.any((d) => d.day == 18), isFalse);
      });
    });

    group('isInRange', () {
      test('returns true for date within range', () {
        final date = DateTime(2024, 6, 17);
        final start = DateTime(2024, 6, 15);
        final end = DateTime(2024, 6, 20);

        expect(DateNormalizer.isInRange(date, start, end), isTrue);
      });

      test('returns true for date at start of range', () {
        final date = DateTime(2024, 6, 15);
        final start = DateTime(2024, 6, 15);
        final end = DateTime(2024, 6, 20);

        expect(DateNormalizer.isInRange(date, start, end), isTrue);
      });

      test('returns true for date at end of range', () {
        final date = DateTime(2024, 6, 20);
        final start = DateTime(2024, 6, 15);
        final end = DateTime(2024, 6, 20);

        expect(DateNormalizer.isInRange(date, start, end), isTrue);
      });

      test('returns false for date before range', () {
        final date = DateTime(2024, 6, 14);
        final start = DateTime(2024, 6, 15);
        final end = DateTime(2024, 6, 20);

        expect(DateNormalizer.isInRange(date, start, end), isFalse);
      });

      test('returns false for date after range', () {
        final date = DateTime(2024, 6, 21);
        final start = DateTime(2024, 6, 15);
        final end = DateTime(2024, 6, 20);

        expect(DateNormalizer.isInRange(date, start, end), isFalse);
      });

      test('ignores time components', () {
        final date = DateTime(2024, 6, 15, 14, 0);
        final start = DateTime(2024, 6, 15, 10, 0);
        final end = DateTime(2024, 6, 15, 18, 0);

        expect(DateNormalizer.isInRange(date, start, end), isTrue);
      });
    });

    group('isWeekend', () {
      test('returns true for Saturday with default days', () {
        final saturday = DateTime(2024, 6, 15); // This is a Saturday
        expect(DateNormalizer.isWeekend(saturday), isTrue);
      });

      test('returns true for Sunday with default days', () {
        final sunday = DateTime(2024, 6, 16); // This is a Sunday
        expect(DateNormalizer.isWeekend(sunday), isTrue);
      });

      test('returns false for Monday with default days', () {
        final monday = DateTime(2024, 6, 17); // This is a Monday
        expect(DateNormalizer.isWeekend(monday), isFalse);
      });

      test('returns false for Friday with default days', () {
        final friday = DateTime(2024, 6, 14); // This is a Friday
        expect(DateNormalizer.isWeekend(friday), isFalse);
      });

      test('uses custom weekend days', () {
        final friday = DateTime(2024, 6, 14); // Friday = 5

        // Custom weekend: Friday + Saturday (not Sunday)
        expect(
          DateNormalizer.isWeekend(friday, weekendDays: [5, 6]),
          isTrue,
        );
      });

      test('returns false when day not in custom weekend', () {
        final sunday = DateTime(2024, 6, 16); // Sunday = 7

        // Custom weekend: Friday + Saturday only
        expect(
          DateNormalizer.isWeekend(sunday, weekendDays: [5, 6]),
          isFalse,
        );
      });
    });

    group('firstDayOfMonth', () {
      test('returns first day of month', () {
        final date = DateTime(2024, 6, 15);
        final first = DateNormalizer.firstDayOfMonth(date);

        expect(first.year, 2024);
        expect(first.month, 6);
        expect(first.day, 1);
      });

      test('preserves year when near year boundary', () {
        final date = DateTime(2024, 1, 15);
        final first = DateNormalizer.firstDayOfMonth(date);

        expect(first.year, 2024);
        expect(first.month, 1);
        expect(first.day, 1);
      });
    });

    group('lastDayOfMonth', () {
      test('returns last day of 30-day month', () {
        final date = DateTime(2024, 6, 15); // June has 30 days
        final last = DateNormalizer.lastDayOfMonth(date);

        expect(last.year, 2024);
        expect(last.month, 6);
        expect(last.day, 30);
      });

      test('returns last day of 31-day month', () {
        final date = DateTime(2024, 7, 15); // July has 31 days
        final last = DateNormalizer.lastDayOfMonth(date);

        expect(last.year, 2024);
        expect(last.month, 7);
        expect(last.day, 31);
      });

      test('returns last day of February leap year', () {
        final date = DateTime(2024, 2, 15); // 2024 is leap year
        final last = DateNormalizer.lastDayOfMonth(date);

        expect(last.year, 2024);
        expect(last.month, 2);
        expect(last.day, 29);
      });

      test('returns last day of February non-leap year', () {
        final date = DateTime(2023, 2, 15); // 2023 is not leap year
        final last = DateNormalizer.lastDayOfMonth(date);

        expect(last.year, 2023);
        expect(last.month, 2);
        expect(last.day, 28);
      });

      test('returns last day of December', () {
        final date = DateTime(2024, 12, 15);
        final last = DateNormalizer.lastDayOfMonth(date);

        expect(last.year, 2024);
        expect(last.month, 12);
        expect(last.day, 31);
      });
    });

    group('firstDayOfYear', () {
      test('returns January 1st', () {
        final date = DateTime(2024, 6, 15);
        final first = DateNormalizer.firstDayOfYear(date);

        expect(first.year, 2024);
        expect(first.month, 1);
        expect(first.day, 1);
      });
    });

    group('lastDayOfYear', () {
      test('returns December 31st', () {
        final date = DateTime(2024, 6, 15);
        final last = DateNormalizer.lastDayOfYear(date);

        expect(last.year, 2024);
        expect(last.month, 12);
        expect(last.day, 31);
      });
    });
  });
}
