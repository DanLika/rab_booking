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
      appBar: isMobile
          ? null // Mobile has AppBar in shell
          : AppBar(
              title: const Text('Dashboard'),
              automaticallyImplyLeading: false,
            ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: statsAsync.when(
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: isMobile
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              // Responsive stats grid
              LayoutBuilder(
                builder: (context, constraints) {
                  // Full width cards on mobile
                  if (constraints.maxWidth < _mobileBreakpoint) {
                    return Column(
                      children: [
                        _StatsCard(
                          title: 'Total Owners',
                          value: stats['totalOwners']?.toString() ?? '0',
                          icon: Icons.people,
                          color: Colors.blue,
                          fullWidth: true,
                        ),
                        const SizedBox(height: 16),
                        _StatsCard(
                          title: 'Trial Users',
                          value: stats['trialUsers']?.toString() ?? '0',
                          icon: Icons.timer,
                          color: Colors.orange,
                          fullWidth: true,
                        ),
                        const SizedBox(height: 16),
                        _StatsCard(
                          title: 'Premium Users',
                          value: stats['premiumUsers']?.toString() ?? '0',
                          icon: Icons.star,
                          color: Colors.green,
                          fullWidth: true,
                        ),
                      ],
                    );
                  }
                  // Wrap layout on desktop/tablet
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _StatsCard(
                        title: 'Total Owners',
                        value: stats['totalOwners']?.toString() ?? '0',
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      _StatsCard(
                        title: 'Trial Users',
                        value: stats['trialUsers']?.toString() ?? '0',
                        icon: Icons.timer,
                        color: Colors.orange,
                      ),
                      _StatsCard(
                        title: 'Premium Users',
                        value: stats['premiumUsers']?.toString() ?? '0',
                        icon: Icons.star,
                        color: Colors.green,
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
  final bool fullWidth;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: fullWidth ? double.infinity : 200,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
