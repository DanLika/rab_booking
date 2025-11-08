/// Date range utility functions for calendar views
class DateRangeUtils {
  /// Get Monday of the week for a given date
  static DateTime getMonday(DateTime date) {
    // weekday: 1 = Monday, 7 = Sunday
    final daysToSubtract = date.weekday - 1;
    return DateTime(
      date.year,
      date.month,
      date.day - daysToSubtract,
    );
  }

  /// Get Sunday of the week for a given date
  static DateTime getSunday(DateTime date) {
    final monday = getMonday(date);
    return DateTime(
      monday.year,
      monday.month,
      monday.day + 6,
      23,
      59,
      59,
    );
  }

  /// Get first day of month
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get last day of month
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  /// Get number of days in a month
  static int getDaysInMonth(DateTime date) {
    final lastDay = getLastDayOfMonth(date);
    return lastDay.day;
  }

  /// Generate list of dates for a week (Monday-Sunday)
  static List<DateTime> getWeekDates(DateTime date) {
    final monday = getMonday(date);
    return List.generate(7, (index) {
      return DateTime(monday.year, monday.month, monday.day + index);
    });
  }

  /// Generate list of dates for a month
  static List<DateTime> getMonthDates(DateTime date) {
    final firstDay = getFirstDayOfMonth(date);
    final daysInMonth = getDaysInMonth(date);
    return List.generate(daysInMonth, (index) {
      return DateTime(firstDay.year, firstDay.month, index + 1);
    });
  }

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Check if date is in the past
  static bool isPast(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isBefore(today);
  }

  /// Check if date is in the future
  static bool isFuture(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isAfter(today);
  }

  /// Check if date is weekend (Saturday or Sunday)
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday;
  }

  /// Format date range for display
  /// Examples: "23 Oct - 29 Oct 2025", "October 2025"
  static String formatWeekRange(DateTime startDate, DateTime endDate) {
    final startDay = startDate.day;
    final endDay = endDate.day;
    final startMonth = _getMonthName(startDate.month);
    final endMonth = _getMonthName(endDate.month);

    if (startDate.month == endDate.month) {
      // Same month: "23 - 29 Oct 2025"
      return '$startDay - $endDay $endMonth ${startDate.year}';
    } else if (startDate.year == endDate.year) {
      // Different months, same year: "30 Oct - 5 Nov 2025"
      return '$startDay $startMonth - $endDay $endMonth ${startDate.year}';
    } else {
      // Different years: "30 Dec 2024 - 5 Jan 2025"
      return '$startDay $startMonth ${startDate.year} - $endDay $endMonth ${endDate.year}';
    }
  }

  /// Format month for display
  /// Example: "October 2025"
  static String formatMonth(DateTime date) {
    return '${_getMonthFullName(date.month)} ${date.year}';
  }

  /// Format date with weekday
  /// Example: "Mon, 23 Oct"
  static String formatDateWithWeekday(DateTime date) {
    final weekday = _getWeekdayShortName(date.weekday);
    final day = date.day;
    final month = _getMonthName(date.month);
    return '$weekday, $day $month';
  }

  /// Get short month name (3 letters)
  static String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  /// Get full month name
  static String _getMonthFullName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  /// Get short weekday name (3 letters)
  static String _getWeekdayShortName(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  /// Get next week's Monday
  static DateTime getNextWeek(DateTime date) {
    final monday = getMonday(date);
    return DateTime(monday.year, monday.month, monday.day + 7);
  }

  /// Get previous week's Monday
  static DateTime getPreviousWeek(DateTime date) {
    final monday = getMonday(date);
    return DateTime(monday.year, monday.month, monday.day - 7);
  }

  /// Get next month's first day
  static DateTime getNextMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 1);
  }

  /// Get previous month's first day
  static DateTime getPreviousMonth(DateTime date) {
    return DateTime(date.year, date.month - 1, 1);
  }

  /// Calculate booking duration in nights
  static int calculateNights(DateTime checkIn, DateTime checkOut) {
    return checkOut.difference(checkIn).inDays;
  }

  /// Check if date range overlaps with another date range
  static bool dateRangesOverlap({
    required DateTime start1,
    required DateTime end1,
    required DateTime start2,
    required DateTime end2,
  }) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  /// Get dates between two dates (inclusive)
  static List<DateTime> getDatesBetween(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (current.isBefore(endDate) || isSameDay(current, endDate)) {
      dates.add(current);
      current = DateTime(current.year, current.month, current.day + 1);
    }

    return dates;
  }
}
