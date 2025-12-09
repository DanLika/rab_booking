import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
@Riverpod(keepAlive: true)
Future<List<PropertyModel>> ownerPropertiesCalendar(Ref ref) async {
  final repository = ref.watch(ownerPropertiesRepositoryProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) {
    throw AuthException('User not authenticated', code: 'auth/not-authenticated');
  }

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
@riverpod
Future<Map<String, List<BookingModel>>> calendarBookings(Ref ref) async {
  final repository = ref.watch(ownerBookingsRepositoryProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) {
    throw AuthException('User not authenticated', code: 'auth/not-authenticated');
  }

  // OPTIMIZED: Get unitIds from cached provider instead of re-fetching
  final units = await ref.watch(allOwnerUnitsProvider.future);
  final unitIds = units.map((u) => u.id).toList();

  if (unitIds.isEmpty) return {};

  // Date range aligned with widget's max scroll limits (_kMaxDaysLimit = 365)
  // 1 year back for historical visibility, 1 year forward for future planning
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month - 12, now.day); // 1 year back
  final endDate = DateTime(now.year + 1, now.month, now.day); // 1 year forward

  // OPTIMIZED: Use method that accepts unitIds directly (skips properties/units fetch)
  final allBookings = await repository.getCalendarBookingsWithUnitIds(
    unitIds: unitIds,
    startDate: startDate,
    endDate: endDate,
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

  @override
  void build() {
    final auth = FirebaseAuth.instance;
    final userId = auth.currentUser?.uid;

    if (userId != null) {
      _setupRealtimeSubscription(userId: userId);
    }

    // FIXED: Cancel ALL subscriptions on dispose
    ref.onDispose(() {
      for (final subscription in _allSubscriptions) {
        subscription.cancel();
      }
      _allSubscriptions.clear();
    });
  }

  /// Setup real-time subscription for ALL owner's bookings with batched listeners
  /// Handles >10 units by creating multiple listeners (Firestore whereIn limit is 10)
  ///
  /// OPTIMIZED: Uses cached unitIds from allOwnerUnitsProvider
  /// Saves 1 + N queries (properties + units) per setup
  void _setupRealtimeSubscription({required String userId}) async {
    // FIXED: Cancel ALL previous subscriptions
    for (final subscription in _allSubscriptions) {
      await subscription.cancel();
    }
    _allSubscriptions.clear();

    final firestore = FirebaseFirestore.instance;

    // PERFORMANCE FIX: Calculate date range for realtime listener
    // Only listen for bookings that could affect the visible calendar
    // Must match the date range used by calendarBookingsProvider
    final now = DateTime.now();
    final endDate = DateTime(now.year + 1, now.month, now.day); // 1 year forward

    try {
      // OPTIMIZED: Get unitIds from cached provider instead of re-fetching
      final units = await ref.read(allOwnerUnitsProvider.future);
      final unitIdsToWatch = units.map((u) => u.id).toList();

      if (unitIdsToWatch.isEmpty) return;

      // BATCHED LISTENING: Split unit IDs into chunks of 10 (Firestore whereIn limit)
      final batches = <List<String>>[];
      for (int i = 0; i < unitIdsToWatch.length; i += 10) {
        final end = (i + 10 < unitIdsToWatch.length)
            ? i + 10
            : unitIdsToWatch.length;
        batches.add(unitIdsToWatch.sublist(i, end));
      }

      LoggingService.log(
        'Setting up ${batches.length} batched listeners for ${unitIdsToWatch.length} units (until: ${endDate.toIso8601String()})',
        tag: 'CALENDAR_REALTIME',
      );

      // FIXED: Create multiple listeners for all batches and store them ALL
      // All batches will trigger the same invalidation
      for (int i = 0; i < batches.length; i++) {
        final batch = batches[i];

        // Listener 1: Regular bookings
        // PERFORMANCE FIX: Add date filter to prevent unbounded data download
        // Filter by check_in <= endDate (server-side) - Firestore only allows one inequality
        // Bookings with check_out before startDate will be ignored via provider filtering
        final bookingsSubscription = firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .where('check_in', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .snapshots()
            .listen(
              (snapshot) {
                LoggingService.log(
                  'Batch $i received ${snapshot.docs.length} booking updates',
                  tag: 'CALENDAR_REALTIME',
                );
                // When bookings change in any batch, invalidate the calendar
                ref.invalidate(calendarBookingsProvider);
              },
              onError: (error) {
                LoggingService.logError(
                  'Error in batch $i realtime subscription',
                  error,
                );
              },
            );
        _allSubscriptions.add(bookingsSubscription);

        // Listener 2: OPTIONAL - iCal events (Booking.com, Airbnb, etc.)
        // Gracefully fails if ical_events collection doesn't exist or has no data
        try {
          final icalSubscription = firestore
              .collection('ical_events')
              .where('unit_id', whereIn: batch)
              .snapshots()
              .listen(
                (snapshot) {
                  LoggingService.log(
                    'Batch $i received ${snapshot.docs.length} iCal event updates',
                    tag: 'CALENDAR_REALTIME_ICAL',
                  );
                  // When iCal events change, also invalidate the calendar
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
      unawaited(LoggingService.logError('Failed to setup realtime subscription', e));
    }
  }

  /// Manually refresh subscription (useful for debugging)
  void refresh() {
    final auth = FirebaseAuth.instance;
    final userId = auth.currentUser?.uid;

    if (userId != null) {
      _setupRealtimeSubscription(userId: userId);
    }
  }
}
