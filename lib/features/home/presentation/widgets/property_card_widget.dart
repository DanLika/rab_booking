import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/enums.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../core/utils/navigation_helpers.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_colors.dart';

/// Property card widget with hover effects
class PropertyCardWidget extends StatefulWidget {
  const PropertyCardWidget({
    required this.property,
    super.key,
  });

  final PropertyModel property;

  @override
  State<PropertyCardWidget> createState() => _PropertyCardWidgetState();
}

class _PropertyCardWidgetState extends State<PropertyCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300), // Increased from 200ms for smoother effect
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate( // Increased from 1.03 to 1.05 for more dramatic effect
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.4, 0.0, 0.2, 1.0), // Smooth premium curve
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build semantic label for screen readers
    final semanticLabel = '${widget.property.name}, ${widget.property.location}, '
        '€${widget.property.basePrice} per night, '
        '${widget.property.rating > 0 ? '${widget.property.rating.toStringAsFixed(1)} stars' : 'No rating yet'}';

    return Semantics(
      label: semanticLabel,
      hint: 'Double tap to view property details',
      button: true,
      child: MouseRegion(
        onEnter: (_) => _onHoverChanged(true),
        onExit: (_) => _onHoverChanged(false),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: () => context.goToPropertyDetails(widget.property.id),
            child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius
              boxShadow: [
                // Azure Blue tinted shadow for premium feel
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: _isHovered ? 24 : 8,
                  offset: Offset(0, _isHovered ? 12 : 4),
                ),
                // Subtle secondary shadow for depth
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isHovered ? 0.12 : 0.06),
                  blurRadius: _isHovered ? 16 : 4,
                  offset: Offset(0, _isHovered ? 8 : 2),
                ),
              ],
            ),
            child: Card(
              elevation: 0, // Using custom shadows instead
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius
              ),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Property image
                      Builder(
                        builder: (context) {
                          final imageUrl = widget.property.coverImage ??
                              widget.property.images.firstOrNull;

                          if (imageUrl == null) {
                            return Container(
                              color: context.surfaceVariantColor,
                              child: Center(
                                child: Icon(Icons.villa,
                                    size: 60, color: context.iconColorSecondary),
                              ),
                            );
                          }

                          return Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: context.surfaceVariantColor,
                                child: Center(
                                  child: Icon(Icons.villa,
                                      size: 60, color: context.iconColorSecondary),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // Premium gradient overlay - full image coverage
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.premiumOverlayGradient,
                          ),
                        ),
                      ),

                      // Premium rating badge with glassmorphism
                      if (widget.property.rating > 0)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.tertiaryGradient,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.tertiary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.property.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Property details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        widget.property.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                            color: context.iconColorSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.property.location,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: context.textColorSecondary,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic)
        .scale(begin: 0.95, end: 1.0, curve: Curves.easeOut);
  }
}

/// Amenity chip
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
