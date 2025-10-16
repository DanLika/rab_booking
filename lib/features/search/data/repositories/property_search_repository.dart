import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/property_model.dart';
import '../../domain/models/search_filters.dart';

part 'property_search_repository.g.dart';

/// Property search repository
class PropertySearchRepository {
  final SupabaseClient _supabase;

  PropertySearchRepository(this._supabase);

  /// Search properties with filters
  Future<List<PropertyModel>> searchProperties(SearchFilters filters) async {
    try {
      // Start with base query
      var query = _supabase
          .from('properties')
          .select('*')
          .eq('is_active', true);

      // Apply location filter
      if (filters.location != null && filters.location!.isNotEmpty) {
        // Use ilike for case-insensitive partial match
        query = query.ilike('location', '%${filters.location}%');
      }

      // Apply price filter (requires joining with units table)
      // For now, we'll fetch all and filter in memory
      // TODO: Optimize with proper SQL join

      // Apply sorting
      switch (filters.sortBy) {
        case SortBy.priceLowToHigh:
          // Will sort after fetching (needs unit prices)
          break;
        case SortBy.priceHighToLow:
          // Will sort after fetching (needs unit prices)
          break;
        case SortBy.rating:
          query = query.order('rating', ascending: false);
          break;
        case SortBy.newest:
          query = query.order('created_at', ascending: false);
          break;
        case SortBy.recommended:
          // Default sorting: rating desc, then review_count desc
          query = query.order('rating', ascending: false);
          break;
      }

      // Apply pagination
      final start = filters.page * filters.pageSize;
      final end = start + filters.pageSize - 1;
      query = query.range(start, end);

      // Execute query
      final response = await query;

      // Map to PropertyModel
      final properties = (response as List)
          .map((json) => PropertyModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Apply in-memory filters
      var filtered = properties;

      // Filter by amenities
      if (filters.amenities.isNotEmpty) {
        filtered = filtered.where((property) {
          return filters.amenities.every(
            (amenity) => property.amenities.contains(amenity),
          );
        }).toList();
      }

      // Filter by property type (based on name/description keywords)
      if (filters.propertyTypes.isNotEmpty) {
        filtered = filtered.where((property) {
          final nameLower = property.name.toLowerCase();
          final descLower = property.description?.toLowerCase() ?? '';

          return filters.propertyTypes.any((type) {
            switch (type) {
              case PropertyType.villa:
                return nameLower.contains('villa');
              case PropertyType.apartment:
                return nameLower.contains('apartment') ||
                    nameLower.contains('apartman');
              case PropertyType.house:
                return nameLower.contains('house') ||
                    nameLower.contains('kuća') ||
                    nameLower.contains('kuca');
              case PropertyType.studio:
                return nameLower.contains('studio');
            }
          });
        }).toList();
      }

      return filtered;
    } catch (e) {
      throw Exception('Failed to search properties: $e');
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

      return PropertyModel.fromJson(response as Map<String, dynamic>);
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
          .eq('is_active', true)
          .order('rating', ascending: false)
          .order('review_count', ascending: false)
          .limit(limit);

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
    PropertySearchRepositoryRef ref) {
  return PropertySearchRepository(Supabase.instance.client);
}
