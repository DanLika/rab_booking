import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/search_filters.dart';
import '../providers/search_state_provider.dart';

/// Filter panel widget (responsive: sidebar on desktop, bottom sheet on mobile)
class FilterPanelWidget extends ConsumerWidget {
  const FilterPanelWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(searchFiltersNotifierProvider);
    final notifier = ref.read(searchFiltersNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filteri',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (filters.hasActiveFilters)
                  TextButton(
                    onPressed: () => notifier.clearFilters(),
                    child: const Text('Očisti sve'),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Price range
            _PriceRangeSection(filters: filters),
            const Divider(height: 32),

            // Property type
            _PropertyTypeSection(filters: filters),
            const Divider(height: 32),

            // Amenities
            _AmenitiesSection(filters: filters),
            const Divider(height: 32),

            // Bedrooms & Bathrooms
            _RoomsSection(filters: filters),
            const SizedBox(height: 32),

            // Apply button
            FilledButton(
              onPressed: () {
                notifier.applyFilters();
                Navigator.of(context).pop(); // Close bottom sheet if mobile
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                filters.filterCount > 0
                    ? 'Primijeni (${filters.filterCount})'
                    : 'Primijeni filtere',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show as bottom sheet (mobile)
  static Future<void> showBottomSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const FilterPanelWidget(),
      ),
    );
  }
}

/// Price range section
class _PriceRangeSection extends ConsumerWidget {
  const _PriceRangeSection({required this.filters});

  final SearchFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(searchFiltersNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cjenovni raspon',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Min €',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  notifier.updatePriceRange(price, filters.maxPrice);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Max €',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  notifier.updatePriceRange(filters.minPrice, price);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Property type section
class _PropertyTypeSection extends ConsumerWidget {
  const _PropertyTypeSection({required this.filters});

  final SearchFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(searchFiltersNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tip smještaja',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PropertyType.values.map((type) {
            final isSelected = filters.propertyTypes.contains(type);
            return FilterChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (selected) => notifier.togglePropertyType(type),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Amenities section
class _AmenitiesSection extends ConsumerWidget {
  const _AmenitiesSection({required this.filters});

  final SearchFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(searchFiltersNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sadržaji',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...commonAmenities.map((amenity) {
          final isSelected = filters.amenities.contains(amenity);
          return CheckboxListTile(
            title: Text(getAmenityDisplayName(amenity)),
            value: isSelected,
            onChanged: (value) => notifier.toggleAmenity(amenity),
            contentPadding: EdgeInsets.zero,
            dense: true,
          );
        }),
      ],
    );
  }
}

/// Rooms section
class _RoomsSection extends ConsumerWidget {
  const _RoomsSection({required this.filters});

  final SearchFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(searchFiltersNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Broj soba',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        // Bedrooms
        Row(
          children: [
            Expanded(
              child: Text('Spavaće sobe'),
            ),
            ...List.generate(5, (index) {
              final bedrooms = index + 1;
              final isSelected = filters.minBedrooms == bedrooms;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text('$bedrooms+'),
                  selected: isSelected,
                  onSelected: (selected) {
                    notifier.updateMinBedrooms(selected ? bedrooms : null);
                  },
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 16),
        // Bathrooms
        Row(
          children: [
            Expanded(
              child: Text('Kupaonice'),
            ),
            ...List.generate(3, (index) {
              final bathrooms = index + 1;
              final isSelected = filters.minBathrooms == bathrooms;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text('$bathrooms+'),
                  selected: isSelected,
                  onSelected: (selected) {
                    notifier.updateMinBathrooms(selected ? bathrooms : null);
                  },
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
