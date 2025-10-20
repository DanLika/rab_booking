import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/models/property_model.dart';
import '../../data/repositories/property_search_repository.dart';
import 'search_state_provider.dart';

part 'search_results_provider.g.dart';

/// Search results state
class SearchResultsState {
  final List<PropertyModel> properties;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const SearchResultsState({
    this.properties = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  SearchResultsState copyWith({
    List<PropertyModel>? properties,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return SearchResultsState(
      properties: properties ?? this.properties,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// Search results notifier with infinite scroll support
@riverpod
class SearchResultsNotifier extends _$SearchResultsNotifier {
  @override
  SearchResultsState build() {
    // Watch filters and reset on filter change
    ref.listen(searchFiltersNotifierProvider, (previous, next) {
      // If filters changed (but not just page increment), reset results
      if (previous != null &&
          (previous.location != next.location ||
           previous.checkIn != next.checkIn ||
           previous.checkOut != next.checkOut ||
           previous.guests != next.guests ||
           previous.minPrice != next.minPrice ||
           previous.maxPrice != next.maxPrice ||
           previous.propertyTypes != next.propertyTypes ||
           previous.amenities != next.amenities ||
           previous.minBedrooms != next.minBedrooms ||
           previous.minBathrooms != next.minBathrooms ||
           previous.sortBy != next.sortBy)) {
        // Reset and load first page
        _loadFirstPage();
      }
    });

    // Load initial results
    _loadFirstPage();
    return const SearchResultsState(isLoading: true);
  }

  Future<void> _loadFirstPage() async {
    state = const SearchResultsState(isLoading: true);

    try {
      final repository = ref.read(propertySearchRepositoryProvider);
      final filters = ref.read(searchFiltersNotifierProvider);

      final properties = await repository.searchProperties(filters);

      state = SearchResultsState(
        properties: properties,
        isLoading: false,
        hasMore: properties.length >= filters.pageSize,
      );
    } catch (e) {
      state = SearchResultsState(
        properties: const [],
        isLoading: false,
        hasMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final repository = ref.read(propertySearchRepositoryProvider);
      final filtersNotifier = ref.read(searchFiltersNotifierProvider.notifier);

      // Increment page
      await filtersNotifier.loadNextPage();
      final filters = ref.read(searchFiltersNotifierProvider);

      final newProperties = await repository.searchProperties(filters);

      state = SearchResultsState(
        properties: [...state.properties, ...newProperties],
        isLoading: false,
        hasMore: newProperties.length >= filters.pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void refresh() {
    // Reset to first page
    ref.read(searchFiltersNotifierProvider.notifier).resetPagination();
    _loadFirstPage();
  }
}

/// Search results count provider
@riverpod
int searchResultsCount(Ref ref) {
  final state = ref.watch(searchResultsNotifierProvider);
  return state.properties.length;
}
