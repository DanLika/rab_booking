import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/favorites_provider.dart';

/// Favorites Screen - Display user's favorite properties
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritePropertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Omiljene Nekretnine'),
        elevation: 0,
      ),
      body: favoritesAsync.when(
        data: (favorites) {
          if (favorites.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildFavoritesList(context, ref, favorites);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => _buildErrorState(context, ref, error),
      ),
    );
  }

  Widget _buildFavoritesList(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> favorites,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(favoritePropertiesProvider);
        return Future.value();
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Vaša Lista Želja',
              style: context.isMobile ? AppTypography.h3 : AppTypography.h2,
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              '${favorites.length} ${favorites.length == 1 ? 'nekretnina' : 'nekretnina'}',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),

            const SizedBox(height: AppDimensions.spaceXL),

            // Properties Grid
            ResponsiveGrid(
              mobileColumns: 1,
              tabletColumns: 2,
              desktopColumns: 3,
              spacing: context.spacing,
              children: favorites.map((property) {
                return PropertyCard(
                  property: property,
                  showFavoriteButton: true,
                );
              }).toList(),
            ),

            const SizedBox(height: AppDimensions.spaceXL),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 120,
              color: AppColors.textSecondaryLight.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              'Nemate Omiljenih Nekretnina',
              style: AppTypography.h3.copyWith(
                fontWeight: AppTypography.weightBold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              'Dodajte nekretnine u omiljene kako biste ih lako pronašli kasnije.',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            PremiumButton.primary(
              label: 'Pregledaj Nekretnine',
              onPressed: () {
                context.go('/search');
              },
              icon: Icons.search,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    Object error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              'Greška pri učitavanju',
              style: AppTypography.h3.copyWith(
                fontWeight: AppTypography.weightBold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              error.toString(),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            PremiumButton.primary(
              label: 'Pokušaj Ponovo',
              onPressed: () {
                ref.invalidate(favoritePropertiesProvider);
              },
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }
}
