import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/models/marketing_content_models.dart';
import '../providers/marketing_content_providers.dart';

/// Popular destinations section for home screen
/// Features: Horizontal scrolling cards with destination images and info
/// Data is fetched from Supabase with fallback to defaults
class PopularDestinationsSection extends ConsumerWidget {
  /// Section title
  final String title;

  /// Section subtitle
  final String? subtitle;

  /// On destination tapped callback
  final Function(DestinationData)? onDestinationTapped;

  const PopularDestinationsSection({
    super.key,
    this.title = 'Popular Destinations',
    this.subtitle,
    this.onDestinationTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationsAsync = ref.watch(popularDestinationsProvider);

    return destinationsAsync.when(
      data: (destinations) => _buildContent(context, destinations),
      loading: () => _buildLoading(context),
      error: (error, stack) => _buildContent(context, defaultDestinations), // Fallback on error
    );
  }

  Widget _buildContent(BuildContext context, List<DestinationData> destinations) {
    if (destinations.isEmpty) {
      return const SizedBox.shrink(); // Hide section if no destinations
    }

    return MaxWidthContainer(
      maxWidth: AppDimensions.containerXXL,
      padding: EdgeInsets.symmetric(
        vertical: context.sectionSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
            child: _buildHeader(context),
          ),

          SizedBox(height: context.isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL),

          // Destinations list
          SizedBox(
            height: _getCardHeight(context),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
              itemCount: destinations.length,
              separatorBuilder: (context, index) => SizedBox(width: context.spacing),
              itemBuilder: (context, index) {
                return DestinationCard(
                  destination: destinations[index],
                  width: _getCardWidth(context),
                  onTap: () => onDestinationTapped?.call(destinations[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return MaxWidthContainer(
      maxWidth: AppDimensions.containerXXL,
      padding: EdgeInsets.symmetric(
        vertical: context.sectionSpacing,
        horizontal: context.horizontalPadding,
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
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
    );
  }

  double _getCardWidth(BuildContext context) {
    if (context.isDesktop) return 320;
    if (context.isTablet) return 280;
    return MediaQuery.of(context).size.width * 0.8;
  }

  double _getCardHeight(BuildContext context) {
    if (context.isDesktop) return 400;
    if (context.isTablet) return 360;
    return 320;
  }
}

/// Destination card widget
class DestinationCard extends StatelessWidget {
  final DestinationData destination;
  final double width;
  final VoidCallback? onTap;

  const DestinationCard({
    super.key,
    required this.destination,
    required this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final height = width * 3 / 4; // 4:3 aspect ratio

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
                // Background image
                Positioned.fill(
                child: PremiumImage(
                  imageUrl: destination.imageUrl,
                  fit: BoxFit.cover,
                  enableOverlay: true,
                  overlayGradient: LinearGradient(
                    colors: [
                      AppColors.withOpacity(Colors.black, AppColors.opacity10),
                      AppColors.withOpacity(Colors.black, AppColors.opacity60),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Destination name
                      Text(
                        destination.name,
                        style: AppTypography.h3.copyWith(
                          color: Colors.white,
                          fontWeight: AppTypography.weightBold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.spaceXXS),

                      // Country
                      Text(
                        destination.country,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.withOpacity(Colors.white, AppColors.opacity90),
                        ),
                      ),

                      if (destination.propertyCount != null) ...[
                        const SizedBox(height: AppDimensions.spaceS),

                        // Property count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceS,
                            vertical: AppDimensions.spaceXXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.withOpacity(Colors.white, AppColors.opacity20),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                            border: Border.all(
                              color: AppColors.withOpacity(Colors.white, AppColors.opacity40),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${destination.propertyCount} properties',
                            style: AppTypography.small.copyWith(
                              color: Colors.white,
                              fontWeight: AppTypography.weightMedium,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
