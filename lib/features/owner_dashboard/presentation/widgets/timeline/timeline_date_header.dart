import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Timeline date header components
///
/// Provides month and day headers for the timeline calendar.
/// Extracted from timeline_calendar_widget.dart for better maintainability.

/// Month header cell spanning multiple days
class TimelineMonthHeader extends StatelessWidget {
  /// The date representing the month
  final DateTime date;

  /// Number of days this month header spans
  final int dayCount;

  /// Width of a single day cell
  final double dayWidth;

  const TimelineMonthHeader({
    super.key,
    required this.date,
    required this.dayCount,
    required this.dayWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: dayWidth * dayCount,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1.5),
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Center(
        child: Text(
          DateFormat('MMMM yyyy', 'hr_HR').format(date),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Day header cell with day of week and day number
class TimelineDayHeader extends StatelessWidget {
  /// The date for this day header
  final DateTime date;

  /// Width of the day cell
  final double dayWidth;

  const TimelineDayHeader({
    super.key,
    required this.date,
    required this.dayWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final isFirstDayOfMonth = date.day == 1;

    return Container(
      width: dayWidth,
      decoration: BoxDecoration(
        color: isToday
            ? theme.colorScheme.primary.withValues(alpha: 0.2)
            : theme.cardColor,
        border: Border(
          left: BorderSide(
            color: isFirstDayOfMonth
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.5),
            width: isFirstDayOfMonth ? 2 : 1,
          ),
          bottom: BorderSide(color: theme.dividerColor, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 8,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day of week
          Flexible(
            child: Text(
              DateFormat('EEE', 'hr_HR').format(date).toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isWeekend
                    ? theme.colorScheme.error
                    : (isToday ? theme.colorScheme.primary : null),
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 2),

          // Day number
          Flexible(
            child: Container(
              width: 26,
              height: 26,
              decoration: isToday
                  ? BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    )
                  : null,
              alignment: Alignment.center,
              child: Text(
                '${date.day}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isToday ? theme.colorScheme.onPrimary : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
