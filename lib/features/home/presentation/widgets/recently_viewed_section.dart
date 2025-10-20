import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart'; // Unused
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
// import '../../../../shared/models/property_model.dart'; // Unused - provided by widgets.dart
import '../../../../shared/widgets/widgets.dart';
import '../../../search/presentation/providers/recently_viewed_provider.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

/// Recently Viewed Properties Section
/// Shows horizontal scrollable list of properties the user has viewed
class RecentlyViewedSection extends ConsumerWidget {
  const RecentlyViewedSection({
    this.title = 'Recently Viewed',
    this.subtitle = 'Properties you have viewed recently',
    this.maxProperties = 10,
    super.key,
  });

  final String title;
  final String subtitle;
  final int maxProperties;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isLoggedIn = authState.user != null;

    // Don't show section if user is not logged in
    if (!isLoggedIn) {
      return const SizedBox.shrink();
    }

    final recentlyViewedAsync = ref.watch(recentlyViewedPropertiesProvider);

    return recentlyViewedAsync.when(
      loading: () => const SizedBox.shrink(), // Don't show loading for recently viewed
      error: (error, stack) => const SizedBox.shrink(), // Silently hide on error
      data: (properties) {
        // Don't show section if no properties
        if (properties.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayProperties = properties.take(maxProperties).toList();
        final isMobile = context.isMobile;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceDark.withValues(alpha: 0.5)
                    : AppColors.surfaceLight.withValues(alpha: 0.5),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? AppDimensions.spaceM : AppDimensions.spaceXL,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              color: AppColors.primary,
                              size: isMobile ? 24 : 28,
                            ),
                            const SizedBox(width: AppDimensions.spaceS),
                            Text(
                              title,
                              style: isMobile
                                  ? AppTypography.h3
                                  : AppTypography.h2,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spaceXS),
                        Text(
                          subtitle,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    // Clear History Button
                    TextButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear History'),
                            content: const Text(
                              'Are you sure you want to clear your viewing history?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              PremiumButton.primary(
                                label: 'Clear',
                                onPressed: () => Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await ref
                              .read(recentlyViewedNotifierProvider.notifier)
                              .clearHistory();
                        }
                      },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceL),

              // Horizontal Property List
              SizedBox(
                height: isMobile ? 320 : 360,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? AppDimensions.spaceM : AppDimensions.spaceXL,
                  ),
                  itemCount: displayProperties.length,
                  itemBuilder: (context, index) {
                    final property = displayProperties[index];

                    return Container(
                      width: isMobile ? 280 : 320,
                      margin: EdgeInsets.only(
                        right: index == displayProperties.length - 1
                            ? 0
                            : AppDimensions.spaceL,
                      ),
                      child: PropertyCard(
                        property: property,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
