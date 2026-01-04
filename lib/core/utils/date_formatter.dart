import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rab_booking/l10n/app_localizations.dart';

/// Centralized date formatting utility
/// Ensures consistent date formats throughout the application
class DateFormatter {
  DateFormatter._(); // Private constructor to prevent instantiation

  // Standard date formats
  static final DateFormat _shortDate = DateFormat('d.M.yyyy'); // 1.1.2024
  static final DateFormat _mediumDate = DateFormat('d. MMM yyyy'); // 1. Led 2024
  static final DateFormat _longDate =
      DateFormat('EEEE, d. MMMM yyyy'); // Ponedjeljak, 1. Siječanj 2024
  static final DateFormat _monthYear = DateFormat('MMMM yyyy'); // Siječanj 2024
  static final DateFormat _dayMonth = DateFormat('d. MMM'); // 1. Led
  static final DateFormat _time = DateFormat('HH:mm'); // 14:30
  static final DateFormat _dateTime = DateFormat('d.M.yyyy HH:mm'); // 1.1.2024 14:30

  /// Format date as short date: 1.1.2024
  static String formatShort(DateTime date) => _shortDate.format(date);

  /// Format date as medium date: 1. Led 2024
  static String formatMedium(DateTime date) => _mediumDate.format(date);

  /// Format date as long date: Ponedjeljak, 1. Siječanj 2024
  static String formatLong(DateTime date) => _longDate.format(date);

  /// Format date as month and year: Siječanj 2024
  static String formatMonthYear(DateTime date) => _monthYear.format(date);

  /// Format date as day and month: 1. Led
  static String formatDayMonth(DateTime date) => _dayMonth.format(date);

  /// Format time: 14:30
  static String formatTime(DateTime date) => _time.format(date);

  /// Format date and time: 1.1.2024 14:30
  static String formatDateTime(DateTime date) => _dateTime.format(date);

  /// Format date range: 1.1.2024 - 5.1.2024
  static String formatRange(DateTime start, DateTime end) {
    return '${formatShort(start)} - ${formatShort(end)}';
  }

  /// Format date range with month names: 1. Led - 5. Led
  static String formatRangeMedium(DateTime start, DateTime end) {
    return '${formatDayMonth(start)} - ${formatDayMonth(end)}';
  }

  /// Get relative date description: Danas, Sutra, Jučer, etc.
  static String formatRelative(DateTime date, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);

    final difference = compareDate.difference(today).inDays;

    if (difference == 0) return l10n.relativeDateToday;
    if (difference == 1) return l10n.relativeDateTomorrow;
    if (difference == -1) return l10n.relativeDateYesterday;
    if (difference == 7) return l10n.relativeDateInAWeek;
    if (difference == -7) return l10n.relativeDateAWeekAgo;
    if (difference > 1) return l10n.relativeDateInXDays(difference);
    if (difference < -1) return l10n.relativeDateXDaysAgo(-difference);

    return formatShort(date);
  }

  /// Format booking duration: 5 noći (6 dana)
  static String formatDuration(DateTime checkIn, DateTime checkOut) {
    final nights = checkOut.difference(checkIn).inDays;
    final days = nights + 1;
    return '$nights ${nights == 1 ? 'noć' : nights < 5 ? 'noći' : 'noći'} ($days ${days == 1 ? 'dan' : days < 5 ? 'dana' : 'dana'})';
  }

  /// Normalize date to midnight (remove time component)
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
