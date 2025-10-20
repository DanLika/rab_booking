import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/booking_model.dart';
import '../../data/owner_bookings_repository.dart';
import '../../data/owner_properties_repository.dart';
import '../../../../shared/models/property_model.dart';
import '../../../property/domain/models/property_unit.dart';
import '../../../../core/providers/auth_state_provider.dart';

part 'owner_calendar_provider.g.dart';

/// Calendar filter state
class CalendarFilters {
  final String? selectedPropertyId;
  final String? selectedUnitId;
  final DateTime focusedMonth;

  const CalendarFilters({
    this.selectedPropertyId,
    this.selectedUnitId,
    required this.focusedMonth,
  });

  CalendarFilters copyWith({
    String? selectedPropertyId,
    String? selectedUnitId,
    DateTime? focusedMonth,
  }) {
    return CalendarFilters(
      selectedPropertyId: selectedPropertyId ?? this.selectedPropertyId,
      selectedUnitId: selectedUnitId ?? this.selectedUnitId,
      focusedMonth: focusedMonth ?? this.focusedMonth,
    );
  }
}

/// Calendar filters notifier
@riverpod
class CalendarFiltersNotifier extends _$CalendarFiltersNotifier {
  @override
  CalendarFilters build() {
    return CalendarFilters(
      focusedMonth: DateTime.now(),
    );
  }

  void selectProperty(String? propertyId) {
    state = state.copyWith(
      selectedPropertyId: propertyId,
      selectedUnitId: null, // Reset unit when property changes
    );
  }

  void selectUnit(String? unitId) {
    state = state.copyWith(selectedUnitId: unitId);
  }

  void setFocusedMonth(DateTime month) {
    state = state.copyWith(focusedMonth: month);
  }
}

/// Owner properties provider
@riverpod
Future<List<PropertyModel>> ownerProperties(Ref ref) async {
  final repository = ref.watch(ownerPropertiesRepositoryProvider);
  final user = ref.watch(currentUserIdProvider);

  if (user == null) {
    throw Exception('User not authenticated');
  }

  return repository.getOwnerProperties(user);
}

/// Units for selected property provider
@riverpod
Future<List<PropertyUnit>> selectedPropertyUnits(Ref ref) async {
  final filters = ref.watch(calendarFiltersNotifierProvider);

  if (filters.selectedPropertyId == null) {
    return [];
  }

  final repository = ref.watch(ownerPropertiesRepositoryProvider);
  return repository.getPropertyUnits(filters.selectedPropertyId!);
}

/// Calendar bookings provider
@riverpod
Future<Map<String, List<BookingModel>>> calendarBookings(Ref ref) async {
  final filters = ref.watch(calendarFiltersNotifierProvider);
  final repository = ref.watch(ownerBookingsRepositoryProvider);
  final user = ref.watch(currentUserIdProvider);

  if (user == null) {
    throw Exception('User not authenticated');
  }

  // Get start and end dates for the current month view
  // Extend to include prev/next month days shown in calendar
  final focusedMonth = filters.focusedMonth;
  final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
  final lastDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);

  // Extend range to show full calendar view (6 weeks)
  final startDate = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday));
  final endDate = lastDayOfMonth.add(Duration(days: 42 - lastDayOfMonth.day));

  return repository.getCalendarBookings(
    ownerId: user,
    propertyId: filters.selectedPropertyId,
    unitId: filters.selectedUnitId,
    startDate: startDate,
    endDate: endDate,
  );
}

/// Helper provider to get current user ID
@riverpod
String? currentUserId(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id;
}

/// Realtime subscription manager for owner calendar
/// Automatically refreshes calendar when bookings change
@riverpod
class OwnerCalendarRealtimeManager extends _$OwnerCalendarRealtimeManager {
  RealtimeChannel? _realtimeSubscription;

  @override
  void build() {
    // Watch filter changes to update subscription
    final filters = ref.watch(calendarFiltersNotifierProvider);
    final userId = ref.watch(currentUserIdProvider);

    if (userId != null) {
      _setupRealtimeSubscription(
        userId: userId,
        propertyId: filters.selectedPropertyId,
        unitId: filters.selectedUnitId,
      );
    }

    // Cancel subscription on dispose
    ref.onDispose(() {
      _realtimeSubscription?.unsubscribe();
    });
  }

  /// Setup real-time subscription for booking updates
  void _setupRealtimeSubscription({
    required String userId,
    String? propertyId,
    String? unitId,
  }) {
    // Unsubscribe from previous channel
    _realtimeSubscription?.unsubscribe();

    final supabase = Supabase.instance.client;

    // Create unique channel name based on filters
    final channelName = 'owner_calendar_${userId}_${propertyId ?? 'all'}_${unitId ?? 'all'}';

    _realtimeSubscription = supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (payload) {
            // Invalidate calendar bookings to trigger refresh
            ref.invalidate(calendarBookingsProvider);
          },
        )
        .subscribe();
  }

  /// Manually refresh subscription (useful for debugging)
  void refresh() {
    final filters = ref.read(calendarFiltersNotifierProvider);
    final userId = ref.read(currentUserIdProvider);

    if (userId != null) {
      _setupRealtimeSubscription(
        userId: userId,
        propertyId: filters.selectedPropertyId,
        unitId: filters.selectedUnitId,
      );
    }
  }
}
