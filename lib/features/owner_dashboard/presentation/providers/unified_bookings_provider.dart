import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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
/// - Otherwise → both merged and sorted by check-in date (descending)
@riverpod
Future<List<UnifiedBookingItem>> unifiedBookings(Ref ref) async {
  final filters = ref.watch(bookingsFiltersNotifierProvider);
  final windowedState = ref.watch(windowedBookingsNotifierProvider);

  // Case 1: Show only imported
  if (filters.showImportedOnly) {
    final eventsAsync = await ref.watch(allOwnerIcalEventsProvider.future);
    return eventsAsync.map(ImportedBookingItem.new).toList()
      ..sort((a, b) => b.checkIn.compareTo(a.checkIn));
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

  // Merge and sort by check-in date (newest first)
  final merged = <UnifiedBookingItem>[...regularBookings, ...importedBookings];
  merged.sort((a, b) => b.checkIn.compareTo(a.checkIn));

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

  return windowedState.isInitialLoad;
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
