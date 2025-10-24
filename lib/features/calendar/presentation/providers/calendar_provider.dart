import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/calendar_repository.dart';
import '../../domain/models/calendar_day.dart';

part 'calendar_provider.g.dart';

/// Provider for calendar data for a specific unit and month
@riverpod
class CalendarData extends _$CalendarData {
  RealtimeChannel? _subscription;

  @override
  Future<List<CalendarDay>> build({
    required String unitId,
    required DateTime month,
  }) async {
    // Cancel subscription when provider is disposed
    ref.onDispose(() {
      _subscription?.unsubscribe();
    });

    // Load initial data
    final repository = ref.watch(calendarRepositoryProvider);
    final data = await repository.getCalendarData(
      unitId: unitId,
      month: month,
    );

    // Setup real-time subscription
    _setupRealtimeSubscription(repository, unitId);

    return data;
  }

  /// Refresh calendar data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(calendarRepositoryProvider);
      return repository.getCalendarData(
        unitId: unitId,
        month: month,
      );
    });
  }

  /// Setup real-time subscription for calendar changes
  void _setupRealtimeSubscription(
    CalendarRepository repository,
    String unitId,
  ) {
    _subscription = repository.subscribeToCalendarChanges(
      unitId: unitId,
      onCalendarUpdate: (updatedData) {
        // Update state with new data
        state = AsyncValue.data(updatedData);
      },
      onAvailabilityUpdate: (_) {
        // Refresh when availability changes
        refresh();
      },
    );
  }
}

/// Provider for calendar settings
@riverpod
class CalendarSettingsNotifier extends _$CalendarSettingsNotifier {
  @override
  Future<CalendarSettings?> build(String unitId) async {
    final repository = ref.watch(calendarRepositoryProvider);
    return repository.getCalendarSettings(unitId);
  }
}

/// Provider for blocked dates
@riverpod
class BlockedDates extends _$BlockedDates {
  @override
  Future<List<CalendarAvailability>> build(String unitId) async {
    final repository = ref.watch(calendarRepositoryProvider);
    return repository.getBlockedDates(unitId);
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

    // Refresh blocked dates
    ref.invalidateSelf();
  }
}

/// Provider for selected date range
@riverpod
class SelectedDateRange extends _$SelectedDateRange {
  @override
  ({DateTime? checkIn, DateTime? checkOut}) build() {
    return (checkIn: null, checkOut: null);
  }

  void setCheckIn(DateTime? date) {
    state = (checkIn: date, checkOut: state.checkOut);
  }

  void setCheckOut(DateTime? date) {
    state = (checkIn: state.checkIn, checkOut: date);
  }

  void setRange(DateTime? checkIn, DateTime? checkOut) {
    state = (checkIn: checkIn, checkOut: checkOut);
  }

  void clear() {
    state = (checkIn: null, checkOut: null);
  }

  /// Check if selected range has conflicts
  Future<bool> hasConflict(String unitId) async {
    if (state.checkIn == null || state.checkOut == null) {
      return false;
    }

    final repository = ref.read(calendarRepositoryProvider);
    return repository.checkBookingConflict(
      unitId: unitId,
      checkIn: state.checkIn!,
      checkOut: state.checkOut!,
    );
  }
}

/// Provider for focused month (which month user is viewing)
@riverpod
class FocusedMonth extends _$FocusedMonth {
  @override
  DateTime build() {
    return DateTime.now();
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }
}
