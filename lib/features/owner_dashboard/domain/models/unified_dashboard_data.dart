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
    @Default('last7') String preset, // 'last7', 'last30', 'last90', 'last365', 'custom'
  }) = _DateRangeFilter;

  factory DateRangeFilter.fromJson(Map<String, dynamic> json) =>
      _$DateRangeFilterFromJson(json);

  /// Last 7 days (rolling window)
  factory DateRangeFilter.last7Days() {
    final now = DateTime.now();
    return DateRangeFilter(
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now,
    );
  }

  /// Last 30 days (rolling window)
  factory DateRangeFilter.last30Days() {
    final now = DateTime.now();
    return DateRangeFilter(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
      preset: 'last30',
    );
  }

  /// Last 90 days (rolling window)
  factory DateRangeFilter.last90Days() {
    final now = DateTime.now();
    return DateRangeFilter(
      startDate: now.subtract(const Duration(days: 90)),
      endDate: now,
      preset: 'last90',
    );
  }

  /// Last 365 days (rolling window)
  factory DateRangeFilter.last365Days() {
    final now = DateTime.now();
    return DateRangeFilter(
      startDate: now.subtract(const Duration(days: 365)),
      endDate: now,
      preset: 'last365',
    );
  }

  // Legacy aliases for backward compatibility (can be removed later)
  /// @deprecated Use last7Days() instead
  factory DateRangeFilter.lastWeek() => DateRangeFilter.last7Days();

  /// @deprecated Use last30Days() instead
  factory DateRangeFilter.currentMonth() => DateRangeFilter.last30Days();

  /// @deprecated Use last90Days() instead
  factory DateRangeFilter.lastQuarter() => DateRangeFilter.last90Days();

  /// @deprecated Use last365Days() instead
  factory DateRangeFilter.lastYear() => DateRangeFilter.last365Days();
}
