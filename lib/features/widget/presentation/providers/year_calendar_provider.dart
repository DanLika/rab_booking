import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../domain/models/calendar_date_status.dart';

/// Provider for year calendar data
final yearCalendarDataProvider = FutureProvider.family<Map<String, CalendarDateInfo>, (String, int)>(
  (ref, params) async {
    final (unitId, year) = params;
    final bookingRepo = ref.watch(bookingRepositoryProvider);

    // Get all bookings for this unit in this year
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31);

    final bookings = await bookingRepo.getBookingsInRange(
      unitId: unitId,
      startDate: startDate,
      endDate: endDate,
    );

    // Build calendar data map
    final Map<String, CalendarDateInfo> calendarData = {};

    // Initialize all dates in the year as available
    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        final key = _getDateKey(date);
        calendarData[key] = CalendarDateInfo(
          date: date,
          status: DateStatus.available,
        );
      }
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
