import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookbed/core/utils/timestamp_converter.dart';

class _MockJSDate {
  final String dateString;
  _MockJSDate(this.dateString);
  @override
  String toString() => dateString;
}

void main() {
  group('TimestampConverter', () {
    const converter = TimestampConverter();

    test('fromJson converts Timestamp correctly', () {
      final date = DateTime(2024, 1, 1);
      final timestamp = Timestamp.fromDate(date);
      expect(converter.fromJson(timestamp), equals(date));
    });

    test('fromJson converts String correctly', () {
      final date = DateTime(2024, 1, 1);
      expect(converter.fromJson('2024-01-01T00:00:00.000'), equals(date));
    });

    test('fromJson converts int correctly', () {
      final date = DateTime(2024, 1, 1);
      expect(converter.fromJson(date.millisecondsSinceEpoch), equals(date));
    });

    test('fromJson converts coerced web types', () {
      final date = DateTime(2024, 1, 1);
      final mockDate = _MockJSDate('2024-01-01T00:00:00.000');
      expect(converter.fromJson(mockDate), equals(date));
    });

    test('fromJson throws on null', () {
      expect(() => converter.fromJson(null), throwsArgumentError);
    });

    test('fromJson throws on invalid types', () {
      expect(() => converter.fromJson(false), throwsArgumentError);
      expect(() => converter.fromJson(_MockJSDate('not-a-date')), throwsArgumentError);
    });

    test('toJson converts DateTime correctly', () {
      final date = DateTime(2024, 1, 1);
      final result = converter.toJson(date);
      expect(result, isA<Timestamp>());
      expect((result as Timestamp).toDate(), equals(date));
    });
  });

  group('NullableTimestampConverter', () {
    const converter = NullableTimestampConverter();

    test('fromJson converts Timestamp correctly', () {
      final date = DateTime(2024, 1, 1);
      final timestamp = Timestamp.fromDate(date);
      expect(converter.fromJson(timestamp), equals(date));
    });

    test('fromJson converts String correctly', () {
      final date = DateTime(2024, 1, 1);
      expect(converter.fromJson('2024-01-01T00:00:00.000'), equals(date));
    });

    test('fromJson converts int correctly', () {
      final date = DateTime(2024, 1, 1);
      expect(converter.fromJson(date.millisecondsSinceEpoch), equals(date));
    });

    test('fromJson converts coerced web types', () {
      final date = DateTime(2024, 1, 1);
      final mockDate = _MockJSDate('2024-01-01T00:00:00.000');
      expect(converter.fromJson(mockDate), equals(date));
    });

    test('fromJson returns null on null', () {
      expect(converter.fromJson(null), isNull);
    });

    test('fromJson returns null on invalid types', () {
      expect(converter.fromJson(false), isNull);
      expect(converter.fromJson(_MockJSDate('not-a-date')), isNull);
    });

    test('toJson converts DateTime correctly', () {
      final date = DateTime(2024, 1, 1);
      final result = converter.toJson(date);
      expect(result, isA<Timestamp>());
      expect((result as Timestamp).toDate(), equals(date));
    });

    test('toJson converts null correctly', () {
      expect(converter.toJson(null), isNull);
    });
  });
}
