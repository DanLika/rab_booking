import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/owner_dashboard/utils/date_range_utils.dart';

void main() {
  group('DateRangeUtils', () {
    group('Boundary Functions', () {
      test('getMonday returns the correct Monday for a given date', () {
        // Wednesday, Nov 1, 2023 -> Monday, Oct 30, 2023
        final date1 = DateTime(2023, 11, 1);
        final monday1 = DateRangeUtils.getMonday(date1);
        expect(monday1.year, 2023);
        expect(monday1.month, 10);
        expect(monday1.day, 30);

        // Monday, Jan 1, 2024 -> Monday, Jan 1, 2024
        final date2 = DateTime(2024, 1, 1);
        final monday2 = DateRangeUtils.getMonday(date2);
        expect(monday2.year, 2024);
        expect(monday2.month, 1);
        expect(monday2.day, 1);

        // Sunday, Dec 31, 2023 -> Monday, Dec 25, 2023
        final date3 = DateTime(2023, 12, 31);
        final monday3 = DateRangeUtils.getMonday(date3);
        expect(monday3.year, 2023);
        expect(monday3.month, 12);
        expect(monday3.day, 25);
      });

      test('getSunday returns the correct Sunday for a given date', () {
        // Wednesday, Nov 1, 2023 -> Sunday, Nov 5, 2023
        final date1 = DateTime(2023, 11, 1);
        final sunday1 = DateRangeUtils.getSunday(date1);
        expect(sunday1.year, 2023);
        expect(sunday1.month, 11);
        expect(sunday1.day, 5);
        expect(sunday1.hour, 23);
        expect(sunday1.minute, 59);
        expect(sunday1.second, 59);

        // Monday, Jan 1, 2024 -> Sunday, Jan 7, 2024
        final date2 = DateTime(2024, 1, 1);
        final sunday2 = DateRangeUtils.getSunday(date2);
        expect(sunday2.year, 2024);
        expect(sunday2.month, 1);
        expect(sunday2.day, 7);

        // Sunday, Dec 31, 2023 -> Sunday, Dec 31, 2023
        final date3 = DateTime(2023, 12, 31);
        final sunday3 = DateRangeUtils.getSunday(date3);
        expect(sunday3.year, 2023);
        expect(sunday3.month, 12);
        expect(sunday3.day, 31);
      });

      test('getFirstDayOfMonth returns the first day of the month', () {
        final date = DateTime(2023, 11, 15);
        final firstDay = DateRangeUtils.getFirstDayOfMonth(date);
        expect(firstDay.year, 2023);
        expect(firstDay.month, 11);
        expect(firstDay.day, 1);
        expect(firstDay.hour, 0);
        expect(firstDay.minute, 0);
      });

      test('getLastDayOfMonth returns the last day of the month', () {
        // Regular month
        final date1 = DateTime(2023, 11, 15);
        final lastDay1 = DateRangeUtils.getLastDayOfMonth(date1);
        expect(lastDay1.year, 2023);
        expect(lastDay1.month, 11);
        expect(lastDay1.day, 30);
        expect(lastDay1.hour, 23);
        expect(lastDay1.minute, 59);
        expect(lastDay1.second, 59);

        // Leap year
        final date2 = DateTime(2024, 2, 15);
        final lastDay2 = DateRangeUtils.getLastDayOfMonth(date2);
        expect(lastDay2.year, 2024);
        expect(lastDay2.month, 2);
        expect(lastDay2.day, 29);

        // Non-leap year
        final date3 = DateTime(2023, 2, 15);
        final lastDay3 = DateRangeUtils.getLastDayOfMonth(date3);
        expect(lastDay3.year, 2023);
        expect(lastDay3.month, 2);
        expect(lastDay3.day, 28);
      });

      test('getDaysInMonth returns the correct number of days', () {
        expect(DateRangeUtils.getDaysInMonth(DateTime(2023, 1, 15)), 31);
        expect(DateRangeUtils.getDaysInMonth(DateTime(2023, 2, 15)), 28);
        expect(DateRangeUtils.getDaysInMonth(DateTime(2024, 2, 15)), 29); // Leap year
        expect(DateRangeUtils.getDaysInMonth(DateTime(2023, 4, 15)), 30);
        expect(DateRangeUtils.getDaysInMonth(DateTime(2023, 12, 15)), 31);
      });
    });

    group('List Generation & Checks', () {
      test('getWeekDates returns a list of 7 days starting from Monday', () {
        final date = DateTime(2023, 11, 1); // Wednesday
        final weekDates = DateRangeUtils.getWeekDates(date);

        expect(weekDates.length, 7);
        // Should start on Monday, Oct 30, 2023
        expect(weekDates[0].year, 2023);
        expect(weekDates[0].month, 10);
        expect(weekDates[0].day, 30);

        // Should end on Sunday, Nov 5, 2023
        expect(weekDates[6].year, 2023);
        expect(weekDates[6].month, 11);
        expect(weekDates[6].day, 5);
      });

      test('getMonthDates returns a list of dates for the entire month', () {
        // November 2023 (30 days)
        final date1 = DateTime(2023, 11, 15);
        final monthDates1 = DateRangeUtils.getMonthDates(date1);
        expect(monthDates1.length, 30);
        expect(monthDates1.first.day, 1);
        expect(monthDates1.last.day, 30);

        // February 2024 (Leap year, 29 days)
        final date2 = DateTime(2024, 2, 10);
        final monthDates2 = DateRangeUtils.getMonthDates(date2);
        expect(monthDates2.length, 29);
        expect(monthDates2.first.day, 1);
        expect(monthDates2.last.day, 29);
      });

      test('isSameDay correctly identifies same days', () {
        final date1 = DateTime(2023, 11, 1, 10, 0, 0);
        final date2 = DateTime(2023, 11, 1, 20, 30, 0);
        final date3 = DateTime(2023, 11, 2, 10, 0, 0);
        final date4 = DateTime(2024, 11, 1, 10, 0, 0);

        expect(DateRangeUtils.isSameDay(date1, date2), isTrue);
        expect(DateRangeUtils.isSameDay(date1, date3), isFalse);
        expect(DateRangeUtils.isSameDay(date1, date4), isFalse);
      });

      test('isToday correctly identifies today', () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final tomorrow = today.add(const Duration(days: 1));

        expect(DateRangeUtils.isToday(today), isTrue);
        expect(DateRangeUtils.isToday(yesterday), isFalse);
        expect(DateRangeUtils.isToday(tomorrow), isFalse);
      });

      test('isPast correctly identifies past dates', () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final tomorrow = today.add(const Duration(days: 1));

        expect(DateRangeUtils.isPast(yesterday), isTrue);
        expect(DateRangeUtils.isPast(today), isFalse);
        expect(DateRangeUtils.isPast(tomorrow), isFalse);
      });

      test('isFuture correctly identifies future dates', () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final tomorrow = today.add(const Duration(days: 1));

        expect(DateRangeUtils.isFuture(tomorrow), isTrue);
        expect(DateRangeUtils.isFuture(today), isFalse);
        expect(DateRangeUtils.isFuture(yesterday), isFalse);
      });

      test('isWeekend correctly identifies Saturday and Sunday', () {
        // Monday - Friday
        expect(DateRangeUtils.isWeekend(DateTime(2023, 10, 30)), isFalse); // Mon
        expect(DateRangeUtils.isWeekend(DateTime(2023, 10, 31)), isFalse); // Tue
        expect(DateRangeUtils.isWeekend(DateTime(2023, 11, 1)), isFalse);  // Wed
        expect(DateRangeUtils.isWeekend(DateTime(2023, 11, 2)), isFalse);  // Thu
        expect(DateRangeUtils.isWeekend(DateTime(2023, 11, 3)), isFalse);  // Fri

        // Saturday - Sunday
        expect(DateRangeUtils.isWeekend(DateTime(2023, 11, 4)), isTrue);   // Sat
        expect(DateRangeUtils.isWeekend(DateTime(2023, 11, 5)), isTrue);   // Sun
      });
    });

    group('Formatting Functions', () {
      test('formatWeekRange correctly formats different date ranges', () {
        // Same month
        final start1 = DateTime(2023, 10, 23);
        final end1 = DateTime(2023, 10, 29);
        expect(DateRangeUtils.formatWeekRange(start1, end1), '23 - 29 Oct 2023');

        // Different months, same year
        final start2 = DateTime(2023, 10, 30);
        final end2 = DateTime(2023, 11, 5);
        expect(DateRangeUtils.formatWeekRange(start2, end2), '30 Oct - 5 Nov 2023');

        // Different years
        final start3 = DateTime(2023, 12, 30);
        final end3 = DateTime(2024, 1, 5);
        expect(DateRangeUtils.formatWeekRange(start3, end3), '30 Dec 2023 - 5 Jan 2024');

        // Edge case: invalid months (though unlikely with DateTime)
        final invalidMonthDate1 = DateTime(2023, 0, 15); // becomes Dec 15, 2022
        final invalidMonthDate2 = DateTime(2023, 13, 15); // becomes Jan 15, 2024
        expect(DateRangeUtils.formatWeekRange(invalidMonthDate1, invalidMonthDate2), '15 Dec 2022 - 15 Jan 2024');
      });

      test('formatMonth correctly formats month and year', () {
        expect(DateRangeUtils.formatMonth(DateTime(2023, 1, 15)), 'January 2023');
        expect(DateRangeUtils.formatMonth(DateTime(2023, 10, 15)), 'October 2023');
        expect(DateRangeUtils.formatMonth(DateTime(2023, 12, 15)), 'December 2023');
      });

      test('formatDateWithWeekday correctly formats date with short weekday', () {
        // Oct 23, 2023 is a Monday
        expect(DateRangeUtils.formatDateWithWeekday(DateTime(2023, 10, 23)), 'Mon, 23 Oct');

        // Nov 5, 2023 is a Sunday
        expect(DateRangeUtils.formatDateWithWeekday(DateTime(2023, 11, 5)), 'Sun, 5 Nov');
      });
    });

    group('Calculation & Navigation', () {
      test('getNextWeek returns Monday of the next week', () {
        // Wed, Nov 1, 2023 -> Monday of current week is Oct 30 -> Next week Monday is Nov 6
        final date1 = DateTime(2023, 11, 1);
        final nextWeek1 = DateRangeUtils.getNextWeek(date1);
        expect(nextWeek1.year, 2023);
        expect(nextWeek1.month, 11);
        expect(nextWeek1.day, 6);

        // Year boundary: Wed, Dec 27, 2023 -> Monday is Dec 25 -> Next week Monday is Jan 1, 2024
        final date2 = DateTime(2023, 12, 27);
        final nextWeek2 = DateRangeUtils.getNextWeek(date2);
        expect(nextWeek2.year, 2024);
        expect(nextWeek2.month, 1);
        expect(nextWeek2.day, 1);
      });

      test('getPreviousWeek returns Monday of the previous week', () {
        // Wed, Nov 1, 2023 -> Monday is Oct 30 -> Previous week Monday is Oct 23
        final date1 = DateTime(2023, 11, 1);
        final prevWeek1 = DateRangeUtils.getPreviousWeek(date1);
        expect(prevWeek1.year, 2023);
        expect(prevWeek1.month, 10);
        expect(prevWeek1.day, 23);

        // Year boundary: Wed, Jan 3, 2024 -> Monday is Jan 1 -> Previous week Monday is Dec 25, 2023
        final date2 = DateTime(2024, 1, 3);
        final prevWeek2 = DateRangeUtils.getPreviousWeek(date2);
        expect(prevWeek2.year, 2023);
        expect(prevWeek2.month, 12);
        expect(prevWeek2.day, 25);
      });

      test('getNextMonth returns the first day of the next month', () {
        // Regular month change
        final date1 = DateTime(2023, 11, 15);
        final nextMonth1 = DateRangeUtils.getNextMonth(date1);
        expect(nextMonth1.year, 2023);
        expect(nextMonth1.month, 12);
        expect(nextMonth1.day, 1);

        // Year boundary change
        final date2 = DateTime(2023, 12, 15);
        final nextMonth2 = DateRangeUtils.getNextMonth(date2);
        expect(nextMonth2.year, 2024);
        expect(nextMonth2.month, 1);
        expect(nextMonth2.day, 1);
      });

      test('getPreviousMonth returns the first day of the previous month', () {
        // Regular month change
        final date1 = DateTime(2023, 11, 15);
        final prevMonth1 = DateRangeUtils.getPreviousMonth(date1);
        expect(prevMonth1.year, 2023);
        expect(prevMonth1.month, 10);
        expect(prevMonth1.day, 1);

        // Year boundary change
        final date2 = DateTime(2024, 1, 15);
        final prevMonth2 = DateRangeUtils.getPreviousMonth(date2);
        expect(prevMonth2.year, 2023);
        expect(prevMonth2.month, 12);
        expect(prevMonth2.day, 1);
      });

      test('calculateNights correctly calculates duration', () {
        final checkIn = DateTime(2023, 10, 1);
        final checkOut = DateTime(2023, 10, 5);
        expect(DateRangeUtils.calculateNights(checkIn, checkOut), 4);

        // Same day returns 0 nights
        expect(DateRangeUtils.calculateNights(checkIn, checkIn), 0);

        // Negative nights if checkout is before checkin (edge case)
        expect(DateRangeUtils.calculateNights(checkOut, checkIn), -4);
      });

      test('dateRangesOverlap correctly identifies overlapping date ranges', () {
        final r1Start = DateTime(2023, 10, 10);
        final r1End = DateTime(2023, 10, 15);

        // Complete overlap
        expect(
          DateRangeUtils.dateRangesOverlap(
            start1: r1Start,
            end1: r1End,
            start2: DateTime(2023, 10, 11),
            end2: DateTime(2023, 10, 14),
          ),
          isTrue,
        );

        // Partial overlap at start
        expect(
          DateRangeUtils.dateRangesOverlap(
            start1: r1Start,
            end1: r1End,
            start2: DateTime(2023, 10, 5),
            end2: DateTime(2023, 10, 12),
          ),
          isTrue,
        );

        // Partial overlap at end
        expect(
          DateRangeUtils.dateRangesOverlap(
            start1: r1Start,
            end1: r1End,
            start2: DateTime(2023, 10, 14),
            end2: DateTime(2023, 10, 20),
          ),
          isTrue,
        );

        // No overlap - strictly before
        expect(
          DateRangeUtils.dateRangesOverlap(
            start1: r1Start,
            end1: r1End,
            start2: DateTime(2023, 10, 1),
            end2: DateTime(2023, 10, 5),
          ),
          isFalse,
        );

        // No overlap - strictly after
        expect(
          DateRangeUtils.dateRangesOverlap(
            start1: r1Start,
            end1: r1End,
            start2: DateTime(2023, 10, 20),
            end2: DateTime(2023, 10, 25),
          ),
          isFalse,
        );

        // Adjacent ranges (touching at exact boundary - isBefore/isAfter logic)
        // If start1 = end2, start1.isBefore(end2) is FALSE.
        expect(
          DateRangeUtils.dateRangesOverlap(
            start1: r1Start,
            end1: r1End,
            start2: DateTime(2023, 10, 5),
            end2: r1Start, // 10
          ),
          isFalse,
        );

        expect(
          DateRangeUtils.dateRangesOverlap(
            start1: r1Start,
            end1: r1End,
            start2: r1End, // 15
            end2: DateTime(2023, 10, 20),
          ),
          isFalse,
        );
      });

      test('getDatesBetween correctly generates a list of dates between two dates', () {
        final start = DateTime(2023, 10, 1);
        final end = DateTime(2023, 10, 5);

        // Standard case
        final dates1 = DateRangeUtils.getDatesBetween(start, end);
        expect(dates1.length, 5);
        expect(dates1.first.day, 1);
        expect(dates1.last.day, 5);

        // Start equals End
        final dates2 = DateRangeUtils.getDatesBetween(start, start);
        expect(dates2.length, 1);
        expect(dates2.first.day, 1);

        // Start is after End (returns empty list)
        final dates3 = DateRangeUtils.getDatesBetween(end, start);
        expect(dates3.length, 0);
      });
    });
  });
}
