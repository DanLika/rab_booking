import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/calendar_repository.dart';
import '../../data/calendar_realtime_manager.dart';
import '../../domain/models/calendar_day.dart';
import '../../domain/models/calendar_update_event.dart';
import 'calendar_update_tracker.dart';

part 'calendar_providers_refactored.g.dart';

// =============================================================================
// 1. REALTIME MANAGER PROVIDER
// =============================================================================

/// Provider for CalendarRealtimeManager singleton
@riverpod
CalendarRealtimeManager calendarRealtimeManager(
  CalendarRealtimeManagerRef ref,
) {
  final manager = CalendarRealtimeManager(Supabase.instance.client);

  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
}

// =============================================================================
// 2. REALTIME STREAM PROVIDER
// =============================================================================

/// Stream provider for calendar realtime updates
@riverpod
Stream<CalendarUpdateEvent> calendarRealtime(
  CalendarRealtimeRef ref,
  String unitId,
) {
  final manager = ref.watch(calendarRealtimeManagerProvider);
  manager.subscribeToUnit(unitId);

  ref.onDispose(() => manager.unsubscribe());

  return manager.updates;
}

// =============================================================================
// 3. CALENDAR DATA PROVIDER (Main Provider)
// =============================================================================

/// Provider for calendar data with realtime updates
@riverpod
class CalendarData extends _$CalendarData {
  @override
  Future<CalendarState> build(String unitId, DateTime month) async {
    // Listen to realtime updates and refresh when they arrive
    ref.listen(
      calendarRealtimeProvider(unitId),
      (prev, next) {
        // When a realtime event arrives, refresh the calendar
        _handleRealtimeUpdate(next);
      },
    );

    // Fetch initial data
    return _fetchCalendarData(unitId, month);
  }

  /// Fetch calendar data from repository
  Future<CalendarState> _fetchCalendarData(String unitId, DateTime month) async {
    final repository = ref.read(calendarRepositoryProvider);
    final days = await repository.getCalendarData(
      unitId: unitId,
      month: month,
    );

    return CalendarState(
      days: days,
      selectedRange: null,
      isLoading: false,
    );
  }

  /// Handle realtime update event
  void _handleRealtimeUpdate(AsyncValue<CalendarUpdateEvent> event) {
    event.whenData((updateEvent) {
      // Track the update for animation purposes
      final tracker = ref.read(calendarUpdateTrackerProvider.notifier);
      final notificationManager = ref.read(updateNotificationManagerProvider.notifier);

      // Mark affected dates as updated based on the event type
      if (updateEvent.checkInDate != null && updateEvent.checkOutDate != null) {
        tracker.markRangeUpdated(
          updateEvent.checkInDate!,
          updateEvent.checkOutDate!,
          updateEvent.action,
        );

        // Show notification
        final message = _getNotificationMessage(updateEvent);
        notificationManager.show(
          message: message,
          action: updateEvent.action,
        );
      }

      // Refresh calendar data when update arrives
      refresh();
    });
  }

  /// Get notification message for update event
  String _getNotificationMessage(CalendarUpdateEvent event) {
    switch (event.action) {
      case CalendarUpdateAction.insert:
        return 'New booking added';
      case CalendarUpdateAction.update:
        return 'Booking updated';
      case CalendarUpdateAction.delete:
        return 'Booking removed';
    }
  }

  /// Refresh calendar data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _fetchCalendarData(unitId, month);
    });
  }

  /// Update selected range
  void updateSelectedRange(DateTimeRange? range) {
    state.whenData((currentState) {
      state = AsyncValue.data(
        currentState.copyWith(selectedRange: range),
      );
    });
  }

  /// Clear selected range
  void clearSelection() {
    updateSelectedRange(null);
  }
}

// =============================================================================
// 4. SELECTED DATE RANGE PROVIDER
// =============================================================================

/// Provider for selected date range (for booking creation)
@riverpod
class SelectedDateRange extends _$SelectedDateRange {
  @override
  DateTimeRange? build() => null;

  /// Select a date range
  void selectRange(DateTime start, DateTime end) {
    state = DateTimeRange(start: start, end: end);
  }

  /// Clear the selection
  void clear() {
    state = null;
  }

  /// Check if a date is in the selected range
  bool contains(DateTime date) {
    if (state == null) return false;
    return date.isAfter(state!.start.subtract(const Duration(days: 1))) &&
        date.isBefore(state!.end.add(const Duration(days: 1)));
  }
}

// =============================================================================
// 5. BOOKING CREATION PROVIDER
// =============================================================================

/// Request model for booking creation
class BookingRequest {
  final String unitId;
  final String guestId;
  final DateTime checkIn;
  final DateTime checkOut;
  final String checkInTime;
  final String checkOutTime;
  final int guestCount;
  final double totalPrice;
  final String? notes;

  const BookingRequest({
    required this.unitId,
    required this.guestId,
    required this.checkIn,
    required this.checkOut,
    required this.checkInTime,
    required this.checkOutTime,
    required this.guestCount,
    required this.totalPrice,
    this.notes,
  });
}

/// Provider for booking creation with error handling
@riverpod
class BookingCreation extends _$BookingCreation {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Create a booking
  Future<void> createBooking(BookingRequest request) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(calendarRepositoryProvider);

      await repository.createBookingAtomic(
        unitId: request.unitId,
        guestId: request.guestId,
        checkIn: request.checkIn,
        checkOut: request.checkOut,
        checkInTime: request.checkInTime,
        checkOutTime: request.checkOutTime,
        guestCount: request.guestCount,
        totalPrice: request.totalPrice,
        notes: request.notes,
      );

      // Invalidate calendar data to trigger refresh
      ref.invalidate(calendarDataProvider);
    });
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

// =============================================================================
// 6. BLOCKED DATES PROVIDER (Refactored)
// =============================================================================

/// Provider for blocked dates with realtime updates
@riverpod
class BlockedDatesRefactored extends _$BlockedDatesRefactored {
  @override
  Future<List<CalendarAvailability>> build(String unitId) async {
    // Listen to realtime updates for availability changes
    ref.listen(
      calendarRealtimeProvider(unitId),
      (prev, next) {
        next.whenData((event) {
          if (event.type == CalendarUpdateType.availability) {
            refresh();
          }
        });
      },
    );

    final repository = ref.watch(calendarRepositoryProvider);
    return repository.getBlockedDates(unitId);
  }

  /// Refresh blocked dates
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(calendarRepositoryProvider);
      return repository.getBlockedDates(unitId);
    });
  }

  /// Add new blocked date range
  Future<void> blockDates({
    required DateTime from,
    required DateTime to,
    required String reason,
    String? notes,
  }) async {
    final repository = ref.read(calendarRepositoryProvider);
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    await repository.blockDates(
      unitId: unitId,
      ownerId: user.id,
      from: from,
      to: to,
      reason: reason,
      notes: notes,
    );

    // Refresh will happen automatically via realtime listener
  }
}

// =============================================================================
// 7. CALENDAR SETTINGS PROVIDER (Refactored)
// =============================================================================

/// Provider for calendar settings
@riverpod
class CalendarSettingsRefactored extends _$CalendarSettingsRefactored {
  @override
  Future<CalendarSettings?> build(String unitId) async {
    final repository = ref.watch(calendarRepositoryProvider);
    return repository.getCalendarSettings(unitId);
  }

  /// Refresh settings
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// =============================================================================
// 8. FOCUSED MONTH PROVIDER (For navigation)
// =============================================================================

/// Provider for the currently focused month (which month user is viewing)
@riverpod
class FocusedMonthRefactored extends _$FocusedMonthRefactored {
  @override
  DateTime build() {
    return DateTime.now();
  }

  /// Set the focused month
  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month);
  }

  /// Navigate to next month
  void nextMonth() {
    state = DateTime(state.year, state.month + 1);
  }

  /// Navigate to previous month
  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }

  /// Navigate to today
  void goToToday() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month);
  }
}
