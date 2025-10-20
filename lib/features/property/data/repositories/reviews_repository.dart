import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'reviews_repository.freezed.dart';
part 'reviews_repository.g.dart';

/// Review model
@freezed
class PropertyReview with _$PropertyReview {
  const factory PropertyReview({
    required String id,
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'booking_id') String? bookingId,
    required int rating,
    required String comment,
    @JsonKey(name: 'cleanliness_rating') int? cleanlinessRating,
    @JsonKey(name: 'communication_rating') int? communicationRating,
    @JsonKey(name: 'checkin_rating') int? checkinRating,
    @JsonKey(name: 'accuracy_rating') int? accuracyRating,
    @JsonKey(name: 'location_rating') int? locationRating,
    @JsonKey(name: 'value_rating') int? valueRating,
    @JsonKey(name: 'host_response') String? hostResponse,
    @JsonKey(name: 'host_response_at') DateTime? hostResponseAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    // User info (joined from users table)
    @JsonKey(name: 'user_name') String? userName,
    @JsonKey(name: 'user_avatar') String? userAvatar,
  }) = _PropertyReview;

  factory PropertyReview.fromJson(Map<String, dynamic> json) =>
      _$PropertyReviewFromJson(json);
}

/// Rating breakdown model
@freezed
class RatingBreakdown with _$RatingBreakdown {
  const factory RatingBreakdown({
    required double overall,
    required double cleanliness,
    required double communication,
    required double checkin,
    required double accuracy,
    required double location,
    required double value,
  }) = _RatingBreakdown;
}

/// Reviews repository
class ReviewsRepository {
  final SupabaseClient _supabase;

  ReviewsRepository(this._supabase);

  /// Get all reviews for a property
  Future<List<PropertyReview>> getPropertyReviews(
    String propertyId, {
    int? limit,
    int? offset,
    String? sortBy, // 'recent', 'oldest', 'highest', 'lowest'
    int? filterByRating,
  }) async {
    try {
      dynamic query = _supabase
          .from('reviews')
          .select('''
            *,
            users!inner(
              id,
              first_name,
              last_name,
              avatar_url
            )
          ''')
          .eq('property_id', propertyId);

      // Apply rating filter
      if (filterByRating != null) {
        query = query.eq('rating', filterByRating);
      }

      // Apply sorting
      switch (sortBy) {
        case 'oldest':
          query = query.order('created_at', ascending: true);
          break;
        case 'highest':
          query = query.order('rating', ascending: false);
          break;
        case 'lowest':
          query = query.order('rating', ascending: true);
          break;
        case 'recent':
        default:
          query = query.order('created_at', ascending: false);
      }

      // Apply pagination
      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await query;

      return (response as List).map((json) {
        // Map user data to review
        final userData = json['users'] as Map<String, dynamic>?;
        final reviewData = Map<String, dynamic>.from(json);

        if (userData != null) {
          reviewData['user_name'] = '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
          reviewData['user_avatar'] = userData['avatar_url'];
        }

        return PropertyReview.fromJson(reviewData);
      }).toList();
    } catch (e) {
      // Return empty list if reviews table doesn't exist or other errors
      // This allows the app to continue working without reviews
      return [];
    }
  }

  /// Get rating breakdown for a property
  Future<RatingBreakdown> getRatingBreakdown(String propertyId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select(
              'rating, cleanliness_rating, communication_rating, checkin_rating, accuracy_rating, location_rating, value_rating')
          .eq('property_id', propertyId);

      if (response.isEmpty) {
        return const RatingBreakdown(
          overall: 0,
          cleanliness: 0,
          communication: 0,
          checkin: 0,
          accuracy: 0,
          location: 0,
          value: 0,
        );
      }

      final reviews = response as List;
      final count = reviews.length;

      double sumOverall = 0;
      double sumCleanliness = 0;
      double sumCommunication = 0;
      double sumCheckin = 0;
      double sumAccuracy = 0;
      double sumLocation = 0;
      double sumValue = 0;

      for (final review in reviews) {
        sumOverall += (review['rating'] as num).toDouble();
        sumCleanliness += (review['cleanliness_rating'] as num?)?.toDouble() ?? 0;
        sumCommunication +=
            (review['communication_rating'] as num?)?.toDouble() ?? 0;
        sumCheckin += (review['checkin_rating'] as num?)?.toDouble() ?? 0;
        sumAccuracy += (review['accuracy_rating'] as num?)?.toDouble() ?? 0;
        sumLocation += (review['location_rating'] as num?)?.toDouble() ?? 0;
        sumValue += (review['value_rating'] as num?)?.toDouble() ?? 0;
      }

      return RatingBreakdown(
        overall: sumOverall / count,
        cleanliness: sumCleanliness / count,
        communication: sumCommunication / count,
        checkin: sumCheckin / count,
        accuracy: sumAccuracy / count,
        location: sumLocation / count,
        value: sumValue / count,
      );
    } catch (e) {
      throw Exception('Failed to fetch rating breakdown: $e');
    }
  }

  /// Get review count for a property
  Future<int> getReviewCount(String propertyId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('id')
          .eq('property_id', propertyId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get rating distribution (count per star)
  Future<Map<int, int>> getRatingDistribution(String propertyId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('rating')
          .eq('property_id', propertyId);

      final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final review in response as List) {
        final rating = (review['rating'] as num).toInt();
        distribution[rating] = (distribution[rating] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    }
  }

  /// Create a new review
  Future<PropertyReview> createReview({
    required String propertyId,
    required String bookingId,
    required int rating,
    required String comment,
    int? cleanlinessRating,
    int? communicationRating,
    int? checkinRating,
    int? accuracyRating,
    int? locationRating,
    int? valueRating,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate rating (1-5)
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      final reviewData = {
        'property_id': propertyId,
        'user_id': user.id,
        'booking_id': bookingId,
        'rating': rating,
        'comment': comment,
        'cleanliness_rating': cleanlinessRating,
        'communication_rating': communicationRating,
        'checkin_rating': checkinRating,
        'accuracy_rating': accuracyRating,
        'location_rating': locationRating,
        'value_rating': valueRating,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('reviews')
          .insert(reviewData)
          .select('''
            *,
            users!inner(
              id,
              first_name,
              last_name,
              avatar_url
            )
          ''')
          .single();

      // Map user data
      final userData = response['users'] as Map<String, dynamic>?;
      final mappedData = Map<String, dynamic>.from(response);

      if (userData != null) {
        mappedData['user_name'] =
            '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'
                .trim();
        mappedData['user_avatar'] = userData['avatar_url'];
      }

      return PropertyReview.fromJson(mappedData);
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  /// Update an existing review
  Future<PropertyReview> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
    int? cleanlinessRating,
    int? communicationRating,
    int? checkinRating,
    int? accuracyRating,
    int? locationRating,
    int? valueRating,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate rating if provided
      if (rating != null && (rating < 1 || rating > 5)) {
        throw Exception('Rating must be between 1 and 5');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (rating != null) updateData['rating'] = rating;
      if (comment != null) updateData['comment'] = comment;
      if (cleanlinessRating != null) {
        updateData['cleanliness_rating'] = cleanlinessRating;
      }
      if (communicationRating != null) {
        updateData['communication_rating'] = communicationRating;
      }
      if (checkinRating != null) {
        updateData['checkin_rating'] = checkinRating;
      }
      if (accuracyRating != null) {
        updateData['accuracy_rating'] = accuracyRating;
      }
      if (locationRating != null) {
        updateData['location_rating'] = locationRating;
      }
      if (valueRating != null) updateData['value_rating'] = valueRating;

      final response = await _supabase
          .from('reviews')
          .update(updateData)
          .eq('id', reviewId)
          .eq('user_id', user.id) // Ensure user owns the review
          .select('''
            *,
            users!inner(
              id,
              first_name,
              last_name,
              avatar_url
            )
          ''')
          .single();

      // Map user data
      final userData = response['users'] as Map<String, dynamic>?;
      final mappedData = Map<String, dynamic>.from(response);

      if (userData != null) {
        mappedData['user_name'] =
            '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'
                .trim();
        mappedData['user_avatar'] = userData['avatar_url'];
      }

      return PropertyReview.fromJson(mappedData);
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  /// Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('reviews')
          .delete()
          .eq('id', reviewId)
          .eq('user_id', user.id); // Ensure user owns the review
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  /// Add host response to a review
  Future<PropertyReview> addHostResponse({
    required String reviewId,
    required String response,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final updateData = {
        'host_response': response,
        'host_response_at': DateTime.now().toIso8601String(),
      };

      final result = await _supabase
          .from('reviews')
          .update(updateData)
          .eq('id', reviewId)
          .select('''
            *,
            users!inner(
              id,
              first_name,
              last_name,
              avatar_url
            )
          ''')
          .single();

      // Map user data
      final userData = result['users'] as Map<String, dynamic>?;
      final mappedData = Map<String, dynamic>.from(result);

      if (userData != null) {
        mappedData['user_name'] =
            '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'
                .trim();
        mappedData['user_avatar'] = userData['avatar_url'];
      }

      return PropertyReview.fromJson(mappedData);
    } catch (e) {
      throw Exception('Failed to add host response: $e');
    }
  }

  /// Check if user has already reviewed a property for a specific booking
  Future<bool> hasUserReviewedBooking({
    required String bookingId,
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('id')
          .eq('booking_id', bookingId)
          .eq('user_id', userId)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get user's review for a specific booking
  Future<PropertyReview?> getUserReviewForBooking({
    required String bookingId,
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('''
            *,
            users!inner(
              id,
              first_name,
              last_name,
              avatar_url
            )
          ''')
          .eq('booking_id', bookingId)
          .eq('user_id', userId)
          .limit(1)
          .single();

      // Map user data
      final userData = response['users'] as Map<String, dynamic>?;
      final mappedData = Map<String, dynamic>.from(response);

      if (userData != null) {
        mappedData['user_name'] =
            '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'
                .trim();
        mappedData['user_avatar'] = userData['avatar_url'];
      }

      return PropertyReview.fromJson(mappedData);
    } catch (e) {
      return null;
    }
  }
}

/// Provider for reviews repository
@riverpod
ReviewsRepository reviewsRepository(ReviewsRepositoryRef ref) {
  return ReviewsRepository(Supabase.instance.client);
}
