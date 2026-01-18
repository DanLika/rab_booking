import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../domain/models/ical_feed.dart';

/// Provider for all iCal feeds (real-time stream)
final icalFeedsStreamProvider = StreamProvider<List<IcalFeed>>((ref) {
  final userId = ref.watch(enhancedAuthProvider).firebaseUser?.uid;
  if (userId == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(icalRepositoryProvider);
  return repository.watchOwnerIcalFeeds(userId);
});

/// Provider for iCal statistics
/// OPTIMIZED: Computes stats from already-loaded feeds instead of separate query
/// This eliminates a duplicate Firestore read (feeds are already in icalFeedsStreamProvider)
final icalStatisticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final feeds = await ref.watch(icalFeedsStreamProvider.future);

  if (feeds.isEmpty) {
    return {
      'total_feeds': 0,
      'active_feeds': 0,
      'error_feeds': 0,
      'paused_feeds': 0,
      'total_events': 0,
      'total_syncs': 0,
    };
  }

  return {
    'total_feeds': feeds.length,
    'active_feeds': feeds.where((f) => f.isActive).length,
    'error_feeds': feeds.where((f) => f.hasError).length,
    'paused_feeds': feeds.where((f) => f.status == IcalStatus.paused).length,
    'total_events': feeds.fold(0, (acc, f) => acc + f.eventCount),
    'total_syncs': feeds.fold(0, (acc, f) => acc + f.syncCount),
  };
});

/// Provider for iCal events for a specific unit (real-time)
final unitIcalEventsProvider = StreamProvider.family<List<IcalEvent>, String>((
  ref,
  unitId,
) {
  final repository = ref.watch(icalRepositoryProvider);
  return repository.watchUnitIcalEvents(unitId);
});

/// State notifier for managing iCal feeds
class IcalFeedsNotifier extends AsyncNotifier<List<IcalFeed>> {
  @override
  Future<List<IcalFeed>> build() async {
    final userId = ref.watch(enhancedAuthProvider).firebaseUser?.uid;
    if (userId == null) {
      return [];
    }

    final repository = ref.watch(icalRepositoryProvider);
    return repository.getOwnerIcalFeeds(userId);
  }

  /// Create new iCal feed
  Future<void> createFeed(IcalFeed feed) async {
    final repository = ref.read(icalRepositoryProvider);
    await repository.createIcalFeed(feed);

    // Refresh the list
    ref.invalidateSelf();
  }

  /// Update iCal feed
  Future<void> updateFeed(IcalFeed feed) async {
    final repository = ref.read(icalRepositoryProvider);
    await repository.updateIcalFeed(feed);

    // Refresh the list
    ref.invalidateSelf();
  }

  /// Delete iCal feed
  Future<void> deleteFeed(String feedId, String propertyId) async {
    final repository = ref.read(icalRepositoryProvider);
    await repository.deleteIcalFeed(feedId, propertyId);

    // Refresh the list
    ref.invalidateSelf();
  }

  /// Update feed status
  Future<void> updateFeedStatus(
    String feedId,
    String propertyId,
    IcalStatus status, {
    String? errorMessage,
  }) async {
    final repository = ref.read(icalRepositoryProvider);
    await repository.updateFeedStatus(
      feedId,
      propertyId,
      status,
      errorMessage: errorMessage,
    );

    // Refresh the list
    ref.invalidateSelf();
  }
}

/// Provider for iCal feeds notifier
final icalFeedsProvider =
    AsyncNotifierProvider<IcalFeedsNotifier, List<IcalFeed>>(
      IcalFeedsNotifier.new,
    );
