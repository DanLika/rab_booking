import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/property_model.dart';

part 'similar_properties_repository.g.dart';

/// Repository for fetching similar properties based on recommendation algorithm
@riverpod
SimilarPropertiesRepository similarPropertiesRepository(
  SimilarPropertiesRepositoryRef ref,
) {
  return SimilarPropertiesRepository(Supabase.instance.client);
}

/// Similar Properties Repository
class SimilarPropertiesRepository {
  const SimilarPropertiesRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Get similar properties based on location, price, and type
  ///
  /// Algorithm:
  /// 1. Same city/location (exact match)
  /// 2. Price range ±30% of current property
  /// 3. Same property type
  /// 4. Exclude the current property
  /// 5. Order by rating (highest first)
  /// 6. Limit to specified number (default 6)
  Future<List<PropertyModel>> getSimilarProperties({
    required String propertyId,
    required String location,
    required String propertyType,
    required double basePrice,
    int limit = 6,
  }) async {
    try {
      // Calculate price range (±30%)
      final minPrice = basePrice * 0.7;
      final maxPrice = basePrice * 1.3;

      // Build query
      var query = _supabase
          .from('properties')
          .select('''
            *,
            units!inner(base_price)
          ''')
          .neq('id', propertyId) // Exclude current property
          .eq('property_type', propertyType)
          .eq('location', location)
          .order('rating', ascending: false)
          .limit(limit);

      final response = await query;

      // Parse and filter properties
      final properties = <PropertyModel>[];

      for (final item in response as List) {
        try {
          // Get the minimum base_price from units
          final units = item['units'] as List;
          if (units.isEmpty) continue;

          double minUnitPrice = double.infinity;
          for (final unit in units) {
            final price = (unit['base_price'] as num?)?.toDouble();
            if (price != null && price < minUnitPrice) {
              minUnitPrice = price;
            }
          }

          // Filter by price range
          if (minUnitPrice >= minPrice && minUnitPrice <= maxPrice) {
            // Create property without units array
            final propertyData = Map<String, dynamic>.from(item);
            propertyData.remove('units');

            final property = PropertyModel.fromJson(propertyData);
            properties.add(property);
          }
        } catch (e) {
          // Skip properties that fail to parse
          continue;
        }
      }

      return properties;
    } catch (e) {
      throw Exception('Failed to load similar properties: $e');
    }
  }

  /// Get similar properties with fallback strategy
  ///
  /// If not enough properties found with strict criteria:
  /// 1. Try relaxing price range to ±50%
  /// 2. Try same region (broader location match)
  /// 3. Try same property type only
  Future<List<PropertyModel>> getSimilarPropertiesWithFallback({
    required String propertyId,
    required String location,
    required String propertyType,
    required double basePrice,
    int limit = 6,
  }) async {
    // Try strict matching first
    var results = await getSimilarProperties(
      propertyId: propertyId,
      location: location,
      propertyType: propertyType,
      basePrice: basePrice,
      limit: limit,
    );

    // If we have enough results, return them
    if (results.length >= 3) {
      return results;
    }

    // Fallback 1: Relax price range (±50%)
    try {
      final minPrice = basePrice * 0.5;
      final maxPrice = basePrice * 1.5;

      var query = _supabase
          .from('properties')
          .select('''
            *,
            units!inner(base_price)
          ''')
          .neq('id', propertyId)
          .eq('property_type', propertyType)
          .eq('location', location)
          .order('rating', ascending: false)
          .limit(limit);

      final response = await query;

      for (final item in response as List) {
        try {
          final units = item['units'] as List;
          if (units.isEmpty) continue;

          double minUnitPrice = double.infinity;
          for (final unit in units) {
            final price = (unit['base_price'] as num?)?.toDouble();
            if (price != null && price < minUnitPrice) {
              minUnitPrice = price;
            }
          }

          if (minUnitPrice >= minPrice && minUnitPrice <= maxPrice) {
            final propertyData = Map<String, dynamic>.from(item);
            propertyData.remove('units');

            final property = PropertyModel.fromJson(propertyData);
            if (!results.any((p) => p.id == property.id)) {
              results.add(property);
            }
          }
        } catch (e) {
          continue;
        }
      }

      if (results.length >= 3) {
        return results.take(limit).toList();
      }
    } catch (e) {
      // Continue to next fallback
    }

    // Fallback 2: Same property type only (any price, any location)
    try {
      final response = await _supabase
          .from('properties')
          .select('*')
          .neq('id', propertyId)
          .eq('property_type', propertyType)
          .order('rating', ascending: false)
          .limit(limit);

      for (final item in response as List) {
        try {
          final property = PropertyModel.fromJson(item);
          if (!results.any((p) => p.id == property.id)) {
            results.add(property);
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      // Return whatever we have
    }

    return results.take(limit).toList();
  }
}
