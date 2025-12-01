import 'package:intl/intl.dart';

/// Utility class for common calendar date operations.
///
/// This class provides static methods used by both MonthCalendarWidget
/// and YearCalendarWidget to avoid code duplication.
class CalendarDateUtils {
  CalendarDateUtils._();

  /// Check if two dates represent the same day (ignoring time).
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get a string key for a date in 'yyyy-MM-dd' format.
  static String getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Check if a date is within a range (inclusive on both ends).
  static bool isDateInRange(
    DateTime date,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  ) {
    if (rangeStart == null || rangeEnd == null) return false;
    return (date.isAfter(rangeStart) || isSameDay(date, rangeStart)) &&
        (date.isBefore(rangeEnd) || isSameDay(date, rangeEnd));
  }
}
