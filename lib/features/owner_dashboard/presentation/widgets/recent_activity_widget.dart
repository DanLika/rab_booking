import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';

/// Activity type enum
enum ActivityType { booking, confirmed, review, message, payment, cancellation, completed }

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
        return Icons.notification_add_rounded; // New booking received
      case ActivityType.confirmed:
        return Icons.check_circle_outline_rounded; // Booking confirmed
      case ActivityType.review:
        return Icons.star_rounded;
      case ActivityType.message:
        return Icons.message_rounded;
      case ActivityType.payment:
        return Icons.payments_rounded;
      case ActivityType.cancellation:
        return Icons.cancel_outlined; // Booking cancelled
      case ActivityType.completed:
        return Icons.task_alt_rounded; // Booking completed
    }
  }

  Color get color {
    switch (type) {
      case ActivityType.booking:
        return AppColors.activityBooking; // Purple - new booking
      case ActivityType.confirmed:
        return AppColors.activityConfirmed; // Green - confirmed
      case ActivityType.review:
        return AppColors.activityReview;
      case ActivityType.message:
        return AppColors.activityMessage;
      case ActivityType.payment:
        return AppColors.activityPayment;
      case ActivityType.cancellation:
        return AppColors.activityCancellation; // Red - cancelled
      case ActivityType.completed:
        return AppColors.activityCompleted; // Gray - completed
    }
  }
}

/// Recent activity widget
class RecentActivityWidget extends StatelessWidget {
  final List<ActivityItem> activities;
  final VoidCallback? onViewAll;
  final void Function(String bookingId)? onActivityTap;

  const RecentActivityWidget({super.key, required this.activities, this.onViewAll, this.onActivityTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
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
                        l10n.ownerRecentActivities,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                          child: Text(l10n.ownerViewAll),
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
                        l10n.ownerRecentActivities,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onViewAll != null) ...[
                      const SizedBox(width: AppDimensions.spaceS),
                      TextButton.icon(
                        onPressed: onViewAll,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          foregroundColor: theme.colorScheme.primary,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(
                          l10n.ownerViewAll,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),

          // Divider
          Divider(height: 1, color: context.gradients.sectionBorder.withAlpha((0.3 * 255).toInt())),

          // Activities list
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 56, horizontal: AppDimensions.spaceL),
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
                            theme.colorScheme.primary.withAlpha((0.15 * 255).toInt()),
                            theme.colorScheme.primary.withAlpha((0.05 * 255).toInt()),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 48,
                        color: theme.colorScheme.primary.withAlpha((0.6 * 255).toInt()),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      l10n.ownerNoRecentActivities,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      l10n.ownerRecentActivitiesDescription,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: context.gradients.sectionBorder.withAlpha((0.3 * 255).toInt())),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [activity.color.withAlpha((0.15 * 255).toInt()), activity.color.withAlpha((0.08 * 255).toInt())],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: activity.color.withAlpha((0.2 * 255).toInt())),
        ),
        child: Icon(activity.icon, color: activity.color, size: 24),
      ),
      title: Text(
        activity.title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          activity.subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          // Subtle tinted background that works in both themes
          color: isDark
              ? const Color(0xFF2D2D3A) // Dark: subtle purple-gray
              : const Color(0xFFF0EDF5), // Light: subtle purple-tinted gray
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3D3D4A) // Dark: subtle border
                : const Color(0xFFE0DCE8), // Light: subtle border
            width: 1,
          ),
        ),
        child: Text(
          _formatTimestamp(activity.timestamp, l10n),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? const Color(0xFFB0B0C0) // Dark: lighter text for better contrast
                : const Color(0xFF6B6B80), // Light: darker text for better contrast
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
