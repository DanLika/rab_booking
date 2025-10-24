import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../core/constants/enums.dart';
import '../../domain/models/property_unit.dart';
import '../../../../../core/theme/theme_extensions.dart';

/// Property info section with title, location, rating, and quick facts
class PropertyInfoSection extends StatefulWidget {
  const PropertyInfoSection({
    required this.property,
    this.units,
    super.key,
  });

  final PropertyModel property;
  final List<PropertyUnit>? units;

  @override
  State<PropertyInfoSection> createState() => _PropertyInfoSectionState();
}

class _PropertyInfoSectionState extends State<PropertyInfoSection> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (30px, bold as per spec)
        AutoSizeText(
          widget.property.name,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          maxLines: 2,
          minFontSize: 20,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),

        // Location and rating row
        Row(
          children: [
            // Rating
            if (widget.property.rating > 0) ...[
              Icon(Icons.star, size: 18, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 4),
              Text(
                widget.property.rating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${widget.property.reviewCount} recenzija)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.textColorSecondary,
                    ),
              ),
              const SizedBox(width: 16),
              Text('•', style: TextStyle(color: context.borderColor)),
              const SizedBox(width: 16),
            ],

            // Location
            Icon(Icons.location_on, size: 18, color: context.iconColorSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: AutoSizeText(
                widget.property.location,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                minFontSize: 12,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),

        // Quick facts (dynamic from units)
        _buildQuickFacts(),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),

        // Description
        Text(
          'O smještaju',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        if (widget.property.description.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                widget.property.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6, // Line height as per spec
                      color: context.textColor,
                    ),
                maxLines: _isDescriptionExpanded ? null : 4,
                minFontSize: 14,
                overflow: _isDescriptionExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
              if (widget.property.description.length > 500) // Show more if >500 chars
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isDescriptionExpanded = !_isDescriptionExpanded;
                    });
                  },
                  child: Text(
                    _isDescriptionExpanded ? 'Prikaži manje' : 'Prikaži više',
                  ),
                ),
            ],
          ),

        const SizedBox(height: 32),

        // Amenities
        Text(
          'Sadržaji',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        _buildAmenitiesGrid(),
      ],
    );
  }

  Widget _buildQuickFacts() {
    // Calculate ranges from units if available
    if (widget.units != null && widget.units!.isNotEmpty) {
      final units = widget.units!;

      // Calculate min/max guests
      final minGuests = units.map((u) => u.maxGuests).reduce((a, b) => a < b ? a : b);
      final maxGuests = units.map((u) => u.maxGuests).reduce((a, b) => a > b ? a : b);
      final guestsValue = minGuests == maxGuests ? '$minGuests' : '$minGuests-$maxGuests';

      // Calculate min/max bedrooms
      final minBedrooms = units.map((u) => u.bedrooms).reduce((a, b) => a < b ? a : b);
      final maxBedrooms = units.map((u) => u.bedrooms).reduce((a, b) => a > b ? a : b);
      final bedroomsValue = minBedrooms == maxBedrooms ? '$minBedrooms' : '$minBedrooms-$maxBedrooms';

      // Calculate min/max bathrooms
      final minBathrooms = units.map((u) => u.bathrooms).reduce((a, b) => a < b ? a : b);
      final maxBathrooms = units.map((u) => u.bathrooms).reduce((a, b) => a > b ? a : b);
      final bathroomsValue = minBathrooms == maxBathrooms ? '$minBathrooms' : '$minBathrooms-$maxBathrooms';

      // Calculate min/max area
      final minArea = units.map((u) => u.area).reduce((a, b) => a < b ? a : b);
      final maxArea = units.map((u) => u.area).reduce((a, b) => a > b ? a : b);
      final areaValue = minArea == maxArea ? '${minArea.toInt()} m²' : '${minArea.toInt()}-${maxArea.toInt()} m²';

      return Wrap(
        spacing: 24,
        runSpacing: 16,
        children: [
          _QuickFactItem(
            icon: Icons.people_outline,
            label: 'Gosti',
            value: guestsValue,
          ),
          _QuickFactItem(
            icon: Icons.bed_outlined,
            label: 'Spavaće sobe',
            value: bedroomsValue,
          ),
          _QuickFactItem(
            icon: Icons.bathtub_outlined,
            label: 'Kupaonice',
            value: bathroomsValue,
          ),
          _QuickFactItem(
            icon: Icons.square_foot,
            label: 'Površina',
            value: areaValue,
          ),
        ],
      );
    }

    // Fallback to property data or placeholders if units not available
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: [
        if (widget.property.maxGuests != null)
          _QuickFactItem(
            icon: Icons.people_outline,
            label: 'Gosti',
            value: '${widget.property.maxGuests}',
          ),
        if (widget.property.bedrooms != null)
          _QuickFactItem(
            icon: Icons.bed_outlined,
            label: 'Spavaće sobe',
            value: '${widget.property.bedrooms}',
          ),
        if (widget.property.bathrooms != null)
          _QuickFactItem(
            icon: Icons.bathtub_outlined,
            label: 'Kupaonice',
            value: '${widget.property.bathrooms}',
          ),
      ],
    );
  }

  Widget _buildAmenitiesGrid() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    // Group amenities by category
    final basicAmenities = widget.property.amenities.where((a) => _isBasicAmenity(a)).toList();
    final kitchenAmenities = widget.property.amenities.where((a) => _isKitchenAmenity(a)).toList();
    final outdoorAmenities = widget.property.amenities.where((a) => _isOutdoorAmenity(a)).toList();
    final entertainmentAmenities = widget.property.amenities.where((a) => _isEntertainmentAmenity(a)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (basicAmenities.isNotEmpty)
          _buildAmenityGroup('Osnovni sadržaji', basicAmenities, isMobile),

        if (kitchenAmenities.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildAmenityGroup('Kuhinja', kitchenAmenities, isMobile),
        ],

        if (outdoorAmenities.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildAmenityGroup('Vanjski prostor', outdoorAmenities, isMobile),
        ],

        if (entertainmentAmenities.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildAmenityGroup('Zabava i rekreacija', entertainmentAmenities, isMobile),
        ],
      ],
    );
  }

  Widget _buildAmenityGroup(String title, List<PropertyAmenity> amenities, bool isMobile) {
    final crossAxisCount = isMobile ? 2 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 12,
          children: amenities.map((amenity) {
            return _AmenityItem(amenity: amenity);
          }).toList(),
        ),
      ],
    );
  }

  bool _isBasicAmenity(PropertyAmenity amenity) {
    return amenity == PropertyAmenity.wifi ||
        amenity == PropertyAmenity.parking ||
        amenity == PropertyAmenity.airConditioning ||
        amenity == PropertyAmenity.heating ||
        amenity == PropertyAmenity.washingMachine ||
        amenity == PropertyAmenity.tv ||
        amenity == PropertyAmenity.petFriendly;
  }

  bool _isKitchenAmenity(PropertyAmenity amenity) {
    return amenity == PropertyAmenity.kitchen;
  }

  bool _isOutdoorAmenity(PropertyAmenity amenity) {
    return amenity == PropertyAmenity.pool ||
        amenity == PropertyAmenity.balcony ||
        amenity == PropertyAmenity.seaView ||
        amenity == PropertyAmenity.bbq ||
        amenity == PropertyAmenity.outdoorFurniture ||
        amenity == PropertyAmenity.beachAccess;
  }

  bool _isEntertainmentAmenity(PropertyAmenity amenity) {
    return amenity == PropertyAmenity.fireplace ||
        amenity == PropertyAmenity.gym ||
        amenity == PropertyAmenity.hotTub ||
        amenity == PropertyAmenity.sauna ||
        amenity == PropertyAmenity.bicycleRental ||
        amenity == PropertyAmenity.boatMooring;
  }
}

/// Quick fact item widget
class _QuickFactItem extends StatelessWidget {
  const _QuickFactItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textColorSecondary,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Amenity item widget
class _AmenityItem extends StatelessWidget {
  const _AmenityItem({required this.amenity});

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
      case PropertyAmenity.petFriendly:
        return Icons.pets;
      case PropertyAmenity.beachAccess:
        return Icons.beach_access;
      case PropertyAmenity.tv:
        return Icons.tv;
      case PropertyAmenity.washingMachine:
        return Icons.local_laundry_service;
      case PropertyAmenity.fireplace:
        return Icons.fireplace;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          _getAmenityIcon(amenity),
          size: 20,
          color: context.iconColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            amenity.displayName,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Common amenities list
final commonAmenities = [
  'wifi',
  'parking',
  'pool',
  'air_conditioning',
  'kitchen',
  'sea_view',
  'balcony',
  'bbq',
  'pet_friendly',
  'beach_access',
  'tv',
  'washer',
];

/// Get amenity display name
String getAmenityDisplayName(String amenity) {
  final lower = amenity.toLowerCase();
  if (lower.contains('wifi')) return 'WiFi';
  if (lower.contains('parking')) return 'Parking';
  if (lower.contains('pool')) return 'Bazen';
  if (lower.contains('air')) return 'Klima';
  if (lower.contains('kitchen')) return 'Kuhinja';
  if (lower.contains('view')) return 'Pogled na more';
  if (lower.contains('balcony')) return 'Balkon';
  if (lower.contains('bbq')) return 'Roštilj';
  if (lower.contains('pet')) return 'Kućni ljubimci';
  if (lower.contains('beach')) return 'Pristup plaži';
  if (lower.contains('tv')) return 'TV';
  if (lower.contains('washer')) return 'Perilica rublja';
  return amenity;
}
