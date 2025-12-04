import 'package:cloud_firestore/cloud_firestore.dart';

/// Safe DateTime parser utility
///
/// Provides safe parsing methods for DateTime with validation and error handling.
/// Prevents runtime crashes from invalid date formats.
///
/// Usage:
/// ```dart
/// // Safe parsing with null return
/// final date = DateTimeParser.tryParse('2024-12-04');
///
/// // Safe parsing with default fallback
/// final date = DateTimeParser.parseOrDefault('invalid', DateTime.now());
///
/// // Parse with custom error handling
/// final date = DateTimeParser.parseOrElse('2024-12-04', () => DateTime.now());
/// ```
class DateTimeParser {
  /// Private constructor to prevent instantiation
  DateTimeParser._();

  /// Safely parse DateTime string
  ///
  /// Returns null if parsing fails instead of throwing exception
  ///
  /// Supports formats:
  /// - ISO 8601: 2024-12-04T10:30:00Z
  /// - Date only: 2024-12-04
  /// - With timezone: 2024-12-04T10:30:00+02:00
  static DateTime? tryParse(String? dateString) {
    if (dateString == null || dateString.trim().isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse DateTime string or return default value
  ///
  /// Returns [defaultValue] if parsing fails
  static DateTime parseOrDefault(String? dateString, DateTime defaultValue) {
    return tryParse(dateString) ?? defaultValue;
  }

  /// Parse DateTime string or execute fallback function
  ///
  /// Returns result of [orElse] function if parsing fails
  static DateTime parseOrElse(String? dateString, DateTime Function() orElse) {
    return tryParse(dateString) ?? orElse();
  }

  /// Parse DateTime string and throw descriptive error if fails
  ///
  /// Throws [FormatException] with helpful message if parsing fails
  ///
  /// Use this when you want to fail fast with clear error message
  static DateTime parseOrThrow(String? dateString, {String? context}) {
    if (dateString == null || dateString.trim().isEmpty) {
      throw FormatException(
        'Cannot parse null or empty date string${context != null ? ' in $context' : ''}',
      );
    }

    try {
      return DateTime.parse(dateString);
    } catch (e) {
      throw FormatException(
        'Invalid date format: "$dateString"${context != null ? ' in $context' : ''}. '
        'Expected ISO 8601 format (e.g., 2024-12-04 or 2024-12-04T10:30:00Z)',
      );
    }
  }

  /// Convert Firestore Timestamp to DateTime safely
  ///
  /// Returns null if timestamp is null or invalid
  static DateTime? fromTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return null;

    try {
      return timestamp.toDate();
    } catch (e) {
      return null;
    }
  }

  /// Convert Firestore Timestamp to DateTime or return default
  static DateTime fromTimestampOrDefault(
    Timestamp? timestamp,
    DateTime defaultValue,
  ) {
    return fromTimestamp(timestamp) ?? defaultValue;
  }

  /// Validate if string is valid DateTime format
  ///
  /// Returns true if string can be parsed as DateTime
  static bool isValidFormat(String? dateString) {
    return tryParse(dateString) != null;
  }

  /// Parse DateTime from various formats (flexible parser)
  ///
  /// Attempts to parse from:
  /// - ISO 8601 string
  /// - Firestore Timestamp
  /// - Unix timestamp (milliseconds)
  ///
  /// Returns null if all parsing attempts fail
  static DateTime? parseFlexible(dynamic value) {
    if (value == null) return null;

    // Already DateTime
    if (value is DateTime) return value;

    // Firestore Timestamp
    if (value is Timestamp) return fromTimestamp(value);

    // String format
    if (value is String) return tryParse(value);

    // Unix timestamp (milliseconds)
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Parse UTC DateTime safely
  ///
  /// Returns null if parsing fails
  static DateTime? tryParseUtc(String? dateString) {
    final parsed = tryParse(dateString);
    return parsed?.toUtc();
  }

  /// Parse local DateTime safely
  ///
  /// Returns null if parsing fails
  static DateTime? tryParseLocal(String? dateString) {
    final parsed = tryParse(dateString);
    return parsed?.toLocal();
  }

  /// Validate date range
  ///
  /// Returns true if start is before or equal to end
  /// Returns false if either date is null or start > end
  static bool isValidRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return false;
    return start.isBefore(end) || start.isAtSameMomentAs(end);
  }

  /// Parse and validate date range
  ///
  /// Returns null if parsing fails or range is invalid (start > end)
  /// Returns tuple (start, end) if valid
  static (DateTime, DateTime)? tryParseRange(
    String? startString,
    String? endString,
  ) {
    final start = tryParse(startString);
    final end = tryParse(endString);

    if (start == null || end == null) return null;
    if (!isValidRange(start, end)) return null;

    return (start, end);
  }
}
