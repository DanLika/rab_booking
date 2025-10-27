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

    // Initialize all dates in the month as available
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(monthStart.year, monthStart.month, day);
      final key = _getDateKey(date);
      calendarData[key] = CalendarDateInfo(
        date: date,
        status: DateStatus.available,
      );
    }

    // Mark booked dates
    for (final booking in bookings) {
      DateTime current = booking.checkIn;
      while (current.isBefore(booking.checkOut) || _isSameDay(current, booking.checkOut)) {
        final key = _getDateKey(current);
        if (calendarData.containsKey(key)) {
          calendarData[key] = CalendarDateInfo(
            date: current,
            status: DateStatus.booked,
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
