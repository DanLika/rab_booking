import 'package:flutter/material.dart';
import '../../../domain/models/date_range_selection.dart';

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
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final responsiveHeight = (60 * textScale).clamp(60.0, 80.0);

    return Container(
      height: responsiveHeight,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 16),
      child: Row(
        children: [
          // Date range with navigation arrows - OVERFLOW FIX: Shrink arrows in compact
          // Previous period (smaller in compact mode)
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPreviousPeriod,
            tooltip: isWeekView ? 'Prethodni tjedan' : 'Prethodni mjesec',
            constraints: BoxConstraints(
              minWidth: isCompact ? 32 : 40,
              minHeight: isCompact ? 32 : 40,
            ),
            iconSize: isCompact ? 18 : 24,
            padding: EdgeInsets.zero,
          ),

          // Date range display (flexible, can shrink)
          Flexible(
            child: InkWell(
              onTap: onDatePickerTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: isCompact
                    ? const BoxConstraints(maxWidth: 120)
                    : null,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 6 : 12,
                  vertical: isCompact ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        dateRange.toDisplayString(isWeek: isWeekView),
                        style: (isCompact
                            ? theme.textTheme.labelSmall
                            : theme.textTheme.titleSmall)?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: isCompact ? 2 : 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: isCompact ? 14 : 20,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Next period (smaller in compact mode)
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNextPeriod,
            tooltip: isWeekView ? 'Sljedeći tjedan' : 'Sljedeći mjesec',
            constraints: BoxConstraints(
              minWidth: isCompact ? 32 : 40,
              minHeight: isCompact ? 32 : 40,
            ),
            iconSize: isCompact ? 18 : 24,
            padding: EdgeInsets.zero,
          ),

          // Spacing between navigation and actions
          if (!isCompact) const SizedBox(width: 8),

          // Action buttons - FIXED OVERFLOW
          if (isCompact)
            // COMPACT MODE: Only overflow menu
            PopupMenuButton<String>(
              icon: Badge(
                label: (notificationCount ?? 0) > 0 ? Text('$notificationCount') : null,
                isLabelVisible: (notificationCount ?? 0) > 0,
                child: const Icon(Icons.more_vert),
              ),
              tooltip: 'Opcije',
              position: PopupMenuPosition.under, // Dropdown opens below button
              offset: const Offset(0, 8), // 8px below button
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
                  case 'multiselect':
                    onMultiSelectToggle?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'today',
                  child: Row(
                    children: [
                      Icon(Icons.today, size: 20),
                      SizedBox(width: 12),
                      Text('Danas'),
                    ],
                  ),
                ),
                if (onNotificationsTap != null)
                  PopupMenuItem(
                    value: 'notifications',
                    child: Row(
                      children: [
                        Badge(
                          label: (notificationCount ?? 0) > 0 ? Text('$notificationCount') : null,
                          isLabelVisible: (notificationCount ?? 0) > 0,
                          child: const Icon(Icons.notifications, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text('Obavijesti'),
                      ],
                    ),
                  ),
                if (onSearchTap != null)
                  const PopupMenuItem(
                    value: 'search',
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 20),
                        SizedBox(width: 12),
                        Text('Pretraži'),
                      ],
                    ),
                  ),
                if (onRefresh != null)
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 20, color: Colors.green),
                        SizedBox(width: 12),
                        Text('Osvježi'),
                      ],
                    ),
                  ),
                if (onFilterTap != null)
                  const PopupMenuItem(
                    value: 'filter',
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, size: 20),
                        SizedBox(width: 12),
                        Text('Filteri'),
                      ],
                    ),
                  ),
                if (showSummaryToggle && onSummaryToggleChanged != null)
                  PopupMenuItem(
                    value: 'analytics',
                    child: Row(
                      children: [
                        Icon(
                          isSummaryVisible ? Icons.analytics : Icons.analytics_outlined,
                          size: 20,
                          color: isSummaryVisible ? theme.colorScheme.primary : null,
                        ),
                        const SizedBox(width: 12),
                        Text(isSummaryVisible ? 'Sakrij statistiku' : 'Prikaži statistiku'),
                      ],
                    ),
                  ),
                if (showMultiSelectToggle && onMultiSelectToggle != null)
                  PopupMenuItem(
                    value: 'multiselect',
                    child: Row(
                      children: [
                        Icon(
                          isMultiSelectActive ? Icons.checklist : Icons.checklist_outlined,
                          size: 20,
                          color: isMultiSelectActive ? theme.colorScheme.primary : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isMultiSelectActive
                              ? 'Isključi višestruku selekciju'
                              : 'Uključi višestruku selekciju',
                        ),
                      ],
                    ),
                  ),
              ],
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
                      tooltip: 'Pretraži rezervacije',
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),

                  // Refresh button
                  if (onRefresh != null)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: onRefresh,
                      tooltip: 'Osvježi',
                      color: Colors.green,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),

                  // Filter button (desktop also gets it now)
                  if (onFilterTap != null)
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: onFilterTap,
                      tooltip: 'Filteri',
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),

                  // Today button
                  _buildTodayButton(theme),

                  // Notifications button
                  if (onNotificationsTap != null)
                    _buildNotificationsButton(
                      theme,
                      onNotificationsTap,
                      notificationCount,
                    ),

                  // Analytics toggle (DESKTOP MODE - icon only to save space)
                  if (showSummaryToggle && onSummaryToggleChanged != null)
                    IconButton(
                      icon: Icon(
                        isSummaryVisible
                            ? Icons.analytics
                            : Icons.analytics_outlined,
                      ),
                      onPressed: () => onSummaryToggleChanged?.call(!isSummaryVisible),
                      tooltip: isSummaryVisible
                          ? 'Sakrij statistiku'
                          : 'Prikaži statistiku',
                      color: isSummaryVisible ? theme.colorScheme.primary : null,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),

                  // Multi-select toggle (DESKTOP MODE - icon only to save space)
                  if (showMultiSelectToggle && onMultiSelectToggle != null)
                    IconButton(
                      icon: Icon(
                        isMultiSelectActive
                            ? Icons.checklist
                            : Icons.checklist_outlined,
                      ),
                      onPressed: onMultiSelectToggle,
                      tooltip: isMultiSelectActive
                          ? 'Isključi višestruku selekciju'
                          : 'Uključi višestruku selekciju',
                      color: isMultiSelectActive ? theme.colorScheme.primary : null,
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
  Widget _buildTodayButton(ThemeData theme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.calendar_today_outlined),
          onPressed: onToday,
          tooltip: 'Idi na danas',
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
        Positioned(
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(3),
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 12,
            ),
            child: Text(
              '${DateTime.now().day}',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  /// Build Notifications button with badge
  Widget _buildNotificationsButton(
    ThemeData theme,
    VoidCallback? onTap,
    int? count,
  ) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: onTap,
          tooltip: 'Obavijesti',
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
        if (count != null && count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
