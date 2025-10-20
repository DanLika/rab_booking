import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/enums.dart';
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
    return HoverEffect(
      enableScale: true,
      enableElevation: true,
      scale: 1.02,
      normalElevation: 2,
      hoverElevation: 8,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius (upgraded from 16)
      onTap: () async {
        await HapticService.buttonPress();
        if (context.mounted) {
          context.goToPropertyDetails(widget.property.id);
        }
      },
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius (upgraded from 16)
        ),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image carousel with Hero animation
                _buildImageCarousel(),

                // Property info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.property.location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quick info icons (guests, bedrooms, bathrooms)
                  if (widget.property.hasCompleteInfo)
                    Row(
                      children: [
                        _QuickInfoIcon(
                          icon: Icons.person_outline,
                          value: widget.property.maxGuests!,
                        ),
                        const SizedBox(width: 16),
                        _QuickInfoIcon(
                          icon: Icons.bed_outlined,
                          value: widget.property.bedrooms!,
                        ),
                        const SizedBox(width: 16),
                        _QuickInfoIcon(
                          icon: Icons.bathroom_outlined,
                          value: widget.property.bathrooms!,
                        ),
                      ],
                    ),

                  if (widget.property.hasCompleteInfo)
                    const SizedBox(height: 12),

                  // Rating and review count
                  if (widget.property.rating > 0)
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          widget.property.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${widget.property.reviewCount})',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),

                  if (widget.property.rating > 0)
                    const SizedBox(height: 12),

                  // Price per night
                  Text(
                    widget.property.formattedPricePerNight,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),

                  const SizedBox(height: 12),

                  // Amenities preview
                  if (widget.property.amenities.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.property.amenities
                          .take(3)
                          .map((amenity) => _AmenityChip(amenity: amenity))
                          .toList(),
                    ),

                  const SizedBox(height: 16),

                  // View Details button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius (upgraded from 8)
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pogledaj detalje',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Theme.of(context).primaryColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                    ],
                  ),
                ),
              ],
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
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.villa, size: 60, color: Colors.grey),
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
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.villa, size: 60, color: Colors.grey),
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
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.bodySmall,
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

    return GestureDetector(
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
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          radius: 18,
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: isFavorite ? Colors.red : Colors.grey[600],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXS), // 6px modern radius
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getAmenityIcon(amenity),
            size: 14,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            amenity.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
