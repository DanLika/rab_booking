import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'favorites_repository.g.dart';

/// Repository for managing user favorites
@riverpod
FavoritesRepository favoritesRepository(Ref ref) {
  return FavoritesRepository(Supabase.instance.client);
}

class FavoritesRepository {
  FavoritesRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Get all favorite property IDs for current user
  Future<Set<String>> getFavoriteIds() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await _supabase
          .from('favorites')
          .select('property_id')
          .eq('user_id', userId);

      return (response as List<dynamic>)
          .map((item) => item['property_id'] as String)
          .toSet();
    } catch (e) {
      // Return empty set on error (user not logged in or network error)
      return {};
    }
  }

  /// Check if a specific property is favorited
  Future<bool> isFavorite(String propertyId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('property_id', propertyId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Add property to favorites
  Future<void> addFavorite(String propertyId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be logged in to favorite properties');
    }

    await _supabase.from('favorites').insert({
      'user_id': userId,
      'property_id': propertyId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Remove property from favorites
  Future<void> removeFavorite(String propertyId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('property_id', propertyId);
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String propertyId) async {
    final isFav = await isFavorite(propertyId);

    if (isFav) {
      await removeFavorite(propertyId);
      return false;
    } else {
      await addFavorite(propertyId);
      return true;
    }
  }
}
