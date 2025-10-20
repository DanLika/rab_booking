import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_filters.freezed.dart';
part 'search_filters.g.dart';

/// Search filters model
@freezed
class SearchFilters with _$SearchFilters {
  const factory SearchFilters({
    // Location & dates (from search bar)
    String? location,
    DateTime? checkIn,
    DateTime? checkOut,
    @Default(2) int guests,

    // Price range
    double? minPrice,
    double? maxPrice,

    // Property type
    @Default([]) List<PropertyType> propertyTypes,

    // Single property type filter (for saved searches)
    String? propertyType,

    // Amenities
    @Default([]) List<String> amenities,

    // Minimum rating filter
    double? minRating,

    // Bedrooms & bathrooms
    int? minBedrooms,
    int? minBathrooms,

    // Sorting
    @Default(SortBy.recommended) SortBy sortBy,

    // Pagination
    @Default(0) int page,
    @Default(20) int pageSize,
  }) = _SearchFilters;

  const SearchFilters._();

  factory SearchFilters.fromJson(Map<String, dynamic> json) =>
      _$SearchFiltersFromJson(json);

  /// Check if any filters are active (excluding default search params)
  bool get hasActiveFilters {
    return minPrice != null ||
        maxPrice != null ||
        propertyTypes.isNotEmpty ||
        amenities.isNotEmpty ||
        minBedrooms != null ||
        minBathrooms != null;
  }

  /// Get filter count (for badge)
  int get filterCount {
    int count = 0;
    if (minPrice != null || maxPrice != null) count++;
    if (propertyTypes.isNotEmpty) count++;
    if (amenities.isNotEmpty) count += amenities.length;
    if (minBedrooms != null) count++;
    if (minBathrooms != null) count++;
    return count;
  }

  /// Clear all filters (keep location, dates, guests)
  SearchFilters clearFilters() {
    return copyWith(
      minPrice: null,
      maxPrice: null,
      propertyTypes: [],
      amenities: [],
      minBedrooms: null,
      minBathrooms: null,
      sortBy: SortBy.recommended,
    );
  }
}

/// Property type enum
enum PropertyType {
  villa,
  apartment,
  house,
  studio;

  String get displayName {
    switch (this) {
      case PropertyType.villa:
        return 'Villa';
      case PropertyType.apartment:
        return 'Apartman';
      case PropertyType.house:
        return 'Kuća';
      case PropertyType.studio:
        return 'Studio';
    }
  }
}

/// Sort by enum
enum SortBy {
  recommended,
  priceLowToHigh,
  priceHighToLow,
  rating,
  newest;

  String get displayName {
    switch (this) {
      case SortBy.recommended:
        return 'Preporučeno';
      case SortBy.priceLowToHigh:
        return 'Cijena (niska do visoka)';
      case SortBy.priceHighToLow:
        return 'Cijena (visoka do niska)';
      case SortBy.rating:
        return 'Ocjena';
      case SortBy.newest:
        return 'Najnovije';
    }
  }
}

/// Common amenities list
const commonAmenities = [
  'wifi',
  'parking',
  'pool',
  'air_conditioning',
  'kitchen',
  'sea_view',
  'balcony',
  'bbq',
  'beach_access',
  'pet_friendly',
  'fireplace',
];

/// Amenity display names
String getAmenityDisplayName(String amenity) {
  final map = {
    'wifi': 'WiFi',
    'parking': 'Parking',
    'pool': 'Bazen',
    'air_conditioning': 'Klima',
    'kitchen': 'Kuhinja',
    'sea_view': 'Pogled na more',
    'balcony': 'Balkon',
    'bbq': 'Roštilj',
    'beach_access': 'Pristup plaži',
    'pet_friendly': 'Dozvoljeni kućni ljubimci',
    'fireplace': 'Kamin',
  };
  return map[amenity] ?? amenity;
}
