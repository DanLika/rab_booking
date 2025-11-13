import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/repository_providers.dart';
import 'month_calendar_provider.dart';
import 'year_calendar_provider.dart';

/// Bug #68 Fix: Auto-refresh calendar when booking status changes
/// Watches booking changes for a unit and invalidates calendar providers

/// Model to track booking IDs and their statuses
class BookingStatusSnapshot {
  final Map<String, String> bookingStatuses; // bookingId -> status
  final DateTime timestamp; // When this snapshot was created

  BookingStatusSnapshot(this.bookingStatuses, this.timestamp);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BookingStatusSnapshot) return false;
    if (bookingStatuses.length != other.bookingStatuses.length) return false;

    for (final entry in bookingStatuses.entries) {
      if (other.bookingStatuses[entry.key] != entry.value) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hashAll(bookingStatuses.entries);
}

/// StreamProvider that watches all booking status changes for a unit
final bookingStatusStreamProvider = StreamProvider.family<BookingStatusSnapshot, String>((ref, unitId) {
  final firestore = ref.watch(firestoreProvider);

  // Watch all bookings for this unit (regardless of status)
  return firestore
      .collection('bookings')
      .where('unit_id', isEqualTo: unitId)
      .snapshots()
      .map((snapshot) {
        final Map<String, String> statuses = {};

        for (final doc in snapshot.docs) {
          final data = doc.data();
          statuses[doc.id] = data['status'] as String? ?? 'unknown';
        }

        return BookingStatusSnapshot(statuses, DateTime.now());
      });
});

/// Provider to initialize calendar auto-refresh for a unit
/// This watches booking status changes and invalidates calendar providers when needed
final calendarAutoRefreshProvider = Provider.family<void, String>((ref, unitId) {
  // Watch the booking status stream
  ref.listen<AsyncValue<BookingStatusSnapshot>>(
    bookingStatusStreamProvider(unitId),
    (previous, next) {
      // Only invalidate if we have valid data and it changed
      final prevValue = previous?.value;
      final nextValue = next.value;

      if (prevValue != null && nextValue != null) {
        // Check if any booking status actually changed
        if (prevValue != nextValue) {
          // Invalidate calendar providers for this unit
          // This forces them to reload with fresh data
          ref.invalidate(monthCalendarDataProvider);
          ref.invalidate(yearCalendarDataProvider);
        }
      }
    },
  );
});
