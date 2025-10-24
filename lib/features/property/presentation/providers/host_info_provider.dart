import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../core/constants/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../shared/repositories/public_profile_repository.dart';

part 'host_info_provider.g.dart';
part 'host_info_provider.freezed.dart';

/// Host statistics model
@freezed
class HostStats with _$HostStats {
  const factory HostStats({
    required UserModel user,
    required int reviewCount,
    required double averageRating,
    required int propertyCount,
    required bool isSuperhost,
  }) = _HostStats;
}

/// Provider for host/owner information
@riverpod
Future<HostStats> hostInfo(
  Ref ref,
  String ownerId,
) async {
  final supabase = Supabase.instance.client;

  try {
    // Fetch user data using PublicProfileRepository
    final publicProfileRepo = ref.read(publicProfileRepositoryProvider);

    UserModel user;
    try {
      final profile = await publicProfileRepo.getPublicProfile(ownerId);

      if (profile != null) {
        // Convert PublicProfile to UserModel
        user = UserModel(
          id: profile.id,
          email: '', // Not available in public profile
          role: UserRole.fromString(profile.role),
          createdAt: DateTime.now(), // Not available in public profile
          firstName: profile.firstName,
          lastName: profile.lastName,
          avatarUrl: profile.avatarUrl,
        );
      } else {
        // Fallback: Create minimal user model if user not found
        user = UserModel(
          id: ownerId,
          email: 'owner@example.com',
          role: UserRole.owner,
          createdAt: DateTime.now(),
          firstName: 'Property',
          lastName: 'Owner',
        );
      }
    } catch (e) {
      // Fallback: Create minimal user model if error occurs
      user = UserModel(
        id: ownerId,
        email: 'owner@example.com',
        role: UserRole.owner,
        createdAt: DateTime.now(),
        firstName: 'Property',
        lastName: 'Owner',
      );
    }

    // Get count of properties owned by this user
    final propertiesResponse = await supabase
        .from('properties')
        .select('id')
        .eq('owner_id', ownerId);

    final propertyCount = (propertiesResponse as List).length;

    // Get all reviews for all properties owned by this user
    // First get all property IDs
    final propertyIds = (propertiesResponse as List)
        .map((p) => p['id'] as String)
        .toList();

    int reviewCount = 0;
    double averageRating = 0.0;

    if (propertyIds.isNotEmpty) {
      // Try to fetch reviews for all these properties
      try {
        final reviewsResponse = await supabase
            .from('reviews')
            .select('rating')
            .inFilter('property_id', propertyIds);

        final reviews = reviewsResponse as List;
        reviewCount = reviews.length;

        if (reviewCount > 0) {
          final totalRating = reviews.fold<double>(
            0.0,
            (sum, review) => sum + (review['rating'] as num).toDouble(),
          );
          averageRating = totalRating / reviewCount;
        }
      } catch (e) {
        // Reviews table doesn't exist or error - use defaults (0 reviews)
        reviewCount = 0;
        averageRating = 0.0;
      }
    }

    // Superhost criteria: 4.8+ rating and 10+ reviews
    final isSuperhost = averageRating >= 4.8 && reviewCount >= 10;

    return HostStats(
      user: user,
      reviewCount: reviewCount,
      averageRating: averageRating,
      propertyCount: propertyCount,
      isSuperhost: isSuperhost,
    );
  } catch (e) {
    throw Exception('Failed to load host info: $e');
  }
}
