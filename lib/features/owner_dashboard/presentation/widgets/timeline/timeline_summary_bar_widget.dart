import 'package:flutter/material.dart';
import '../../../../../shared/models/booking_model.dart';
import 'timeline_summary_cell.dart';
import 'timeline_dimensions.dart';

/// Timeline summary bar widget
/// Displays aggregated booking information below the timeline grid
/// Shows occupancy stats per day
class TimelineSummaryBarWidget extends StatelessWidget {
  /// Bookings grouped by unit ID
  final Map<String, List<BookingModel>> bookingsByUnit;

  /// List of visible dates
  final List<DateTime> dates;

  /// Offset width for windowing
  final double offsetWidth;

  /// Timeline dimensions
  final TimelineDimensions dimensions;

  /// Summary bar height
  static const double _kSummaryBarHeight = 120.0;

  const TimelineSummaryBarWidget({
    super.key,
    required this.bookingsByUnit,
    required this.dates,
    required this.offsetWidth,
    required this.dimensions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: _kSummaryBarHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(
          (0.3 * 255).toInt(),
        ),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withAlpha((0.5 * 255).toInt()),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          if (offsetWidth > 0) SizedBox(width: offsetWidth),
          ...dates.map(
            (date) => TimelineSummaryCell(
              date: date,
              bookingsByUnit: bookingsByUnit,
              dayWidth: dimensions.dayWidth,
            ),
          ),
        ],
      ),
    );
  }
}
