import 'package:freezed_annotation/freezed_annotation.dart';

part 'unified_dashboard_data.freezed.dart';
part 'unified_dashboard_data.g.dart';

/// Unified dashboard data model - combines metrics and chart data
/// Used by the main Dashboard page with time period filtering
@freezed
class UnifiedDashboardData with _$UnifiedDashboardData {
  const factory UnifiedDashboardData({
    /// Total revenue in the selected period (EUR)
    required double revenue,

    /// Number of bookings in the selected period
    required int bookings,

    /// Upcoming check-ins in next 7 days (always 7 days, regardless of period)
    required int upcomingCheckIns,

    /// Occupancy rate for the selected period (0-100%)
    required double occupancyRate,

    /// Revenue data points for chart
    required List<RevenueDataPoint> revenueHistory,

    /// Booking data points for chart
    required List<BookingDataPoint> bookingHistory,
  }) = _UnifiedDashboardData;

  factory UnifiedDashboardData.fromJson(Map<String, dynamic> json) =>
      _$UnifiedDashboardDataFromJson(json);

  /// Empty data when no bookings exist
  static const empty = UnifiedDashboardData(
    revenue: 0.0,
    bookings: 0,
    upcomingCheckIns: 0,
    occupancyRate: 0.0,
    revenueHistory: [],
    bookingHistory: [],
  );
}

/// Revenue data point for chart
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

/// Booking data point for chart
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

/// Date range filter for time period selection
@freezed
class DateRangeFilter with _$DateRangeFilter {
  const factory DateRangeFilter({
    required DateTime startDate,
    required DateTime endDate,
    @Default('month') String preset, // 'week', 'month', 'quarter', 'year', 'custom'
  }) = _DateRangeFilter;

  factory DateRangeFilter.fromJson(Map<String, dynamic> json) =>
      _$DateRangeFilterFromJson(json);

  /// Current calendar month (default)
  factory DateRangeFilter.currentMonth() {
    final now = DateTime.now();
    return DateRangeFilter(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      preset: 'month',
    );
  }

  /// Last 7 days
  factory DateRangeFilter.lastWeek() {
    final now = DateTime.now();
    return DateRangeFilter(
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now,
      preset: 'week',
    );
  }

  /// Last 3 months
  factory DateRangeFilter.lastQuarter() {
    final now = DateTime.now();
    return DateRangeFilter(
      startDate: DateTime(now.year, now.month - 3, now.day),
      endDate: now,
      preset: 'quarter',
    );
  }

  /// Last 12 months
  factory DateRangeFilter.lastYear() {
    final now = DateTime.now();
    return DateRangeFilter(
      startDate: DateTime(now.year - 1, now.month, now.day),
      endDate: now,
      preset: 'year',
    );
  }
}
