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
final icalStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = ref.watch(enhancedAuthProvider).firebaseUser?.uid;
  if (userId == null) {
    return {};
  }

  final repository = ref.watch(icalRepositoryProvider);
  return repository.getIcalStatistics(userId);
});

/// Provider for iCal events for a specific unit (real-time)
final unitIcalEventsProvider = StreamProvider.family<List<IcalEvent>, String>((ref, unitId) {
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
  Future<void> deleteFeed(String feedId) async {
    final repository = ref.read(icalRepositoryProvider);
    await repository.deleteIcalFeed(feedId);

    // Refresh the list
    ref.invalidateSelf();
  }

  /// Update feed status
  Future<void> updateFeedStatus(String feedId, String status, {String? errorMessage}) async {
    final repository = ref.read(icalRepositoryProvider);
    await repository.updateFeedStatus(feedId, status, errorMessage: errorMessage);

    // Refresh the list
    ref.invalidateSelf();
  }
}

/// Provider for iCal feeds notifier
final icalFeedsProvider = AsyncNotifierProvider<IcalFeedsNotifier, List<IcalFeed>>(
  IcalFeedsNotifier.new,
);
