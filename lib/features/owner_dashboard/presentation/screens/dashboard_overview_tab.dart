import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/config/router_owner.dart';
import '../widgets/recent_activity_widget.dart';
import '../providers/owner_properties_provider.dart';
import '../providers/owner_bookings_provider.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/enums.dart';
import '../../../../shared/widgets/cards/cards.dart';

/// Dashboard overview tab
/// Shows basic overview information and recent activity
class DashboardOverviewTab extends ConsumerWidget {
  const DashboardOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(ownerPropertiesProvider);
    final isMobile = MediaQuery.of(context).size.width < AppDimensions.mobile;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ownerPropertiesProvider);
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          isMobile ? AppDimensions.spaceM : AppDimensions.spaceL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Welcome Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6B4CE6),
                    Color(0xFF4A90E2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4CE6).withAlpha((0.3 * 255).toInt()),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.dashboard_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pregled',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dobrodošli u vaš Dashboard',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withAlpha((0.9 * 255).toInt()),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B4CE6)),
                  ),
                ),
              ),
              error: (e, s) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceXL),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFEF4444).withAlpha((0.1 * 255).toInt()),
                              const Color(0xFFDC2626).withAlpha((0.05 * 255).toInt()),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceL),
                      const Text(
                        'Greška prilikom učitavanja podataka',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                      Text(
                        e.toString(),
                        style: const TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.spaceXL),

            // Recent activity
            _buildRecentActivity(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
    final recentBookingsAsync = ref.watch(recentOwnerBookingsProvider);

    return recentBookingsAsync.when(
      data: (bookings) {
        final activities = bookings.map((ownerBooking) {
          return _convertBookingToActivity(ownerBooking);
        }).toList();

        return RecentActivityWidget(
          activities: activities,
          onViewAll: () => context.go(OwnerRoutes.bookings),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spaceXL),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B4CE6)),
          ),
        ),
      ),
      error: (e, s) => RecentActivityWidget(
        activities: const [],
        onViewAll: () => context.go(OwnerRoutes.bookings),
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
        final isMobile = constraints.maxWidth < AppDimensions.mobile;
        final isTablet = constraints.maxWidth < AppDimensions.tablet;

        // Mobile: 2 cards per row, Desktop: 3 cards per row
        final cardsPerRow = isMobile ? 2 : 3;
        final spacing = isMobile ? 12.0 : 16.0;
        final cardWidth = isMobile
            ? (constraints.maxWidth - spacing * (cardsPerRow + 1)) / cardsPerRow
            : isTablet
                ? (constraints.maxWidth - spacing * (cardsPerRow + 1)) / cardsPerRow
                : 280.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.center,
          children: [
            _buildStatCard(
              context: context,
              title: 'Ukupno Nekretnina',
              value: '$totalProperties',
              icon: Icons.villa,
              color: const Color(0xFF6B4CE6),
              width: cardWidth,
            ),
            _buildStatCard(
              context: context,
              title: 'Aktivne Nekretnine',
              value: '$activeProperties',
              icon: Icons.check_circle,
              color: const Color(0xFF10B981),
              width: cardWidth,
            ),
            _buildStatCard(
              context: context,
              title: 'Neaktivne',
              value: '${totalProperties - activeProperties}',
              icon: Icons.pause_circle,
              color: const Color(0xFFF59E0B),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    final isMobile = MediaQuery.of(context).size.width < AppDimensions.mobile;

    return Container(
      width: width,
      height: isMobile ? 160 : 200, // FIXED HEIGHT
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withAlpha((0.1 * 255).toInt()),
            color.withAlpha((0.05 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha((0.2 * 255).toInt()),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha((0.15 * 255).toInt()),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon container
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withAlpha((0.2 * 255).toInt()),
                  color.withAlpha((0.1 * 255).toInt()),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha((0.3 * 255).toInt()),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: isMobile ? 28 : 36,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),

          // Value
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 28 : 40,
                  color: color,
                  height: 1.1,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 4 : 6),

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF4A5568),
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 11 : 13,
                  height: 1.2,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
