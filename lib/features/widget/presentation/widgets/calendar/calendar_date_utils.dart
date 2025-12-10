import 'package:intl/intl.dart';
import '../../../domain/models/calendar_date_status.dart';
import '../../l10n/widget_translations.dart';

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

  /// Generate semantic label for screen readers (localized).
  /// Used by both MonthCalendarWidget and YearCalendarWidget.
  static String getSemanticLabel({
    required DateTime date,
    required DateStatus status,
    required bool isPending,
    required bool isRangeStart,
    required bool isRangeEnd,
    required WidgetTranslations translations,
  }) {
    // Status description (localized)
    final statusStr = status == DateStatus.available
        ? translations.semanticAvailable
        : status == DateStatus.booked
        ? translations.semanticBooked
        : status == DateStatus.partialCheckIn
        ? translations.semanticCheckIn
        : status == DateStatus.partialCheckOut
        ? translations.semanticCheckOut
        : status == DateStatus.partialBoth
        ? translations.semanticTurnover
        : status == DateStatus.blocked
        ? translations.semanticBlocked
        : status == DateStatus.disabled
        ? translations.semanticUnavailable
        : translations.semanticPastReservation;

    final pendingStr = isPending ? ', ${translations.semanticPendingApproval}' : '';

    // Range indicators (localized)
    final rangeStr = isRangeStart
        ? ', ${translations.semanticCheckInDate}'
        : isRangeEnd
        ? ', ${translations.semanticCheckOutDate}'
        : '';

    // Format date (localized)
    final dateStr = translations.formatDateForSemantic(date);

    return '$dateStr, $statusStr$pendingStr$rangeStr';
  }
}
