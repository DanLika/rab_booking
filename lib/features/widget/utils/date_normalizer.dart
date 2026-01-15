import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class for normalizing DateTime objects.
///
/// Normalization removes time components (hour, minute, second, millisecond)
/// leaving only year, month, and day. This is essential for date comparisons
/// in calendar and booking logic.
///
/// ## Usage
/// ```dart
/// final normalized = DateNormalizer.normalize(DateTime.now());
/// // Result: DateTime with time set to 00:00:00.000
///
/// final fromTimestamp = DateNormalizer.fromTimestamp(firestoreTimestamp);
/// // Result: Normalized DateTime from Firestore Timestamp
/// ```
class DateNormalizer {
  DateNormalizer._(); // Private constructor - static methods only

  /// Normalizes a DateTime by removing time components.
  ///
  /// Returns a new DateTime with only year, month, and day in UTC.
  /// Time is set to 00:00:00.000 UTC.
  ///
  /// CRITICAL: Always uses UTC to avoid timezone bugs (per CLAUDE.md standards).
  static DateTime normalize(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Normalizes a Firestore Timestamp to DateTime.
  ///
  /// Converts Timestamp to DateTime and removes time components in UTC.
  /// Returns null if timestamp is null.
  ///
  /// CRITICAL: Always uses UTC to avoid timezone bugs (per CLAUDE.md standards).
  static DateTime? fromTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return null;
    final date = timestamp.toDate();
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Normalizes a Firestore Timestamp to DateTime (non-nullable).
  ///
  /// Throws [ArgumentError] if timestamp is null.
  ///
  /// CRITICAL: Always uses UTC to avoid timezone bugs (per CLAUDE.md standards).
  static DateTime fromTimestampRequired(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Checks if two dates are the same day (ignoring time).
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Checks if [date] is today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  /// Checks if [date] is in the past (before today).
  static bool isPast(DateTime date) {
    final today = normalize(DateTime.now());
    final normalized = normalize(date);
    return normalized.isBefore(today);
  }

  /// Checks if [date] is in the future (after today).
  static bool isFuture(DateTime date) {
    final today = normalize(DateTime.now());
    final normalized = normalize(date);
    return normalized.isAfter(today);
  }

  /// Returns the number of days between two dates.
  ///
  /// Always returns a positive number regardless of order.
  static int daysBetween(DateTime a, DateTime b) {
    final normalizedA = normalize(a);
    final normalizedB = normalize(b);
    return normalizedA.difference(normalizedB).inDays.abs();
  }

  /// Returns the number of nights for a booking (checkOut - checkIn).
  ///
  /// Returns 0 if checkOut is before or equal to checkIn.
  static int nightsBetween(DateTime checkIn, DateTime checkOut) {
    final normalizedIn = normalize(checkIn);
    final normalizedOut = normalize(checkOut);
    final days = normalizedOut.difference(normalizedIn).inDays;
    return days > 0 ? days : 0;
  }

  /// Generates a list of dates from [start] to [end] (inclusive).
  ///
  /// Both dates are normalized before generating the range.
  static List<DateTime> dateRange(DateTime start, DateTime end) {
    final normalizedStart = normalize(start);
    final normalizedEnd = normalize(end);

    if (normalizedEnd.isBefore(normalizedStart)) {
      return [];
    }

    final days = normalizedEnd.difference(normalizedStart).inDays + 1;
    return List.generate(days, (i) => normalizedStart.add(Duration(days: i)));
  }

  /// Generates a list of dates for booking nights (checkIn to checkOut-1).
  ///
  /// This represents the nights stayed, not including checkout day.
  /// For a booking from Jan 1 to Jan 3, returns [Jan 1, Jan 2].
  static List<DateTime> bookingNights(DateTime checkIn, DateTime checkOut) {
    final normalizedIn = normalize(checkIn);
    final normalizedOut = normalize(checkOut);

    if (normalizedOut.isBefore(normalizedIn) ||
        normalizedOut.isAtSameMomentAs(normalizedIn)) {
      return [];
    }

    final nights = normalizedOut.difference(normalizedIn).inDays;
    return List.generate(nights, (i) => normalizedIn.add(Duration(days: i)));
  }

  /// Checks if [date] falls within the range [start, end] (inclusive).
  static bool isInRange(DateTime date, DateTime start, DateTime end) {
    final normalized = normalize(date);
    final normalizedStart = normalize(start);
    final normalizedEnd = normalize(end);

    return !normalized.isBefore(normalizedStart) &&
        !normalized.isAfter(normalizedEnd);
  }

  /// Checks if [date] is a weekend day (for hotel pricing).
  ///
  /// [weekendDays] defaults to Friday (5) and Saturday (6) using ISO weekday.
  /// This represents nights slept on Friday→Saturday and Saturday→Sunday.
  static bool isWeekend(DateTime date, {List<int> weekendDays = const [5, 6]}) {
    return weekendDays.contains(date.weekday);
  }

  /// Returns the first day of the month containing [date].
  ///
  /// CRITICAL: Always uses UTC to avoid timezone bugs (per CLAUDE.md standards).
  static DateTime firstDayOfMonth(DateTime date) {
    // ignore: avoid_redundant_argument_values
    return DateTime.utc(date.year, date.month, 1); // Explicit for clarity
  }

  /// Returns the last day of the month containing [date].
  ///
  /// CRITICAL: Always uses UTC to avoid timezone bugs (per CLAUDE.md standards).
  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime.utc(date.year, date.month + 1, 0);
  }

  /// Returns the first day of the year containing [date].
  ///
  /// CRITICAL: Always uses UTC to avoid timezone bugs (per CLAUDE.md standards).
  static DateTime firstDayOfYear(DateTime date) {
    // ignore: avoid_redundant_argument_values
    return DateTime.utc(date.year, 1, 1); // Explicit for clarity
  }

  /// Returns the last day of the year containing [date].
  ///
  /// CRITICAL: Always uses UTC to avoid timezone bugs (per CLAUDE.md standards).
  static DateTime lastDayOfYear(DateTime date) {
    return DateTime.utc(date.year, 12, 31);
  }
}
