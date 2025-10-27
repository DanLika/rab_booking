import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';

part 'owner_calendar_provider.g.dart';

/// Owner properties provider - returns ALL properties for owner
@riverpod
Future<List<PropertyModel>> ownerPropertiesCalendar(Ref ref) async {
  final repository = ref.watch(ownerPropertiesRepositoryProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  return repository.getOwnerProperties(userId);
}

/// All units provider - returns ALL units for ALL properties (no filtering)
@riverpod
Future<List<UnitModel>> allOwnerUnits(Ref ref) async {
  final properties = await ref.watch(ownerPropertiesCalendarProvider.future);
  final repository = ref.watch(ownerPropertiesRepositoryProvider);

  List<UnitModel> allUnits = [];

  for (final property in properties) {
    final units = await repository.getPropertyUnits(property.id);
    allUnits.addAll(units);
  }

  return allUnits;
}

/// Calendar bookings provider - returns ALL bookings for owner (no filtering)
@riverpod
Future<Map<String, List<BookingModel>>> calendarBookings(Ref ref) async {
  final repository = ref.watch(ownerBookingsRepositoryProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  // Wide date range: 1 year ago to 2 years in future
  final now = DateTime.now();
  final startDate = DateTime(now.year - 1, now.month, now.day);
  final endDate = DateTime(now.year + 2, now.month, now.day);

  // No property/unit filtering - timeline widget shows ALL units
  return repository.getCalendarBookings(
    ownerId: userId,
    propertyId: null,  // No property filter
    unitId: null,      // No unit filter
    startDate: startDate,
    endDate: endDate,
  );
}

/// Realtime subscription manager for owner calendar
/// Automatically refreshes calendar when ANY booking changes
@riverpod
class OwnerCalendarRealtimeManager extends _$OwnerCalendarRealtimeManager {
  StreamSubscription<QuerySnapshot>? _bookingsSubscription;

  @override
  void build() {
    final auth = FirebaseAuth.instance;
    final userId = auth.currentUser?.uid;

    if (userId != null) {
      _setupRealtimeSubscription(userId: userId);
    }

    // Cancel subscription on dispose
    ref.onDispose(() {
      _bookingsSubscription?.cancel();
    });
  }

  /// Setup real-time subscription for ALL owner's bookings
  void _setupRealtimeSubscription({required String userId}) async {
    // Cancel previous subscription
    await _bookingsSubscription?.cancel();

    final firestore = FirebaseFirestore.instance;

    try {
      // Get all unit IDs for owner's properties
      final propertiesSnapshot = await firestore
          .collection('properties')
          .where('owner_id', isEqualTo: userId)
          .get();

      final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();

      // Get all units for these properties from subcollections
      List<String> unitIdsToWatch = [];
      for (final propertyId in propertyIds) {
        final unitsSnapshot = await firestore
            .collection('properties')
            .doc(propertyId)
            .collection('units')
            .get();

        unitIdsToWatch.addAll(unitsSnapshot.docs.map((doc) => doc.id));
      }

      if (unitIdsToWatch.isEmpty) return;

      // Firestore whereIn limit is 10, so if we have more units,
      // we need to create multiple listeners
      // For simplicity, we'll listen to the first 10 units
      // TODO: In production, implement batched listeners for > 10 units
      final unitsToListen = unitIdsToWatch.take(10).toList();

      // Create Firestore snapshot listener
      _bookingsSubscription = firestore
          .collection('bookings')
          .where('unit_id', whereIn: unitsToListen)
          .snapshots()
          .listen(
        (snapshot) {
          // When bookings change, invalidate the calendar bookings provider
          ref.invalidate(calendarBookingsProvider);
        },
        onError: (error) {
          print('Error in calendar realtime subscription: $error');
        },
      );
    } catch (e) {
      print('Failed to setup realtime subscription: $e');
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
