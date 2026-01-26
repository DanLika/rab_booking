import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/constants/enums.dart';
import '../../domain/models/unified_booking_item.dart';
import '../../domain/models/ical_feed.dart';
import 'owner_bookings_provider.dart';
import 'ical_feeds_provider.dart';

part 'unified_bookings_provider.g.dart';

/// Provider that merges regular bookings with imported reservations
/// for display in a unified, sorted list.
///
/// Behavior:
/// - When `showImportedOnly == true` → only imported reservations (IcalEvents)
/// - When status filter is applied → only regular bookings (imported don't have status)
/// - Otherwise → both merged and sorted by creation date (newest first)
@riverpod
Future<List<UnifiedBookingItem>> unifiedBookings(Ref ref) async {
  final filters = ref.watch(bookingsFiltersNotifierProvider);
  final windowedState = ref.watch(windowedBookingsNotifierProvider);

  // Case 1: Show only imported
  if (filters.showImportedOnly) {
    final eventsAsync = await ref.watch(allOwnerIcalEventsProvider.future);
    return eventsAsync.map(ImportedBookingItem.new).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Case 2: Status filter applied - only regular bookings (imported don't have status)
  if (filters.status != null) {
    return windowedState.visibleBookings.map(RegularBookingItem.new).toList();
  }

  // Case 3: "All" - merge both sources
  final regularBookings = windowedState.visibleBookings
      .map(RegularBookingItem.new)
      .toList();

  // Fetch imported reservations
  List<IcalEvent> importedEvents = [];
  try {
    importedEvents = await ref.watch(allOwnerIcalEventsProvider.future);
  } catch (_) {
    // If imported events fail to load, just show regular bookings
  }

  final importedBookings = importedEvents.map(ImportedBookingItem.new).toList();

  // Merge and sort: pending first (by check-in), then all others by created_at (newest first)
  // This matches the sorting logic in firebase_owner_bookings_repository.dart
  final merged = <UnifiedBookingItem>[...regularBookings, ...importedBookings];
  merged.sort((a, b) {
    // Determine if item is pending (only RegularBookingItem can be pending)
    final aPending =
        a is RegularBookingItem &&
            a.ownerBooking.booking.status == BookingStatus.pending
        ? 0
        : 1;
    final bPending =
        b is RegularBookingItem &&
            b.ownerBooking.booking.status == BookingStatus.pending
        ? 0
        : 1;

    // Pending bookings come first
    if (aPending != bPending) return aPending.compareTo(bPending);

    // Both pending and non-pending: sort by check-in (soonest first)
    return a.checkIn.compareTo(b.checkIn);
  });

  return merged;
}

/// Convenience provider to check if unified list is loading
@riverpod
bool isUnifiedBookingsLoading(Ref ref) {
  final windowedState = ref.watch(windowedBookingsNotifierProvider);
  final filters = ref.watch(bookingsFiltersNotifierProvider);

  if (filters.showImportedOnly) {
    return ref.watch(allOwnerIcalEventsProvider).isLoading;
  }

  // Also check if the unified bookings provider itself is loading
  // This fixes the race condition where windowedState is ready but
  // unifiedBookingsProvider is still computing the merged list
  final unifiedAsync = ref.watch(unifiedBookingsProvider);

  return windowedState.isInitialLoad || unifiedAsync.isLoading;
}

/// Convenience provider for unified bookings error
@riverpod
String? unifiedBookingsError(Ref ref) {
  final windowedState = ref.watch(windowedBookingsNotifierProvider);
  final filters = ref.watch(bookingsFiltersNotifierProvider);

  if (filters.showImportedOnly) {
    final eventsAsync = ref.watch(allOwnerIcalEventsProvider);
    return eventsAsync.hasError ? eventsAsync.error.toString() : null;
  }

  return windowedState.error;
}
