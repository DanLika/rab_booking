import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/widgets.dart';

/// Activity type enum
enum ActivityType { booking, review, message, payment, cancellation }

/// Activity item model
class ActivityItem {
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String? imageUrl;
  final String? bookingId;

  const ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.imageUrl,
    this.bookingId,
  });

  IconData get icon {
    switch (type) {
      case ActivityType.booking:
        return Icons.event_available_rounded;
      case ActivityType.review:
        return Icons.star_rounded;
      case ActivityType.message:
        return Icons.message_rounded;
      case ActivityType.payment:
        return Icons.payments_rounded;
      case ActivityType.cancellation:
        return Icons.event_busy_rounded;
    }
  }

  Color get color {
    switch (type) {
      case ActivityType.booking:
        return AppColors.activityBooking;
      case ActivityType.review:
        return AppColors.activityReview;
      case ActivityType.message:
        return AppColors.activityMessage;
      case ActivityType.payment:
        return AppColors.activityPayment;
      case ActivityType.cancellation:
        return AppColors.activityCancellation;
    }
  }
}

/// Recent activity widget
class RecentActivityWidget extends StatelessWidget {
  final List<ActivityItem> activities;
  final VoidCallback? onViewAll;
  final void Function(String bookingId)? onActivityTap;

  const RecentActivityWidget({
    super.key,
    required this.activities,
    this.onViewAll,
    this.onActivityTap,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Very narrow screen - stack vertically
                if (constraints.maxWidth < 300) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: AppTypography.h3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (onViewAll != null) ...[
                        const SizedBox(height: AppDimensions.spaceXS),
                        TextButton(
                          onPressed: onViewAll,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spaceS,
                              vertical: AppDimensions.spaceXS,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('View All'),
                        ),
                      ],
                    ],
                  );
                }

                // Normal width - horizontal layout
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Nedavne Aktivnosti',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onViewAll != null) ...[
                      const SizedBox(width: AppDimensions.spaceS),
                      TextButton.icon(
                        onPressed: onViewAll,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          foregroundColor: AppColors.primary,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text(
                          'Sve',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
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
              padding: const EdgeInsets.symmetric(
                vertical: 56,
                horizontal: AppDimensions.spaceL,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Enhanced icon with gradient background
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.authPrimary.withAlpha(
                              (0.15 * 255).toInt(),
                            ),
                            AppColors.authPrimary.withAlpha(
                              (0.05 * 255).toInt(),
                            ),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 48,
                        color: AppColors.authPrimary.withAlpha(
                          (0.6 * 255).toInt(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      'Nema nedavnih aktivnosti',
                      style: AppTypography.h3.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      'Vaše nedavne rezervacije i aktivnosti će se prikazati ovdje',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textTertiaryLight,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
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
                return _ActivityTile(
                  activity: activity,
                  onTap: activity.bookingId != null && onActivityTap != null
                      ? () => onActivityTap!(activity.bookingId!)
                      : null,
                );
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
  final VoidCallback? onTap;

  const _ActivityTile({required this.activity, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              activity.color.withAlpha((0.15 * 255).toInt()),
              activity.color.withAlpha((0.08 * 255).toInt()),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activity.color.withAlpha((0.2 * 255).toInt()),
          ),
        ),
        child: Icon(activity.icon, color: activity.color, size: 24),
      ),
      title: Text(
        activity.title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          activity.subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariantLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          _formatTimestamp(activity.timestamp),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
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
