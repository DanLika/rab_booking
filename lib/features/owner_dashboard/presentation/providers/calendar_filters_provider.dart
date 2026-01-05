import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../domain/models/calendar_filter_options.dart';
import 'owner_calendar_provider.dart';

/// Provider for calendar and bookings list filters
/// Unified filter state shared across Week, Month, Timeline, and Bookings List
final calendarFiltersProvider =
    StateNotifierProvider<CalendarFiltersNotifier, CalendarFilterOptions>((
      ref,
    ) {
      return CalendarFiltersNotifier();
    });

/// State notifier for calendar filters
class CalendarFiltersNotifier extends StateNotifier<CalendarFilterOptions> {
  CalendarFiltersNotifier() : super(const CalendarFilterOptions());

  /// Update property filter
  void setPropertyIds(List<String> propertyIds) {
    state = state.copyWith(propertyIds: propertyIds);
  }

  /// Update unit filter
  void setUnitIds(List<String> unitIds) {
    state = state.copyWith(unitIds: unitIds);
  }

  /// Update status filter
  void setStatuses(List<String> statuses) {
    state = state.copyWith(statuses: statuses);
  }

  /// Update source filter
  void setSources(List<String> sources) {
    state = state.copyWith(sources: sources);
  }

  /// Update date range filter
  void setDateRange({DateTime? startDate, DateTime? endDate}) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
  }

  /// Update guest search query
  void setGuestSearchQuery(String? query) {
    state = state.copyWith(guestSearchQuery: query);
  }

  /// Update booking ID search
  void setBookingIdSearch(String? bookingId) {
    state = state.copyWith(bookingIdSearch: bookingId);
  }

  /// Clear all filters
  void clearFilters() {
    state = const CalendarFilterOptions();
  }

  /// Apply multiple filters at once
  void applyFilters(CalendarFilterOptions filters) {
    state = filters;
  }
}

/// Helper class for compute() parameters
/// Needed because compute() can only accept one parameter
class _FilterParams {
  final Map<String, List<BookingModel>> bookingsMap;
  final CalendarFilterOptions filters;
  final List<UnitModel> units;

  const _FilterParams({
    required this.bookingsMap,
    required this.filters,
    required this.units,
  });
}

/// PERFORMANCE: Background filtering function for compute()
/// Runs in separate isolate to avoid blocking UI thread
Map<String, List<BookingModel>> _applyFiltersInBackground(
  _FilterParams params,
) {
  final bookingsMap = params.bookingsMap;
  final filters = params.filters;
  final units = params.units;

  // Create unitId -> propertyId map for property filtering
  final unitToProperty = <String, String>{};
  for (final unit in units) {
    unitToProperty[unit.id] = unit.propertyId;
  }

  // Filter bookings map
  final filteredMap = <String, List<BookingModel>>{};

  bookingsMap.forEach((unitId, bookings) {
    // Filter by unit IDs if specified
    if (filters.unitIds.isNotEmpty && !filters.unitIds.contains(unitId)) {
      return; // Skip this unit
    }

    // Filter by property IDs if specified
    final propertyId = unitToProperty[unitId];
    if (filters.propertyIds.isNotEmpty &&
        propertyId != null &&
        !filters.propertyIds.contains(propertyId)) {
      return; // Skip this unit (wrong property)
    }

    // Filter bookings in this unit
    final filteredBookings = bookings.where((booking) {
      // Filter by status
      if (filters.statuses.isNotEmpty &&
          !filters.statuses.contains(booking.status.name)) {
        return false;
      }

      // Filter by source
      // FIX: Previously, null source bookings would ALWAYS pass through filters
      // Now: If source filter is active, exclude bookings with null source
      // (unless "direct" is explicitly in the filter list for null/direct bookings)
      if (filters.sources.isNotEmpty) {
        final bookingSource = booking.source;
        if (bookingSource == null) {
          // Null source = direct booking. Only include if "direct" is in filter
          if (!filters.sources.contains('direct')) {
            return false;
          }
        } else if (!filters.sources.contains(bookingSource)) {
          return false;
        }
      }

      // Filter by date range (check-in dates)
      if (filters.startDate != null || filters.endDate != null) {
        final checkInDate = booking.checkIn;
        if (filters.startDate != null &&
            checkInDate.isBefore(filters.startDate!)) {
          return false;
        }
        if (filters.endDate != null && checkInDate.isAfter(filters.endDate!)) {
          return false;
        }
      }

      // Filter by guest search
      if (filters.guestSearchQuery != null &&
          filters.guestSearchQuery!.isNotEmpty) {
        final query = filters.guestSearchQuery!.toLowerCase();
        final guestName = booking.guestName?.toLowerCase() ?? '';
        final guestEmail = booking.guestEmail?.toLowerCase() ?? '';
        if (!guestName.contains(query) && !guestEmail.contains(query)) {
          return false;
        }
      }

      // Filter by booking ID
      if (filters.bookingIdSearch != null &&
          filters.bookingIdSearch!.isNotEmpty) {
        final query = filters.bookingIdSearch!.toLowerCase();
        if (!booking.id.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    if (filteredBookings.isNotEmpty) {
      filteredMap[unitId] = filteredBookings;
    }
  });

  return filteredMap;
}

/// Apply filters with automatic compute() optimization for large datasets
/// Uses compute() for >100 bookings, synchronous for smaller datasets
Future<Map<String, List<BookingModel>>> _applyFiltersOptimized({
  required Map<String, List<BookingModel>> bookingsMap,
  required CalendarFilterOptions filters,
  required List<UnitModel> units,
}) async {
  // Count total bookings to decide if compute() is worth the overhead
  final totalBookings = bookingsMap.values.fold<int>(
    0,
    (sum, list) => sum + list.length,
  );

  final params = _FilterParams(
    bookingsMap: bookingsMap,
    filters: filters,
    units: units,
  );

  // PERFORMANCE: Use compute() for large datasets (>100 bookings)
  if (totalBookings > 100) {
    try {
      return await compute(_applyFiltersInBackground, params);
    } catch (_) {
      // Fallback to synchronous filtering if compute() fails
      return _applyFiltersInBackground(params);
    }
  }

  // Small dataset - use synchronous filtering (no compute() overhead)
  return _applyFiltersInBackground(params);
}

/// Filtered bookings provider
/// Applies filter state to calendar bookings
/// PERFORMANCE: Uses compute() for background filtering on large datasets
final filteredCalendarBookingsProvider =
    FutureProvider<Map<String, List<BookingModel>>>((ref) async {
      final allBookingsAsync = await ref.watch(calendarBookingsProvider.future);
      final filters = ref.watch(calendarFiltersProvider);
      final units = await ref.watch(allOwnerUnitsProvider.future);

      if (!filters.hasActiveFilters) {
        return allBookingsAsync;
      }

      return _applyFiltersOptimized(
        bookingsMap: allBookingsAsync,
        filters: filters,
        units: units,
      );
    });

/// Timeline calendar bookings provider
/// Applies all filters including status filter
/// Note: Conflict detection uses calendarBookingsProvider (unfiltered), so filtering
/// statuses here does NOT affect overbooking detection
final timelineCalendarBookingsProvider =
    FutureProvider<Map<String, List<BookingModel>>>((ref) async {
      final allBookingsAsync = await ref.watch(calendarBookingsProvider.future);
      final filters = ref.watch(calendarFiltersProvider);
      final units = await ref.watch(allOwnerUnitsProvider.future);

      if (!filters.hasActiveFilters) {
        return allBookingsAsync;
      }

      return _applyFiltersOptimized(
        bookingsMap: allBookingsAsync,
        filters: filters,
        units: units,
      );
    });

/// Filtered units provider for timeline calendar
/// Filters units based on property and unit filter selections
/// This ensures the timeline only shows rows for filtered units
final filteredUnitsProvider = FutureProvider<List<UnitModel>>((ref) async {
  final allUnits = await ref.watch(allOwnerUnitsProvider.future);
  final filters = ref.watch(calendarFiltersProvider);

  // No property or unit filters active - return all units
  if (filters.propertyIds.isEmpty && filters.unitIds.isEmpty) {
    return allUnits;
  }

  return allUnits.where((unit) {
    // Filter by specific unit IDs if selected
    if (filters.unitIds.isNotEmpty) {
      return filters.unitIds.contains(unit.id);
    }

    // Filter by property IDs if selected
    if (filters.propertyIds.isNotEmpty) {
      return filters.propertyIds.contains(unit.propertyId);
    }

    return true;
  }).toList();
});
