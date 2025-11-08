import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../domain/models/calendar_date_status.dart';

/// Provider for month calendar data
final monthCalendarDataProvider = FutureProvider.family<Map<String, CalendarDateInfo>, (String, DateTime)>(
  (ref, params) async {
    final (unitId, monthStart) = params;
    final bookingRepo = ref.watch(bookingRepositoryProvider);

    // Get first and last day of the month
    final firstDay = DateTime(monthStart.year, monthStart.month, 1);
    final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0);

    final bookings = await bookingRepo.getBookingsInRange(
      unitId: unitId,
      startDate: firstDay,
      endDate: lastDay,
    );

    // Build calendar data map
    final Map<String, CalendarDateInfo> calendarData = {};

    // Get today normalized to midnight for comparison
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    // Initialize all dates in the month as available or disabled (past dates)
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(monthStart.year, monthStart.month, day);
      final key = _getDateKey(date);

      // Mark past dates as disabled
      final isPast = date.isBefore(todayNormalized);

      calendarData[key] = CalendarDateInfo(
        date: date,
        status: isPast ? DateStatus.disabled : DateStatus.available,
      );
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
            // Past dates should remain disabled regardless of booking status
            status = DateStatus.disabled;
          } else if (isCheckIn && isCheckOut) {
            status = DateStatus.booked;
          } else if (isCheckIn) {
            status = DateStatus.partialCheckIn;
          } else if (isCheckOut) {
            status = DateStatus.partialCheckOut;
          } else {
            status = DateStatus.booked;
          }

          calendarData[key] = CalendarDateInfo(
            date: current,
            status: status,
          );
        }
        current = current.add(const Duration(days: 1));
      }
    }

    return calendarData;
  },
);

String _getDateKey(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
