import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'user_stats_provider.g.dart';

/// Get user bookings count
@riverpod
Future<int> userBookingsCount(UserBookingsCountRef ref, String userId) async {
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase
        .from('bookings')
        .select('id')
        .eq('user_id', userId);

    return (response as List).length;
  } catch (e) {
    return 0;
  }
}

/// Get user favorites count
@riverpod
Future<int> userFavoritesCount(UserFavoritesCountRef ref, String userId) async {
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase
        .from('favorites')
        .select('id')
        .eq('user_id', userId);

    return (response as List).length;
  } catch (e) {
    return 0;
  }
}

/// Get user reviews count (reviews written by user)
@riverpod
Future<int> userReviewsCount(UserReviewsCountRef ref, String userId) async {
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase
        .from('reviews')
        .select('id')
        .eq('user_id', userId);

    return (response as List).length;
  } catch (e) {
    return 0;
  }
}

/// Get user average rating (for property owners)
@riverpod
Future<double?> userAverageRating(UserAverageRatingRef ref, String userId) async {
  final supabase = Supabase.instance.client;

  try {
    // Get all properties owned by user
    final propertiesResponse = await supabase
        .from('properties')
        .select('id')
        .eq('owner_id', userId);

    final properties = propertiesResponse as List;
    if (properties.isEmpty) return null;

    final propertyIds = properties.map((p) => p['id'] as String).toList();

    // Get all reviews for these properties
    final reviewsResponse = await supabase
        .from('reviews')
        .select('rating')
        .inFilter('property_id', propertyIds);

    final reviews = reviewsResponse as List;
    if (reviews.isEmpty) return null;

    // Calculate average
    final totalRating = reviews.fold<double>(
      0.0,
      (sum, review) => sum + (review['rating'] as num).toDouble(),
    );

    return totalRating / reviews.length;
  } catch (e) {
    return null;
  }
}
