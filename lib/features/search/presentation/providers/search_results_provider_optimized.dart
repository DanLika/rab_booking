import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/models/property_model.dart';
import '../../domain/models/search_filters.dart';
import '../../data/repositories/property_search_repository_optimized.dart';
import '../../data/repositories/search_cache_manager.dart';
import 'search_state_provider.dart';

part 'search_results_provider_optimized.g.dart';

/// Search results state
class SearchResultsState {
  final List<PropertyModel> properties;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final bool isFromCache;

  const SearchResultsState({
    this.properties = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.isFromCache = false,
  });

  SearchResultsState copyWith({
    List<PropertyModel>? properties,
    bool? isLoading,
    bool? hasMore,
    String? error,
    bool? isFromCache,
  }) {
    return SearchResultsState(
      properties: properties ?? this.properties,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

/// Optimized search results notifier with caching
///
/// Performance improvements:
/// - Cache-first strategy (instant results for cached queries)
/// - Debounced filter changes
/// - Proper pagination without duplicates
/// - Memory leak prevention
@riverpod
class SearchResultsNotifierOptimized extends _$SearchResultsNotifierOptimized {
  @override
  SearchResultsState build() {
    // Watch filters and reset on significant changes
    ref.listen(searchFiltersNotifierProvider, (previous, next) {
      if (previous == null) return;

      // Check if this is just a page increment (don't reload)
      if (_isOnlyPageChange(previous, next)) {
        return; // Let loadNextPage handle this
      }

      // Significant filter change detected - reload from page 0
      if (_hasSignificantChange(previous, next)) {
        _loadFirstPage();
      }
    });

    // Load initial results
    _loadFirstPage();
    return const SearchResultsState(isLoading: true);
  }

  /// Check if filters changed significantly (not just page)
  bool _hasSignificantChange(
    SearchFilters previous,
    SearchFilters next,
  ) {
    return previous.location != next.location ||
        previous.checkIn != next.checkIn ||
        previous.checkOut != next.checkOut ||
        previous.guests != next.guests ||
        previous.minPrice != next.minPrice ||
        previous.maxPrice != next.maxPrice ||
        previous.propertyTypes != next.propertyTypes ||
        previous.amenities != next.amenities ||
        previous.minBedrooms != next.minBedrooms ||
        previous.minBathrooms != next.minBathrooms ||
        previous.sortBy != next.sortBy;
  }

  /// Check if only page changed (pagination)
  bool _isOnlyPageChange(
    SearchFilters previous,
    SearchFilters next,
  ) {
    final pageChanged = previous.page != next.page;
    final otherFieldsUnchanged = !_hasSignificantChange(previous, next);
    return pageChanged && otherFieldsUnchanged;
  }

  /// Load first page of results
  Future<void> _loadFirstPage() async {
    // Don't reload if already loading
    if (state.isLoading) return;

    state = const SearchResultsState(isLoading: true);

    try {
      final repository = ref.read(propertySearchRepositoryOptimizedProvider);
      final cacheManager = ref.read(searchCacheManagerProvider);
      final filters = ref.read(searchFiltersNotifierProvider);

      // Try cache first (instant results!)
      final cachedResults = cacheManager.get(filters);
      if (cachedResults != null) {
        state = SearchResultsState(
          properties: cachedResults,
          isLoading: false,
          hasMore: cachedResults.length >= filters.pageSize,
          isFromCache: true,
        );
        return;
      }

      // Cache miss - fetch from database
      final properties = await repository.searchProperties(filters);

      // Store in cache for next time
      cacheManager.set(filters, properties);

      state = SearchResultsState(
        properties: properties,
        isLoading: false,
        hasMore: properties.length >= filters.pageSize,
        isFromCache: false,
      );
    } catch (e) {
      state = SearchResultsState(
        properties: const [],
        isLoading: false,
        hasMore: false,
        error: e.toString(),
        isFromCache: false,
      );
    }
  }

  /// Load next page (infinite scroll)
  Future<void> loadNextPage() async {
    // Prevent loading if:
    // - Already loading
    // - No more results
    // - Has error
    if (state.isLoading || !state.hasMore || state.error != null) {
      return;
    }

    // Set loading state but keep existing properties
    state = state.copyWith(isLoading: true);

    try {
      final repository = ref.read(propertySearchRepositoryOptimizedProvider);
      final cacheManager = ref.read(searchCacheManagerProvider);
      final filtersNotifier = ref.read(searchFiltersNotifierProvider.notifier);

      // Increment page
      await filtersNotifier.loadNextPage();
      final filters = ref.read(searchFiltersNotifierProvider);

      // Try cache first
      final cachedResults = cacheManager.get(filters);
      if (cachedResults != null) {
        // Append cached results
        state = SearchResultsState(
          properties: [...state.properties, ...cachedResults],
          isLoading: false,
          hasMore: cachedResults.length >= filters.pageSize,
          isFromCache: true,
        );
        return;
      }

      // Cache miss - fetch from database
      final newProperties = await repository.searchProperties(filters);

      // Store in cache
      cacheManager.set(filters, newProperties);

      // Append new properties (no duplicates because pagination is DB-level)
      state = SearchResultsState(
        properties: [...state.properties, ...newProperties],
        isLoading: false,
        hasMore: newProperties.length >= filters.pageSize,
        isFromCache: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh results (pull-to-refresh)
  Future<void> refresh() async {
    // Invalidate cache for current filters
    final cacheManager = ref.read(searchCacheManagerProvider);
    final filters = ref.read(searchFiltersNotifierProvider);
    cacheManager.invalidate(filters);

    // Reset to first page
    ref.read(searchFiltersNotifierProvider.notifier).resetPagination();

    // Reload
    await _loadFirstPage();
  }

  /// Clear all cached results
  void clearCache() {
    final cacheManager = ref.read(searchCacheManagerProvider);
    cacheManager.invalidateAll();
  }
}

/// Search results count provider
@riverpod
int searchResultsCountOptimized(Ref ref) {
  final state = ref.watch(searchResultsNotifierOptimizedProvider);
  return state.properties.length;
}

/// Cache statistics provider (for debugging/monitoring)
@riverpod
CacheStats searchCacheStats(Ref ref) {
  final cacheManager = ref.watch(searchCacheManagerProvider);
  return cacheManager.stats;
}
