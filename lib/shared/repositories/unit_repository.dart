import '../models/unit_model.dart';

/// Abstract unit repository interface
abstract class UnitRepository {
  /// Get unit by ID
  Future<UnitModel?> fetchUnitById(String id);

  /// Get units by property ID
  Future<List<UnitModel>> fetchUnitsByProperty(String propertyId);

  /// Get available units by property ID and date range
  Future<List<UnitModel>> fetchAvailableUnits({
    required String propertyId,
    required DateTime checkIn,
    required DateTime checkOut,
  });

  /// Create new unit
  Future<UnitModel> createUnit(UnitModel unit);

  /// Update unit
  Future<UnitModel> updateUnit(UnitModel unit);

  /// Delete unit
  Future<void> deleteUnit(String id);

  /// Toggle unit availability
  Future<UnitModel> toggleUnitAvailability(String id, bool isAvailable);

  /// Update unit price
  Future<UnitModel> updateUnitPrice(String id, double pricePerNight);

  /// Check if unit is available for date range
  Future<bool> isUnitAvailable({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  });

  /// Get units filtered by criteria
  Future<List<UnitModel>> fetchFilteredUnits({
    String? propertyId,
    double? maxPrice,
    int? minGuests,
    bool? availableOnly,
  });

  /// Update sort order for multiple units (for drag-and-drop reordering)
  Future<void> updateUnitsSortOrder(List<UnitModel> units);

  /// Get unit by slug within a property (for widget URL slug resolution)
  Future<UnitModel?> fetchUnitBySlug(String propertyId, String slug);

  /// Check if slug is unique within property (for validation)
  Future<bool> isSlugUniqueInProperty(
    String propertyId,
    String slug, {
    String? excludeUnitId,
  });

  /// Get unit by ID with forced server fetch (bypasses cache)
  ///
  /// IMPORTANT: Use this for booking price calculations to ensure fresh data.
  /// This prevents price mismatch errors caused by stale cached unit data.
  ///
  /// Requires [propertyId] for efficient direct path query.
  Future<UnitModel?> fetchUnitByIdFresh({
    required String unitId,
    required String propertyId,
  });
}
