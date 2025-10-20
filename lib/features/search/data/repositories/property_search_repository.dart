import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/property_model.dart';
import '../../domain/models/search_filters.dart' as search;

part 'property_search_repository.g.dart';

/// Property search repository
class PropertySearchRepository {
  final SupabaseClient _supabase;

  PropertySearchRepository(this._supabase);

  /// Search properties with filters
  Future<List<PropertyModel>> searchProperties(search.SearchFilters filters) async {
    try {
      // Start with base query - simple properties query without inner join
      dynamic query = _supabase
          .from('properties')
          .select('*')
          .eq('is_active', true); // Only active properties

      // Apply location filter
      if (filters.location != null && filters.location!.isNotEmpty) {
        // Search in multiple location fields
        query = query.or(
          'city.ilike.%${filters.location}%,'
          'address.ilike.%${filters.location}%,'
          'location.ilike.%${filters.location}%'
        );
      }

      // Apply amenities filter (PostgreSQL array contains)
      if (filters.amenities.isNotEmpty) {
        query = query.contains('amenities', filters.amenities);
      }

      // Apply sorting (only property-level fields, not unit fields)
      switch (filters.sortBy) {
        case search.SortBy.priceLowToHigh:
        case search.SortBy.priceHighToLow:
          // Will sort by unit price in memory after fetching
          query = query.order('created_at', ascending: false);
          break;
        case search.SortBy.rating:
          query = query.order('rating', ascending: false);
          break;
        case search.SortBy.newest:
          query = query.order('created_at', ascending: false);
          break;
        case search.SortBy.recommended:
          // Default sorting: rating desc, then review_count desc
          query = query.order('rating', ascending: false);
          query = query.order('review_count', ascending: false);
          break;
      }

      // Apply reasonable limit to reduce over-fetching
      // We'll filter and paginate in memory, but start with fewer properties
      final initialLimit = filters.pageSize * 3; // Fetch 3 pages worth to account for filtering
      query = query.limit(initialLimit);

      // Execute query
      final response = await query;

      // Map to PropertyModel
      var properties = (response as List)
          .map((json) => PropertyModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Now filter by unit-specific criteria
      properties = await _filterByUnitCriteria(
        properties,
        guests: filters.guests,
        minPrice: filters.minPrice,
        maxPrice: filters.maxPrice,
        minBedrooms: filters.minBedrooms,
        minBathrooms: filters.minBathrooms,
        sortBy: filters.sortBy,
      );

      // Apply in-memory filters for complex logic
      var filtered = properties;

      // Filter by property type (based on name/description/property_type field)
      if (filters.propertyTypes.isNotEmpty) {
        filtered = filtered.where((property) {
          final nameLower = property.name.toLowerCase();
          final descLower = property.description.toLowerCase();
          final typeLower = property.propertyType.value.toLowerCase();

          return filters.propertyTypes.any((type) {
            switch (type) {
              case search.PropertyType.villa:
                return typeLower.contains('villa') ||
                    nameLower.contains('villa') ||
                    descLower.contains('villa');
              case search.PropertyType.apartment:
                return typeLower.contains('apartment') ||
                    typeLower.contains('apartman') ||
                    nameLower.contains('apartment') ||
                    nameLower.contains('apartman') ||
                    descLower.contains('apartment') ||
                    descLower.contains('apartman');
              case search.PropertyType.house:
                return typeLower.contains('house') ||
                    typeLower.contains('kuća') ||
                    typeLower.contains('kuca') ||
                    nameLower.contains('house') ||
                    nameLower.contains('kuća') ||
                    nameLower.contains('kuca') ||
                    descLower.contains('house') ||
                    descLower.contains('kuća') ||
                    descLower.contains('kuca');
              case search.PropertyType.studio:
                return typeLower.contains('studio') ||
                    nameLower.contains('studio') ||
                    descLower.contains('studio');
            }
          });
        }).toList();
      }

      // Filter by date availability (check if units are not booked)
      if (filters.checkIn != null && filters.checkOut != null) {
        filtered = await _filterByAvailability(
          filtered,
          filters.checkIn!,
          filters.checkOut!,
        );
      }

      // Apply pagination after all filtering
      final start = filters.page * filters.pageSize;
      final end = start + filters.pageSize;
      if (start < filtered.length) {
        filtered = filtered.sublist(
          start,
          end > filtered.length ? filtered.length : end,
        );
      } else {
        filtered = [];
      }

      return filtered;
    } catch (e) {
      throw Exception('Failed to search properties: $e');
    }
  }

  /// Filter properties by unit-specific criteria
  Future<List<PropertyModel>> _filterByUnitCriteria(
    List<PropertyModel> properties, {
    int guests = 0,
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    int? minBathrooms,
    required search.SortBy sortBy,
  }) async {
    try {
      if (properties.isEmpty) return properties;

      // Get property IDs
      final propertyIds = properties.map((p) => p.id).toList();

      // Fetch units for these properties
      final dynamic unitsQuery = _supabase
          .from('units')
          .select('id, property_id, base_price, max_guests, bedrooms, bathrooms, is_available')
          .inFilter('property_id', propertyIds)
          .eq('is_available', true);

      final unitsResponse = await unitsQuery;
      final units = unitsResponse as List;

      // Create a map of property_id -> list of units
      final Map<String, List<Map<String, dynamic>>> propertyUnitsMap = {};
      for (final unit in units) {
        final propertyId = unit['property_id'] as String;
        if (!propertyUnitsMap.containsKey(propertyId)) {
          propertyUnitsMap[propertyId] = [];
        }
        propertyUnitsMap[propertyId]!.add(unit as Map<String, dynamic>);
      }

      // Filter properties that have at least one unit matching criteria
      final filtered = properties.where((property) {
        final units = propertyUnitsMap[property.id];
        if (units == null || units.isEmpty) return false;

        // Check if any unit matches the criteria
        return units.any((unit) {
          // Guest capacity check
          if (guests > 0 && (unit['max_guests'] as int? ?? 0) < guests) {
            return false;
          }

          // Price range check
          final price = (unit['base_price'] as num?)?.toDouble();
          if (price != null) {
            if (minPrice != null && price < minPrice) return false;
            if (maxPrice != null && price > maxPrice) return false;
          }

          // Bedrooms check
          if (minBedrooms != null && (unit['bedrooms'] as int? ?? 0) < minBedrooms) {
            return false;
          }

          // Bathrooms check
          if (minBathrooms != null && (unit['bathrooms'] as int? ?? 0) < minBathrooms) {
            return false;
          }

          return true;
        });
      }).toList();

      // Sort by unit price if requested
      if (sortBy == search.SortBy.priceLowToHigh || sortBy == search.SortBy.priceHighToLow) {
        filtered.sort((a, b) {
          final aUnits = propertyUnitsMap[a.id] ?? [];
          final bUnits = propertyUnitsMap[b.id] ?? [];

          if (aUnits.isEmpty && bUnits.isEmpty) return 0;
          if (aUnits.isEmpty) return 1;
          if (bUnits.isEmpty) return -1;

          // Get minimum price from each property's units
          final aMinPrice = aUnits
              .map((u) => (u['base_price'] as num?)?.toDouble() ?? double.infinity)
              .reduce((a, b) => a < b ? a : b);
          final bMinPrice = bUnits
              .map((u) => (u['base_price'] as num?)?.toDouble() ?? double.infinity)
              .reduce((a, b) => a < b ? a : b);

          final comparison = aMinPrice.compareTo(bMinPrice);
          return sortBy == search.SortBy.priceLowToHigh ? comparison : -comparison;
        });
      }

      return filtered;
    } catch (e) {
      debugPrint('Warning: Failed to filter by unit criteria: $e');
      return properties; // Return unfiltered on error
    }
  }

  /// Filter properties by availability (exclude fully booked properties)
  Future<List<PropertyModel>> _filterByAvailability(
    List<PropertyModel> properties,
    DateTime checkIn,
    DateTime checkOut,
  ) async {
    try {
      // If no properties to filter, return early
      if (properties.isEmpty) return properties;

      // Extract property IDs
      final propertyIds = properties.map((p) => p.id).toList();

      // Step 1: Get all units for these properties
      final unitsResponse = await _supabase
          .from('units')
          .select('id, property_id, is_available')
          .inFilter('property_id', propertyIds)
          .eq('is_available', true); // Only consider available units

      // Create map of property_id -> list of unit IDs
      final Map<String, List<String>> propertyUnitsMap = {};
      for (final unit in unitsResponse as List) {
        final propertyId = unit['property_id'] as String;
        final unitId = unit['id'] as String;

        if (!propertyUnitsMap.containsKey(propertyId)) {
          propertyUnitsMap[propertyId] = [];
        }
        propertyUnitsMap[propertyId]!.add(unitId);
      }

      // Step 2: Get all bookings that overlap with the requested dates
      // A booking overlaps if: check_in < requestedCheckOut AND check_out > requestedCheckIn
      final bookingsResponse = await _supabase
          .from('bookings')
          .select('unit_id')
          .lte('check_in', checkOut.toIso8601String())
          .gte('check_out', checkIn.toIso8601String())
          .inFilter('status', ['confirmed', 'pending', 'blocked']);

      // Create set of booked unit IDs
      final Set<String> bookedUnitIds = (bookingsResponse as List)
          .map((booking) => booking['unit_id'] as String)
          .toSet();

      // Step 3: Filter properties that have at least one available unit
      final availableProperties = properties.where((property) {
        final unitIds = propertyUnitsMap[property.id];

        // If property has no units, exclude it
        if (unitIds == null || unitIds.isEmpty) {
          return false;
        }

        // Check if at least one unit is not booked
        final hasAvailableUnit = unitIds.any((unitId) => !bookedUnitIds.contains(unitId));

        return hasAvailableUnit;
      }).toList();

      return availableProperties;
    } catch (e) {
      // On error, return all properties (fail open to avoid blocking search)
      // Log error but don't throw to prevent blocking entire search
      debugPrint('Warning: Failed to filter by availability: $e');
      return properties;
    }
  }

  /// Get property by ID
  Future<PropertyModel?> getPropertyById(String id) async {
    try {
      final response = await _supabase
          .from('properties')
          .select('*')
          .eq('id', id)
          .single();

      return PropertyModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get featured properties (top rated)
  Future<List<PropertyModel>> getFeaturedProperties({int limit = 6}) async {
    try {
      final response = await _supabase
          .from('properties')
          .select('*')
          .eq('is_active', true) // Filter active properties at DB level
          .order('rating', ascending: false)
          .order('review_count', ascending: false)
          .limit(limit); // Only fetch what we need

      return (response as List)
          .map((json) => PropertyModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch featured properties: $e');
    }
  }
}

/// Provider for property search repository
@riverpod
PropertySearchRepository propertySearchRepository(
    Ref ref) {
  return PropertySearchRepository(Supabase.instance.client);
}
