import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/search_filters.dart';

part 'search_state_provider.g.dart';

/// Search filters state notifier
@riverpod
class SearchFiltersNotifier extends _$SearchFiltersNotifier {
  @override
  SearchFilters build() {
    return const SearchFilters();
  }

  /// Initialize from query parameters
  void initializeFromParams({
    String? location,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
  }) {
    state = state.copyWith(
      location: location,
      checkIn: checkIn,
      checkOut: checkOut,
      guests: guests ?? 2,
    );
  }

  /// Update location
  void updateLocation(String? location) {
    state = state.copyWith(location: location);
  }

  /// Update dates
  void updateDates(DateTime? checkIn, DateTime? checkOut) {
    state = state.copyWith(checkIn: checkIn, checkOut: checkOut);
  }

  /// Update guests
  void updateGuests(int guests) {
    state = state.copyWith(guests: guests);
  }

  /// Update price range
  void updatePriceRange(double? min, double? max) {
    state = state.copyWith(minPrice: min, maxPrice: max);
  }

  /// Toggle property type
  void togglePropertyType(PropertyType type) {
    final current = List<PropertyType>.from(state.propertyTypes);
    if (current.contains(type)) {
      current.remove(type);
    } else {
      current.add(type);
    }
    state = state.copyWith(propertyTypes: current);
  }

  /// Toggle amenity
  void toggleAmenity(String amenity) {
    final current = List<String>.from(state.amenities);
    if (current.contains(amenity)) {
      current.remove(amenity);
    } else {
      current.add(amenity);
    }
    state = state.copyWith(amenities: current);
  }

  /// Update bedrooms
  void updateMinBedrooms(int? bedrooms) {
    state = state.copyWith(minBedrooms: bedrooms);
  }

  /// Update bathrooms
  void updateMinBathrooms(int? bathrooms) {
    state = state.copyWith(minBathrooms: bathrooms);
  }

  /// Update sort by
  void updateSortBy(SortBy sortBy) {
    state = state.copyWith(sortBy: sortBy, page: 0); // Reset page on sort change
  }

  /// Load next page
  Future<void> loadNextPage() async {
    state = state.copyWith(page: state.page + 1);
  }

  /// Reset pagination
  void resetPagination() {
    state = state.copyWith(page: 0);
  }

  /// Clear all filters
  void clearFilters() {
    state = state.clearFilters();
    resetPagination();
  }

  /// Apply filters (triggers new search)
  void applyFilters() {
    resetPagination();
    // This will trigger SearchResultsProvider to refetch
  }
}
