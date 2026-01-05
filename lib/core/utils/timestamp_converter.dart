import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'date_time_parser.dart';

/// Converter for Firestore Timestamp to DateTime
class TimestampConverter implements JsonConverter<DateTime, Object?> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json == null) {
      throw ArgumentError('Cannot convert null to DateTime');
    }

    if (json is Timestamp) {
      return json.toDate();
    }

    if (json is String) {
      return DateTimeParser.parseOrThrow(
        json,
        context: 'TimestampConverter.fromJson',
      );
    }

    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }

    throw ArgumentError('Cannot convert $json to DateTime');
  }

  @override
  Object toJson(DateTime object) => Timestamp.fromDate(object);
}

/// Converter for nullable Firestore Timestamp to DateTime
class NullableTimestampConverter implements JsonConverter<DateTime?, Object?> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) {
      return null;
    }

    if (json is Timestamp) {
      return json.toDate();
    }

    if (json is String) {
      return DateTimeParser.tryParse(json);
    }

    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }

    return null;
  }

  @override
  Object? toJson(DateTime? object) {
    if (object == null) return null;
    return Timestamp.fromDate(object);
  }
}
