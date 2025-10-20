import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../models/property_model.dart';
import '../../core/utils/navigation_helpers.dart';
import '../../core/utils/web_hover_utils.dart';
import '../../core/services/haptic_service.dart';
import '../../features/favorites/presentation/providers/favorites_provider.dart';
import 'animations/animations.dart';

/// Reusable property card widget with image carousel
class PropertyCard extends ConsumerStatefulWidget {
  const PropertyCard({
    required this.property,
    this.showFavoriteButton = true,
    super.key,
  });

  final PropertyModel property;
  final bool showFavoriteButton;

  @override
  ConsumerState<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends ConsumerState<PropertyCard> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _images {
    final images = <String>[];
    if (widget.property.coverImage != null) {
      images.add(widget.property.coverImage!);
    }
    images.addAll(widget.property.images);
    // Return empty list if no images - will be handled by errorWidget
    return images;
  }

  @override
  Widget build(BuildContext context) {
    // Build semantic label for screen readers
    final semanticLabel = '${widget.property.name}, ${widget.property.location}, '
        '${widget.property.formattedPricePerNight}, '
        '${widget.property.rating > 0 ? '${widget.property.rating.toStringAsFixed(1)} stars, ${widget.property.reviewCount} reviews' : 'No rating yet'}';

    return Semantics(
      label: semanticLabel,
      hint: 'Double tap to view property details',
      button: true,
      excludeSemantics: true, // Prevent child widgets from adding conflicting semantics
      child: HoverEffect(
        enableScale: true,
        enableElevation: true,
        scale: 1.02,
        normalElevation: 0, // Changed from 2 to match bordered design
        hoverElevation: 4,  // Changed from 8 for subtle effect
        borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius (upgraded from 16)
        onTap: () async {
          await HapticService.buttonPress();
          if (context.mounted) {
            context.goToPropertyDetails(widget.property.id);
          }
        },
        child: Card(
          elevation: 0, // Changed from 2 to match modern bordered design
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius (upgraded from 16)
            side: BorderSide(color: AppColors.borderLight, width: 1), // Added border for modern design
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image carousel with Hero animation
              _buildImageCarousel(),

              // Property info - Flexible to prevent overflow
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(12), // Reduced from 16
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Important for preventing overflow
                    children: [
                      // Name
                      Text(
                        widget.property.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6), // Reduced from 8

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: AppDimensions.iconS,
                            color: AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: AppDimensions.spaceXXS),
                          Expanded(
                            child: Text(
                              widget.property.location,
                              style: AppTypography.small.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8), // Reduced from 12

                      // Quick info icons (guests, bedrooms, bathrooms)
                      if (widget.property.hasCompleteInfo)
                      Row(
                        children: [
                          _QuickInfoIcon(
                            icon: Icons.person_outline,
                            value: widget.property.maxGuests!,
                          ),
                          const SizedBox(width: 12), // Reduced from 16
                          _QuickInfoIcon(
                            icon: Icons.bed_outlined,
                            value: widget.property.bedrooms!,
                          ),
                          const SizedBox(width: 12), // Reduced from 16
                          _QuickInfoIcon(
                            icon: Icons.bathroom_outlined,
                            value: widget.property.bathrooms!,
                          ),
                        ],
                      ),

                    if (widget.property.hasCompleteInfo)
                      const SizedBox(height: 8), // Reduced from 12

                    // Rating and review count
                    if (widget.property.rating > 0)
                      Row(
                        children: [
                          Icon(Icons.star, size: AppDimensions.iconS, color: AppColors.star),
                          const SizedBox(width: AppDimensions.spaceXXS),
                          Text(
                            widget.property.rating.toStringAsFixed(1),
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: AppTypography.weightSemibold,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceXXS),
                          Text(
                            '(${widget.property.reviewCount})',
                            style: AppTypography.small.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),

                    if (widget.property.rating > 0)
                      const SizedBox(height: 8), // Reduced from 12

                    // Price per night
                    Text(
                      widget.property.formattedPricePerNight,
                      style: AppTypography.h3.copyWith(
                        fontWeight: AppTypography.weightBold,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 8), // Reduced from 12

                    // Amenities preview
                    if (widget.property.amenities.isNotEmpty)
                      Flexible(
                        child: Wrap(
                          spacing: 6, // Reduced from 8
                          runSpacing: 6, // Reduced from 8
                          children: widget.property.amenities
                              .take(3)
                              .map((amenity) => _AmenityChip(amenity: amenity))
                              .toList(),
                        ),
                      ),

                    const SizedBox(height: 10), // Reduced from 16

                    // View Details button - Compact version
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceS),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        border: Border.all(
                          color: AppColors.primary,
                          width: AppDimensions.borderWidthFocus,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Pogledaj detalje',
                            style: AppTypography.buttonText.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceXS),
                          Icon(
                            Icons.arrow_forward,
                            color: AppColors.primary,
                            size: AppDimensions.iconS,
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildImageCarousel() {
    // If no images, show placeholder
    if (_images.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9, // 16:9 aspect ratio
        child: Container(
          color: AppColors.surfaceVariantLight,
          child: Center(
            child: Icon(
              Icons.villa,
              size: AppDimensions.iconXL,
              color: AppColors.textDisabled,
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9, // 16:9 aspect ratio for all images
      child: Stack(
        children: [
          // Image PageView with Hero animation
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemCount: _images.length,
            itemBuilder: (context, index) {
              // Use Hero animation for the first (cover) image
              final heroTag = 'property_${widget.property.id}_image_$index';
              return Hero(
                tag: heroTag,
                child: CachedNetworkImage(
                  imageUrl: _images[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const SkeletonLoader(
                    borderRadius: 0,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.surfaceVariantLight,
                    child: Center(
                      child: Icon(
                        Icons.villa,
                        size: AppDimensions.iconXL,
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Favorite button (top right)
          if (widget.showFavoriteButton)
            Positioned(
              top: 12,
              right: 12,
              child: _FavoriteButton(propertyId: widget.property.id),
            ),

          // Dots indicator (bottom center)
          if (_images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _images.length,
                  (index) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha:0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Quick info icon widget (guests, bedrooms, bathrooms)
class _QuickInfoIcon extends StatelessWidget {
  const _QuickInfoIcon({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppDimensions.iconS, color: AppColors.textSecondaryLight),
        const SizedBox(width: AppDimensions.spaceXXS),
        Text(
          value.toString(),
          style: AppTypography.small,
        ),
      ],
    );
  }
}

/// Favorite button widget with state management and animation
class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesNotifier = ref.watch(favoritesNotifierProvider);
    final isFavorite = favoritesNotifier.maybeWhen(
      data: (favorites) => favorites.contains(propertyId),
      orElse: () => false,
    );

    return Semantics(
      label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      hint: isFavorite
          ? 'Double tap to remove this property from your favorites'
          : 'Double tap to add this property to your favorites',
      button: true,
      child: GestureDetector(
        onTap: () async {
          await HapticService.lightImpact();

          try {
            await ref
                .read(favoritesNotifierProvider.notifier)
                .toggleFavorite(propertyId);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Greška: $e')),
              );
            }
          }
        },
        child: AnimatedScale(
          scale: isFavorite ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: CircleAvatar(
            backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.95),
            radius: 18,
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: isFavorite ? AppColors.favorite : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

/// Amenity chip widget
class _AmenityChip extends StatelessWidget {
  const _AmenityChip({required this.amenity});

  final PropertyAmenity amenity;

  IconData _getAmenityIcon(PropertyAmenity amenity) {
    switch (amenity) {
      case PropertyAmenity.wifi:
        return Icons.wifi;
      case PropertyAmenity.parking:
        return Icons.local_parking;
      case PropertyAmenity.pool:
        return Icons.pool;
      case PropertyAmenity.airConditioning:
        return Icons.ac_unit;
      case PropertyAmenity.kitchen:
        return Icons.kitchen;
      case PropertyAmenity.seaView:
        return Icons.visibility;
      case PropertyAmenity.balcony:
        return Icons.balcony;
      case PropertyAmenity.bbq:
        return Icons.outdoor_grill;
      case PropertyAmenity.beachAccess:
        return Icons.beach_access;
      case PropertyAmenity.petFriendly:
        return Icons.pets;
      case PropertyAmenity.fireplace:
        return Icons.fireplace;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceXS,
        vertical: AppDimensions.spaceXXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getAmenityIcon(amenity),
            size: AppDimensions.iconXS,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppDimensions.spaceXXS),
          Text(
            amenity.displayName,
            style: AppTypography.small.copyWith(
              fontWeight: AppTypography.weightMedium,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
