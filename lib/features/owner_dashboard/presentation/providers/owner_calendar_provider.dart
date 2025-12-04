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
@riverpod
Future<List<PropertyModel>> ownerPropertiesCalendar(Ref ref) async {
  final repository = ref.watch(ownerPropertiesRepositoryProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) {
    throw AuthException('User not authenticated', code: 'auth/not-authenticated');
  }

  return repository.getOwnerProperties(userId);
}

/// All units provider - returns ALL units for ALL properties (no filtering)
@riverpod
Future<List<UnitModel>> allOwnerUnits(Ref ref) async {
  final properties = await ref.watch(ownerPropertiesCalendarProvider.future);
  final repository = ref.watch(ownerPropertiesRepositoryProvider);

  final List<UnitModel> allUnits = [];

  for (final property in properties) {
    final units = await repository.getPropertyUnits(property.id);
    allUnits.addAll(units);
  }

  return allUnits;
}

/// Calendar bookings provider - returns ACTIVE bookings only (excludes cancelled)
/// Cancelled bookings are not shown on timeline calendar (consistent with booking widget)
@riverpod
Future<Map<String, List<BookingModel>>> calendarBookings(Ref ref) async {
  final repository = ref.watch(ownerBookingsRepositoryProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) {
    throw AuthException('User not authenticated', code: 'auth/not-authenticated');
  }

  // OPTIMIZED: Narrower date range: 3 months ago to 1 year in future
  // Old properties with past bookings can be viewed via archive feature
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month - 3, now.day);
  final endDate = DateTime(now.year + 1, now.month, now.day);

  // No property/unit filtering - timeline widget shows ALL units
  final allBookings = await repository.getCalendarBookings(
    ownerId: userId,
    startDate: startDate,
    endDate: endDate,
  );

  // FILTER: Only show active bookings on timeline (pending + confirmed)
  // Completed and cancelled bookings are visible on Reservations page
  final activeBookingsMap = <String, List<BookingModel>>{};
  for (final entry in allBookings.entries) {
    final activeBookings = entry.value
        .where((booking) =>
            booking.status == BookingStatus.pending ||
            booking.status == BookingStatus.confirmed)
        .toList();
    if (activeBookings.isNotEmpty) {
      activeBookingsMap[entry.key] = activeBookings;
    }
  }

  return activeBookingsMap;
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
  void _setupRealtimeSubscription({required String userId}) async {
    // FIXED: Cancel ALL previous subscriptions
    for (final subscription in _allSubscriptions) {
      await subscription.cancel();
    }
    _allSubscriptions.clear();

    final firestore = FirebaseFirestore.instance;

    try {
      // Get all unit IDs for owner's properties
      final propertiesSnapshot = await firestore
          .collection('properties')
          .where('owner_id', isEqualTo: userId)
          .get();

      final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();

      // Get all units for these properties from subcollections
      final List<String> unitIdsToWatch = [];
      for (final propertyId in propertyIds) {
        final unitsSnapshot = await firestore
            .collection('properties')
            .doc(propertyId)
            .collection('units')
            .get();

        unitIdsToWatch.addAll(unitsSnapshot.docs.map((doc) => doc.id));
      }

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
        'Setting up ${batches.length} batched listeners for ${unitIdsToWatch.length} units',
        tag: 'CALENDAR_REALTIME',
      );

      // FIXED: Create multiple listeners for all batches and store them ALL
      // All batches will trigger the same invalidation
      for (int i = 0; i < batches.length; i++) {
        final batch = batches[i];

        // Listener 1: Regular bookings
        final bookingsSubscription = firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
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
