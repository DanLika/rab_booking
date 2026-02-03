import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
    final signupsAsync = ref.watch(recentSignupsProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < _mobileBreakpoint;
    final isTablet = width >= _mobileBreakpoint && width < _tabletBreakpoint;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                final totalOwners = stats['totalOwners'] ?? 0;
                final trialUsers = stats['trialUsers'] ?? 0;
                final premiumUsers = stats['premiumUsers'] ?? 0;
                final lifetimeUsers = stats['lifetimeUsers'] ?? 0;

                final statsItems = [
                  _StatItem(
                    title: 'Total Owners',
                    value: totalOwners.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  _StatItem(
                    title: 'Trial Users',
                    value: trialUsers.toString(),
                    icon: Icons.timer,
                    color: Colors.orange,
                  ),
                  _StatItem(
                    title: 'Premium Users',
                    value: premiumUsers.toString(),
                    icon: Icons.star,
                    color: Colors.green,
                  ),
                  _StatItem(
                    title: 'Lifetime Licenses',
                    value: lifetimeUsers.toString(),
                    icon: Icons.verified,
                    color: Colors.purple,
                  ),
                ];

                // Responsive grid: 2 cols mobile/tablet, 4 cols desktop
                final availableWidth = width - 48;
                final columns = (isMobile || isTablet) ? 2 : 4;
                final totalSpacing = (columns - 1) * 16.0;
                final itemWidth = (availableWidth - totalSpacing) / columns;

                // Conversion rate
                final paidUsers = premiumUsers + lifetimeUsers;
                final conversionRate = totalOwners > 0
                    ? (paidUsers / totalOwners * 100)
                    : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: statsItems.map((item) {
                        return SizedBox(
                          width: itemWidth < 140 ? 140 : itemWidth,
                          child: _StatsCard(item: item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Analytics Section
                    Text(
                      'Analytics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        // Conversion rate card
                        SizedBox(
                          width: isMobile ? availableWidth : 280,
                          child: _AnalyticsCard(
                            title: 'Conversion Rate',
                            subtitle: 'Trial to Paid',
                            value: '${conversionRate.toStringAsFixed(1)}%',
                            detail: '$paidUsers of $totalOwners owners',
                            icon: Icons.trending_up,
                            color: Colors.teal,
                          ),
                        ),
                        // Recent signups
                        signupsAsync.when(
                          data: (signups) => SizedBox(
                            width: isMobile ? availableWidth : 280,
                            child: _AnalyticsCard(
                              title: 'New Signups',
                              subtitle: 'Last 7 days',
                              value: signups['last7Days']?.toString() ?? '0',
                              detail:
                                  '${signups['last30Days'] ?? 0} in last 30 days',
                              icon: Icons.person_add,
                              color: Colors.indigo,
                            ),
                          ),
                          loading: () => SizedBox(
                            width: isMobile ? availableWidth : 280,
                            height: 140,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        // Account type distribution
                        SizedBox(
                          width: isMobile ? availableWidth : 280,
                          child: _DistributionCard(
                            totalOwners: totalOwners,
                            trialUsers: trialUsers,
                            premiumUsers: premiumUsers,
                            lifetimeUsers: lifetimeUsers,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const _StatsLoading(),
              error: (err, _) => _StatsError(
                error: err.toString(),
                onRetry: () => ref.invalidate(dashboardStatsProvider),
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

  _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 24),
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

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  final int totalOwners;
  final int trialUsers;
  final int premiumUsers;
  final int lifetimeUsers;

  const _DistributionCard({
    required this.totalOwners,
    required this.trialUsers,
    required this.premiumUsers,
    required this.lifetimeUsers,
  });

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pie_chart,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Account Distribution',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Distribution bar
          if (totalOwners > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (trialUsers > 0)
                      Expanded(
                        flex: trialUsers,
                        child: Container(color: Colors.orange),
                      ),
                    if (premiumUsers > 0)
                      Expanded(
                        flex: premiumUsers,
                        child: Container(color: Colors.green),
                      ),
                    if (lifetimeUsers > 0)
                      Expanded(
                        flex: lifetimeUsers,
                        child: Container(color: Colors.purple),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Legend
          _DistLegendRow(
            color: Colors.orange,
            label: 'Trial',
            count: trialUsers,
            total: totalOwners,
          ),
          const SizedBox(height: 4),
          _DistLegendRow(
            color: Colors.green,
            label: 'Premium',
            count: premiumUsers,
            total: totalOwners,
          ),
          const SizedBox(height: 4),
          _DistLegendRow(
            color: Colors.purple,
            label: 'Lifetime',
            count: lifetimeUsers,
            total: totalOwners,
          ),
        ],
      ),
    );
  }
}

class _DistLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;

  const _DistLegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Text(
          '$count ($pct%)',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
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
