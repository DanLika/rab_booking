import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/models/property_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/featured_properties_provider.dart';

/// Featured properties section for home screen
/// Displays a responsive grid of featured properties
class FeaturedPropertiesSection extends ConsumerWidget {
  /// Section title
  final String title;

  /// Section subtitle
  final String? subtitle;

  /// On property tapped callback
  final Function(PropertyModel)? onPropertyTapped;

  /// On see all tapped callback
  final VoidCallback? onSeeAllTapped;

  /// Show see all button
  final bool showSeeAll;

  /// Maximum properties to show
  final int? maxProperties;

  const FeaturedPropertiesSection({
    super.key,
    this.title = 'Featured Properties',
    this.subtitle,
    this.onPropertyTapped,
    this.onSeeAllTapped,
    this.showSeeAll = true,
    this.maxProperties,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(featuredPropertiesProvider);

    return MaxWidthContainer(
      maxWidth: AppDimensions.containerXXL,
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: context.sectionSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          _buildHeader(context),

          SizedBox(height: context.isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL),

          // Properties grid
          propertiesAsync.when(
            data: (properties) {
              final displayProperties = maxProperties != null
                  ? properties.take(maxProperties!).toList()
                  : properties;

              if (displayProperties.isEmpty) {
                return _buildEmptyState(context);
              }

              return _buildPropertiesGrid(context, displayProperties);
            },
            loading: () => _buildLoadingState(context),
            error: (error, stack) => _buildErrorState(context, error.toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.isMobile ? AppTypography.h2 : AppTypography.h1,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  subtitle!,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showSeeAll && !context.isMobile) ...[
          const SizedBox(width: AppDimensions.spaceM),
          PremiumButton.text(
            label: 'See all',
            icon: Icons.arrow_forward,
            iconPosition: IconPosition.right,
            onPressed: onSeeAllTapped ?? () {},
          ),
        ],
      ],
    );
  }

  Widget _buildPropertiesGrid(BuildContext context, List<PropertyModel> properties) {
    return Column(
      children: [
        ResponsivePropertyGrid(
          properties: properties.map((property) {
            return PropertyCardWidget(
              property: property,
              onTap: () => onPropertyTapped?.call(property),
            );
          }).toList(),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          customColumns: const ResponsiveValue(
            mobile: 1,
            tablet: 2,
            desktop: 3,
            largeDesktop: 4,
          ),
        ),
        if (showSeeAll && context.isMobile) ...[
          const SizedBox(height: AppDimensions.spaceL),
          PremiumButton.outline(
            label: 'See all properties',
            onPressed: onSeeAllTapped ?? () {},
            isFullWidth: true,
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return ResponsivePropertyGrid(
      properties: List.generate(
        context.isMobile ? 2 : (context.isTablet ? 4 : 6),
        (index) => _buildSkeletonCard(),
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  Widget _buildSkeletonCard() {
    return PremiumCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.home_outlined,
              size: AppDimensions.iconXL * 2,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              'No properties available',
              style: AppTypography.h3.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: AppDimensions.iconXL * 2,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              'Failed to load properties',
              style: AppTypography.h3.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              error,
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

/// Property card widget for grid
class PropertyCardWidget extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback? onTap;

  const PropertyCardWidget({
    super.key,
    required this.property,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard.elevated(
      onTap: onTap,
      enableHover: true,
      elevation: 1,
      imageHeader: PremiumImage(
        imageUrl: property.coverImage ?? (property.images.isNotEmpty ? property.images.first : ''),
        aspectRatio: 16 / 9,
        fit: BoxFit.cover,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property name
            Text(
              property.name,
              style: AppTypography.propertyCardTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.spaceXXS),

            // Location
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: AppDimensions.iconS,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(width: AppDimensions.spaceXXS),
                Expanded(
                  child: Text(
                    property.location,
                    style: AppTypography.propertyCardSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spaceS),

            // Price and rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Price
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '\$${property.pricePerNight}',
                        style: AppTypography.priceText.copyWith(
                          color: AppColors.primary,
                          fontSize: 20,
                        ),
                      ),
                      TextSpan(
                        text: ' / night',
                        style: AppTypography.priceLabel.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Rating
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: AppDimensions.iconS,
                      color: AppColors.star,
                    ),
                    const SizedBox(width: AppDimensions.spaceXXS),
                    Text(
                      property.rating.toStringAsFixed(1),
                      style: AppTypography.small.copyWith(
                        fontWeight: AppTypography.weightSemibold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
