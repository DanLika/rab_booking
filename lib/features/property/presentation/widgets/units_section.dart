import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/property_unit.dart';

/// Units section showing all available units in a property
class UnitsSection extends StatelessWidget {
  const UnitsSection({
    required this.units,
    required this.onSelectUnit,
    super.key,
  });

  final List<PropertyUnit> units;
  final void Function(PropertyUnit unit) onSelectUnit;

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dostupni smještaji',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: units.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _UnitCard(
              unit: units[index],
              onSelect: () => onSelectUnit(units[index]),
            );
          },
        ),
      ],
    );
  }
}

/// Unit card widget
class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.onSelect,
  });

  final PropertyUnit unit;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: isMobile ? _buildMobileLayout(context) : _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        _buildImage(),

        // Content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildSpecs(context),
              const SizedBox(height: 16),
              _buildPricing(context),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSelect,
                  child: const Text('Odaberi'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Image (30%)
        SizedBox(
          width: 200,
          height: 200,
          child: _buildImage(),
        ),

        // Content (70%)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 12),
                          _buildSpecs(context),
                          if (unit.description != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              unit.description!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildPricing(context),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: onSelect,
                          child: const Text('Odaberi'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    final imageUrl = unit.coverImage ??
        (unit.images.isNotEmpty ? unit.images.first : null);

    return CachedNetworkImage(
      imageUrl: imageUrl ?? 'https://via.placeholder.com/400x300?text=No+Image',
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.villa, size: 60, color: Colors.grey),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          unit.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${unit.area.toStringAsFixed(0)} m²',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildSpecs(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _SpecItem(
          icon: Icons.people_outline,
          label: '${unit.maxGuests} ${unit.maxGuests == 1 ? 'gost' : 'gostiju'}',
        ),
        _SpecItem(
          icon: Icons.bed_outlined,
          label: '${unit.bedrooms} ${unit.bedrooms == 1 ? 'soba' : 'sobe'}',
        ),
        _SpecItem(
          icon: Icons.bathtub_outlined,
          label: '${unit.bathrooms} ${unit.bathrooms == 1 ? 'kupaonica' : 'kupaonice'}',
        ),
      ],
    );
  }

  Widget _buildPricing(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '€${unit.pricePerNight.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(width: 4),
            Text(
              '/ noć',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        if (unit.minStayNights > 1)
          Text(
            'Min. ${unit.minStayNights} noći',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
      ],
    );
  }
}

/// Spec item widget
class _SpecItem extends StatelessWidget {
  const _SpecItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
