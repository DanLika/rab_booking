import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Timeline date header components
///
/// Provides month and day headers for the timeline calendar.
/// Extracted from timeline_calendar_widget.dart for better maintainability.

/// Month header cell spanning multiple days
class TimelineMonthHeader extends StatefulWidget {
  /// The date representing the month
  final DateTime date;

  /// Number of days this month header spans
  final int dayCount;

  /// Width of a single day cell
  final double dayWidth;

  /// Screen width for responsive sizing (optional)
  final double? screenWidth;

  /// Callback when month header is tapped
  final Function(DateTime month)? onTap;

  const TimelineMonthHeader({
    super.key,
    required this.date,
    required this.dayCount,
    required this.dayWidth,
    this.screenWidth,
    this.onTap,
  });

  @override
  State<TimelineMonthHeader> createState() => _TimelineMonthHeaderState();
}

class _TimelineMonthHeaderState extends State<TimelineMonthHeader> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Fixed font size — matches fixed TimelineDimensions for all devices
    const fontSize = 11.0;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap != null ? () => widget.onTap!(widget.date) : null,
        child: Container(
          width: widget.dayWidth * widget.dayCount,
          decoration: BoxDecoration(
            color: _isHovered && widget.onTap != null
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor, width: 1.5),
              right: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: Center(
            child: Text(
              DateFormat(
                'MMMM yyyy',
                Localizations.localeOf(context).languageCode,
              ).format(widget.date),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
                color: theme.colorScheme.primary,
                decoration: _isHovered && widget.onTap != null
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: theme.colorScheme.primary,
              ),
            ),
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
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final isFirstDayOfMonth = date.day == 1;

    // Fixed sizing — matches fixed TimelineDimensions for all devices
    const minHeight = 38.0;
    const verticalPadding = 6.0;
    const circleSize = 24.0;
    const fontSize = 12.0;

    return Container(
      width: dayWidth,
      constraints: const BoxConstraints(minHeight: minHeight),
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
      padding: const EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: 4,
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
              // Weekend: use softer orange instead of error red
              color: isToday
                  ? theme.colorScheme.onPrimary
                  : (isWeekend ? const Color(0xFFE67E22) : null),
            ),
          ),
        ),
      ),
    );
  }
}
