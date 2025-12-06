import 'package:flutter/material.dart';
import '../../../domain/models/date_range_selection.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// Calendar top toolbar widget
/// Shows date range picker, search, refresh, today button, add room, summary toggle, and notifications
class CalendarTopToolbar extends StatelessWidget {
  final DateRangeSelection dateRange;
  final bool isWeekView; // true = week, false = month
  final VoidCallback onPreviousPeriod;
  final VoidCallback onNextPeriod;
  final VoidCallback onToday;
  final VoidCallback? onDatePickerTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onRefresh;
  final VoidCallback? onFilterTap;
  final int? notificationCount;
  final VoidCallback? onNotificationsTap;
  final bool isCompact;

  // ENHANCED: Analytics/Summary toggle (consolidated from separate row)
  final bool showSummaryToggle;
  final bool isSummaryVisible;
  final ValueChanged<bool>? onSummaryToggleChanged;

  // ENHANCED: Multi-select mode toggle
  final bool showMultiSelectToggle;
  final bool isMultiSelectActive;
  final VoidCallback? onMultiSelectToggle;

  const CalendarTopToolbar({
    super.key,
    required this.dateRange,
    required this.isWeekView,
    required this.onPreviousPeriod,
    required this.onNextPeriod,
    required this.onToday,
    this.onDatePickerTap,
    this.onSearchTap,
    this.onRefresh,
    this.onFilterTap,
    this.notificationCount,
    this.onNotificationsTap,
    this.isCompact = false,
    this.showSummaryToggle = false,
    this.isSummaryVisible = false,
    this.onSummaryToggleChanged,
    this.showMultiSelectToggle = false,
    this.isMultiSelectActive = false,
    this.onMultiSelectToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final responsiveHeight = (60 * textScale).clamp(60.0, 80.0);

    return Container(
      height: responsiveHeight,
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent to show parent gradient
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 16),
      child: Row(
        children: [
          // Previous period - LEFT of month selector
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPreviousPeriod,
            tooltip: isWeekView ? l10n.ownerCalendarPreviousWeek : l10n.ownerCalendarPreviousMonth,
            constraints: BoxConstraints(minWidth: isCompact ? 32 : 40, minHeight: isCompact ? 32 : 40),
            iconSize: isCompact ? 18 : 24,
            padding: EdgeInsets.zero,
          ),

          // Date range display (centered)
          InkWell(
            onTap: onDatePickerTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: isCompact ? const BoxConstraints(maxWidth: 120) : null,
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 12, vertical: isCompact ? 6 : 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dateRange.toDisplayString(isWeek: isWeekView),
                    style: (isCompact ? theme.textTheme.labelSmall : theme.textTheme.titleSmall)?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(width: isCompact ? 2 : 4),
                  Icon(Icons.arrow_drop_down, size: isCompact ? 14 : 20, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),

          // Next period - RIGHT of month selector
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNextPeriod,
            tooltip: isWeekView ? l10n.ownerCalendarNextWeek : l10n.ownerCalendarNextMonth,
            constraints: BoxConstraints(minWidth: isCompact ? 32 : 40, minHeight: isCompact ? 32 : 40),
            iconSize: isCompact ? 18 : 24,
            padding: EdgeInsets.zero,
          ),

          // Spacer - push action buttons to the right
          const Spacer(flex: 2),

          // Action buttons - FIXED OVERFLOW
          if (isCompact)
            // COMPACT MODE: Only overflow menu with styled items
            PopupMenuButton<String>(
              icon: _buildCompactMenuIcon(theme, notificationCount),
              tooltip: l10n.ownerCalendarOptions,
              position: PopupMenuPosition.under,
              offset: const Offset(0, 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: theme.brightness == Brightness.dark ? const Color(0xFF252530) : Colors.white,
              elevation: 8,
              onSelected: (value) {
                switch (value) {
                  case 'today':
                    onToday();
                    break;
                  case 'search':
                    onSearchTap?.call();
                    break;
                  case 'refresh':
                    onRefresh?.call();
                    break;
                  case 'filter':
                    onFilterTap?.call();
                    break;
                  case 'notifications':
                    onNotificationsTap?.call();
                    break;
                  case 'analytics':
                    onSummaryToggleChanged?.call(!isSummaryVisible);
                    break;
                }
              },
              itemBuilder: (context) {
                final l10n = AppLocalizations.of(context);
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return [
                  _buildStyledMenuItem(
                    value: 'today',
                    icon: Icons.today,
                    iconColor: AppColors.primary,
                    label: l10n.ownerCalendarToday,
                    isDark: isDark,
                  ),
                  if (onNotificationsTap != null)
                    _buildStyledMenuItem(
                      value: 'notifications',
                      icon: Icons.notifications_outlined,
                      iconColor: AppColors.warning,
                      label: l10n.ownerCalendarNotifications,
                      isDark: isDark,
                      badge: notificationCount,
                    ),
                  if (onSearchTap != null)
                    _buildStyledMenuItem(
                      value: 'search',
                      icon: Icons.search,
                      iconColor: AppColors.info,
                      label: l10n.ownerCalendarSearch,
                      isDark: isDark,
                    ),
                  if (onRefresh != null)
                    _buildStyledMenuItem(
                      value: 'refresh',
                      icon: Icons.refresh,
                      iconColor: AppColors.success,
                      label: l10n.ownerCalendarRefresh,
                      isDark: isDark,
                    ),
                  if (onFilterTap != null)
                    _buildStyledMenuItem(
                      value: 'filter',
                      icon: Icons.tune,
                      iconColor: AppColors.warning,
                      label: l10n.ownerCalendarFilters,
                      isDark: isDark,
                    ),
                  if (showSummaryToggle && onSummaryToggleChanged != null)
                    _buildStyledMenuItem(
                      value: 'analytics',
                      icon: isSummaryVisible ? Icons.bar_chart : Icons.bar_chart_outlined,
                      iconColor: isSummaryVisible ? AppColors.primary : AppColors.info,
                      label: isSummaryVisible ? l10n.ownerCalendarHideStats : l10n.ownerCalendarShowStats,
                      isDark: isDark,
                    ),
                ];
              },
            )
          else
            // DESKTOP MODE: Show all buttons
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search button
                  if (onSearchTap != null)
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: onSearchTap,
                      tooltip: l10n.ownerCalendarSearchBookings,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),

                  // Refresh button
                  if (onRefresh != null)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: onRefresh,
                      tooltip: l10n.ownerCalendarRefresh,
                      color: Colors.green,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),

                  // Filter button (desktop also gets it now)
                  if (onFilterTap != null)
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: onFilterTap,
                      tooltip: l10n.ownerCalendarFilters,
                      color: Colors.orange,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),

                  // Today button
                  _buildTodayButton(theme, l10n),

                  // Notifications button
                  if (onNotificationsTap != null)
                    _buildNotificationsButton(theme, l10n, onNotificationsTap, notificationCount),

                  // Analytics toggle (DESKTOP MODE - icon only to save space)
                  if (showSummaryToggle && onSummaryToggleChanged != null)
                    IconButton(
                      icon: Icon(isSummaryVisible ? Icons.bar_chart : Icons.bar_chart_outlined),
                      onPressed: () => onSummaryToggleChanged?.call(!isSummaryVisible),
                      tooltip: isSummaryVisible ? l10n.ownerCalendarHideStats : l10n.ownerCalendarShowStats,
                      color: isSummaryVisible ? theme.colorScheme.primary : Colors.blue,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build Today button with day badge
  Widget _buildTodayButton(ThemeData theme, AppLocalizations l10n) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.calendar_today_outlined),
          onPressed: onToday,
          tooltip: l10n.ownerCalendarGoToToday,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
        // Positioned must be direct child of Stack, IgnorePointer inside
        Positioned(
          bottom: 10,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(3)),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 12),
              child: Text(
                '${DateTime.now().day}',
                style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build Notifications button with badge
  Widget _buildNotificationsButton(ThemeData theme, AppLocalizations l10n, VoidCallback? onTap, int? count) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: onTap,
          tooltip: l10n.ownerCalendarNotifications,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
        if (count != null && count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(8)),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// Build compact menu icon with subtle notification indicator
  Widget _buildCompactMenuIcon(ThemeData theme, int? notificationCount) {
    final hasNotifications = (notificationCount ?? 0) > 0;

    return Stack(
      children: [
        const Icon(Icons.more_vert),
        if (hasNotifications)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: theme.scaffoldBackgroundColor),
              ),
            ),
          ),
      ],
    );
  }

  /// Build styled popup menu item with icon badge
  PopupMenuItem<String> _buildStyledMenuItem({
    required String value,
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool isDark,
    int? badge,
  }) {
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D3A) : const Color(0xFFF8F8FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha((0.15 * 255).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: badge != null && badge > 0
                  ? Badge(
                      label: Text(badge > 9 ? '9+' : '$badge', style: const TextStyle(fontSize: 10)),
                      child: Icon(icon, size: 20, color: iconColor),
                    )
                  : Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
