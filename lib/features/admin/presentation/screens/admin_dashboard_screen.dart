import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_users_repository.dart';

/// Responsive breakpoint for mobile layout
const double _mobileBreakpoint = 600.0;

/// Admin dashboard with stats overview
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final isMobile = MediaQuery.of(context).size.width < _mobileBreakpoint;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: statsAsync.when(
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Stats in a single row (responsive)
              LayoutBuilder(
                builder: (context, constraints) {
                  // On mobile, stack vertically with smaller spacing
                  if (constraints.maxWidth < _mobileBreakpoint) {
                    return Column(
                      children: [
                        _StatsCard(
                          title: 'Total Owners',
                          value: stats['totalOwners']?.toString() ?? '0',
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        _StatsCard(
                          title: 'Trial Users',
                          value: stats['trialUsers']?.toString() ?? '0',
                          icon: Icons.timer,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 8),
                        _StatsCard(
                          title: 'Premium Users',
                          value: stats['premiumUsers']?.toString() ?? '0',
                          icon: Icons.star,
                          color: Colors.green,
                        ),
                      ],
                    );
                  }
                  // On desktop/tablet, single row with flex
                  return Row(
                    children: [
                      Expanded(
                        child: _StatsCard(
                          title: 'Total Owners',
                          value: stats['totalOwners']?.toString() ?? '0',
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatsCard(
                          title: 'Trial Users',
                          value: stats['trialUsers']?.toString() ?? '0',
                          icon: Icons.timer,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatsCard(
                          title: 'Premium Users',
                          value: stats['premiumUsers']?.toString() ?? '0',
                          icon: Icons.star,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading stats',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(dashboardStatsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
