import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/admin_providers.dart';
import '../../data/repositories/admin_repository.dart';

/// Admin Property Management Screen
class AdminPropertiesScreen extends ConsumerWidget {
  const AdminPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(adminPropertiesProvider);
    final filters = ref.watch(adminPropertyFiltersProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminPropertiesProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: EdgeInsets.all(isMobile ? AppDimensions.spaceM : AppDimensions.spaceL),
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surfaceLight,
            child: Row(
              children: [
                Text('Status:', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: AppDimensions.spaceM),
                FilterChip(
                  label: const Text('All'),
                  selected: filters.isActive == null,
                  onSelected: (_) => ref.read(adminPropertyFiltersProvider.notifier).setActiveStatus(null),
                ),
                const SizedBox(width: AppDimensions.spaceS),
                FilterChip(
                  label: const Text('Active'),
                  selected: filters.isActive == true,
                  onSelected: (_) => ref.read(adminPropertyFiltersProvider.notifier).setActiveStatus(true),
                ),
                const SizedBox(width: AppDimensions.spaceS),
                FilterChip(
                  label: const Text('Inactive'),
                  selected: filters.isActive == false,
                  onSelected: (_) => ref.read(adminPropertyFiltersProvider.notifier).setActiveStatus(false),
                ),
              ],
            ),
          ),
          // Properties List
          Expanded(
            child: propertiesAsync.when(
              data: (properties) {
                if (properties.isEmpty) {
                  return const Center(child: Text('No properties found'));
                }
                return ListView.separated(
                  padding: EdgeInsets.all(isMobile ? AppDimensions.spaceM : AppDimensions.spaceL),
                  itemCount: properties.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceM),
                  itemBuilder: (context, index) => _PropertyCard(property: properties[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ErrorStateWidget(
                message: 'Failed to load properties',
                onRetry: () => ref.invalidate(adminPropertiesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyCard extends ConsumerWidget {
  final dynamic property;
  const _PropertyCard({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (property.coverImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    child: Image.network(
                      property.coverImage!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 80,
                        height: 80,
                        color: AppColors.surfaceLight,
                        child: const Icon(Icons.home),
                      ),
                    ),
                  ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(property.name, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      Text(property.location, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
                      const SizedBox(height: AppDimensions.spaceXS),
                      Row(
                        children: [
                          Icon(
                            property.isActive ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: property.isActive ? AppColors.success : AppColors.error,
                          ),
                          const SizedBox(width: AppDimensions.spaceXXS),
                          Text(
                            property.isActive ? 'Active' : 'Inactive',
                            style: AppTypography.small.copyWith(
                              color: property.isActive ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(adminRepositoryProvider).togglePropertyStatus(property.id, !property.isActive);
                    ref.invalidate(adminPropertiesProvider);
                  },
                  icon: Icon(property.isActive ? Icons.pause : Icons.play_arrow, size: 16),
                  label: Text(property.isActive ? 'Deactivate' : 'Activate'),
                ),
                const SizedBox(width: AppDimensions.spaceS),
                TextButton.icon(
                  onPressed: () => _showDeleteDialog(context, ref, property),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, dynamic property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text('Delete "${property.name}"? This will delete all units and bookings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(adminRepositoryProvider).deleteProperty(property.id);
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(adminPropertiesProvider);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
