import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/public_profile.dart';

part 'public_profile_repository.g.dart';

/// Repository for fetching public user profiles (non-sensitive data only)
class PublicProfileRepository {
  final SupabaseClient _supabase;

  PublicProfileRepository(this._supabase);

  /// Get public profile by user ID
  /// Returns only non-sensitive information (name, avatar, role)
  /// Email and phone are NOT included for privacy
  Future<PublicProfile?> getPublicProfile(String userId) async {
    try {
      // Use the secure RPC function (SECURITY INVOKER)
      final response = await _supabase
          .rpc('get_public_profiles')
          .eq('id', userId)
          .single();

      return PublicProfile.fromJson(response);
    } catch (e) {
      // User not found or database error
      return null;
    }
  }

  /// Get multiple public profiles by user IDs
  /// Useful for displaying multiple owners/reviewers at once
  Future<List<PublicProfile>> getPublicProfiles(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    try {
      final response = await _supabase
          .rpc('get_public_profiles')
          .inFilter('id', userIds);

      return (response as List)
          .map((json) => PublicProfile.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get public profile using the safe SQL function (alternative method)
  /// This calls the PostgreSQL function directly for extra safety
  /// Note: This method is now identical to getPublicProfile since both use RPC
  Future<PublicProfile?> getPublicProfileSafe(String userId) async {
    try {
      final response = await _supabase
          .rpc('get_public_profiles')
          .eq('id', userId)
          .single();

      return PublicProfile.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}

/// Provider for PublicProfileRepository
@riverpod
PublicProfileRepository publicProfileRepository(Ref ref) {
  return PublicProfileRepository(Supabase.instance.client);
}

/// Provider for fetching a single public profile
@riverpod
Future<PublicProfile?> publicProfile(Ref ref, String userId) async {
  final repository = ref.watch(publicProfileRepositoryProvider);
  return await repository.getPublicProfile(userId);
}

/// Provider for fetching multiple public profiles
@riverpod
Future<List<PublicProfile>> publicProfiles(Ref ref, List<String> userIds) async {
  final repository = ref.watch(publicProfileRepositoryProvider);
  return await repository.getPublicProfiles(userIds);
}
