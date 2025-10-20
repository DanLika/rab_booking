import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../widgets/recent_activity_widget.dart';
import '../providers/owner_properties_provider.dart';
import '../../../../core/theme/app_colors.dart';

/// Dashboard overview tab
/// Shows basic overview information and recent activity
class DashboardOverviewTab extends ConsumerWidget {
  const DashboardOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(ownerPropertiesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ownerPropertiesProvider);
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          context.isMobile ? AppDimensions.spaceM : AppDimensions.spaceL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Text(
              'Pregled',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppDimensions.spaceXS),
            Text(
              'Dobrodošli u vaš Dashboard',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),

            const SizedBox(height: AppDimensions.spaceXL),

            // Simple stats cards
            propertiesAsync.when(
              data: (properties) => _buildStatsCards(
                context,
                totalProperties: properties.length,
                activeProperties: properties.where((p) => p.isActive).length,
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.spaceXL),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, s) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceXL),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: AppDimensions.spaceM),
                      const Text(
                        'Greška prilikom učitavanja podataka',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                      Text(
                        e.toString(),
                        style:
                            const TextStyle(color: AppColors.textSecondaryLight),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.spaceXL),

            // Recent activity
            RecentActivityWidget(
              activities: _generateRecentActivities(),
              onViewAll: () {
                // Navigate to bookings tab
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(
    BuildContext context, {
    required int totalProperties,
    required int activeProperties,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
                ? 2
                : 1;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppDimensions.spaceM,
          crossAxisSpacing: AppDimensions.spaceM,
          childAspectRatio: constraints.maxWidth > 900
              ? 2.5
              : constraints.maxWidth > 600
                  ? 2.0
                  : 1.8,
          children: [
            _StatCard(
              title: 'Ukupno Nekretnina',
              value: '$totalProperties',
              icon: Icons.villa,
              color: AppColors.primary,
            ),
            _StatCard(
              title: 'Aktivne Nekretnine',
              value: '$activeProperties',
              icon: Icons.check_circle,
              color: AppColors.success,
            ),
            _StatCard(
              title: 'Neaktivne',
              value: '${totalProperties - activeProperties}',
              icon: Icons.pause_circle,
              color: AppColors.warning,
            ),
          ],
        );
      },
    );
  }

  List<ActivityItem> _generateRecentActivities() {
    final now = DateTime.now();
    return [
      ActivityItem(
        type: ActivityType.booking,
        title: 'Nova rezervacija primljena',
        subtitle: 'Villa Mediteran - 7 noćenja',
        timestamp: now.subtract(const Duration(minutes: 15)),
      ),
      ActivityItem(
        type: ActivityType.review,
        title: 'Nova recenzija',
        subtitle: '5 zvjezdica od John Smith',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      ActivityItem(
        type: ActivityType.payment,
        title: 'Plaćanje primljeno',
        subtitle: '€850.00 za rezervaciju #BK-2024-001',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      ActivityItem(
        type: ActivityType.message,
        title: 'Nova poruka',
        subtitle: 'Upit gosta o Apartment Sunset',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      ActivityItem(
        type: ActivityType.booking,
        title: 'Rezervacija potvrđena',
        subtitle: 'Apartment Sunset - 3 noćenja',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}

/// Simple stat card widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        side: BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceS),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppDimensions.spaceXS),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
