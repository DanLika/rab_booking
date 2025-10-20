import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_summary.freezed.dart';
part 'analytics_summary.g.dart';

@freezed
class AnalyticsSummary with _$AnalyticsSummary {
  const factory AnalyticsSummary({
    required double totalRevenue,
    required double monthlyRevenue,
    required int totalBookings,
    required int monthlyBookings,
    required double occupancyRate,
    required double averageNightlyRate,
    required int totalProperties,
    required int activeProperties,
    required double cancellationRate,
    required List<RevenueDataPoint> revenueHistory,
    required List<BookingDataPoint> bookingHistory,
    required List<PropertyPerformance> topPerformingProperties,
  }) = _AnalyticsSummary;

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsSummaryFromJson(json);
}

@freezed
class RevenueDataPoint with _$RevenueDataPoint {
  const factory RevenueDataPoint({
    required DateTime date,
    required double amount,
    required String label,
  }) = _RevenueDataPoint;

  factory RevenueDataPoint.fromJson(Map<String, dynamic> json) =>
      _$RevenueDataPointFromJson(json);
}

@freezed
class BookingDataPoint with _$BookingDataPoint {
  const factory BookingDataPoint({
    required DateTime date,
    required int count,
    required String label,
  }) = _BookingDataPoint;

  factory BookingDataPoint.fromJson(Map<String, dynamic> json) =>
      _$BookingDataPointFromJson(json);
}

@freezed
class PropertyPerformance with _$PropertyPerformance {
  const factory PropertyPerformance({
    required String propertyId,
    required String propertyName,
    required double revenue,
    required int bookings,
    required double occupancyRate,
    required double rating,
  }) = _PropertyPerformance;

  factory PropertyPerformance.fromJson(Map<String, dynamic> json) =>
      _$PropertyPerformanceFromJson(json);
}

@freezed
class DateRangeFilter with _$DateRangeFilter {
  const factory DateRangeFilter({
    required DateTime startDate,
    required DateTime endDate,
    @Default('custom') String preset, // 'week', 'month', 'quarter', 'year', 'custom'
  }) = _DateRangeFilter;

  factory DateRangeFilter.fromJson(Map<String, dynamic> json) =>
      _$DateRangeFilterFromJson(json);

  factory DateRangeFilter.lastWeek() {
    final now = DateTime.now();
    return DateRangeFilter(
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now,
      preset: 'week',
    );
  }

  factory DateRangeFilter.lastMonth() {
    final now = DateTime.now();
    return DateRangeFilter(
      startDate: DateTime(now.year, now.month - 1, now.day),
      endDate: now,
      preset: 'month',
    );
  }

  factory DateRangeFilter.lastQuarter() {
    final now = DateTime.now();
    return DateRangeFilter(
      startDate: DateTime(now.year, now.month - 3, now.day),
      endDate: now,
      preset: 'quarter',
    );
  }

  factory DateRangeFilter.lastYear() {
    final now = DateTime.now();
    return DateRangeFilter(
      startDate: DateTime(now.year - 1, now.month, now.day),
      endDate: now,
      preset: 'year',
    );
  }
}
