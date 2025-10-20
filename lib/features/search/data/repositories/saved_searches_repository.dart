import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/saved_search.dart';
import '../../domain/models/search_filters.dart';

part 'saved_searches_repository.g.dart';

/// Provider for saved searches repository
@riverpod
SavedSearchesRepository savedSearchesRepository(Ref ref) {
  return SavedSearchesRepository(Supabase.instance.client);
}

/// Repository for managing saved searches
class SavedSearchesRepository {
  final SupabaseClient _supabase;

  SavedSearchesRepository(this._supabase);

  /// Get all saved searches for a user
  Future<List<SavedSearch>> getSavedSearches(String userId) async {
    try {
      final response = await _supabase
          .from('saved_searches')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false) as List<dynamic>;

      if (response.isEmpty) {
        return [];
      }

      return response.map((item) {
        // Parse filters from JSONB
        final filtersJson = item['filters'] as Map<String, dynamic>;
        item['filters'] = SearchFilters.fromJson(filtersJson);

        return SavedSearch.fromJson(item);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get saved searches: $e');
    }
  }

  /// Save a new search
  Future<SavedSearch> saveSearch({
    required String userId,
    required String name,
    required SearchFilters filters,
    bool notificationEnabled = false,
  }) async {
    try {
      final response = await _supabase
          .from('saved_searches')
          .insert({
            'user_id': userId,
            'name': name,
            'filters': filters.toJson(),
            'notification_enabled': notificationEnabled,
          })
          .select()
          .single();

      // Parse filters from JSONB
      final filtersJson = response['filters'] as Map<String, dynamic>;
      response['filters'] = SearchFilters.fromJson(filtersJson);

      return SavedSearch.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save search: $e');
    }
  }

  /// Update a saved search
  Future<SavedSearch> updateSearch({
    required String searchId,
    String? name,
    SearchFilters? filters,
    bool? notificationEnabled,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (filters != null) updates['filters'] = filters.toJson();
      if (notificationEnabled != null) {
        updates['notification_enabled'] = notificationEnabled;
      }

      final response = await _supabase
          .from('saved_searches')
          .update(updates)
          .eq('id', searchId)
          .select()
          .single();

      // Parse filters from JSONB
      final filtersJson = response['filters'] as Map<String, dynamic>;
      response['filters'] = SearchFilters.fromJson(filtersJson);

      return SavedSearch.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update search: $e');
    }
  }

  /// Delete a saved search
  Future<void> deleteSearch(String searchId) async {
    try {
      await _supabase
          .from('saved_searches')
          .delete()
          .eq('id', searchId);
    } catch (e) {
      throw Exception('Failed to delete search: $e');
    }
  }

  /// Get count of saved searches for a user
  Future<int> getSavedSearchesCount(String userId) async {
    try {
      final response = await _supabase
          .from('saved_searches')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Check if a search with the same filters already exists
  Future<SavedSearch?> findDuplicate({
    required String userId,
    required SearchFilters filters,
  }) async {
    try {
      final allSearches = await getSavedSearches(userId);

      // Compare filters manually since JSONB comparison is complex
      for (final search in allSearches) {
        if (_filtersMatch(search.filters, filters)) {
          return search;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Helper to compare two SearchFilters for equality
  bool _filtersMatch(SearchFilters a, SearchFilters b) {
    return a.location == b.location &&
        a.checkIn == b.checkIn &&
        a.checkOut == b.checkOut &&
        a.guests == b.guests &&
        a.minPrice == b.minPrice &&
        a.maxPrice == b.maxPrice &&
        a.propertyType == b.propertyType &&
        a.minRating == b.minRating &&
        a.sortBy == b.sortBy;
  }
}
