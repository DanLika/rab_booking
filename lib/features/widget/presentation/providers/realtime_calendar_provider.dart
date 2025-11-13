import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/models/booking_model.dart';
import 'year_calendar_provider.dart';
import 'month_calendar_provider.dart';

/// Provider for Firebase realtime bookings stream for a specific unit
final realtimeBookingsStreamProvider = StreamProvider.family<List<BookingModel>, String>((ref, unitId) {
  final firestore = ref.watch(firestoreProvider);

  // Listen to bookings collection for this unit
  return firestore
      .collection('bookings')
      .where('unit_id', isEqualTo: unitId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  });
});

/// Provider that invalidates calendar data when bookings change
final realtimeCalendarDataProvider = StreamProvider.family<bool, String>((ref, unitId) {
  final firestore = ref.watch(firestoreProvider);

  // Listen to bookings collection for this unit
  return firestore
      .collection('bookings')
      .where('unit_id', isEqualTo: unitId)
      .snapshots()
      .map((snapshot) {
    // Invalidate calendar providers when bookings change
    ref.invalidate(yearCalendarDataProvider);
    ref.invalidate(monthCalendarDataProvider);

    return true;
  });
});
