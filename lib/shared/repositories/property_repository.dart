import '../models/property_model.dart';
import '../../core/constants/enums.dart';

/// Filters for property search
class PropertyFilters {
  const PropertyFilters({
    this.location,
    this.minPrice,
    this.maxPrice,
    this.amenities,
    this.minGuests,
    this.minRating,
    this.ownerId,
  });

  final String? location;
  final double? minPrice;
  final double? maxPrice;
  final List<PropertyAmenity>? amenities;
  final int? minGuests;
  final double? minRating;
  final String? ownerId;

  /// Check if any filters are applied
  bool get hasFilters =>
      location != null ||
      minPrice != null ||
      maxPrice != null ||
      amenities != null ||
      minGuests != null ||
      minRating != null ||
      ownerId != null;
}

/// Abstract property repository interface
abstract class PropertyRepository {
  /// Get all properties with optional filters
  Future<List<PropertyModel>> fetchProperties([PropertyFilters? filters]);

  /// Get property by ID
  Future<PropertyModel?> fetchPropertyById(String id);

  /// Get properties by owner ID
  Future<List<PropertyModel>> fetchPropertiesByOwner(String ownerId);

  /// Create new property
  Future<PropertyModel> createProperty(PropertyModel property);

  /// Update property
  Future<PropertyModel> updateProperty(PropertyModel property);

  /// Delete property
  Future<void> deleteProperty(String id);

  /// Search properties by query string
  Future<List<PropertyModel>> searchProperties(String query);

  /// Get featured properties (high rating, popular)
  Future<List<PropertyModel>> getFeaturedProperties({int limit = 10});

  /// Get nearby properties (by coordinates)
  Future<List<PropertyModel>> getNearbyProperties({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  });

  /// Toggle property active status
  Future<PropertyModel> togglePropertyStatus(String id, bool isActive);

  /// Update property rating
  Future<PropertyModel> updatePropertyRating(
    String id,
    double rating,
    int reviewCount,
  );

  /// Get property by subdomain (for widget URL slug resolution)
  Future<PropertyModel?> fetchPropertyBySubdomain(String subdomain);
}
