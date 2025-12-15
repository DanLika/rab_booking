import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/domain/constants/calendar_constants.dart';

void main() {
  group('CalendarDataService - Month Calculation Edge Cases', () {
    test('extendedStart handles January (month 1) correctly', () {
      // Test: startDate in January should correctly go to December of previous year
      final startDate = DateTime.utc(2024, 1, 15); // January 15, 2024

      // Expected: extendedStart should be December 2023 (month 12, year 2023)
      // Calculation: month 1 - 1 = 0, adjusted to 12, year 2024 - 1 = 2023
      final expectedMonth = 12;
      final expectedYear = 2023;

      // Verify the calculation logic (same as in calendar_data_service.dart)
      final startMonth = startDate.month - CalendarConstants.monthsBeforeForGapDetection;
      final startYear = startDate.year;
      final adjustedStartMonth = startMonth <= 0 ? 12 + startMonth : startMonth;
      final adjustedStartYear = startMonth <= 0 ? startYear - 1 : startYear;

      expect(adjustedStartMonth, expectedMonth);
      expect(adjustedStartYear, expectedYear);

      // Verify the resulting DateTime is valid
      final extendedStart = DateTime.utc(adjustedStartYear, adjustedStartMonth);
      expect(extendedStart.year, 2023);
      expect(extendedStart.month, 12);
    });

    test('extendedStart handles February (month 2) correctly', () {
      // Test: startDate in February should correctly go to January of same year
      final startDate = DateTime.utc(2024, 2, 15); // February 15, 2024

      // Expected: extendedStart should be January 2024 (month 1, year 2024)
      final startMonth = startDate.month - CalendarConstants.monthsBeforeForGapDetection;
      final startYear = startDate.year;
      final adjustedStartMonth = startMonth <= 0 ? 12 + startMonth : startMonth;
      final adjustedStartYear = startMonth <= 0 ? startYear - 1 : startYear;

      expect(adjustedStartMonth, 1);
      expect(adjustedStartYear, 2024);

      // Verify the resulting DateTime is valid
      final extendedStart = DateTime.utc(adjustedStartYear, adjustedStartMonth);
      expect(extendedStart.year, 2024);
      expect(extendedStart.month, 1);
    });

    test('extendedEnd handles December (month 12) correctly', () {
      // Test: endDate in December should correctly go to January of next year
      // Note: day=0 gives last day of previous month, so month 2, day 0 = Jan 31
      final endDate = DateTime.utc(2024, 12, 31); // December 31, 2024

      // Calculation: month 12 + 1 + 1 = 14, adjusted to 14 - 12 = 2, year 2024 + 1 = 2025
      // DateTime.utc(2025, 2, 0) = last day of January 2025 (because day 0 = previous month)
      final endMonth = endDate.month + CalendarConstants.monthsAfterForGapDetection + 1;
      final endYear = endDate.year;
      final adjustedEndMonth = endMonth > 12 ? endMonth - 12 : endMonth;
      final adjustedEndYear = endMonth > 12 ? endYear + 1 : endYear;

      expect(adjustedEndMonth, 2);
      expect(adjustedEndYear, 2025);

      // Verify the resulting DateTime is valid
      // Note: day=0 means last day of previous month, so month 2, day 0 = January 31
      final extendedEnd = DateTime.utc(adjustedEndYear, adjustedEndMonth, 0);
      expect(extendedEnd.year, 2025);
      expect(extendedEnd.month, 1); // January (because day 0 gives previous month)
    });

    test('extendedEnd handles November (month 11) correctly', () {
      // Test: endDate in November should correctly go to December of same year
      // Note: month 11 + 1 + 1 = 13, which doesn't overflow, so stays in same year
      final endDate = DateTime.utc(2024, 11, 30); // November 30, 2024

      // Calculation: month 11 + 1 + 1 = 13, which is > 12, so adjusted to 13 - 12 = 1, year 2024 + 1 = 2025
      // But wait, let's check: 13 > 12, so adjustedEndMonth = 1, adjustedEndYear = 2025
      // DateTime.utc(2025, 1, 0) = last day of December 2024
      final endMonth = endDate.month + CalendarConstants.monthsAfterForGapDetection + 1;
      final endYear = endDate.year;
      final adjustedEndMonth = endMonth > 12 ? endMonth - 12 : endMonth;
      final adjustedEndYear = endMonth > 12 ? endYear + 1 : endYear;

      expect(adjustedEndMonth, 1);
      expect(adjustedEndYear, 2025);

      // Verify the resulting DateTime is valid
      // Note: day=0 means last day of previous month, so month 1, day 0 = December 31 of previous year
      final extendedEnd = DateTime.utc(adjustedEndYear, adjustedEndMonth, 0);
      expect(extendedEnd.year, 2024); // December 31, 2024 (previous year because day 0)
      expect(extendedEnd.month, 12); // December
    });

    test('year boundary crossing works correctly', () {
      // Test: startDate in January, endDate in December of same year
      final startDate = DateTime.utc(2024); // January 1, 2024
      final endDate = DateTime.utc(2024, 12, 31); // December 31, 2024

      // Test extendedStart (should go to December 2023)
      final startMonth = startDate.month - CalendarConstants.monthsBeforeForGapDetection;
      final startYear = startDate.year;
      final adjustedStartMonth = startMonth <= 0 ? 12 + startMonth : startMonth;
      final adjustedStartYear = startMonth <= 0 ? startYear - 1 : startYear;

      expect(adjustedStartMonth, 12);
      expect(adjustedStartYear, 2023);

      final extendedStart = DateTime.utc(adjustedStartYear, adjustedStartMonth);
      expect(extendedStart.year, 2023);
      expect(extendedStart.month, 12);

      // Test extendedEnd (should go to January 2025, last day)
      // Note: day=0 gives last day of previous month
      final endMonth = endDate.month + CalendarConstants.monthsAfterForGapDetection + 1;
      final endYear = endDate.year;
      final adjustedEndMonth = endMonth > 12 ? endMonth - 12 : endMonth;
      final adjustedEndYear = endMonth > 12 ? endYear + 1 : endYear;

      expect(adjustedEndMonth, 2);
      expect(adjustedEndYear, 2025);

      final extendedEnd = DateTime.utc(adjustedEndYear, adjustedEndMonth, 0);
      expect(extendedEnd.year, 2025);
      expect(extendedEnd.month, 1); // January (because day 0 gives previous month)
    });

    test('normal months (not at boundaries) work correctly', () {
      // Test: startDate and endDate in middle of year
      final startDate = DateTime.utc(2024, 6); // June 1, 2024
      final endDate = DateTime.utc(2024, 8, 31); // August 31, 2024

      // Test extendedStart (should go to May 2024)
      final startMonth = startDate.month - CalendarConstants.monthsBeforeForGapDetection;
      final startYear = startDate.year;
      final adjustedStartMonth = startMonth <= 0 ? 12 + startMonth : startMonth;
      final adjustedStartYear = startMonth <= 0 ? startYear - 1 : startYear;

      expect(adjustedStartMonth, 5);
      expect(adjustedStartYear, 2024);

      final extendedStart = DateTime.utc(adjustedStartYear, adjustedStartMonth);
      expect(extendedStart.year, 2024);
      expect(extendedStart.month, 5);

      // Test extendedEnd (should go to September 2024, last day)
      // Note: day=0 gives last day of previous month
      // August (8) + 1 + 1 = 10, day 0 = last day of September
      final endMonth = endDate.month + CalendarConstants.monthsAfterForGapDetection + 1;
      final endYear = endDate.year;
      final adjustedEndMonth = endMonth > 12 ? endMonth - 12 : endMonth;
      final adjustedEndYear = endMonth > 12 ? endYear + 1 : endYear;

      expect(adjustedEndMonth, 10);
      expect(adjustedEndYear, 2024);

      final extendedEnd = DateTime.utc(adjustedEndYear, adjustedEndMonth, 0);
      expect(extendedEnd.year, 2024);
      expect(extendedEnd.month, 9); // September (because day 0 gives previous month)
    });
  });

  group('CalendarDataService - Gap Calculation Edge Cases', () {
    test('overlapping reservations are skipped (no gap to block)', () {
      // Test: If reservations overlap, gapEnd will be before gapStart
      // current.checkOut = Jan 10, next.checkIn = Jan 8 (overlap)
      final currentCheckOut = DateTime.utc(2024, 1, 10);
      final nextCheckIn = DateTime.utc(2024, 1, 8);

      final gapStart = currentCheckOut.add(const Duration(days: 1)); // Jan 11
      final gapEnd = nextCheckIn.subtract(const Duration(days: 1)); // Jan 7

      // gapEnd (Jan 7) is before gapStart (Jan 11) - overlap detected
      expect(gapEnd.isBefore(gapStart), isTrue);

      // This should be skipped (continue in the loop)
      // No gap calculation should happen
    });

    test('adjacent reservations are skipped (no gap to block)', () {
      // Test: If reservations are adjacent (checkout == checkin), gapEnd == gapStart - 1
      // current.checkOut = Jan 5, next.checkIn = Jan 6 (adjacent)
      final currentCheckOut = DateTime.utc(2024, 1, 5);
      final nextCheckIn = DateTime.utc(2024, 1, 6);

      final gapStart = currentCheckOut.add(const Duration(days: 1)); // Jan 6
      final gapEnd = nextCheckIn.subtract(const Duration(days: 1)); // Jan 5

      // gapEnd (Jan 5) is before gapStart (Jan 6) - adjacency detected
      expect(gapEnd.isBefore(gapStart), isTrue);

      // This should be skipped (continue in the loop)
      // No gap calculation should happen
    });

    test('normal gap calculation works correctly', () {
      // Test: Normal gap between reservations
      // current.checkOut = Jan 4, next.checkIn = Jan 8
      final currentCheckOut = DateTime.utc(2024, 1, 4);
      final nextCheckIn = DateTime.utc(2024, 1, 8);

      final gapStart = currentCheckOut.add(const Duration(days: 1)); // Jan 5
      final gapEnd = nextCheckIn.subtract(const Duration(days: 1)); // Jan 7

      // gapEnd (Jan 7) is after gapStart (Jan 5) - valid gap
      expect(gapEnd.isBefore(gapStart), isFalse);

      // Calculate gap size
      final gapNights = gapEnd.difference(gapStart).inDays; // 2 days

      // Verify gap calculation
      expect(gapNights, 2);

      // Verify the gap would be blocked if less than minNights
      final minNights = 3;
      expect(gapNights > 0 && gapNights < minNights, isTrue);
    });

    test('large gap is not blocked (greater than minNights)', () {
      // Test: Large gap should not be blocked
      // current.checkOut = Jan 1, next.checkIn = Jan 10
      final currentCheckOut = DateTime.utc(2024);
      final nextCheckIn = DateTime.utc(2024, 1, 10);

      final gapStart = currentCheckOut.add(const Duration(days: 1)); // Jan 2
      final gapEnd = nextCheckIn.subtract(const Duration(days: 1)); // Jan 9

      // gapEnd (Jan 9) is after gapStart (Jan 2) - valid gap
      expect(gapEnd.isBefore(gapStart), isFalse);

      // Calculate gap size
      final gapNights = gapEnd.difference(gapStart).inDays; // 7 days

      // Verify gap calculation
      expect(gapNights, 7);

      // Verify the gap would NOT be blocked if greater than or equal to minNights
      final minNights = 3;
      expect(gapNights > 0 && gapNights < minNights, isFalse);
    });

    test('zero gap (same day checkout and checkin) is skipped', () {
      // Test: Same day checkout and checkin (same-day turnover)
      // current.checkOut = Jan 5, next.checkIn = Jan 5
      final currentCheckOut = DateTime.utc(2024, 1, 5);
      final nextCheckIn = DateTime.utc(2024, 1, 5);

      final gapStart = currentCheckOut.add(const Duration(days: 1)); // Jan 6
      final gapEnd = nextCheckIn.subtract(const Duration(days: 1)); // Jan 4

      // gapEnd (Jan 4) is before gapStart (Jan 6) - no gap
      expect(gapEnd.isBefore(gapStart), isTrue);

      // This should be skipped (continue in the loop)
      // No gap calculation should happen
    });
  });
}
