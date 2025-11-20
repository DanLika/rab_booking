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
        vertical: 12,
        horizontal: 8,
      ),
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: isToday
              ? BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                )
              : null,
          alignment: Alignment.center,
          child: Text(
            '${date.day}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isToday
                  ? theme.colorScheme.onPrimary
                  : (isWeekend ? theme.colorScheme.error : null),
            ),
          ),
        ),
      ),
    );
  }
}
