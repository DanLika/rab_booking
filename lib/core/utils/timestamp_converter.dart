import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'date_time_parser.dart';

/// Converter for Firestore Timestamp to DateTime
///
/// Handles multiple input formats for cross-platform compatibility:
/// - Firestore Timestamp objects (native and web)
/// - ISO 8601 strings (from inline edits or legacy data)
/// - Unix timestamps (milliseconds)
///
/// WEB COMPATIBILITY FIX: On Flutter Web, Firestore data may come through
/// JavaScript interop in unexpected formats. This converter defensively
/// handles type coercion to prevent TypeError in production.
class TimestampConverter implements JsonConverter<DateTime, Object?> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json == null) {
      throw ArgumentError('Cannot convert null to DateTime');
    }

    // Try Timestamp first (most common for Firestore data)
    if (json is Timestamp) {
      return json.toDate();
    }

    // Handle String dates (from inline edits that save ISO8601 strings)
    if (json is String) {
      return DateTimeParser.parseOrThrow(
        json,
        context: 'TimestampConverter.fromJson',
      );
    }

    // Handle Unix timestamps
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }

    // WEB COMPATIBILITY FIX: On Flutter Web with JS interop, types may not
    // match Dart's type system exactly. Try to coerce the value to String
    // and parse it as a fallback. This handles edge cases where Firestore
    // returns a JavaScript Date object or other unexpected type.
    try {
      final stringValue = json.toString();
      // Check if it looks like a date string (starts with year)
      if (stringValue.isNotEmpty &&
          RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(stringValue)) {
        return DateTimeParser.parseOrThrow(
          stringValue,
          context: 'TimestampConverter.fromJson (coerced)',
        );
      }
    } catch (_) {
      // Fall through to error
    }

    throw ArgumentError(
      'Cannot convert ${json.runtimeType} to DateTime: $json',
    );
  }

  @override
  Object toJson(DateTime object) => Timestamp.fromDate(object);
}

/// Converter for nullable Firestore Timestamp to DateTime
///
/// Same as TimestampConverter but returns null instead of throwing on failure.
/// WEB COMPATIBILITY: Includes fallback for JS interop edge cases.
class NullableTimestampConverter implements JsonConverter<DateTime?, Object?> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) {
      return null;
    }

    // Try Timestamp first (most common for Firestore data)
    if (json is Timestamp) {
      return json.toDate();
    }

    // Handle String dates
    if (json is String) {
      return DateTimeParser.tryParse(json);
    }

    // Handle Unix timestamps
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }

    // WEB COMPATIBILITY FIX: Try to coerce unknown types to String and parse
    try {
      final stringValue = json.toString();
      if (stringValue.isNotEmpty &&
          RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(stringValue)) {
        return DateTimeParser.tryParse(stringValue);
      }
    } catch (_) {
      // Fall through to return null
    }

    return null;
  }

  @override
  Object? toJson(DateTime? object) {
    if (object == null) return null;
    return Timestamp.fromDate(object);
  }
}
