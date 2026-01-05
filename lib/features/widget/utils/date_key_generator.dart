/// Utility for generating consistent date keys for map lookups.
///
/// Date keys are string representations of dates used as map keys
/// for price lookups and calendar data. This ensures consistent
/// key format across the application.
///
/// ## Usage
/// ```dart
/// final key = DateKeyGenerator.fromDate(DateTime(2024, 1, 15));
/// // Result: '2024-1-15'
///
/// final map = {key: priceModel};
/// final price = map[DateKeyGenerator.fromDate(someDate)];
/// ```
class DateKeyGenerator {
  DateKeyGenerator._(); // Private constructor - static methods only

  /// Generate a date key from DateTime.
  ///
  /// Format: 'year-month-day' (e.g., '2024-1-15')
  /// Note: Month and day are NOT zero-padded to match existing data format.
  static String fromDate(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  /// Generate a date key from individual components.
  ///
  /// Useful when you already have year, month, day as separate values.
  static String fromComponents(int year, int month, int day) {
    return '$year-$month-$day';
  }

  /// Parse a date key back to DateTime.
  ///
  /// Returns null if the key format is invalid.
  static DateTime? parseKey(String key) {
    try {
      final parts = key.split('-');
      if (parts.length != 3) return null;

      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);

      if (year == null || month == null || day == null) return null;
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;

      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  /// Generate a list of date keys for a date range.
  ///
  /// [start] and [end] are inclusive.
  /// Useful for bulk lookups or setting prices for multiple dates.
  static List<String> forRange(DateTime start, DateTime end) {
    if (end.isBefore(start)) return [];

    final keys = <String>[];
    DateTime current = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(normalizedEnd)) {
      keys.add(fromDate(current));
      current = current.add(const Duration(days: 1));
    }

    return keys;
  }

  /// Generate date keys for booking nights (checkIn to checkOut-1).
  ///
  /// This represents the nights stayed, not including checkout day.
  /// For a booking from Jan 1 to Jan 3, returns keys for [Jan 1, Jan 2].
  static List<String> forBookingNights(DateTime checkIn, DateTime checkOut) {
    if (checkOut.isBefore(checkIn) || checkOut.isAtSameMomentAs(checkIn)) {
      return [];
    }

    final keys = <String>[];
    DateTime current = DateTime(checkIn.year, checkIn.month, checkIn.day);
    final normalizedOut = DateTime(checkOut.year, checkOut.month, checkOut.day);

    while (current.isBefore(normalizedOut)) {
      keys.add(fromDate(current));
      current = current.add(const Duration(days: 1));
    }

    return keys;
  }
}
