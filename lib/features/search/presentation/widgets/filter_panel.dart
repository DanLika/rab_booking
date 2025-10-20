import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/search_filters.dart';
import '../providers/search_state_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/range_slider.dart';

/// Premium filter panel widget
/// Features: Smooth animations, premium styling, responsive design
class PremiumFilterPanel extends ConsumerWidget {
  const PremiumFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(searchFiltersNotifierProvider);
    final notifier = ref.read(searchFiltersNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = context.isMobile;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL))
            : BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: AppShadows.elevation3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          // Header
          _buildHeader(context, filters, notifier, isDark),

          const Divider(height: 1),

          // Filter sections
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                isMobile ? AppDimensions.spaceM : AppDimensions.spaceL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Price range
                  _PriceRangeSection(filters: filters),

                  const SizedBox(height: AppDimensions.spaceXL),

                  // Property type
                  _PropertyTypeSection(filters: filters),

                  const SizedBox(height: AppDimensions.spaceXL),

                  // Amenities
                  _AmenitiesSection(filters: filters),

                  const SizedBox(height: AppDimensions.spaceXL),

                  // Bedrooms & Bathrooms
                  _RoomsSection(filters: filters),

                  const SizedBox(height: AppDimensions.spaceXL),
                ],
              ),
            ),
          ),

          // Footer with apply button
          if (isMobile) _buildFooter(context, filters, notifier, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    SearchFilters filters,
    dynamic notifier,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      child: Row(
        children: [
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Filteri',
                  style: AppTypography.h3.copyWith(
                    fontWeight: AppTypography.weightBold,
                  ),
                ),
                if (filters.filterCount > 0) ...[
                  const SizedBox(height: AppDimensions.spaceXXS),
                  Text(
                    '${filters.filterCount} ${filters.filterCount == 1 ? 'aktivan filter' : 'aktivnih filtera'}',
                    style: AppTypography.small.copyWith(
                      color: AppColors.primary,
                      fontWeight: AppTypography.weightMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Clear button
          if (filters.hasActiveFilters)
            PremiumButton.text(
              label: 'Očisti',
              icon: Icons.clear_all,
              onPressed: () => notifier.clearFilters(),
            ),

          // Close button (mobile)
          if (context.isMobile)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              tooltip: 'Zatvori',
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    SearchFilters filters,
    dynamic notifier,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: PremiumButton.primary(
        label: filters.filterCount > 0
            ? 'Prikaži rezultate (${filters.filterCount})'
            : 'Prikaži rezultate',
        icon: Icons.search,
        onPressed: () {
          notifier.applyFilters();
          Navigator.of(context).pop();
        },
        isFullWidth: true,
      ),
    );
  }

  /// Show as bottom sheet (mobile)
  static Future<void> showBottomSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => const PremiumFilterPanel(),
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

    return PremiumCard.elevated(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceS),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Icon(
                    Icons.euro,
                    color: context.textColorInverted,
                    size: AppDimensions.iconM,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: Text(
                    'Cjenovni raspon',
                    style: AppTypography.h3.copyWith(
                      fontWeight: AppTypography.weightSemibold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spaceL),

            PremiumRangeSlider(
              values: RangeValues(
                filters.minPrice ?? 0,
                filters.maxPrice ?? 500,
              ),
              min: 0,
              max: 1000,
              divisions: 100,
              currencySymbol: '€',
              minLabel: 'Min cijena',
              maxLabel: 'Max cijena',
              onChangeEnd: (values) {
                notifier.updatePriceRange(values.start, values.end);
              },
            ),
          ],
        ),
      ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceS),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(
                Icons.villa,
                color: context.textColorInverted,
                size: AppDimensions.iconM,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: Text(
                'Tip smještaja',
                style: AppTypography.h3.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.spaceM),

        Wrap(
          spacing: AppDimensions.spaceS,
          runSpacing: AppDimensions.spaceS,
          children: PropertyType.values.map((type) {
            final isSelected = filters.propertyTypes.contains(type);
            return AnimatedContainer(
              duration: AppAnimations.fast,
              child: FilterChip(
                label: Text(type.displayName),
                selected: isSelected,
                onSelected: (selected) => notifier.togglePropertyType(type),
                backgroundColor: isSelected ? AppColors.primary : null,
                selectedColor: AppColors.primary,
                checkmarkColor: context.textColorInverted,
                labelStyle: AppTypography.bodyMedium.copyWith(
                  color: isSelected ? context.textColorInverted : null,
                  fontWeight: isSelected
                      ? AppTypography.weightSemibold
                      : AppTypography.weightMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                side: isSelected
                    ? BorderSide.none
                    : BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceS),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(
                Icons.featured_play_list,
                color: context.textColorInverted,
                size: AppDimensions.iconM,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: Text(
                'Sadržaji',
                style: AppTypography.h3.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.spaceM),

        ...commonAmenities.map((amenity) {
          final isSelected = filters.amenities.contains(amenity);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spaceXS),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => notifier.toggleAmenity(amenity),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceM,
                    vertical: AppDimensions.spaceS,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : (isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariantLight),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: AppAnimations.fast,
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 14,
                                color: context.textColorInverted,
                              )
                            : null,
                      ),
                      const SizedBox(width: AppDimensions.spaceM),
                      Expanded(
                        child: Text(
                          getAmenityDisplayName(amenity),
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: isSelected
                                ? AppTypography.weightSemibold
                                : AppTypography.weightMedium,
                            color: isSelected ? AppColors.primary : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

    return PremiumCard.elevated(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceS),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Icon(
                    Icons.bed,
                    color: context.textColorInverted,
                    size: AppDimensions.iconM,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: Text(
                    'Broj soba',
                    style: AppTypography.h3.copyWith(
                      fontWeight: AppTypography.weightSemibold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // Bedrooms
            Text(
              'Spavaće sobe',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: AppTypography.weightMedium,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Wrap(
              spacing: AppDimensions.spaceS,
              runSpacing: AppDimensions.spaceS,
              children: List.generate(5, (index) {
                final bedrooms = index + 1;
                final isSelected = filters.minBedrooms == bedrooms;
                return _buildRoomChip(
                  label: '$bedrooms+',
                  isSelected: isSelected,
                  onSelected: (selected) {
                    notifier.updateMinBedrooms(selected ? bedrooms : null);
                  },
                );
              }),
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // Bathrooms
            Text(
              'Kupaonice',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: AppTypography.weightMedium,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Wrap(
              spacing: AppDimensions.spaceS,
              runSpacing: AppDimensions.spaceS,
              children: List.generate(3, (index) {
                final bathrooms = index + 1;
                final isSelected = filters.minBathrooms == bathrooms;
                return _buildRoomChip(
                  label: '$bathrooms+',
                  isSelected: isSelected,
                  onSelected: (selected) {
                    notifier.updateMinBathrooms(selected ? bathrooms : null);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: isSelected ? AppColors.primary : null,
      selectedColor: AppColors.primary,
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: isSelected ? Colors.white : null,
        fontWeight:
            isSelected ? AppTypography.weightSemibold : AppTypography.weightMedium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      side: isSelected ? BorderSide.none : null,
    );
  }
}
