import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/property_model.dart';

part 'recently_viewed_repository.g.dart';

/// Repository for managing recently viewed properties
class RecentlyViewedRepository {
  final SupabaseClient _supabase;

  RecentlyViewedRepository(this._supabase);

  /// Add a property view (or update timestamp if already exists)
  Future<void> addView(String userId, String propertyId) async {
    try {
      // Use upsert to insert or update the viewed_at timestamp
      await _supabase.from('recently_viewed').upsert({
        'user_id': userId,
        'property_id': propertyId,
        'viewed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,property_id');
    } catch (e) {
      throw Exception('Failed to add property view: $e');
    }
  }

  /// Get recently viewed properties for a user
  Future<List<PropertyModel>> getRecentlyViewed(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('recently_viewed')
          .select('''
            property_id,
            viewed_at,
            properties:property_id (
              id,
              title,
              description,
              price_per_night,
              location,
              property_type,
              image_url,
              images,
              amenities,
              guests,
              bedrooms,
              bathrooms,
              rating,
              review_count,
              owner_id,
              created_at,
              updated_at,
              profiles:owner_id (
                id,
                first_name,
                last_name,
                avatar_url
              )
            )
          ''')
          .eq('user_id', userId)
          .order('viewed_at', ascending: false)
          .limit(limit) as List<dynamic>;

      if (response.isEmpty) {
        return [];
      }

      final properties = <PropertyModel>[];

      for (final item in response) {
        if (item['properties'] != null) {
          try {
            final propertyData = item['properties'] as Map<String, dynamic>;

            // Extract owner data
            final ownerData = propertyData['profiles'];
            if (ownerData != null) {
              propertyData['owner_name'] =
                '${ownerData['first_name'] ?? ''} ${ownerData['last_name'] ?? ''}'.trim();
              propertyData['owner_avatar'] = ownerData['avatar_url'];
            }

            // Remove the profiles nested object
            propertyData.remove('profiles');

            final property = PropertyModel.fromJson(propertyData);
            properties.add(property);
          } catch (e) {
            // Skip invalid properties
            continue;
          }
        }
      }

      return properties;
    } catch (e) {
      throw Exception('Failed to get recently viewed properties: $e');
    }
  }

  /// Get recently viewed property IDs only (for checking if a property was viewed)
  Future<List<String>> getRecentlyViewedIds(String userId) async {
    try {
      final response = await _supabase
          .from('recently_viewed')
          .select('property_id')
          .eq('user_id', userId)
          .order('viewed_at', ascending: false) as List<dynamic>;

      if (response.isEmpty) {
        return [];
      }

      return response
          .map((item) => item['property_id'] as String)
          .toList();
    } catch (e) {
      throw Exception('Failed to get recently viewed IDs: $e');
    }
  }

  /// Clear all recently viewed properties for a user
  Future<void> clearHistory(String userId) async {
    try {
      await _supabase
          .from('recently_viewed')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to clear recently viewed history: $e');
    }
  }

  /// Remove a specific property from recently viewed
  Future<void> removeProperty(String userId, String propertyId) async {
    try {
      await _supabase
          .from('recently_viewed')
          .delete()
          .eq('user_id', userId)
          .eq('property_id', propertyId);
    } catch (e) {
      throw Exception('Failed to remove property from recently viewed: $e');
    }
  }

  /// Get count of recently viewed properties
  Future<int> getViewCount(String userId) async {
    try {
      final response = await _supabase
          .from('recently_viewed')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}

/// Provider for RecentlyViewedRepository
@riverpod
RecentlyViewedRepository recentlyViewedRepository(RecentlyViewedRepositoryRef ref) {
  return RecentlyViewedRepository(Supabase.instance.client);
}
