import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/search_filters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';

/// No results empty state with helpful actions
/// Features: Illustration, clear message, action buttons, search suggestions
class SearchNoResults extends StatelessWidget {
  const SearchNoResults({
    required this.filters,
    required this.onClearFilters,
    super.key,
  });

  final SearchFilters filters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = context.isMobile;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          isMobile ? AppDimensions.spaceL : AppDimensions.spaceXXL,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            _buildIllustration(isDark),

            SizedBox(height: isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL),

            // Title
            Text(
              'Nema dostupnih smještaja',
              style: isMobile ? AppTypography.h2 : AppTypography.h1,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppDimensions.spaceM),

            // Message
            Text(
              filters.hasActiveFilters
                  ? 'Nije pronađen nijedan smještaj koji odgovara odabranim filterima.'
                  : 'Nije pronađen nijedan smještaj na ovoj lokaciji.',
              style: AppTypography.bodyLarge.copyWith(
                color: context.textColorSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),

            SizedBox(height: isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL),

            // Action buttons
            _buildActions(context, isMobile),

            if (filters.hasActiveFilters) ...[
              SizedBox(height: isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL),
              _buildSuggestions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(bool isDark) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circles
          ...List.generate(3, (index) {
            final size = 160.0 - (index * 40);
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2 - (index * 0.05)),
                  width: 2,
                ),
              ),
            );
          }),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppShadows.glowPrimary,
            ),
            child: const Icon(
              Icons.search_off,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isMobile) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppDimensions.spaceM,
      runSpacing: AppDimensions.spaceM,
      children: [
        if (filters.hasActiveFilters)
          PremiumButton.primary(
            label: 'Očisti filtere',
            icon: Icons.filter_alt_off,
            onPressed: onClearFilters,
          )
        else
          PremiumButton.primary(
            label: 'Pretražite sve smještaje',
            icon: Icons.explore,
            onPressed: () {
              context.go('/search');
            },
          ),

        PremiumButton.outline(
          label: 'Povratak na početnu',
          icon: Icons.home,
          onPressed: () {
            context.go('/');
          },
        ),
      ],
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    final suggestions = <String>[];

    if (filters.minPrice != null || filters.maxPrice != null) {
      suggestions.add('Pokušajte s širim cjenovnim rasponom');
    }

    if (filters.propertyTypes.isNotEmpty) {
      suggestions.add('Uklonite filter tipa smještaja');
    }

    if (filters.amenities.isNotEmpty) {
      if (filters.amenities.length > 3) {
        suggestions.add('Smanjite broj odabranih sadržaja');
      } else {
        suggestions.add('Uklonite neke od odabranih sadržaja');
      }
    }

    if (filters.minBedrooms != null || filters.minBathrooms != null) {
      suggestions.add('Smanjite broj soba');
    }

    if (suggestions.isEmpty) {
      suggestions.add('Pokušajte s drugom lokacijom');
      suggestions.add('Promijenite datume dolaska i odlaska');
    }

    return PremiumCard.elevated(
      elevation: 1,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.primary,
                    size: AppDimensions.iconM,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: Text(
                    'Prijedlozi',
                    style: AppTypography.h3.copyWith(
                      fontWeight: AppTypography.weightSemibold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spaceM),

            ...suggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
