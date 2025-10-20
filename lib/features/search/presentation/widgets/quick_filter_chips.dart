import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/search_filters.dart';
import '../providers/search_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Quick filter preset model
class QuickFilterPreset {
  final String label;
  final IconData icon;
  final SearchFilters filters;
  final String description;

  const QuickFilterPreset({
    required this.label,
    required this.icon,
    required this.filters,
    required this.description,
  });
}

/// Predefined quick filter presets
class QuickFilterPresets {
  QuickFilterPresets._();

  static const List<QuickFilterPreset> presets = [
    QuickFilterPreset(
      label: 'Villa sa bazenom',
      icon: Icons.pool,
      filters: SearchFilters(
        propertyTypes: [PropertyType.villa],
        amenities: ['pool'],
      ),
      description: 'Luksuzne ville sa privatnim bazenom',
    ),
    QuickFilterPreset(
      label: 'Pogled na more',
      icon: Icons.water,
      filters: SearchFilters(
        amenities: ['sea_view'],
      ),
      description: 'Smještaji sa pogledom na more',
    ),
    QuickFilterPreset(
      label: 'Pristup plaži',
      icon: Icons.beach_access,
      filters: SearchFilters(
        amenities: ['beach_access'],
      ),
      description: 'Direktan pristup plaži',
    ),
    QuickFilterPreset(
      label: 'Pet friendly',
      icon: Icons.pets,
      filters: SearchFilters(
        amenities: ['pet_friendly'],
      ),
      description: 'Dozvoljeni kućni ljubimci',
    ),
    QuickFilterPreset(
      label: 'Luksuzni apartmani',
      icon: Icons.apartment,
      filters: SearchFilters(
        propertyTypes: [PropertyType.apartment],
        minPrice: 100,
        amenities: ['pool', 'air_conditioning', 'wifi'],
      ),
      description: 'Premium apartmani sa svim sadržajima',
    ),
    QuickFilterPreset(
      label: 'Budget friendly',
      icon: Icons.attach_money,
      filters: SearchFilters(
        maxPrice: 50,
      ),
      description: 'Povoljni smještaji do 50€',
    ),
    QuickFilterPreset(
      label: 'Velike grupe',
      icon: Icons.groups,
      filters: SearchFilters(
        guests: 8,
        minBedrooms: 4,
      ),
      description: 'Smještaji za veće grupe (8+ osoba)',
    ),
    QuickFilterPreset(
      label: 'Wellness',
      icon: Icons.spa,
      filters: SearchFilters(
        amenities: ['pool', 'bbq'],
        propertyTypes: [PropertyType.villa],
      ),
      description: 'Ville sa bazenom i roštiljem za opuštanje',
    ),
  ];

  /// Get preset by label
  static QuickFilterPreset? getByLabel(String label) {
    try {
      return presets.firstWhere((p) => p.label == label);
    } catch (_) {
      return null;
    }
  }
}

/// Quick filter chips widget
///
/// Displays horizontal scrollable list of quick filter presets
class QuickFilterChips extends ConsumerWidget {
  const QuickFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilters = ref.watch(searchFiltersNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceL,
            vertical: AppDimensions.spaceS,
          ),
          child: Row(
            children: [
              Icon(
                Icons.flash_on,
                size: AppDimensions.iconS,
                color: AppColors.tertiary,
              ),
              const SizedBox(width: AppDimensions.spaceS),
              Text(
                'Brzi filteri',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceL,
            ),
            itemCount: QuickFilterPresets.presets.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppDimensions.spaceS),
            itemBuilder: (context, index) {
              final preset = QuickFilterPresets.presets[index];
              final isActive = _isPresetActive(currentFilters, preset);

              return _QuickFilterChip(
                preset: preset,
                isActive: isActive,
                onTap: () {
                  final notifier = ref.read(searchFiltersNotifierProvider.notifier);

                  if (isActive) {
                    // Deactivate - clear filters
                    notifier.clearFilters();
                  } else {
                    // Activate - apply preset filters
                    _applyPreset(notifier, preset);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Check if preset is currently active
  bool _isPresetActive(SearchFilters current, QuickFilterPreset preset) {
    // Check property types
    if (preset.filters.propertyTypes.isNotEmpty) {
      if (!_listsEqual(current.propertyTypes, preset.filters.propertyTypes)) {
        return false;
      }
    }

    // Check amenities
    if (preset.filters.amenities.isNotEmpty) {
      if (!preset.filters.amenities.every((a) => current.amenities.contains(a))) {
        return false;
      }
    }

    // Check price
    if (preset.filters.minPrice != null && current.minPrice != preset.filters.minPrice) {
      return false;
    }
    if (preset.filters.maxPrice != null && current.maxPrice != preset.filters.maxPrice) {
      return false;
    }

    // Check guests
    if (preset.filters.guests > 0 && current.guests != preset.filters.guests) {
      return false;
    }

    // Check rooms
    if (preset.filters.minBedrooms != null &&
        current.minBedrooms != preset.filters.minBedrooms) {
      return false;
    }

    return true;
  }

  /// Compare two lists for equality
  bool _listsEqual<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!b.contains(a[i])) return false;
    }
    return true;
  }

  /// Apply preset filters
  void _applyPreset(dynamic notifier, QuickFilterPreset preset) {
    // Clear current filters first
    notifier.clearFilters();

    // Apply preset filters
    final filters = preset.filters;

    if (filters.propertyTypes.isNotEmpty) {
      for (final type in filters.propertyTypes) {
        notifier.togglePropertyType(type);
      }
    }

    if (filters.amenities.isNotEmpty) {
      for (final amenity in filters.amenities) {
        notifier.toggleAmenity(amenity);
      }
    }

    if (filters.minPrice != null || filters.maxPrice != null) {
      notifier.updatePriceRange(filters.minPrice, filters.maxPrice);
    }

    if (filters.guests > 0) {
      notifier.updateGuests(filters.guests);
    }

    if (filters.minBedrooms != null) {
      notifier.updateMinBedrooms(filters.minBedrooms);
    }

    if (filters.minBathrooms != null) {
      notifier.updateMinBathrooms(filters.minBathrooms);
    }

    // Apply filters
    notifier.applyFilters();
  }
}

/// Quick filter chip widget
class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.preset,
    required this.isActive,
    required this.onTap,
  });

  final QuickFilterPreset preset;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${preset.label} quick filter',
      hint: preset.description,
      selected: isActive,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceM,
              vertical: AppDimensions.spaceS,
            ),
            decoration: BoxDecoration(
              gradient: isActive ? AppColors.primaryGradient : null,
              color: isActive ? null : AppColors.surfaceVariantLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(
                color: isActive ? Colors.transparent : AppColors.borderLight,
                width: 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  preset.icon,
                  size: AppDimensions.iconS,
                  color: isActive ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.spaceS),
                Text(
                  preset.label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isActive
                        ? AppTypography.weightSemibold
                        : AppTypography.weightMedium,
                    color: isActive ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
