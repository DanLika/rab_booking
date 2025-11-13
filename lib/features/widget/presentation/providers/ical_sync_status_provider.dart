import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../owner_dashboard/data/firebase/firebase_ical_repository.dart';

/// Model for iCal sync status information
class IcalSyncStatus {
  final bool hasActiveFeeds;
  final DateTime? oldestSyncTime;
  final int minutesSinceSync;
  final String displayText;
  final bool isStale; // true if > 30 minutes

  IcalSyncStatus({
    required this.hasActiveFeeds,
    this.oldestSyncTime,
    required this.minutesSinceSync,
    required this.displayText,
    required this.isStale,
  });

  /// Factory for when there are no active feeds
  factory IcalSyncStatus.noFeeds() {
    return IcalSyncStatus(
      hasActiveFeeds: false,
      minutesSinceSync: 0,
      displayText: '',
      isStale: false,
    );
  }

  /// Factory for when there are active feeds
  factory IcalSyncStatus.fromLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    final minutes = difference.inMinutes;

    String displayText;
    if (minutes < 1) {
      displayText = 'External calendars synced just now';
    } else if (minutes == 1) {
      displayText = 'External calendars last synced: 1 min ago';
    } else if (minutes < 60) {
      displayText = 'External calendars last synced: $minutes min ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      displayText =
          'External calendars last synced: ${hours}h ${minutes % 60}min ago';
    } else {
      final days = difference.inDays;
      displayText = 'External calendars last synced: $days days ago';
    }

    return IcalSyncStatus(
      hasActiveFeeds: true,
      oldestSyncTime: lastSync,
      minutesSinceSync: minutes,
      displayText: displayText,
      isStale: minutes >= 30, // Stale if >= 30 minutes
    );
  }
}

/// Provider for iCal repository
final icalRepositoryProvider = Provider<FirebaseIcalRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseIcalRepository(firestore);
});

/// Provider for iCal sync status for a specific unit
/// Bug #67 Fix: Track when external calendars (Airbnb/Booking.com) were last synced
/// to warn users about potential double-booking during sync delays
final icalSyncStatusProvider = FutureProvider.family<IcalSyncStatus, String>((
  ref,
  unitId,
) async {
  final repository = ref.watch(icalRepositoryProvider);

  // Get all iCal feeds for this unit
  final feeds = await repository.getUnitIcalFeeds(unitId);

  // Filter only active feeds
  final activeFeeds = feeds.where((feed) => feed.status == 'active').toList();

  if (activeFeeds.isEmpty) {
    return IcalSyncStatus.noFeeds();
  }

  // Find the oldest (stalest) sync time among all active feeds
  DateTime? oldestSync;

  for (final feed in activeFeeds) {
    if (feed.lastSynced != null) {
      if (oldestSync == null || feed.lastSynced!.isBefore(oldestSync)) {
        oldestSync = feed.lastSynced;
      }
    }
  }

  // If no feeds have been synced yet, show warning
  if (oldestSync == null) {
    return IcalSyncStatus(
      hasActiveFeeds: true,
      minutesSinceSync: 999999, // Very high number to indicate "never synced"
      displayText: 'External calendars have never been synced',
      isStale: true,
    );
  }

  return IcalSyncStatus.fromLastSync(oldestSync);
});
