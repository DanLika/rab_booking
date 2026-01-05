import 'package:cloud_firestore/cloud_firestore.dart';

import 'date_normalizer.dart';

/// Utility class for validating and parsing Firestore document data.
///
/// Provides type-safe extraction of common Firestore field types
/// with proper null handling and validation.
///
/// ## Usage
/// ```dart
/// final data = doc.data() as Map<String, dynamic>;
///
/// // Parse timestamp safely
/// final date = FirestoreValidators.parseTimestamp(data, 'created_at');
///
/// // Validate required fields
/// if (!FirestoreValidators.hasRequiredFields(data, ['date', 'unit_id'])) {
///   return null; // Invalid document
/// }
/// ```
class FirestoreValidators {
  FirestoreValidators._(); // Private constructor - static methods only

  /// Parses a Timestamp field from Firestore data.
  ///
  /// Returns null if:
  /// - Field doesn't exist
  /// - Field is null
  /// - Field is not a Timestamp
  ///
  /// The returned DateTime is normalized (time components removed).
  static DateTime? parseTimestamp(Map<String, dynamic>? data, String field) {
    if (data == null) return null;
    final value = data[field];
    if (value == null || value is! Timestamp) return null;
    return DateNormalizer.fromTimestampRequired(value);
  }

  /// Parses a Timestamp field, returning raw DateTime with time preserved.
  ///
  /// Use this when you need the exact timestamp (e.g., for created_at, updated_at).
  static DateTime? parseTimestampRaw(Map<String, dynamic>? data, String field) {
    if (data == null) return null;
    final value = data[field];
    if (value == null || value is! Timestamp) return null;
    return value.toDate();
  }

  /// Checks if a field exists and is a valid Timestamp.
  static bool hasValidTimestamp(Map<String, dynamic>? data, String field) {
    if (data == null) return false;
    final value = data[field];
    return value != null && value is Timestamp;
  }

  /// Checks if all required fields exist and are not null.
  static bool hasRequiredFields(
    Map<String, dynamic>? data,
    List<String> fields,
  ) {
    if (data == null) return false;
    return fields.every((field) => data[field] != null);
  }

  /// Validates a DailyPrice document structure.
  ///
  /// Required fields: 'date' (Timestamp), 'unit_id' (String)
  static bool isValidDailyPriceDoc(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data['date'] != null &&
        data['date'] is Timestamp &&
        data['unit_id'] != null;
  }

  /// Validates a Booking document structure.
  ///
  /// Required fields: 'check_in', 'check_out' (Timestamps), 'unit_id', 'status'
  static bool isValidBookingDoc(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data['check_in'] != null &&
        data['check_in'] is Timestamp &&
        data['check_out'] != null &&
        data['check_out'] is Timestamp &&
        data['unit_id'] != null &&
        data['status'] != null;
  }

  /// Validates an iCal Event document structure.
  ///
  /// Required fields: 'start_date', 'end_date' (Timestamps), 'unit_id'
  static bool isValidICalEventDoc(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data['start_date'] != null &&
        data['start_date'] is Timestamp &&
        data['end_date'] != null &&
        data['end_date'] is Timestamp &&
        data['unit_id'] != null;
  }

  /// Parses a String field from Firestore data.
  ///
  /// Returns null if field doesn't exist or is not a String.
  /// Returns empty string if [defaultToEmpty] is true and field is missing.
  static String? parseString(
    Map<String, dynamic>? data,
    String field, {
    bool defaultToEmpty = false,
  }) {
    if (data == null) return defaultToEmpty ? '' : null;
    final value = data[field];
    if (value == null) return defaultToEmpty ? '' : null;
    if (value is String) return value;
    return value.toString();
  }

  /// Parses an int field from Firestore data.
  ///
  /// Handles both int and double (truncates to int).
  /// Returns [defaultValue] if field is missing or invalid.
  static int parseInt(
    Map<String, dynamic>? data,
    String field, {
    int defaultValue = 0,
  }) {
    if (data == null) return defaultValue;
    final value = data[field];
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Parses a double field from Firestore data.
  ///
  /// Handles both int and double types.
  /// Returns [defaultValue] if field is missing or invalid.
  static double parseDouble(
    Map<String, dynamic>? data,
    String field, {
    double defaultValue = 0.0,
  }) {
    if (data == null) return defaultValue;
    final value = data[field];
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Parses a bool field from Firestore data.
  ///
  /// Returns [defaultValue] if field is missing or not a bool.
  static bool parseBool(
    Map<String, dynamic>? data,
    String field, {
    bool defaultValue = false,
  }) {
    if (data == null) return defaultValue;
    final value = data[field];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return defaultValue;
  }

  /// Parses a List field from Firestore data.
  ///
  /// Returns empty list if field is missing or not a List.
  static List<T> parseList<T>(Map<String, dynamic>? data, String field) {
    if (data == null) return [];
    final value = data[field];
    if (value == null || value is! List) return [];
    return List<T>.from(value);
  }

  /// Parses a nested Map field from Firestore data.
  ///
  /// Returns null if field is missing or not a Map.
  static Map<String, dynamic>? parseMap(
    Map<String, dynamic>? data,
    String field,
  ) {
    if (data == null) return null;
    final value = data[field];
    if (value == null || value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  /// Parses an enum value from a String field.
  ///
  /// Returns [defaultValue] if field is missing or doesn't match any enum value.
  static T parseEnum<T extends Enum>(
    Map<String, dynamic>? data,
    String field,
    List<T> values, {
    required T defaultValue,
  }) {
    final stringValue = parseString(data, field);
    if (stringValue == null) return defaultValue;

    for (final value in values) {
      if (value.name == stringValue) return value;
    }
    return defaultValue;
  }
}
