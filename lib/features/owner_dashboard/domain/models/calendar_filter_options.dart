import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_filter_options.freezed.dart';
part 'calendar_filter_options.g.dart';

/// Filter options for calendar and bookings list
///
/// Supports filtering by:
/// - Property IDs (multi-select)
/// - Unit IDs (multi-select)
/// - Booking statuses (multi-select)
/// - Booking sources (multi-select)
/// - Date range (check-in dates)
/// - Guest name/email search
/// - Booking ID search
@freezed
class CalendarFilterOptions with _$CalendarFilterOptions {
  const factory CalendarFilterOptions({
    /// Selected property IDs (empty = all properties)
    @Default([]) List<String> propertyIds,

    /// Selected unit IDs (empty = all units)
    @Default([]) List<String> unitIds,

    /// Selected booking statuses (empty = all statuses)
    /// Values: 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'
    @Default([]) List<String> statuses,

    /// Selected booking sources (empty = all sources)
    /// Values: 'widget', 'manual', 'ical', 'booking_com', 'airbnb'
    @Default([]) List<String> sources,

    /// Start date for filtering (check-in date range start)
    DateTime? startDate,

    /// End date for filtering (check-in date range end)
    DateTime? endDate,

    /// Guest name or email search query
    String? guestSearchQuery,

    /// Booking ID search
    String? bookingIdSearch,
  }) = _CalendarFilterOptions;

  factory CalendarFilterOptions.fromJson(Map<String, dynamic> json) =>
      _$CalendarFilterOptionsFromJson(json);
}

extension CalendarFilterOptionsX on CalendarFilterOptions {
  /// Check if any filters are active
  bool get hasActiveFilters {
    return propertyIds.isNotEmpty ||
        unitIds.isNotEmpty ||
        statuses.isNotEmpty ||
        sources.isNotEmpty ||
        startDate != null ||
        endDate != null ||
        (guestSearchQuery?.isNotEmpty ?? false) ||
        (bookingIdSearch?.isNotEmpty ?? false);
  }

  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (propertyIds.isNotEmpty) count++;
    if (unitIds.isNotEmpty) count++;
    if (statuses.isNotEmpty) count++;
    if (sources.isNotEmpty) count++;
    if (startDate != null || endDate != null) count++;
    if (guestSearchQuery?.isNotEmpty ?? false) count++;
    if (bookingIdSearch?.isNotEmpty ?? false) count++;
    return count;
  }

  /// Clear all filters
  CalendarFilterOptions clear() {
    return const CalendarFilterOptions();
  }
}
