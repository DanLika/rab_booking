import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/admin_providers.dart';

/// Admin Dashboard - Main Overview Screen
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final recentActivityAsync = ref.watch(recentActivityProvider);
    final systemHealthAsync = ref.watch(systemHealthProvider);
    final isMobile = context.isMobile;
    final isDesktop = context.isDesktop;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(adminStatsProvider);
              ref.invalidate(recentActivityProvider);
              ref.invalidate(systemHealthProvider);
            },
            tooltip: 'Refresh',
          ),
          const SizedBox(width: AppDimensions.spaceS),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isMobile ? AppDimensions.spaceM : AppDimensions.spaceL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Text(
              'Dashboard Overview',
              style: AppTypography.h1,
            ),
            Text(
              'Monitor platform metrics and manage resources',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),

            // System Health Status
            systemHealthAsync.when(
              data: (health) => _SystemHealthBanner(health: health),
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
            ),
            const SizedBox(height: AppDimensions.spaceL),

            // Quick Actions
            _QuickActionsGrid(isDesktop: isDesktop, isMobile: isMobile),
            const SizedBox(height: AppDimensions.spaceXL),

            // Statistics Cards
            statsAsync.when(
              data: (stats) => _StatisticsCards(
                stats: stats,
                isMobile: isMobile,
                isDesktop: isDesktop,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ErrorStateWidget(
                message: 'Failed to load statistics',
                onRetry: () => ref.invalidate(adminStatsProvider),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),

            // Recent Activity
            Text(
              'Recent Activity',
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            recentActivityAsync.when(
              data: (activities) => _RecentActivityList(activities: activities),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ErrorStateWidget(
                message: 'Failed to load recent activity',
                onRetry: () => ref.invalidate(recentActivityProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// System health banner
class _SystemHealthBanner extends StatelessWidget {
  final dynamic health; // SystemHealth

  const _SystemHealthBanner({required this.health});

  @override
  Widget build(BuildContext context) {
    final isHealthy = health.databaseHealthy &&
        health.storageHealthy &&
        health.realtimeHealthy;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: isHealthy ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isHealthy ? AppColors.success : AppColors.error,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.error,
            color: isHealthy ? AppColors.success : AppColors.error,
            size: 24,
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHealthy ? 'All Systems Operational' : 'System Issues Detected',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isHealthy ? AppColors.success : AppColors.error,
                  ),
                ),
                if (!isHealthy)
                  Text(
                    'Some services are experiencing issues',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick actions grid
class _QuickActionsGrid extends StatelessWidget {
  final bool isDesktop;
  final bool isMobile;

  const _QuickActionsGrid({
    required this.isDesktop,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.people,
        label: 'Manage Users',
        color: AppColors.primary,
        onTap: () => context.go('/admin/users'),
      ),
      _QuickAction(
        icon: Icons.home_work,
        label: 'Manage Properties',
        color: AppColors.secondary,
        onTap: () => context.go('/admin/properties'),
      ),
      _QuickAction(
        icon: Icons.book,
        label: 'Manage Bookings',
        color: AppColors.warning,
        onTap: () => context.go('/admin/bookings'),
      ),
      _QuickAction(
        icon: Icons.analytics,
        label: 'View Analytics',
        color: AppColors.info,
        onTap: () => context.go('/admin/analytics'),
      ),
    ];

    final crossAxisCount = isDesktop ? 4 : (isMobile ? 2 : 3);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: AppDimensions.spaceM,
      crossAxisSpacing: AppDimensions.spaceM,
      childAspectRatio: 1.2,
      children: actions,
    );
  }
}

/// Quick action card
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceM),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Statistics cards grid
class _StatisticsCards extends StatelessWidget {
  final dynamic stats; // AdminStats
  final bool isMobile;
  final bool isDesktop;

  const _StatisticsCards({
    required this.stats,
    required this.isMobile,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isDesktop ? 4 : (isMobile ? 1 : 2);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: AppDimensions.spaceM,
      crossAxisSpacing: AppDimensions.spaceM,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Total Users',
          value: stats.totalUsers.toString(),
          subtitle: '+${stats.newUsersThisMonth} this month',
          icon: Icons.people,
          color: AppColors.primary,
        ),
        _StatCard(
          title: 'Total Properties',
          value: stats.totalProperties.toString(),
          subtitle: '${stats.activeProperties} active',
          icon: Icons.home,
          color: AppColors.secondary,
        ),
        _StatCard(
          title: 'Total Bookings',
          value: stats.totalBookings.toString(),
          subtitle: '${stats.activeBookings} active',
          icon: Icons.book,
          color: AppColors.warning,
        ),
        _StatCard(
          title: 'Total Revenue',
          value: '€${stats.totalRevenue.toStringAsFixed(0)}',
          subtitle: '€${stats.platformFeeTotal.toStringAsFixed(0)} platform fee',
          icon: Icons.euro,
          color: AppColors.success,
        ),
      ],
    );
  }
}

/// Stat card widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            Text(
              value,
              style: AppTypography.h1.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: AppTypography.small.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recent activity list
class _RecentActivityList extends StatelessWidget {
  final List<dynamic> activities; // List<UserActivity>

  const _RecentActivityList({required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXL),
          child: Center(
            child: Text(
              'No recent activity',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length > 10 ? 10 : activities.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(
                _getActivityIcon(activity.action),
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              activity.userName ?? activity.userEmail ?? 'Unknown User',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _getActivityDescription(activity),
              style: AppTypography.small,
            ),
            trailing: Text(
              _formatTime(activity.createdAt),
              style: AppTypography.small.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getActivityIcon(String action) {
    switch (action) {
      case 'created_booking':
        return Icons.book;
      case 'created_property':
        return Icons.home;
      case 'user_registered':
        return Icons.person_add;
      default:
        return Icons.circle;
    }
  }

  String _getActivityDescription(dynamic activity) {
    switch (activity.action) {
      case 'created_booking':
        return 'Created a new booking';
      case 'created_property':
        return 'Added a new property';
      case 'user_registered':
        return 'Registered a new account';
      default:
        return activity.action;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
