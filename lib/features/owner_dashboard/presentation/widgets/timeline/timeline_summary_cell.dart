import 'package:flutter/material.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/calendar_cell_colors.dart';
import '../shared/daily_stats_widgets.dart';

/// Timeline summary cell widget
///
/// Displays daily statistics (guests, check-ins, check-outs) in summary row.
/// Uses shared DailyStats and badge widgets for consistency with other calendar views.
class TimelineSummaryCell extends StatelessWidget {
  /// The date for this summary
  final DateTime date;

  /// All bookings by unit
  final Map<String, List<BookingModel>> bookingsByUnit;

  /// Width of the day cell
  final double dayWidth;

  const TimelineSummaryCell({
    super.key,
    required this.date,
    required this.bookingsByUnit,
    required this.dayWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    // Calculate statistics using shared DailyStats
    final stats = DailyStats.calculate(date, bookingsByUnit);

    return Container(
      width: dayWidth,
      decoration: BoxDecoration(
        color: CalendarCellColors.getSummaryCellBackground(
          context: context,
          isToday: isToday,
          isWeekend: isWeekend,
        ),
        border: Border(
          left: BorderSide(
            color: isDark
                ? AppColors.sectionDividerDark
                : AppColors.sectionDividerLight,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: DailyStatsColumn(stats: stats, isNarrow: true),
    );
  }
}
