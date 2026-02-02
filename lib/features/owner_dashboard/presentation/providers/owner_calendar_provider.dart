import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/constants/enums.dart';

part 'owner_calendar_provider.g.dart';

/// Owner properties provider - returns ALL properties for owner
/// keepAlive: Prevents re-fetching when filters dialog opens
/// SECURITY: Watches enhancedAuthProvider to invalidate cache on user change
@Riverpod(keepAlive: true)
Future<List<PropertyModel>> ownerPropertiesCalendar(Ref ref) async {
  // SECURITY FIX: Watch auth state to invalidate cache when user changes
  // This ensures a new user doesn't see the previous user's data
  final authState = ref.watch(enhancedAuthProvider);
  final userId = authState.firebaseUser?.uid;

  if (userId == null) {
    throw AuthException(
      'User not authenticated',
      code: 'auth/not-authenticated',
    );
  }

  final repository = ref.watch(ownerPropertiesRepositoryProvider);
  return repository.getOwnerProperties(userId);
}

/// All units provider - returns ALL ACTIVE units for ALL properties
/// Filters out soft-deleted units (deletedAt != null) and unavailable units
/// keepAlive: Prevents re-fetching when filters dialog opens/closes
@Riverpod(keepAlive: true)
Future<List<UnitModel>> allOwnerUnits(Ref ref) async {
  final properties = await ref.watch(ownerPropertiesCalendarProvider.future);
  final repository = ref.watch(ownerPropertiesRepositoryProvider);

  final List<UnitModel> allUnits = [];

  for (final property in properties) {
    final units = await repository.getPropertyUnits(property.id);

    // FILTER: Only include active units (not soft-deleted)
    final activeUnits = units.where((unit) => unit.deletedAt == null).toList();

    allUnits.addAll(activeUnits);
  }

  return allUnits;
}

/// Calendar bookings provider - returns all bookings except cancelled
/// Cancelled bookings are hidden as they don't occupy dates
///
/// OPTIMIZED: Uses pre-cached unitIds from allOwnerUnitsProvider
/// Saves 1 + N queries (properties + units) per invocation
/// keepAlive: Prevents re-fetching when navigating away and back
@Riverpod(keepAlive: true)
Future<Map<String, List<BookingModel>>> calendarBookings(Ref ref) async {
  final repository = ref.watch(ownerBookingsRepositoryProvider);

  // BUG FIX: Watch auth state to rebuild when user changes
  // Consistent with dashboard fix - prevents stale data after re-login
  final authState = ref.watch(enhancedAuthProvider);
  final userId = authState.userModel?.id;

  if (userId == null) {
    throw AuthException(
      'User not authenticated',
      code: 'auth/not-authenticated',
    );
  }

  // OPTIMIZED: Get unitIds from cached provider instead of re-fetching
  final units = await ref.watch(allOwnerUnitsProvider.future);
  final unitIds = units.map((u) => u.id).toList();

  if (unitIds.isEmpty) return {};

  // OPTIMIZED: Create unit->property map to avoid N+1 queries in repository
  final unitToPropertyMap = <String, String>{};
  for (final unit in units) {
    unitToPropertyMap[unit.id] = unit.propertyId;
  }

  // Date range aligned with widget's max scroll limits (_kMaxDaysLimit = 365)
  // OPTIMIZATION: Reduced from 12m back to 3m back to reduce query size
  // 3 months back covers recent history, 9 months forward covers most future bookings
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month - 3, now.day);
  final endDate = DateTime(now.year, now.month + 9, now.day);

  // OPTIMIZED: Use method that accepts unitIds directly (skips properties/units fetch)
  final allBookings = await repository.getCalendarBookingsWithUnitIds(
    unitIds: unitIds,
    startDate: startDate,
    endDate: endDate,
    unitToPropertyMap: unitToPropertyMap,
  );

  // FILTER: Show active bookings + completed on timeline (exclude only cancelled)
  // Completed bookings are included for historical visibility
  // Cancelled bookings are hidden as they don't occupy dates
  final visibleBookingsMap = <String, List<BookingModel>>{};
  for (final entry in allBookings.entries) {
    final visibleBookings = entry.value
        .where((booking) => booking.status != BookingStatus.cancelled)
        .toList();
    if (visibleBookings.isNotEmpty) {
      visibleBookingsMap[entry.key] = visibleBookings;
    }
  }

  return visibleBookingsMap;
}

/// Realtime subscription manager for owner calendar
/// Automatically refreshes calendar when ANY booking changes
@riverpod
class OwnerCalendarRealtimeManager extends _$OwnerCalendarRealtimeManager {
  // FIXED: Store ALL subscriptions to prevent memory leak
  final List<StreamSubscription<QuerySnapshot>> _allSubscriptions = [];
  // FIXED: Track disposed state to prevent race conditions in async setup
  bool _isDisposed = false;

  @override
  void build() {
    _isDisposed = false;

    // BUG FIX: Watch auth state to rebuild subscriptions when user changes
    final authState = ref.watch(enhancedAuthProvider);
    final userId = authState.userModel?.id;

    if (userId != null) {
      _setupRealtimeSubscription(userId: userId);
    }

    // FIXED: Cancel ALL subscriptions on dispose
    ref.onDispose(() {
      _isDisposed = true;
      for (final subscription in _allSubscriptions) {
        subscription.cancel();
      }
      _allSubscriptions.clear();
    });
  }

  /// Setup real-time subscription for ALL owner's bookings
  /// Uses owner_id query for bookings (matches security rules) and
  /// batched unit_id whereIn for iCal events (public read rules)
  ///
  /// OPTIMIZED: Uses cached unitIds from allOwnerUnitsProvider
  /// Saves 1 + N queries (properties + units) per setup
  void _setupRealtimeSubscription({required String userId}) async {
    // FIXED: Check if disposed before starting async setup
    if (_isDisposed) return;

    // FIXED: Cancel ALL previous subscriptions
    for (final subscription in _allSubscriptions) {
      await subscription.cancel();
    }
    _allSubscriptions.clear();

    // FIXED: Check again after async cancel operations
    if (_isDisposed) return;

    final firestore = FirebaseFirestore.instance;

    // PERFORMANCE FIX: Calculate date range for realtime listener
    // Only listen for bookings that could affect the visible calendar
    // Must match the date range used by calendarBookingsProvider
    final now = DateTime.now();
    // OPTIMIZATION: Synced with calendarBookings provider (9 months forward)
    final endDate = DateTime(now.year, now.month + 9, now.day);

    try {
      // OPTIMIZED: Get unitIds from cached provider instead of re-fetching
      final units = await ref.read(allOwnerUnitsProvider.future);

      // FIXED: Check if disposed after async operation
      if (_isDisposed) return;

      final unitIdsToWatch = units.map((u) => u.id).toList();

      if (unitIdsToWatch.isEmpty) return;

      LoggingService.log(
        'Setting up realtime listeners for ${unitIdsToWatch.length} units (until: ${endDate.toIso8601String()})',
        tag: 'CALENDAR_REALTIME',
      );

      // Listener 1: Single owner-based bookings listener
      // SECURITY FIX: Uses owner_id filter to satisfy Firestore security rules
      // (rules require resource.data.owner_id == request.auth.uid for collection group)
      // Uses existing composite index: owner_id ASC + check_in ASC
      // No batching needed - one listener covers ALL owner's bookings
      final bookingsSubscription = firestore
          .collectionGroup('bookings')
          .where('owner_id', isEqualTo: userId)
          .where('check_in', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .listen(
            (snapshot) {
              LoggingService.log(
                'Received ${snapshot.docs.length} booking updates',
                tag: 'CALENDAR_REALTIME',
              );
              ref.invalidate(calendarBookingsProvider);
            },
            onError: (error) {
              LoggingService.logError(
                'Error in bookings realtime subscription',
                error,
              );
            },
          );
      _allSubscriptions.add(bookingsSubscription);

      // Listener 2: OPTIONAL - Batched iCal events (Booking.com, Airbnb, etc.)
      // iCal events use public read rules (allow read: if true) so unit_id whereIn works
      // Still needs batching due to Firestore whereIn limit of 10
      final batches = <List<String>>[];
      for (int i = 0; i < unitIdsToWatch.length; i += 10) {
        final end = (i + 10 < unitIdsToWatch.length)
            ? i + 10
            : unitIdsToWatch.length;
        batches.add(unitIdsToWatch.sublist(i, end));
      }

      for (int i = 0; i < batches.length; i++) {
        final batch = batches[i];

        try {
          final icalSubscription = firestore
              .collectionGroup('ical_events')
              .where('unit_id', whereIn: batch)
              .snapshots()
              .listen(
                (snapshot) {
                  LoggingService.log(
                    'iCal batch $i received ${snapshot.docs.length} event updates',
                    tag: 'CALENDAR_REALTIME_ICAL',
                  );
                  ref.invalidate(calendarBookingsProvider);
                },
                onError: (error) {
                  // GRACEFUL: If iCal events collection doesn't exist or query fails,
                  // just log it and continue - calendar will still work with regular bookings
                  LoggingService.log(
                    'iCal events listener error (non-critical): $error',
                    tag: 'CALENDAR_REALTIME_ICAL',
                  );
                },
              );
          _allSubscriptions.add(icalSubscription);
        } catch (e) {
          // GRACEFUL: If iCal listener fails to setup, continue without it
          LoggingService.log(
            'Failed to setup iCal listener (non-critical): $e',
            tag: 'CALENDAR_REALTIME_ICAL',
          );
        }
      }
    } catch (e) {
      unawaited(
        LoggingService.logError('Failed to setup realtime subscription', e),
      );
    }
  }

  /// Manually refresh subscription (useful for debugging)
  void refresh() {
    // Use auth provider for consistency
    final authState = ref.read(enhancedAuthProvider);
    final userId = authState.userModel?.id;

    if (userId != null) {
      _setupRealtimeSubscription(userId: userId);
    }
  }
}
