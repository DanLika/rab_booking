import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../shared/widgets/widgets.dart';

/// Premium amenities section with categorized display
/// Features: Grouped amenities, icons, expandable sections, responsive grid
class PremiumAmenitiesSection extends StatelessWidget {
  /// List of amenities
  final List<PropertyAmenity> amenities;

  /// Section title
  final String title;

  /// Show all amenities or collapse after limit
  final bool expandable;

  /// Number of amenities to show before "Show more"
  final int initialDisplayCount;

  /// Display style
  final AmenitiesDisplayStyle displayStyle;

  const PremiumAmenitiesSection({
    super.key,
    required this.amenities,
    this.title = 'Amenities',
    this.expandable = true,
    this.initialDisplayCount = 6,
    this.displayStyle = AmenitiesDisplayStyle.grid,
  });

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    // Categorize amenities
    final categorized = _categorizeAmenities(amenities);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Text(
          title,
          style: context.isMobile ? AppTypography.h3 : AppTypography.h2,
        ),

        const SizedBox(height: AppDimensions.spaceL),

        // Display based on style
        if (displayStyle == AmenitiesDisplayStyle.grid)
          _AmenitiesGrid(
            amenities: amenities,
            expandable: expandable,
            initialDisplayCount: initialDisplayCount,
          )
        else if (displayStyle == AmenitiesDisplayStyle.categorized)
          _CategorizedAmenities(categorized: categorized)
        else
          _AmenitiesList(
            amenities: amenities,
            expandable: expandable,
            initialDisplayCount: initialDisplayCount,
          ),
      ],
    );
  }

  Map<AmenityCategory, List<PropertyAmenity>> _categorizeAmenities(
      List<PropertyAmenity> amenities) {
    final Map<AmenityCategory, List<PropertyAmenity>> categorized = {};

    for (final amenity in amenities) {
      final category = _getAmenityCategory(amenity);
      categorized.putIfAbsent(category, () => []);
      categorized[category]!.add(amenity);
    }

    return categorized;
  }

  AmenityCategory _getAmenityCategory(PropertyAmenity amenity) {
    switch (amenity) {
      case PropertyAmenity.wifi:
      case PropertyAmenity.tv:
      case PropertyAmenity.airConditioning:
      case PropertyAmenity.heating:
        return AmenityCategory.essentials;

      case PropertyAmenity.kitchen:
      case PropertyAmenity.washingMachine:
        return AmenityCategory.kitchen;

      case PropertyAmenity.pool:
      case PropertyAmenity.hotTub:
      case PropertyAmenity.sauna:
      case PropertyAmenity.gym:
        return AmenityCategory.leisure;

      case PropertyAmenity.balcony:
      case PropertyAmenity.seaView:
      case PropertyAmenity.beachAccess:
      case PropertyAmenity.bbq:
      case PropertyAmenity.outdoorFurniture:
        return AmenityCategory.outdoor;

      case PropertyAmenity.parking:
      case PropertyAmenity.bicycleRental:
      case PropertyAmenity.boatMooring:
        return AmenityCategory.parking;

      case PropertyAmenity.petFriendly:
      case PropertyAmenity.fireplace:
        return AmenityCategory.other;
    }
  }
}

/// Amenities grid layout
class _AmenitiesGrid extends StatefulWidget {
  final List<PropertyAmenity> amenities;
  final bool expandable;
  final int initialDisplayCount;

  const _AmenitiesGrid({
    required this.amenities,
    required this.expandable,
    required this.initialDisplayCount,
  });

  @override
  State<_AmenitiesGrid> createState() => _AmenitiesGridState();
}

class _AmenitiesGridState extends State<_AmenitiesGrid> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final displayAmenities = _showAll || !widget.expandable
        ? widget.amenities
        : widget.amenities.take(widget.initialDisplayCount).toList();

    final shouldShowButton =
        widget.expandable && widget.amenities.length > widget.initialDisplayCount;

    return Column(
      children: [
        ResponsiveBuilder(
          mobile: (context, constraints) => _buildGridContent(context, 2, displayAmenities),
          tablet: (context, constraints) => _buildGridContent(context, 3, displayAmenities),
          desktop: (context, constraints) => _buildGridContent(context, 4, displayAmenities),
        ),
        if (shouldShowButton) ...[
          const SizedBox(height: AppDimensions.spaceM),
          PremiumButton.text(
            label: _showAll
                ? 'Show less'
                : 'Show all ${widget.amenities.length} amenities',
            icon: _showAll ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            iconPosition: IconPosition.right,
            onPressed: () {
              setState(() {
                _showAll = !_showAll;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildGridContent(
      BuildContext context, int columns, List<PropertyAmenity> amenities) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppDimensions.spaceM,
        mainAxisSpacing: AppDimensions.spaceM,
        childAspectRatio: context.isMobile ? 3 : 4,
      ),
      itemCount: amenities.length,
      itemBuilder: (context, index) {
        return AmenityChip(amenity: amenities[index]);
      },
    );
  }
}

/// Amenities list layout
class _AmenitiesList extends StatefulWidget {
  final List<PropertyAmenity> amenities;
  final bool expandable;
  final int initialDisplayCount;

  const _AmenitiesList({
    required this.amenities,
    required this.expandable,
    required this.initialDisplayCount,
  });

  @override
  State<_AmenitiesList> createState() => _AmenitiesListState();
}

class _AmenitiesListState extends State<_AmenitiesList> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final displayAmenities = _showAll || !widget.expandable
        ? widget.amenities
        : widget.amenities.take(widget.initialDisplayCount).toList();

    final shouldShowButton =
        widget.expandable && widget.amenities.length > widget.initialDisplayCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayAmenities.map((amenity) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceM),
              child: AmenityListItem(amenity: amenity),
            )),
        if (shouldShowButton) ...[
          const SizedBox(height: AppDimensions.spaceS),
          PremiumButton.text(
            label: _showAll
                ? 'Show less'
                : 'Show all ${widget.amenities.length} amenities',
            icon: _showAll ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            iconPosition: IconPosition.right,
            onPressed: () {
              setState(() {
                _showAll = !_showAll;
              });
            },
          ),
        ],
      ],
    );
  }
}

/// Categorized amenities display
class _CategorizedAmenities extends StatelessWidget {
  final Map<AmenityCategory, List<PropertyAmenity>> categorized;

  const _CategorizedAmenities({required this.categorized});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categorized.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spaceXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category title
              Text(
                entry.key.displayName,
                style: AppTypography.h3.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceM),

              // Amenities in category
              Wrap(
                spacing: AppDimensions.spaceM,
                runSpacing: AppDimensions.spaceM,
                children: entry.value.map((amenity) {
                  return AmenityChip(amenity: amenity);
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Amenity chip widget
class AmenityChip extends StatelessWidget {
  final PropertyAmenity amenity;

  const AmenityChip({
    super.key,
    required this.amenity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceS,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: AppDimensions.borderWidth,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getAmenityIcon(amenity),
            size: AppDimensions.iconM,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppDimensions.spaceS),
          Flexible(
            child: Text(
              amenity.displayName,
              style: AppTypography.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

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
      case PropertyAmenity.heating:
        return Icons.local_fire_department;
      case PropertyAmenity.kitchen:
        return Icons.kitchen;
      case PropertyAmenity.washingMachine:
        return Icons.local_laundry_service;
      case PropertyAmenity.tv:
        return Icons.tv;
      case PropertyAmenity.balcony:
        return Icons.balcony;
      case PropertyAmenity.seaView:
        return Icons.water;
      case PropertyAmenity.petFriendly:
        return Icons.pets;
      case PropertyAmenity.bbq:
        return Icons.outdoor_grill;
      case PropertyAmenity.outdoorFurniture:
        return Icons.deck;
      case PropertyAmenity.beachAccess:
        return Icons.beach_access;
      case PropertyAmenity.fireplace:
        return Icons.fireplace;
      case PropertyAmenity.gym:
        return Icons.fitness_center;
      case PropertyAmenity.hotTub:
        return Icons.hot_tub;
      case PropertyAmenity.sauna:
        return Icons.spa;
      case PropertyAmenity.bicycleRental:
        return Icons.pedal_bike;
      case PropertyAmenity.boatMooring:
        return Icons.directions_boat;
    }
  }
}

/// Amenity list item widget
class AmenityListItem extends StatelessWidget {
  final PropertyAmenity amenity;

  const AmenityListItem({
    super.key,
    required this.amenity,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spaceS),
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: AppShadows.glowPrimary,
          ),
          child: Icon(
            _getAmenityIcon(amenity),
            size: AppDimensions.iconS,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: Text(
            amenity.displayName,
            style: AppTypography.bodyLarge,
          ),
        ),
      ],
    );
  }

  IconData _getAmenityIcon(PropertyAmenity amenity) {
    // Same icon mapping as AmenityChip
    switch (amenity) {
      case PropertyAmenity.wifi:
        return Icons.wifi;
      case PropertyAmenity.parking:
        return Icons.local_parking;
      case PropertyAmenity.pool:
        return Icons.pool;
      case PropertyAmenity.airConditioning:
        return Icons.ac_unit;
      case PropertyAmenity.heating:
        return Icons.local_fire_department;
      case PropertyAmenity.kitchen:
        return Icons.kitchen;
      case PropertyAmenity.washingMachine:
        return Icons.local_laundry_service;
      case PropertyAmenity.tv:
        return Icons.tv;
      case PropertyAmenity.balcony:
        return Icons.balcony;
      case PropertyAmenity.seaView:
        return Icons.water;
      case PropertyAmenity.petFriendly:
        return Icons.pets;
      case PropertyAmenity.bbq:
        return Icons.outdoor_grill;
      case PropertyAmenity.outdoorFurniture:
        return Icons.deck;
      case PropertyAmenity.beachAccess:
        return Icons.beach_access;
      case PropertyAmenity.fireplace:
        return Icons.fireplace;
      case PropertyAmenity.gym:
        return Icons.fitness_center;
      case PropertyAmenity.hotTub:
        return Icons.hot_tub;
      case PropertyAmenity.sauna:
        return Icons.spa;
      case PropertyAmenity.bicycleRental:
        return Icons.pedal_bike;
      case PropertyAmenity.boatMooring:
        return Icons.directions_boat;
    }
  }
}

/// Amenity categories
enum AmenityCategory {
  essentials,
  kitchen,
  leisure,
  outdoor,
  parking,
  other,
}

extension AmenityCategoryExtension on AmenityCategory {
  String get displayName {
    switch (this) {
      case AmenityCategory.essentials:
        return 'Essentials';
      case AmenityCategory.kitchen:
        return 'Kitchen & Laundry';
      case AmenityCategory.leisure:
        return 'Leisure & Wellness';
      case AmenityCategory.outdoor:
        return 'Outdoor & Views';
      case AmenityCategory.parking:
        return 'Parking & Transportation';
      case AmenityCategory.other:
        return 'Other Amenities';
    }
  }
}

/// Amenities display style
enum AmenitiesDisplayStyle {
  /// Grid layout with chips
  grid,

  /// List layout with icons
  list,

  /// Categorized with sections
  categorized,
}
