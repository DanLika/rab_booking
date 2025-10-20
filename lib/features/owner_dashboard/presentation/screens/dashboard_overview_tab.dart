import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../widgets/dashboard_stats_card.dart';
import '../widgets/revenue_chart_widget.dart';
import '../widgets/recent_activity_widget.dart';
import '../providers/revenue_analytics_provider.dart';
import '../providers/performance_metrics_provider.dart';

/// Dashboard overview tab
/// Shows stats cards, revenue chart, and recent activity
class DashboardOverviewTab extends ConsumerWidget {
  const DashboardOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all data providers
    final revenueWeeklyAsync = ref.watch(revenueWeeklyProvider);
    final totalRevenueAsync = ref.watch(revenueThisMonthProvider);
    final revenueTrendAsync = ref.watch(revenueTrendProvider);
    final occupancyRateAsync = ref.watch(occupancyRateProvider);
    final occupancyTrendAsync = ref.watch(occupancyTrendProvider);
    final totalBookingsAsync = ref.watch(totalBookingsCountProvider);
    final bookingsTrendAsync = ref.watch(bookingsTrendProvider);
    final activeListingsAsync = ref.watch(activeListingsCountProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // Invalidate all providers to force refresh
        ref.invalidate(revenueWeeklyProvider);
        ref.invalidate(revenueThisMonthProvider);
        ref.invalidate(revenueTrendProvider);
        ref.invalidate(occupancyRateProvider);
        ref.invalidate(occupancyTrendProvider);
        ref.invalidate(totalBookingsCountProvider);
        ref.invalidate(bookingsTrendProvider);
        ref.invalidate(activeListingsCountProvider);
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          context.isMobile ? AppDimensions.spaceM : AppDimensions.spaceL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats cards grid - Show loading or data
            totalBookingsAsync.when(
              data: (totalBookings) => totalRevenueAsync.when(
                data: (totalRevenue) => occupancyRateAsync.when(
                  data: (occupancyRate) => activeListingsAsync.when(
                    data: (activeListings) => bookingsTrendAsync.when(
                      data: (bookingsTrend) => revenueTrendAsync.when(
                        data: (revenueTrend) => occupancyTrendAsync.when(
                          data: (occupancyTrendVal) {
                            // Format trends
                            final bookingsTrendStr = bookingsTrend >= 0
                                ? '+${bookingsTrend.toStringAsFixed(1)}%'
                                : '${bookingsTrend.toStringAsFixed(1)}%';
                            final revenueTrendStr = revenueTrend >= 0
                                ? '+${revenueTrend.toStringAsFixed(1)}%'
                                : '${revenueTrend.toStringAsFixed(1)}%';
                            final occupancyTrendStr = occupancyTrendVal >= 0
                                ? '+${occupancyTrendVal.toStringAsFixed(1)}%'
                                : '${occupancyTrendVal.toStringAsFixed(1)}%';

                            return DashboardStatsGrid(
                              totalBookings: totalBookings,
                              totalRevenue: totalRevenue,
                              occupancyRate: occupancyRate,
                              activeListings: activeListings,
                              bookingsTrend: bookingsTrendStr,
                              revenueTrend: revenueTrendStr,
                              occupancyTrend: occupancyTrendStr,
                              isBookingsTrendPositive: bookingsTrend >= 0,
                              isRevenueTrendPositive: revenueTrend >= 0,
                              isOccupancyTrendPositive: occupancyTrendVal >= 0,
                            );
                          },
                          loading: () => _buildLoadingStats(),
                          error: (e, s) => _buildErrorStats(e.toString()),
                        ),
                        loading: () => _buildLoadingStats(),
                        error: (e, s) => _buildErrorStats(e.toString()),
                      ),
                      loading: () => _buildLoadingStats(),
                      error: (e, s) => _buildErrorStats(e.toString()),
                    ),
                    loading: () => _buildLoadingStats(),
                    error: (e, s) => _buildErrorStats(e.toString()),
                  ),
                  loading: () => _buildLoadingStats(),
                  error: (e, s) => _buildErrorStats(e.toString()),
                ),
                loading: () => _buildLoadingStats(),
                error: (e, s) => _buildErrorStats(e.toString()),
              ),
              loading: () => _buildLoadingStats(),
              error: (e, s) => _buildErrorStats(e.toString()),
            ),

            const SizedBox(height: AppDimensions.spaceXL),

            // Charts section
            if (context.isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Revenue chart
                  Expanded(
                    flex: 2,
                    child: revenueWeeklyAsync.when(
                      data: (data) => RevenueChartWidget(
                        data: data,
                        subtitle: 'Last 7 days',
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, s) => Center(
                        child: Text('Error loading revenue data: $e'),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppDimensions.spaceL),

                  // Recent activity
                  Expanded(
                    child: RecentActivityWidget(
                      activities: _generateRecentActivities(),
                      onViewAll: () {
                        // Navigate to activity page
                      },
                    ),
                  ),
                ],
              )
            else ...[
              // Revenue chart
              revenueWeeklyAsync.when(
                data: (data) => RevenueChartWidget(
                  data: data,
                  subtitle: 'Last 7 days',
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, s) => Center(
                  child: Text('Error loading revenue data: $e'),
                ),
              ),

              const SizedBox(height: AppDimensions.spaceL),

              // Recent activity
              RecentActivityWidget(
                activities: _generateRecentActivities(),
                onViewAll: () {
                  // Navigate to activity page
                },
              ),
            ],

            const SizedBox(height: AppDimensions.spaceXL),

            // Quick actions
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingStats() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spaceXL),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorStats(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: AppDimensions.spaceM),
            const Text(
              'Error loading dashboard data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              error,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: AppDimensions.spaceM),

        Wrap(
          spacing: AppDimensions.spaceM,
          runSpacing: AppDimensions.spaceM,
          children: [
            _QuickActionButton(
              icon: Icons.add_home,
              label: 'Add Property',
              onTap: () {
                // Navigate to add property
              },
            ),
            _QuickActionButton(
              icon: Icons.calendar_month,
              label: 'Manage Calendar',
              onTap: () {
                // Navigate to calendar
              },
            ),
            _QuickActionButton(
              icon: Icons.euro_symbol,
              label: 'View Payments',
              onTap: () {
                // Navigate to payments
              },
            ),
            _QuickActionButton(
              icon: Icons.analytics,
              label: 'View Analytics',
              onTap: () {
                // Navigate to analytics
              },
            ),
          ],
        ),
      ],
    );
  }

  // Removed: _generateRevenueData() - now using real data from revenueWeeklyProvider

  List<ActivityItem> _generateRecentActivities() {
    final now = DateTime.now();
    return [
      ActivityItem(
        type: ActivityType.booking,
        title: 'New booking received',
        subtitle: 'Villa Mediteran - 7 nights',
        timestamp: now.subtract(const Duration(minutes: 15)),
      ),
      ActivityItem(
        type: ActivityType.review,
        title: 'New review posted',
        subtitle: '5 stars from John Smith',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      ActivityItem(
        type: ActivityType.payment,
        title: 'Payment received',
        subtitle: '€850.00 for booking #BK-2024-001',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      ActivityItem(
        type: ActivityType.message,
        title: 'New message',
        subtitle: 'Guest inquiry about Apartment Sunset',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      ActivityItem(
        type: ActivityType.booking,
        title: 'Booking confirmed',
        subtitle: 'Apartment Sunset - 3 nights',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}

/// Quick action button
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceL,
          vertical: AppDimensions.spaceM,
        ),
      ),
    );
  }
}
