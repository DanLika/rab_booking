import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/reviews_provider.dart';
import '../../data/repositories/reviews_repository.dart';

/// Premium reviews section with filtering and sorting
/// Features: Star ratings, filtering, sorting, pagination, review cards
class PremiumReviewsSection extends StatefulWidget {
  /// List of reviews
  final List<ReviewData> reviews;

  /// Average rating
  final double averageRating;

  /// Total review count
  final int totalReviews;

  /// Section title
  final String title;

  /// Enable filtering
  final bool enableFiltering;

  /// Enable sorting
  final bool enableSorting;

  /// Initial reviews to show
  final int initialDisplayCount;

  /// Callback for viewing all reviews
  final VoidCallback? onViewAll;

  const PremiumReviewsSection({
    super.key,
    required this.reviews,
    required this.averageRating,
    required this.totalReviews,
    this.title = 'Guest Reviews',
    this.enableFiltering = true,
    this.enableSorting = true,
    this.initialDisplayCount = 5,
    this.onViewAll,
  });

  @override
  State<PremiumReviewsSection> createState() => _PremiumReviewsSectionState();
}

class _PremiumReviewsSectionState extends State<PremiumReviewsSection> {
  int? _selectedRatingFilter;
  ReviewSortOption _sortOption = ReviewSortOption.recent;
  int _displayCount = 0;

  @override
  void initState() {
    super.initState();
    _displayCount = widget.initialDisplayCount;
  }

  List<ReviewData> get _filteredAndSortedReviews {
    var reviews = widget.reviews;

    // Apply filter
    if (_selectedRatingFilter != null) {
      reviews = reviews.where((r) => r.rating == _selectedRatingFilter!).toList();
    }

    // Apply sort
    switch (_sortOption) {
      case ReviewSortOption.recent:
        reviews.sort((a, b) => b.date.compareTo(a.date));
        break;
      case ReviewSortOption.oldest:
        reviews.sort((a, b) => a.date.compareTo(b.date));
        break;
      case ReviewSortOption.highestRated:
        reviews.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ReviewSortOption.lowestRated:
        reviews.sort((a, b) => a.rating.compareTo(b.rating));
        break;
    }

    return reviews;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reviews.isEmpty) {
      return _buildEmptyState();
    }

    final displayReviews = _filteredAndSortedReviews.take(_displayCount).toList();
    final hasMore = _filteredAndSortedReviews.length > _displayCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with rating summary
        _buildHeader(),

        const SizedBox(height: AppDimensions.spaceXL),

        // Rating distribution
        _buildRatingDistribution(),

        const SizedBox(height: AppDimensions.spaceXL),

        // Filters and sort
        if (widget.enableFiltering || widget.enableSorting) ...[
          _buildFiltersSortRow(),
          const SizedBox(height: AppDimensions.spaceL),
        ],

        // Reviews list
        ...displayReviews.map((review) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceL),
              child: ReviewCard(review: review),
            )),

        // Load more button
        if (hasMore) ...[
          const SizedBox(height: AppDimensions.spaceM),
          Center(
            child: PremiumButton.outline(
              label: 'Show more reviews',
              icon: Icons.keyboard_arrow_down,
              iconPosition: IconPosition.right,
              onPressed: () {
                setState(() {
                  _displayCount += widget.initialDisplayCount;
                });
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: context.isMobile ? AppTypography.h3 : AppTypography.h2,
              ),
              const SizedBox(height: AppDimensions.spaceXS),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: AppColors.star,
                    size: AppDimensions.iconM,
                  ),
                  const SizedBox(width: AppDimensions.spaceXS),
                  Text(
                    widget.averageRating.toStringAsFixed(1),
                    style: AppTypography.h3.copyWith(
                      fontWeight: AppTypography.weightBold,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceXS),
                  Text(
                    '(${widget.totalReviews} reviews)',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // View all button
        if (widget.onViewAll != null && widget.totalReviews > widget.initialDisplayCount)
          TextButton.icon(
            onPressed: widget.onViewAll,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('View all'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildRatingDistribution() {
    final ratingCounts = <int, int>{};
    for (final review in widget.reviews) {
      ratingCounts[review.rating] = (ratingCounts[review.rating] ?? 0) + 1;
    }

    return Column(
      children: List.generate(5, (index) {
        final rating = 5 - index;
        final count = ratingCounts[rating] ?? 0;
        final percentage = widget.reviews.isEmpty ? 0.0 : count / widget.reviews.length;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
          child: _buildRatingBar(rating, count, percentage),
        );
      }),
    );
  }

  Widget _buildRatingBar(int rating, int count, double percentage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: widget.enableFiltering
          ? () {
              setState(() {
                _selectedRatingFilter =
                    _selectedRatingFilter == rating ? null : rating;
                _displayCount = widget.initialDisplayCount;
              });
            }
          : null,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceS,
          vertical: AppDimensions.spaceXS,
        ),
        child: Row(
          children: [
            // Star rating
            SizedBox(
              width: 60,
              child: Row(
                children: [
                  Text(
                    rating.toString(),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: AppTypography.weightMedium,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceXXS),
                  const Icon(
                    Icons.star,
                    color: AppColors.star,
                    size: AppDimensions.iconS,
                  ),
                ],
              ),
            ),

            // Progress bar
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                      boxShadow: percentage > 0 ? AppShadows.glowPrimary : null,
                    ),
                  ),
                ),
              ),
            ),

            // Count
            const SizedBox(width: AppDimensions.spaceM),
            SizedBox(
              width: 40,
              child: Text(
                count.toString(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSortRow() {
    return Wrap(
      spacing: AppDimensions.spaceM,
      runSpacing: AppDimensions.spaceM,
      children: [
        // Active filter chip
        if (_selectedRatingFilter != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedRatingFilter = null;
                  _displayCount = widget.initialDisplayCount;
                });
              },
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceM,
                  vertical: AppDimensions.spaceS,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  boxShadow: AppShadows.glowPrimary,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_selectedRatingFilter stars',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: AppTypography.weightMedium,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceXS),
                    const Icon(
                      Icons.close,
                      size: AppDimensions.iconS,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Sort dropdown
        if (widget.enableSorting)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceM,
              vertical: AppDimensions.spaceXS,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: DropdownButton<ReviewSortOption>(
              value: _sortOption,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.arrow_drop_down, size: AppDimensions.iconM),
              items: ReviewSortOption.values.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(
                    option.displayName,
                    style: AppTypography.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sortOption = value;
                    _displayCount = widget.initialDisplayCount;
                  });
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: AppDimensions.iconXL * 2,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              'No reviews yet',
              style: AppTypography.h3.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'Be the first to review this property',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Review card widget
class ReviewCard extends StatelessWidget {
  final ReviewData review;

  const ReviewCard({
    super.key,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumCard.elevated(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and rating
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: review.userAvatar != null
                        ? PremiumImage(
                            imageUrl: review.userAvatar!,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              review.userName.substring(0, 1).toUpperCase(),
                              style: AppTypography.h3.copyWith(
                                color: Colors.white,
                                fontWeight: AppTypography.weightBold,
                              ),
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: AppDimensions.spaceM),

                // Name and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: AppTypography.weightSemibold,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceXXS),
                      Text(
                        _formatDate(review.date),
                        style: AppTypography.small.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),

                // Rating stars
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: AppColors.star,
                      size: AppDimensions.iconS,
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spaceM),

            // Review text
            Text(
              review.comment,
              style: AppTypography.bodyMedium,
            ),

            // Host response
            if (review.hostResponse != null) ...[
              const SizedBox(height: AppDimensions.spaceM),
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceM),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.reply,
                          size: AppDimensions.iconS,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppDimensions.spaceXS),
                        Text(
                          'Host response',
                          style: AppTypography.small.copyWith(
                            fontWeight: AppTypography.weightSemibold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    Text(
                      review.hostResponse!,
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}

/// Review data model
class ReviewData {
  final String userName;
  final String? userAvatar;
  final int rating;
  final String comment;
  final DateTime date;
  final String? hostResponse;

  const ReviewData({
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    required this.date,
    this.hostResponse,
  });
}

/// Review sort options
enum ReviewSortOption {
  recent,
  oldest,
  highestRated,
  lowestRated,
}

extension ReviewSortOptionExtension on ReviewSortOption {
  String get displayName {
    switch (this) {
      case ReviewSortOption.recent:
        return 'Most Recent';
      case ReviewSortOption.oldest:
        return 'Oldest First';
      case ReviewSortOption.highestRated:
        return 'Highest Rated';
      case ReviewSortOption.lowestRated:
        return 'Lowest Rated';
    }
  }
}

/// Adapter widget that fetches reviews from Supabase
class ReviewsSection extends ConsumerWidget {
  final String propertyId;
  final String propertyName;
  final double rating;
  final int reviewCount;

  const ReviewsSection({
    super.key,
    required this.propertyId,
    required this.propertyName,
    required this.rating,
    required this.reviewCount,
  });

  /// Convert PropertyReview to ReviewData
  ReviewData _convertToReviewData(PropertyReview review) {
    return ReviewData(
      userName: review.userName ?? 'Anonymous',
      userAvatar: review.userAvatar,
      rating: review.rating,
      comment: review.comment,
      date: review.createdAt,
      hostResponse: review.hostResponse,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch reviews from provider
    final reviewsAsync = ref.watch(
      propertyReviewsProvider(propertyId, limit: 10, sortBy: 'recent'),
    );

    return reviewsAsync.when(
      data: (propertyReviews) {
        // Convert PropertyReview list to ReviewData list
        final reviewDataList = propertyReviews
            .map((review) => _convertToReviewData(review))
            .toList();

        return PremiumReviewsSection(
          reviews: reviewDataList,
          averageRating: rating,
          totalReviews: reviewCount,
          title: 'Guest Reviews',
          onViewAll: () {
            // Navigate to all reviews screen
            context.go('/property/$propertyId/reviews', extra: {
              'propertyId': propertyId,
              'propertyName': propertyName,
              'rating': rating,
              'reviewCount': reviewCount,
            });
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spaceXL),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: AppDimensions.spaceM),
            const Text(
              'Failed to load reviews',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
