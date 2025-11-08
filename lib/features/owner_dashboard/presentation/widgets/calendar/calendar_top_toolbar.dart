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
  final VoidCallback? onAddRoom;
  final bool? showSummary;
  final ValueChanged<bool>? onSummaryToggle;
  final int? notificationCount;
  final bool isCompact;

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
    this.onAddRoom,
    this.showSummary,
    this.onSummaryToggle,
    this.notificationCount,
    this.isCompact = false,
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
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 16),
      child: Row(
        children: [
          // Filter button (mobile only - drawer icon)
          if (isCompact && onFilterTap != null) ...[
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: onFilterTap,
              tooltip: 'Filters',
            ),
            const SizedBox(width: 8),
          ],

          // Date range with navigation arrows
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Previous period
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: onPreviousPeriod,
                  tooltip: isWeekView ? 'Previous week' : 'Previous month',
                ),

                // Date range display (tappable for date picker)
                Flexible(
                  child: InkWell(
                    onTap: onDatePickerTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 80),
                              child: Text(
                                dateRange.toDisplayString(isWeek: isWeekView),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Next period
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: onNextPeriod,
                  tooltip: isWeekView ? 'Next week' : 'Next month',
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search button
              if (onSearchTap != null)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: onSearchTap,
                  tooltip: 'Search bookings',
                ),

              // Refresh button
              if (onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                  tooltip: 'Refresh',
                  color: Colors.green,
                ),

              // Today button (calendar icon with day badge)
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: onToday,
                    tooltip: 'Go to Today',
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
              ),

              // Add room button (quick action)
              if (onAddRoom != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton.icon(
                    onPressed: onAddRoom,
                    icon: const Icon(Icons.add, size: 18),
                    label: isCompact
                        ? const SizedBox.shrink()
                        : const Text('Add Room'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 12 : 16,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

              // Summary toggle switch
              if (onSummaryToggle != null && showSummary != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isCompact) ...[
                        Text(
                          'Summary',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Switch(
                        value: showSummary!,
                        onChanged: onSummaryToggle,
                        activeTrackColor: theme.colorScheme.primary,
                        activeThumbColor: theme.colorScheme.onPrimary,
                      ),
                    ],
                  ),
                ),

              // Notifications button (with badge)
              if (notificationCount != null && notificationCount! > 0)
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        // Handle notifications
                      },
                      tooltip: 'Notifications',
                    ),
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
                          notificationCount! > 9 ? '9+' : '$notificationCount',
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
                ),
            ],
          ),
        ],
      ),
    );
  }
}
