import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookbed/core/utils/date_time_parser.dart';

void main() {
  group('DateTimeParser', () {
    test('tryParse handles valid date string', () {
      final date = DateTimeParser.tryParse('2024-12-04');
      expect(date, isNotNull);
      expect(date!.year, 2024);
      expect(date.month, 12);
      expect(date.day, 4);
    });

    test('tryParse handles valid ISO8601 string', () {
      final date = DateTimeParser.tryParse('2024-12-04T10:30:00Z');
      expect(date, isNotNull);
      expect(date!.year, 2024);
      expect(date.month, 12);
      expect(date.day, 4);
      expect(date.isUtc, isTrue);
    });

    test('tryParse returns null for invalid string', () {
      expect(DateTimeParser.tryParse('invalid'), isNull);
    });

    test('tryParse returns null for empty string', () {
      expect(DateTimeParser.tryParse(''), isNull);
    });

    test('tryParse returns null for null input', () {
      expect(DateTimeParser.tryParse(null), isNull);
    });

    test('parseOrDefault returns parsed date for valid string', () {
      final defaultDate = DateTime(2020, 1, 1);
      final date = DateTimeParser.parseOrDefault('2024-12-04', defaultDate);
      expect(date.year, 2024);
      expect(date.month, 12);
      expect(date.day, 4);
    });

    test('parseOrDefault returns default for invalid string', () {
      final defaultDate = DateTime(2020, 1, 1);
      final date = DateTimeParser.parseOrDefault('invalid', defaultDate);
      expect(date, defaultDate);
    });

    test('parseOrDefault returns default for null string', () {
      final defaultDate = DateTime(2020, 1, 1);
      final date = DateTimeParser.parseOrDefault(null, defaultDate);
      expect(date, defaultDate);
    });

    test('parseOrElse executes fallback function on invalid string', () {
      final defaultDate = DateTime(2020, 1, 1);
      final date = DateTimeParser.parseOrElse('invalid', () => defaultDate);
      expect(date, defaultDate);
    });

    test('parseOrThrow returns parsed date for valid string', () {
      final date = DateTimeParser.parseOrThrow('2024-12-04');
      expect(date.year, 2024);
    });

    test('parseOrThrow throws FormatException for invalid string', () {
      expect(
        () => DateTimeParser.parseOrThrow('invalid', context: 'Test'),
        throwsA(isA<FormatException>()),
      );
    });

    test('parseOrThrow throws FormatException for null string', () {
      expect(
        () => DateTimeParser.parseOrThrow(null),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromTimestamp returns parsed date for valid timestamp', () {
      final dateTime = DateTime(2024, 12, 4);
      final timestamp = Timestamp.fromDate(dateTime);
      final parsed = DateTimeParser.fromTimestamp(timestamp);
      expect(parsed, isNotNull);
      expect(parsed!.isAtSameMomentAs(dateTime), isTrue);
    });

    test('fromTimestamp returns null for null timestamp', () {
      expect(DateTimeParser.fromTimestamp(null), isNull);
    });

    test('fromTimestampOrDefault returns valid date from timestamp', () {
      final dateTime = DateTime(2024, 12, 4);
      final timestamp = Timestamp.fromDate(dateTime);
      final defaultDate = DateTime(2020, 1, 1);
      final parsed = DateTimeParser.fromTimestampOrDefault(timestamp, defaultDate);
      expect(parsed.isAtSameMomentAs(dateTime), isTrue);
    });

    test('fromTimestampOrDefault returns default from null timestamp', () {
      final defaultDate = DateTime(2020, 1, 1);
      final parsed = DateTimeParser.fromTimestampOrDefault(null, defaultDate);
      expect(parsed, defaultDate);
    });

    test('isValidFormat returns true for valid date string', () {
      expect(DateTimeParser.isValidFormat('2024-12-04'), isTrue);
    });

    test('isValidFormat returns false for invalid date string', () {
      expect(DateTimeParser.isValidFormat('invalid'), isFalse);
    });

    test('parseFlexible handles DateTime', () {
      final input = DateTime(2024, 12, 4);
      final parsed = DateTimeParser.parseFlexible(input);
      expect(parsed, input);
    });

    test('parseFlexible handles Timestamp', () {
      final dateTime = DateTime(2024, 12, 4);
      final input = Timestamp.fromDate(dateTime);
      final parsed = DateTimeParser.parseFlexible(input);
      expect(parsed!.isAtSameMomentAs(dateTime), isTrue);
    });

    test('parseFlexible handles String', () {
      final parsed = DateTimeParser.parseFlexible('2024-12-04');
      expect(parsed!.year, 2024);
    });

    test('parseFlexible handles Unix timestamp in milliseconds', () {
      final dateTime = DateTime(2024, 12, 4);
      final parsed = DateTimeParser.parseFlexible(dateTime.millisecondsSinceEpoch);
      expect(parsed!.isAtSameMomentAs(dateTime), isTrue);
    });

    test('parseFlexible returns null for unhandled type', () {
      expect(DateTimeParser.parseFlexible(123.45), isNull);
    });

    test('parseFlexible returns null for null input', () {
      expect(DateTimeParser.parseFlexible(null), isNull);
    });

    test('tryParseUtc returns UTC DateTime', () {
      final parsed = DateTimeParser.tryParseUtc('2024-12-04');
      expect(parsed!.isUtc, isTrue);
    });

    test('tryParseUtc returns null on invalid input', () {
      expect(DateTimeParser.tryParseUtc('invalid'), isNull);
    });

    test('tryParseLocal returns local DateTime', () {
      final parsed = DateTimeParser.tryParseLocal('2024-12-04T10:30:00Z');
      expect(parsed!.isUtc, isFalse);
    });

    test('tryParseLocal returns null on invalid input', () {
      expect(DateTimeParser.tryParseLocal('invalid'), isNull);
    });

    test('isValidRange returns true for start before end', () {
      final start = DateTime(2024, 12, 4);
      final end = DateTime(2024, 12, 5);
      expect(DateTimeParser.isValidRange(start, end), isTrue);
    });

    test('isValidRange returns true for start same as end', () {
      final date = DateTime(2024, 12, 4);
      expect(DateTimeParser.isValidRange(date, date), isTrue);
    });

    test('isValidRange returns false for start after end', () {
      final start = DateTime(2024, 12, 5);
      final end = DateTime(2024, 12, 4);
      expect(DateTimeParser.isValidRange(start, end), isFalse);
    });

    test('isValidRange returns false for null inputs', () {
      expect(DateTimeParser.isValidRange(null, DateTime.now()), isFalse);
      expect(DateTimeParser.isValidRange(DateTime.now(), null), isFalse);
      expect(DateTimeParser.isValidRange(null, null), isFalse);
    });

    test('tryParseRange returns valid range tuple', () {
      final result = DateTimeParser.tryParseRange('2024-12-04', '2024-12-05');
      expect(result, isNotNull);
      expect(result!.$1.year, 2024);
      expect(result.$2.day, 5);
    });

    test('tryParseRange returns null for invalid inputs', () {
      expect(DateTimeParser.tryParseRange('invalid', '2024-12-05'), isNull);
      expect(DateTimeParser.tryParseRange('2024-12-05', 'invalid'), isNull);
    });

    test('tryParseRange returns null for start after end', () {
      expect(DateTimeParser.tryParseRange('2024-12-05', '2024-12-04'), isNull);
    });
  });
}
