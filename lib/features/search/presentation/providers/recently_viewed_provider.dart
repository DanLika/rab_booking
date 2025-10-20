import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../features/auth/presentation/providers/auth_notifier.dart';
import '../../data/repositories/recently_viewed_repository.dart';

part 'recently_viewed_provider.g.dart';

/// Provider for user's recently viewed properties
@riverpod
Future<List<PropertyModel>> recentlyViewedProperties(
  RecentlyViewedPropertiesRef ref,
) async {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return [];
  }

  final repository = ref.watch(recentlyViewedRepositoryProvider);
  return await repository.getRecentlyViewed(userId, limit: 10);
}

/// Provider for recently viewed property IDs (for quick lookups)
@riverpod
Future<List<String>> recentlyViewedPropertyIds(
  RecentlyViewedPropertyIdsRef ref,
) async {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return [];
  }

  final repository = ref.watch(recentlyViewedRepositoryProvider);
  return await repository.getRecentlyViewedIds(userId);
}

/// Provider for recently viewed count
@riverpod
Future<int> recentlyViewedCount(
  RecentlyViewedCountRef ref,
) async {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return 0;
  }

  final repository = ref.watch(recentlyViewedRepositoryProvider);
  return await repository.getViewCount(userId);
}

/// Notifier for managing recently viewed operations
@riverpod
class RecentlyViewedNotifier extends _$RecentlyViewedNotifier {
  @override
  FutureOr<List<PropertyModel>> build() async {
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return [];
    }

    final repository = ref.watch(recentlyViewedRepositoryProvider);
    return await repository.getRecentlyViewed(userId);
  }

  /// Add a property to recently viewed
  Future<void> addView(String propertyId) async {
    final authState = ref.read(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) return;

    final repository = ref.read(recentlyViewedRepositoryProvider);

    try {
      await repository.addView(userId, propertyId);
      // Refresh the list
      ref.invalidateSelf();
    } catch (e) {
      // Silently fail - this is not critical functionality
      // ignore: avoid_print
      print('Failed to add recently viewed: $e');
    }
  }

  /// Clear all recently viewed history
  Future<void> clearHistory() async {
    final authState = ref.read(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) return;

    final repository = ref.read(recentlyViewedRepositoryProvider);

    try {
      await repository.clearHistory(userId);
      // Refresh the list
      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to clear history: $e');
    }
  }

  /// Remove a specific property from recently viewed
  Future<void> removeProperty(String propertyId) async {
    final authState = ref.read(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) return;

    final repository = ref.read(recentlyViewedRepositoryProvider);

    try {
      await repository.removeProperty(userId, propertyId);
      // Refresh the list
      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to remove property: $e');
    }
  }
}
