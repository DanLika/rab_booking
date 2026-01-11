import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/animations/animated_empty_state.dart';

/// Activity type enum
enum ActivityType {
  booking,
  confirmed,
  review,
  message,
  payment,
  cancellation,
  completed,
}

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

  IconData get icon => switch (type) {
    ActivityType.booking => Icons.notification_add_rounded,
    ActivityType.confirmed => Icons.check_circle_outline_rounded,
    ActivityType.review => Icons.star_rounded,
    ActivityType.message => Icons.message_rounded,
    ActivityType.payment => Icons.payments_rounded,
    ActivityType.cancellation => Icons.cancel_outlined,
    ActivityType.completed => Icons.task_alt_rounded,
  };

  Color get color => switch (type) {
    ActivityType.booking => AppColors.activityBooking,
    ActivityType.confirmed => AppColors.activityConfirmed,
    ActivityType.review => AppColors.activityReview,
    ActivityType.message => AppColors.activityMessage,
    ActivityType.payment => AppColors.activityPayment,
    ActivityType.cancellation => AppColors.activityCancellation,
    ActivityType.completed => AppColors.activityCompleted,
  };
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.gradients.sectionBorder.withValues(alpha: 0.5),
        ),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            child: Row(
              children: [
                Expanded(
                  child: AutoSizeText(
                    l10n.ownerRecentActivities,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    minFontSize: 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onViewAll != null) ...[
                  const SizedBox(width: AppDimensions.spaceS),
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      foregroundColor: theme.colorScheme.primary,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AutoSizeText(
                          l10n.ownerViewAll,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          minFontSize: 11,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: isDark
                ? AppColors.sectionDividerDark
                : AppColors.sectionDividerLight,
          ),

          // Activities list
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 32,
                horizontal: AppDimensions.spaceL,
              ),
              child: Center(
                child: AnimatedEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: l10n.ownerNoRecentActivities,
                  subtitle: l10n.ownerRecentActivitiesDescription,
                  iconSize: 40,
                  iconColor: theme.colorScheme.primary.withValues(alpha: 0.6),
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
                color: isDark
                    ? AppColors.sectionDividerDark
                    : AppColors.sectionDividerLight,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: activity.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(activity.icon, color: activity.color, size: 20),
      ),
      title: Text(
        activity.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        activity.subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          // Subtle tinted background using design system colors
          color: isDark
              ? AppColors.sectionDividerDark
              : AppColors.dialogFooterLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? AppColors.borderDark
                : AppColors.sectionDividerLight,
          ),
        ),
        child: Text(
          _formatTimestamp(activity.timestamp, l10n),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return l10n.ownerJustNow;
    } else if (difference.inMinutes < 60) {
      return l10n.ownerMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.ownerHoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.ownerDaysAgo(difference.inDays);
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
