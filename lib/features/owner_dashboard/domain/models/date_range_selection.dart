import 'package:freezed_annotation/freezed_annotation.dart';

part 'date_range_selection.freezed.dart';
part 'date_range_selection.g.dart';

/// Date range helper for calendar views
///
/// Provides start and end dates for week/month views
@freezed
class DateRangeSelection with _$DateRangeSelection {
  const DateRangeSelection._();

  const factory DateRangeSelection({
    required DateTime startDate,
    required DateTime endDate,
  }) = _DateRangeSelection;

  factory DateRangeSelection.fromJson(Map<String, dynamic> json) =>
      _$DateRangeSelectionFromJson(json);

  /// Create a week range (Monday-Sunday) from a given date
  factory DateRangeSelection.week(DateTime date) {
    final monday = _getMonday(date);
    final sunday = monday.add(const Duration(days: 6));
    return DateRangeSelection(
      startDate: DateTime(monday.year, monday.month, monday.day),
      endDate: DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59),
    );
  }

  /// Create a month range from a given date
  factory DateRangeSelection.month(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    // Using day 0 of next month to get last day of current month (Dart idiom)
    // DateTime normalizes: month+1 with day 0 = last day of current month
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return DateRangeSelection(
      startDate: firstDay,
      endDate: DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59),
    );
  }

  /// Get Monday of the week for a given date
  static DateTime _getMonday(DateTime date) {
    // weekday: 1 = Monday, 7 = Sunday
    final daysToSubtract = date.weekday - 1;
    return date.subtract(Duration(days: daysToSubtract));
  }

  /// Get number of days in this range
  int get dayCount {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Get list of all dates in this range
  List<DateTime> get dates {
    final List<DateTime> result = [];
    DateTime current = startDate;
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      result.add(DateTime(current.year, current.month, current.day));
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  /// Check if a date is within this range
  bool contains(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    return (dateOnly.isAfter(startOnly) || dateOnly.isAtSameMomentAs(startOnly)) &&
        (dateOnly.isBefore(endOnly) || dateOnly.isAtSameMomentAs(endOnly));
  }

  /// Move to next week/month
  DateRangeSelection next({required bool isWeek}) {
    if (isWeek) {
      return DateRangeSelection.week(startDate.add(const Duration(days: 7)));
    } else {
      // Handle month overflow explicitly
      int nextMonth = startDate.month + 1;
      int nextYear = startDate.year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
      return DateRangeSelection.month(DateTime(nextYear, nextMonth, 1));
    }
  }

  /// Move to previous week/month
  DateRangeSelection previous({required bool isWeek}) {
    if (isWeek) {
      return DateRangeSelection.week(startDate.subtract(const Duration(days: 7)));
    } else {
      // Handle month underflow explicitly
      int prevMonth = startDate.month - 1;
      int prevYear = startDate.year;
      if (prevMonth < 1) {
        prevMonth = 12;
        prevYear--;
      }
      return DateRangeSelection.month(DateTime(prevYear, prevMonth, 1));
    }
  }

  /// Get display string for this range
  String toDisplayString({required bool isWeek}) {
    if (isWeek) {
      // Format: "23 Oct - 29 Oct 2025"
      final startDay = startDate.day;
      final endDay = endDate.day;
      final startMonth = _getMonthName(startDate.month);
      final endMonth = _getMonthName(endDate.month);

      if (startDate.month == endDate.month) {
        return '$startDay - $endDay $endMonth ${startDate.year}';
      } else {
        return '$startDay $startMonth - $endDay $endMonth ${startDate.year}';
      }
    } else {
      // Format: "October 2025"
      return '${_getMonthName(startDate.month)} ${startDate.year}';
    }
  }

  static String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
