import '../../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_users_repository.dart';

/// Responsive breakpoint for mobile layout
const double _mobileBreakpoint = 800.0;
const double _tabletBreakpoint = 1100.0;

/// Admin dashboard with stats overview
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < _mobileBreakpoint;
    final isTablet = width >= _mobileBreakpoint && width < _tabletBreakpoint;

    return Scaffold(
      backgroundColor: Colors.transparent, // Uses shell background
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              'Dashboard Overview',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome back! Here is what\'s happening with your platform.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 32),

            // Stats Grid
            statsAsync.when(
              data: (stats) {
                final statsItems = [
                  _StatItem(
                    title: 'Total Owners',
                    value: stats['totalOwners']?.toString() ?? '0',
                    icon: Icons.people,
                    color: Colors.blue,
                    trend: '+12%', // Mock trend
                  ),
                  _StatItem(
                    title: 'Trial Users',
                    value: stats['trialUsers']?.toString() ?? '0',
                    icon: Icons.timer,
                    color: Colors.orange,
                    trend: '-5%', // Mock trend
                  ),
                  _StatItem(
                    title: 'Premium Users',
                    value: stats['premiumUsers']?.toString() ?? '0',
                    icon: Icons.star,
                    color: Colors.green,
                    trend: '+8%', // Mock trend
                  ),
                  _StatItem(
                    title: 'Lifetime Licenses',
                    value: stats['lifetimeUsers']?.toString() ?? '0',
                    icon: Icons.verified,
                    color: Colors.purple,
                    trend: '0%', // Mock trend
                  ),
                ];

                if (isMobile) {
                  return Column(
                    children: statsItems
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _StatsCard(item: item),
                          ),
                        )
                        .toList(),
                  );
                }

                // Grid Layout
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: statsItems.map((item) {
                    // Calculate width based on available space
                    // Desktop: 4 items per row (approx 25%)
                    // Tablet: 2 items per row (approx 50%)
                    final availableWidth =
                        width -
                        48 -
                        (isMobile ? 0 : 260); // Subtract padding and sidebar
                    final itemWidth = isTablet
                        ? (availableWidth - 16) / 2
                        : (availableWidth - 48) / 4;

                    // Ensure minimum width
                    return SizedBox(
                      width: itemWidth < 200 ? 200 : itemWidth,
                      child: _StatsCard(item: item),
                    );
                  }).toList(),
                );
              },
              loading: () => const _StatsLoading(),
              error: (err, _) => _StatsError(
                error: err.toString(),
                onRetry: () => ref.invalidate(dashboardStatsProvider),
              ),
            ),

            // Future placeholder for charts/activity
            const SizedBox(height: 48),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Activity Charts Coming Soon',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });
}

class _StatsCard extends StatelessWidget {
  final _StatItem item;

  const _StatsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              _TrendBadge(trend: item.trend, color: item.color),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final String trend;
  final Color color;

  const _TrendBadge({required this.trend, required this.color});

  @override
  Widget build(BuildContext context) {
    final isPositive = !trend.startsWith('-');
    final trendColor = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: trendColor,
          ),
          const SizedBox(width: 4),
          Text(
            trend,
            style: TextStyle(
              color: trendColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List.generate(
        4,
        (index) => Container(
          width: 240,
          height: 140,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _StatsError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _StatsError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error loading stats',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}
