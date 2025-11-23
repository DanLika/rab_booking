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

  /// Screen width for responsive sizing (optional)
  final double? screenWidth;

  const TimelineMonthHeader({
    super.key,
    required this.date,
    required this.dayCount,
    required this.dayWidth,
    this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Responsive font size
    final width = screenWidth ?? MediaQuery.of(context).size.width;
    final fontSize = width < 600 ? 11.0 : (width < 900 ? 12.0 : 13.0);

    return Container(
      width: dayWidth * dayCount,
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent to show parent gradient
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
            fontSize: fontSize,
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

  /// Screen width for responsive sizing (optional)
  final double? screenWidth;

  const TimelineDayHeader({
    super.key,
    required this.date,
    required this.dayWidth,
    this.screenWidth,
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

    // Responsive sizing based on screen width
    final width = screenWidth ?? MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;
    final bool isTablet = width >= 600 && width < 900;

    final minHeight = isMobile ? 40.0 : (isTablet ? 46.0 : 52.0);
    final verticalPadding = isMobile ? 8.0 : (isTablet ? 10.0 : 12.0);
    final circleSize = isMobile ? 24.0 : (isTablet ? 28.0 : 32.0);
    final fontSize = isMobile ? 12.0 : (isTablet ? 14.0 : 15.0);

    return Container(
      width: dayWidth,
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: isToday
            ? theme.colorScheme.primary.withValues(alpha: 0.2)
            : Colors.transparent, // Transparent to show parent gradient
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
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: 4, // Reduced from 8 to prevent overflow
      ),
      child: Center(
        child: Container(
          width: circleSize,
          height: circleSize,
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
              fontSize: fontSize,
              height: 1.2,
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
