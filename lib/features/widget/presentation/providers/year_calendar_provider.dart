import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../domain/models/calendar_date_status.dart';

/// Provider for year calendar data
final yearCalendarDataProvider =
    FutureProvider.family<Map<String, CalendarDateInfo>, (String, int)>((
      ref,
      params,
    ) async {
      final (unitId, year) = params;
      final bookingRepo = ref.watch(bookingRepositoryProvider);

      // Get all bookings for this unit in this year
      final startDate = DateTime(year, 1);
      final endDate = DateTime(year, 12, 31);

      final bookings = await bookingRepo.getBookingsInRange(
        unitId: unitId,
        startDate: startDate,
        endDate: endDate,
      );

      // Build calendar data map
      final Map<String, CalendarDateInfo> calendarData = {};

      // Get today normalized to midnight for comparison
      final today = DateTime.now();
      final todayNormalized = DateTime(today.year, today.month, today.day);

      // Initialize all dates in the year as available or disabled (past dates)
      for (int month = 1; month <= 12; month++) {
        final daysInMonth = DateTime(year, month + 1, 0).day;
        for (int day = 1; day <= daysInMonth; day++) {
          final date = DateTime(year, month, day);
          final key = _getDateKey(date);

          // Mark past dates as disabled
          final isPast = date.isBefore(todayNormalized);

          calendarData[key] = CalendarDateInfo(
            date: date,
            status: isPast ? DateStatus.disabled : DateStatus.available,
          );
        }
      }

      // Mark booked dates with partial CheckIn/CheckOut support
      for (final booking in bookings) {
        final checkIn = DateTime(
          booking.checkIn.year,
          booking.checkIn.month,
          booking.checkIn.day,
        );
        final checkOut = DateTime(
          booking.checkOut.year,
          booking.checkOut.month,
          booking.checkOut.day,
        );

        DateTime current = checkIn;
        while (current.isBefore(checkOut) || _isSameDay(current, checkOut)) {
          final key = _getDateKey(current);
          if (calendarData.containsKey(key)) {
            // Check if date is in the past
            final isPast = current.isBefore(todayNormalized);

            final isCheckIn = _isSameDay(current, checkIn);
            final isCheckOut = _isSameDay(current, checkOut);

            DateStatus status;
            if (isPast) {
              // Past dates that were part of a reservation show as pastReservation (red with opacity)
              status = DateStatus.pastReservation;
            } else if (isCheckIn && isCheckOut) {
              // Single day booking
              status = DateStatus.booked;
            } else if (isCheckIn) {
              // First day - diagonal split (morning available, evening booked)
              status = DateStatus.partialCheckIn;
            } else if (isCheckOut) {
              // Last day - diagonal split (morning booked, evening available)
              status = DateStatus.partialCheckOut;
            } else {
              // Full day booked
              status = DateStatus.booked;
            }

            calendarData[key] = CalendarDateInfo(date: current, status: status);
          }
          current = current.add(const Duration(days: 1));
        }
      }

      return calendarData;
    });

String _getDateKey(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
