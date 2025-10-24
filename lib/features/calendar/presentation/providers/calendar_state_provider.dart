import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/calendar_repository.dart';
import '../../data/calendar_realtime_manager.dart';
import '../../domain/models/calendar_day.dart';
import '../../domain/models/calendar_update_event.dart';

part 'calendar_state_provider.g.dart';

/// Calendar state with optimistic updates support
class CalendarState {
  final List<CalendarDay> days;
  final List<CalendarDay> optimisticDays;
  final bool hasOptimisticUpdates;
  final String? error;
  final bool isLoading;

  const CalendarState({
    required this.days,
    this.optimisticDays = const [],
    this.hasOptimisticUpdates = false,
    this.error,
    this.isLoading = false,
  });

  /// Get effective days (optimistic if available, otherwise confirmed)
  List<CalendarDay> get effectiveDays =>
      hasOptimisticUpdates ? optimisticDays : days;

  CalendarState copyWith({
    List<CalendarDay>? days,
    List<CalendarDay>? optimisticDays,
    bool? hasOptimisticUpdates,
    String? error,
    bool? isLoading,
  }) {
    return CalendarState(
      days: days ?? this.days,
      optimisticDays: optimisticDays ?? this.optimisticDays,
      hasOptimisticUpdates: hasOptimisticUpdates ?? this.hasOptimisticUpdates,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Booking request for optimistic updates
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

/// Enhanced calendar provider with optimistic updates and real-time sync
@riverpod
class CalendarStateNotifier extends _$CalendarStateNotifier {
  CalendarRealtimeManager? _realtimeManager;

  @override
  Future<CalendarState> build({
    required String unitId,
    required DateTime month,
  }) async {
    // Setup realtime manager
    _realtimeManager = CalendarRealtimeManager(Supabase.instance.client);
    _realtimeManager!.subscribeToUnit(unitId);

    // Listen to realtime updates
    _realtimeManager!.updates.listen(_handleRealtimeUpdate);

    // Cleanup on dispose
    ref.onDispose(() {
      _realtimeManager?.dispose();
    });

    // Load initial data
    final repository = ref.watch(calendarRepositoryProvider);
    final days = await repository.getCalendarData(
      unitId: unitId,
      month: month,
    );

    return CalendarState(days: days);
  }

  /// Handle real-time updates from Supabase
  void _handleRealtimeUpdate(CalendarUpdateEvent event) {
    // Refresh calendar data when updates arrive
    refresh();
  }

  /// Refresh calendar data
  Future<void> refresh() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final repository = ref.read(calendarRepositoryProvider);
      final days = await repository.getCalendarData(
        unitId: unitId,
        month: month,
      );

      state = AsyncValue.data(CalendarState(days: days));
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  /// Create booking with optimistic update
  ///
  /// This provides immediate UI feedback by showing the booking
  /// before the server confirms it. If the server request fails,
  /// the optimistic update is rolled back.
  Future<Map<String, dynamic>> createBookingOptimistic(
    BookingRequest request,
  ) async {
    final currentState = state.valueOrNull;
    if (currentState == null) {
      throw Exception('Calendar not loaded');
    }

    // Step 1: Create optimistic booking days
    final optimisticDays = _createOptimisticBookingDays(
      currentState.days,
      request,
    );

    // Step 2: Apply optimistic update immediately (instant UI feedback)
    state = AsyncValue.data(
      currentState.copyWith(
        optimisticDays: optimisticDays,
        hasOptimisticUpdates: true,
      ),
    );

    try {
      // Step 3: Send request to backend
      final repository = ref.read(calendarRepositoryProvider);
      final confirmedBooking = await repository.createBookingAtomic(
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

      // Step 4: Refresh to get confirmed data from server
      // The real-time subscription will also trigger, ensuring we have latest data
      await refresh();

      return confirmedBooking;
    } catch (e) {
      // Step 5: Rollback on error
      state = AsyncValue.data(
        currentState.copyWith(
          hasOptimisticUpdates: false,
          error: 'Failed to create booking: $e',
        ),
      );
      rethrow;
    }
  }

  /// Block dates with optimistic update
  Future<void> blockDatesOptimistic({
    required DateTime from,
    required DateTime to,
    required String reason,
    String? notes,
  }) async {
    final currentState = state.valueOrNull;
    if (currentState == null) {
      throw Exception('Calendar not loaded');
    }

    // Create optimistic blocked days
    final optimisticDays = _createOptimisticBlockedDays(
      currentState.days,
      from,
      to,
    );

    // Apply optimistic update
    state = AsyncValue.data(
      currentState.copyWith(
        optimisticDays: optimisticDays,
        hasOptimisticUpdates: true,
      ),
    );

    try {
      // Send to backend
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

      // Refresh with confirmed data
      await refresh();
    } catch (e) {
      // Rollback on error
      state = AsyncValue.data(
        currentState.copyWith(
          hasOptimisticUpdates: false,
          error: 'Failed to block dates: $e',
        ),
      );
      rethrow;
    }
  }

  /// Create optimistic booking days by updating status of affected dates
  List<CalendarDay> _createOptimisticBookingDays(
    List<CalendarDay> currentDays,
    BookingRequest request,
  ) {
    return currentDays.map((day) {
      // Check if this day is in the booking range
      if (day.date.isBefore(request.checkIn) ||
          day.date.isAfter(request.checkOut)) {
        return day;
      }

      // Check-in day
      if (day.date.isAtSameMomentAs(request.checkIn)) {
        return day.copyWith(
          status: DayStatus.checkIn,
          checkInTime: _parseTimeString(request.checkInTime),
        );
      }

      // Check-out day
      if (day.date.isAtSameMomentAs(request.checkOut)) {
        return day.copyWith(
          status: DayStatus.checkOut,
          checkOutTime: _parseTimeString(request.checkOutTime),
        );
      }

      // Days in between are booked
      return day.copyWith(status: DayStatus.booked);
    }).toList();
  }

  /// Create optimistic blocked days
  List<CalendarDay> _createOptimisticBlockedDays(
    List<CalendarDay> currentDays,
    DateTime from,
    DateTime to,
  ) {
    return currentDays.map((day) {
      if (day.date.isAfter(from.subtract(const Duration(days: 1))) &&
          day.date.isBefore(to.add(const Duration(days: 1)))) {
        return day.copyWith(status: DayStatus.blocked);
      }
      return day;
    }).toList();
  }

  /// Parse time string to DateTime
  DateTime? _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      final now = DateTime.now();
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
        parts.length > 2 ? int.parse(parts[2]) : 0,
      );
    } catch (e) {
      return null;
    }
  }
}
