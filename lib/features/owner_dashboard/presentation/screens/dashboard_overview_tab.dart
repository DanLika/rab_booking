import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../widgets/recent_activity_widget.dart';
import '../providers/owner_properties_provider.dart';
import '../providers/owner_bookings_provider.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/enums.dart';

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
            _buildRecentActivity(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(WidgetRef ref) {
    final recentBookingsAsync = ref.watch(recentOwnerBookingsProvider);

    return recentBookingsAsync.when(
      data: (bookings) {
        final activities = bookings.map((ownerBooking) {
          return _convertBookingToActivity(ownerBooking);
        }).toList();

        return RecentActivityWidget(
          activities: activities,
          onViewAll: () {
            // Navigate to bookings tab
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spaceXL),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, s) => RecentActivityWidget(
        activities: const [],
        onViewAll: () {},
      ),
    );
  }

  ActivityItem _convertBookingToActivity(OwnerBooking ownerBooking) {
    final booking = ownerBooking.booking;
    final property = ownerBooking.property;
    final unit = ownerBooking.unit;

    // Determine activity type and details based on booking status
    ActivityType type;
    String title;
    String subtitle;

    switch (booking.status) {
      case BookingStatus.pending:
        type = ActivityType.booking;
        title = 'Nova rezervacija primljena';
        subtitle = '${property.name} - ${unit.name}';
        break;
      case BookingStatus.confirmed:
        type = ActivityType.payment;
        title = 'Rezervacija potvrđena';
        subtitle = '${property.name} - ${unit.name}';
        break;
      case BookingStatus.cancelled:
        type = ActivityType.cancellation;
        title = 'Rezervacija otkazana';
        subtitle = '${property.name} - ${unit.name}';
        break;
      case BookingStatus.inProgress:
        type = ActivityType.booking;
        title = 'Gost boravi';
        subtitle = '${property.name} - ${unit.name}';
        break;
      case BookingStatus.completed:
        type = ActivityType.booking;
        title = 'Rezervacija završena';
        subtitle = '${property.name} - ${unit.name}';
        break;
      case BookingStatus.blocked:
        type = ActivityType.cancellation;
        title = 'Datum blokiran';
        subtitle = '${property.name} - ${unit.name}';
        break;
    }

    return ActivityItem(
      type: type,
      title: title,
      subtitle: subtitle,
      timestamp: booking.createdAt,
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: AppDimensions.spaceXS),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
