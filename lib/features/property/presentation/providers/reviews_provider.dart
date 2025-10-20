import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/reviews_repository.dart';

part 'reviews_provider.g.dart';

/// Get reviews for a property
@riverpod
Future<List<PropertyReview>> propertyReviews(
  PropertyReviewsRef ref,
  String propertyId, {
  int limit = 10,
  int offset = 0,
  String sortBy = 'recent',
  int? filterByRating,
}) async {
  final repository = ref.watch(reviewsRepositoryProvider);
  return repository.getPropertyReviews(
    propertyId,
    limit: limit,
    offset: offset,
    sortBy: sortBy,
    filterByRating: filterByRating,
  );
}

/// Get rating breakdown for a property
@riverpod
Future<RatingBreakdown> propertyRatingBreakdown(
  PropertyRatingBreakdownRef ref,
  String propertyId,
) async {
  final repository = ref.watch(reviewsRepositoryProvider);
  return repository.getRatingBreakdown(propertyId);
}

/// Get review count for a property
@riverpod
Future<int> propertyReviewCount(
  PropertyReviewCountRef ref,
  String propertyId,
) async {
  final repository = ref.watch(reviewsRepositoryProvider);
  return repository.getReviewCount(propertyId);
}

/// Get rating distribution for a property
@riverpod
Future<Map<int, int>> propertyRatingDistribution(
  PropertyRatingDistributionRef ref,
  String propertyId,
) async {
  final repository = ref.watch(reviewsRepositoryProvider);
  return repository.getRatingDistribution(propertyId);
}
