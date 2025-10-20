import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../features/search/data/repositories/property_search_repository.dart';
import '../../../../features/search/domain/models/search_filters.dart';
import '../../data/favorites_repository.dart';

part 'favorites_provider.g.dart';

/// Provider for user's favorite property IDs
@riverpod
class FavoritesNotifier extends _$FavoritesNotifier {
  @override
  Future<Set<String>> build() async {
    final repository = ref.watch(favoritesRepositoryProvider);
    return await repository.getFavoriteIds();
  }

  /// Check if a property is favorited
  bool isFavorite(String propertyId) {
    return state.value?.contains(propertyId) ?? false;
  }

  /// Toggle favorite status for a property
  Future<void> toggleFavorite(String propertyId) async {
    final repository = ref.read(favoritesRepositoryProvider);

    try {
      final newStatus = await repository.toggleFavorite(propertyId);

      // Update local state
      state = state.when(
        data: (favorites) {
          final newFavorites = Set<String>.from(favorites);
          if (newStatus) {
            newFavorites.add(propertyId);
          } else {
            newFavorites.remove(propertyId);
          }
          return AsyncData(newFavorites);
        },
        loading: () => state,
        error: (e, s) => state,
      );
    } catch (e) {
      // If error, refresh from server
      ref.invalidateSelf();
      rethrow;
    }
  }

  /// Add a property to favorites
  Future<void> addFavorite(String propertyId) async {
    final repository = ref.read(favoritesRepositoryProvider);

    try {
      await repository.addFavorite(propertyId);

      // Update local state
      state = state.when(
        data: (favorites) {
          final newFavorites = Set<String>.from(favorites)..add(propertyId);
          return AsyncData(newFavorites);
        },
        loading: () => state,
        error: (e, s) => state,
      );
    } catch (e) {
      ref.invalidateSelf();
      rethrow;
    }
  }

  /// Remove a property from favorites
  Future<void> removeFavorite(String propertyId) async {
    final repository = ref.read(favoritesRepositoryProvider);

    try {
      await repository.removeFavorite(propertyId);

      // Update local state
      state = state.when(
        data: (favorites) {
          final newFavorites = Set<String>.from(favorites)..remove(propertyId);
          return AsyncData(newFavorites);
        },
        loading: () => state,
        error: (e, s) => state,
      );
    } catch (e) {
      ref.invalidateSelf();
      rethrow;
    }
  }
}

/// Provider for favorite properties with full details
@riverpod
Future<List<PropertyModel>> favoriteProperties(FavoritePropertiesRef ref) async {
  // Get favorite IDs
  final favoriteIds = await ref.watch(favoritesNotifierProvider.future);

  if (favoriteIds.isEmpty) {
    return [];
  }

  // Fetch property details for each favorite
  final searchRepo = ref.read(propertySearchRepositoryProvider);

  try {
    // Search with filters to get favorites
    // Note: This is not the most efficient way but works with existing API
    // Ideally we'd have a direct "get properties by IDs" method
    final allProperties = await searchRepo.searchProperties(const SearchFilters());

    // Filter to only include favorites
    return allProperties
        .where((property) => favoriteIds.contains(property.id))
        .toList();
  } catch (e) {
    throw Exception('Failed to fetch favorite properties: $e');
  }
}
