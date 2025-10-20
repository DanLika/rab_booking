import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../features/auth/presentation/providers/auth_notifier.dart';
import '../../data/repositories/saved_searches_repository.dart';
import '../../domain/models/saved_search.dart';
import '../../domain/models/search_filters.dart';

part 'saved_searches_provider.g.dart';

/// Provider for fetching user's saved searches
@riverpod
Future<List<SavedSearch>> userSavedSearches(
  Ref ref,
) async {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return [];
  }

  final repository = ref.watch(savedSearchesRepositoryProvider);
  return await repository.getSavedSearches(userId);
}

/// Provider for saved searches count
@riverpod
Future<int> savedSearchesCount(
  Ref ref,
) async {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return 0;
  }

  final repository = ref.watch(savedSearchesRepositoryProvider);
  return await repository.getSavedSearchesCount(userId);
}

/// Notifier for managing saved searches
@riverpod
class SavedSearchesNotifier extends _$SavedSearchesNotifier {
  @override
  Future<List<SavedSearch>> build() async {
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return [];
    }

    final repository = ref.watch(savedSearchesRepositoryProvider);
    return await repository.getSavedSearches(userId);
  }

  /// Save a new search
  Future<SavedSearch> saveSearch({
    required String name,
    required SearchFilters filters,
    bool notificationEnabled = false,
  }) async {
    final authState = ref.read(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      throw Exception('User must be logged in to save searches');
    }

    final repository = ref.read(savedSearchesRepositoryProvider);

    // Check for duplicate
    final duplicate = await repository.findDuplicate(
      userId: userId,
      filters: filters,
    );

    if (duplicate != null) {
      throw Exception('You already have a saved search with these filters: "${duplicate.name}"');
    }

    // Save the search
    final savedSearch = await repository.saveSearch(
      userId: userId,
      name: name,
      filters: filters,
      notificationEnabled: notificationEnabled,
    );

    // Refresh the list
    ref.invalidateSelf();

    return savedSearch;
  }

  /// Update an existing saved search
  Future<SavedSearch> updateSearch({
    required String searchId,
    String? name,
    SearchFilters? filters,
    bool? notificationEnabled,
  }) async {
    final repository = ref.read(savedSearchesRepositoryProvider);

    final updatedSearch = await repository.updateSearch(
      searchId: searchId,
      name: name,
      filters: filters,
      notificationEnabled: notificationEnabled,
    );

    // Refresh the list
    ref.invalidateSelf();

    return updatedSearch;
  }

  /// Delete a saved search
  Future<void> deleteSearch(String searchId) async {
    final repository = ref.read(savedSearchesRepositoryProvider);

    await repository.deleteSearch(searchId);

    // Refresh the list
    ref.invalidateSelf();
  }

  /// Clear all saved searches for the current user
  Future<void> clearAll() async {
    final currentSearches = await future;

    final repository = ref.read(savedSearchesRepositoryProvider);

    // Delete all searches
    for (final search in currentSearches) {
      await repository.deleteSearch(search.id);
    }

    // Refresh the list
    ref.invalidateSelf();
  }

  /// Check if a search with the same filters exists
  Future<SavedSearch?> findDuplicate(SearchFilters filters) async {
    final authState = ref.read(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return null;
    }

    final repository = ref.read(savedSearchesRepositoryProvider);
    return await repository.findDuplicate(
      userId: userId,
      filters: filters,
    );
  }
}
