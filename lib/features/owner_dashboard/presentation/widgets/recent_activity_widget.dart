import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/widgets.dart';

/// Activity type enum
enum ActivityType {
  booking,
  review,
  message,
  payment,
  cancellation,
}

/// Activity item model
class ActivityItem {
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String? imageUrl;

  const ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.imageUrl,
  });

  IconData get icon {
    switch (type) {
      case ActivityType.booking:
        return Icons.book_online;
      case ActivityType.review:
        return Icons.star;
      case ActivityType.message:
        return Icons.message;
      case ActivityType.payment:
        return Icons.euro;
      case ActivityType.cancellation:
        return Icons.cancel;
    }
  }

  Color get color {
    switch (type) {
      case ActivityType.booking:
        return AppColors.success;
      case ActivityType.review:
        return AppColors.warning;
      case ActivityType.message:
        return AppColors.info;
      case ActivityType.payment:
        return AppColors.primary;
      case ActivityType.cancellation:
        return AppColors.error;
    }
  }
}

/// Recent activity widget
class RecentActivityWidget extends StatelessWidget {
  final List<ActivityItem> activities;
  final VoidCallback? onViewAll;

  const RecentActivityWidget({
    super.key,
    required this.activities,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumCard.elevated(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            child: Row(
              children: [
                Text(
                  'Recent Activity',
                  style: AppTypography.h3,
                ),
                const Spacer(),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('View All'),
                  ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // Activities list
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceXL),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    Text(
                      'No recent activity',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length > 5 ? 5 : activities.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _ActivityTile(activity: activity);
              },
            ),
        ],
      ),
    );
  }
}

/// Activity tile
class _ActivityTile extends StatelessWidget {
  final ActivityItem activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceL,
        vertical: AppDimensions.spaceS,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.withOpacity(activity.color, AppColors.opacity10),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Icon(
          activity.icon,
          color: activity.color,
          size: AppDimensions.iconM,
        ),
      ),
      title: Text(
        activity.title,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: AppTypography.weightSemibold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        activity.subtitle,
        style: AppTypography.small.copyWith(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: SizedBox(
        width: 60, // Fixed width to prevent overflow
        child: Text(
          _formatTimestamp(activity.timestamp),
          style: AppTypography.small.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
