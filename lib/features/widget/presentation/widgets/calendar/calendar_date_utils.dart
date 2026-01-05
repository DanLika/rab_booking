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
  /// Bug #40 Fix: Normalize both dates to UTC for consistent comparison
  static bool isSameDay(DateTime a, DateTime b) {
    // Normalize both dates to UTC for consistent comparison
    final aUtc = DateTime.utc(a.year, a.month, a.day);
    final bUtc = DateTime.utc(b.year, b.month, b.day);
    return aUtc == bUtc;
  }

  /// Get a string key for a date in 'yyyy-MM-dd' format.
  /// Bug #40 Fix: Normalize to UTC by extracting year/month/day components
  static String getDateKey(DateTime date) {
    // Normalize to UTC by extracting year/month/day components
    // This ensures we format the correct day regardless of timezone
    final utcDate = DateTime.utc(date.year, date.month, date.day);
    return DateFormat('yyyy-MM-dd').format(utcDate);
  }

  /// Check if a date is within a range (inclusive on both ends).
  /// Bug #43 Fix: Normalize all dates to UTC for consistent comparison
  static bool isDateInRange(
    DateTime date,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  ) {
    if (rangeStart == null || rangeEnd == null) return false;

    // Normalize all dates to UTC for consistent comparison
    final dateUtc = DateTime.utc(date.year, date.month, date.day);
    final startUtc = DateTime.utc(
      rangeStart.year,
      rangeStart.month,
      rangeStart.day,
    );
    final endUtc = DateTime.utc(rangeEnd.year, rangeEnd.month, rangeEnd.day);

    return (dateUtc.isAfter(startUtc) || dateUtc.isAtSameMomentAs(startUtc)) &&
        (dateUtc.isBefore(endUtc) || dateUtc.isAtSameMomentAs(endUtc));
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

    final pendingStr = isPending
        ? ', ${translations.semanticPendingApproval}'
        : '';

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
