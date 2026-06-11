import 'package:flutter/material.dart';
import '../../../../../core/design/tokens.dart';
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

  // HR weekday abbreviations indexed by DateTime.weekday (1..7).
  static const List<String> _hrDays = <String>[
    'Pon',
    'Uto',
    'Sri',
    'Čet',
    'Pet',
    'Sub',
    'Ned',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = BBColor.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final isFirstDayOfMonth = date.day == 1;

    // Fixed sizing — matches fixed TimelineDimensions for all devices.
    // Weekday eyebrow + number circle must stay within the fixed 38px
    // day-header band (FROZEN dimensions), hence the compact metrics.
    const minHeight = 38.0;
    const verticalPadding = 2.0;
    const circleSize = 22.0;
    const fontSize = 12.0;

    return Container(
      width: dayWidth,
      constraints: const BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        // Handoff today tint: primary-tint-bg 6% light / 8% dark.
        color: isToday
            ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.06)
            : Colors.transparent,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Weekday eyebrow (handoff day header) — tertiary tone on
          // weekends, text-tertiary otherwise.
          Text(
            _hrDays[(date.weekday - 1).clamp(0, 6)],
            style: TextStyle(
              fontSize: 8,
              height: 1.1,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: isWeekend ? c.tertiary : c.textTertiary,
            ),
          ),
          const SizedBox(height: 1),
          Container(
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
                    : (isWeekend ? c.tertiary : null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
