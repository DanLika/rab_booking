import 'package:flutter/material.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../features/search/domain/models/search_filters.dart';

/// Property info section with title, location, rating, and quick facts
class PropertyInfoSection extends StatefulWidget {
  const PropertyInfoSection({
    required this.property,
    super.key,
  });

  final PropertyModel property;

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
        // Title
        Text(
          widget.property.name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        // Location and rating row
        Row(
          children: [
            // Rating
            if (widget.property.rating > 0) ...[
              Icon(Icons.star, size: 18, color: Colors.amber[700]),
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
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(width: 16),
              Text('•', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(width: 16),
            ],

            // Location
            Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.property.location,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),

        // Quick facts
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _QuickFactItem(
              icon: Icons.people_outline,
              label: 'Gosti',
              value: '1-8',
            ),
            _QuickFactItem(
              icon: Icons.bed_outlined,
              label: 'Spavaće sobe',
              value: '1-4',
            ),
            _QuickFactItem(
              icon: Icons.bathtub_outlined,
              label: 'Kupaonice',
              value: '1-3',
            ),
            _QuickFactItem(
              icon: Icons.square_foot,
              label: 'Površina',
              value: '45-120 m²',
            ),
          ],
        ),

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

        if (widget.property.description != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.property.description!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: Colors.grey[800],
                    ),
                maxLines: _isDescriptionExpanded ? null : 4,
                overflow: _isDescriptionExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
              if (widget.property.description!.length > 200)
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

  Widget _buildAmenitiesGrid() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final crossAxisCount = isMobile ? 2 : 3;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 12,
      children: widget.property.amenities.map((amenity) {
        return _AmenityItem(amenity: amenity);
      }).toList(),
    );
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
                    color: Colors.grey[600],
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

  final String amenity;

  IconData _getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('wifi')) return Icons.wifi;
    if (lower.contains('parking')) return Icons.local_parking;
    if (lower.contains('pool')) return Icons.pool;
    if (lower.contains('air')) return Icons.ac_unit;
    if (lower.contains('kitchen')) return Icons.kitchen;
    if (lower.contains('view')) return Icons.visibility;
    if (lower.contains('balcony')) return Icons.balcony;
    if (lower.contains('bbq')) return Icons.outdoor_grill;
    if (lower.contains('pet')) return Icons.pets;
    if (lower.contains('beach')) return Icons.beach_access;
    if (lower.contains('tv')) return Icons.tv;
    if (lower.contains('washer')) return Icons.local_laundry_service;
    return Icons.check_circle_outline;
  }

  String _getAmenityLabel(String amenity) {
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
    if (lower.contains('washer')) return 'Perilica';
    return amenity;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          _getAmenityIcon(amenity),
          size: 20,
          color: Colors.grey[700],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _getAmenityLabel(amenity),
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
