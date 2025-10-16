import 'package:freezed_annotation/freezed_annotation.dart';

part 'date_range.freezed.dart';

/// Date range model for booked dates
@freezed
class DateRange with _$DateRange {
  const factory DateRange({
    required DateTime start,
    required DateTime end,
  }) = _DateRange;

  const DateRange._();

  /// Check if a date falls within this range (inclusive start, exclusive end)
  bool contains(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    return (normalizedDate.isAtSameMomentAs(normalizedStart) ||
            normalizedDate.isAfter(normalizedStart)) &&
        normalizedDate.isBefore(normalizedEnd);
  }

  /// Check if this range overlaps with another range
  bool overlaps(DateRange other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  /// Get all dates in this range
  List<DateTime> get dates {
    final result = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    while (current.isBefore(normalizedEnd)) {
      result.add(current);
      current = current.add(const Duration(days: 1));
    }

    return result;
  }

  /// Number of nights in this range
  int get nights {
    return end.difference(start).inDays;
  }
}
