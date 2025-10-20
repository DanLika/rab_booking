import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';

/// Premium stats cards widget
/// Features: Animated counters, icons, gradient backgrounds, responsive layout
class PremiumStatsCards extends StatelessWidget {
  /// Number of bookings
  final int bookingsCount;

  /// Number of favorites
  final int favoritesCount;

  /// Number of reviews
  final int reviewsCount;

  /// Average rating
  final double? averageRating;

  /// On bookings tap
  final VoidCallback? onBookingsTap;

  /// On favorites tap
  final VoidCallback? onFavoritesTap;

  /// On reviews tap
  final VoidCallback? onReviewsTap;

  const PremiumStatsCards({
    super.key,
    required this.bookingsCount,
    required this.favoritesCount,
    required this.reviewsCount,
    this.averageRating,
    this.onBookingsTap,
    this.onFavoritesTap,
    this.onReviewsTap,
  });

  @override
  Widget build(BuildContext context) {
    return context.isMobile
        ? Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.calendar_month_outlined,
                      value: bookingsCount.toString(),
                      label: 'Bookings',
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.withOpacity(
                            AppColors.primary,
                            AppColors.opacity70,
                          ),
                        ],
                      ),
                      onTap: onBookingsTap,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceM),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.favorite_outlined,
                      value: favoritesCount.toString(),
                      label: 'Favorites',
                      gradient: LinearGradient(
                        colors: [
                          AppColors.error,
                          AppColors.withOpacity(
                            AppColors.error,
                            AppColors.opacity70,
                          ),
                        ],
                      ),
                      onTap: onFavoritesTap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceM),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.star_outline,
                      value: reviewsCount.toString(),
                      label: 'Reviews',
                      gradient: LinearGradient(
                        colors: [
                          AppColors.warning,
                          AppColors.withOpacity(
                            AppColors.warning,
                            AppColors.opacity70,
                          ),
                        ],
                      ),
                      onTap: onReviewsTap,
                    ),
                  ),
                  if (averageRating != null) ...[
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.trending_up,
                        value: averageRating!.toStringAsFixed(1),
                        label: 'Rating',
                        gradient: LinearGradient(
                          colors: [
                            AppColors.success,
                            AppColors.withOpacity(
                              AppColors.success,
                              AppColors.opacity70,
                            ),
                          ],
                        ),
                        onTap: null,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.calendar_month_outlined,
                  value: bookingsCount.toString(),
                  label: 'Bookings',
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.withOpacity(
                        AppColors.primary,
                        AppColors.opacity70,
                      ),
                    ],
                  ),
                  onTap: onBookingsTap,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.favorite_outlined,
                  value: favoritesCount.toString(),
                  label: 'Favorites',
                  gradient: LinearGradient(
                    colors: [
                      AppColors.error,
                      AppColors.withOpacity(
                        AppColors.error,
                        AppColors.opacity70,
                      ),
                    ],
                  ),
                  onTap: onFavoritesTap,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.star_outline,
                  value: reviewsCount.toString(),
                  label: 'Reviews',
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning,
                      AppColors.withOpacity(
                        AppColors.warning,
                        AppColors.opacity70,
                      ),
                    ],
                  ),
                  onTap: onReviewsTap,
                ),
              ),
              if (averageRating != null) ...[
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.trending_up,
                    value: averageRating!.toStringAsFixed(1),
                    label: 'Rating',
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success,
                        AppColors.withOpacity(
                          AppColors.success,
                          AppColors.opacity70,
                        ),
                      ],
                    ),
                    onTap: null,
                  ),
                ),
              ],
            ],
          );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required LinearGradient gradient,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: PremiumCard.elevated(
        elevation: 2,
        child: Container(
          padding: EdgeInsets.all(
            context.isMobile ? AppDimensions.spaceM : AppDimensions.spaceL,
          ),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: AppShadows.elevation2,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: context.isMobile
                    ? AppDimensions.iconL
                    : AppDimensions.iconXL,
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                value,
                style: (context.isMobile ? AppTypography.h2 : AppTypography.h1)
                    .copyWith(
                  color: Colors.white,
                  fontWeight: AppTypography.weightBold,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXXS),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.withOpacity(
                    Colors.white,
                    AppColors.opacity90,
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(height: AppDimensions.spaceXS),
                Icon(
                  Icons.arrow_forward,
                  color: AppColors.withOpacity(
                    Colors.white,
                    AppColors.opacity70,
                  ),
                  size: AppDimensions.iconS,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
