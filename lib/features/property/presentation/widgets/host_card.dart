import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/models/user_model.dart';

/// Premium host information card
/// Features: Host avatar, name, stats, verification badge, contact button
class PremiumHostCard extends StatelessWidget {
  /// Host user model
  final UserModel host;

  /// Number of properties
  final int propertyCount;

  /// Total reviews across all properties
  final int totalReviews;

  /// Average rating across all properties
  final double averageRating;

  /// Member since year
  final int memberSince;

  /// Is verified host
  final bool isVerified;

  /// Contact callback
  final VoidCallback? onContact;

  const PremiumHostCard({
    super.key,
    required this.host,
    this.propertyCount = 0,
    this.totalReviews = 0,
    this.averageRating = 0.0,
    required this.memberSince,
    this.isVerified = false,
    this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumCard.elevated(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(
          context.isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Hosted by',
              style: AppTypography.h3,
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // Host info
            Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: context.isMobile ? 64 : 80,
                      height: context.isMobile ? 64 : 80,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.glowPrimary,
                      ),
                      child: ClipOval(
                        child: host.avatarUrl != null
                            ? PremiumImage(
                                imageUrl: host.avatarUrl!,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Text(
                                  host.fullName.substring(0, 1).toUpperCase(),
                                  style: (context.isMobile
                                          ? AppTypography.h2
                                          : AppTypography.h1)
                                      .copyWith(
                                    color: Colors.white,
                                    fontWeight: AppTypography.weightBold,
                                  ),
                                ),
                              ),
                      ),
                    ),

                    // Verification badge
                    if (isVerified)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(AppDimensions.spaceXXS),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surfaceLight,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.check,
                            size: context.isMobile
                                ? AppDimensions.iconS
                                : AppDimensions.iconM,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: AppDimensions.spaceL),

                // Name and member since
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              host.fullName,
                              style: context.isMobile
                                  ? AppTypography.h3
                                  : AppTypography.h2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: AppDimensions.spaceXS),
                            const Tooltip(
                              message: 'Verified Host',
                              child: Icon(
                                Icons.verified,
                                size: AppDimensions.iconM,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceXS),
                      Text(
                        'Member since $memberSince',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // Stats
            _buildStats(),

            // Bio placeholder removed (field not in UserModel)

            const SizedBox(height: AppDimensions.spaceL),

            // Contact button
            PremiumButton.outline(
              label: 'Contact Host',
              icon: Icons.message_outlined,
              isFullWidth: true,
              onPressed: onContact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.home_outlined,
            value: propertyCount.toString(),
            label: propertyCount == 1 ? 'Property' : 'Properties',
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: _buildStatItem(
            icon: Icons.star_outline,
            value: averageRating.toStringAsFixed(1),
            label: 'Rating',
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: _buildStatItem(
            icon: Icons.rate_review_outlined,
            value: totalReviews.toString(),
            label: totalReviews == 1 ? 'Review' : 'Reviews',
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: AppDimensions.iconL,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppDimensions.spaceXS),
        Text(
          value,
          style: AppTypography.h3.copyWith(
            fontWeight: AppTypography.weightBold,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXXS),
        Text(
          label,
          style: AppTypography.small.copyWith(
            color: AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
