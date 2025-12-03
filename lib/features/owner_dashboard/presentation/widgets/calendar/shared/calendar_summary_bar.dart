import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../shared/models/booking_model.dart';
import '../../../../utils/date_range_utils.dart';

/// Shared Calendar Summary Bar Widget
/// Displays daily statistics: guests, meals, check-ins, check-outs
/// Used in both Week and Timeline calendar views
class CalendarSummaryBar extends StatelessWidget {
  final List<DateTime> dates;
  final Map<String, List<BookingModel>> bookingsByUnit;
  final double cellWidth;
  final ScrollController? scrollController;

  const CalendarSummaryBar({
    super.key,
    required this.dates,
    required this.bookingsByUnit,
    required this.cellWidth,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      physics: scrollController != null
          ? const NeverScrollableScrollPhysics() // Synced scroll
          : const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 120,
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
          children: dates.map((date) {
            return _buildSummaryCell(context, date);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCell(BuildContext context, DateTime date) {
    final theme = Theme.of(context);

    // Calculate statistics for this date
    int totalGuests = 0;
    int checkIns = 0;
    int checkOuts = 0;

    // Iterate through all bookings
    for (final bookings in bookingsByUnit.values) {
      for (final booking in bookings) {
        // Count guests currently in property (checkIn <= date < checkOut)
        if (!booking.checkIn.isAfter(date) && booking.checkOut.isAfter(date)) {
          totalGuests += booking.guestCount;
        }

        // Count check-ins (checkIn == date)
        if (DateRangeUtils.isSameDay(booking.checkIn, date)) {
          checkIns++;
        }

        // Count check-outs (checkOut == date)
        if (DateRangeUtils.isSameDay(booking.checkOut, date)) {
          checkOuts++;
        }
      }
    }

    // Calculate meals (2 meals per guest per day)
    final int meals = totalGuests * 2;

    final isToday = DateRangeUtils.isToday(date);
    final isWeekend = DateRangeUtils.isWeekend(date);

    return Container(
      width: cellWidth,
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primary.withValues(alpha: 0.1)
            : isWeekend
                ? theme.colorScheme.surfaceContainerHighest.withAlpha(
                    (0.5 * 255).toInt(),
                  )
                : theme.cardColor,
        border: Border(
          left: BorderSide(
            color: theme.dividerColor.withAlpha((0.3 * 255).toInt()),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.spaceXS,
        horizontal: AppDimensions.spaceXXS,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Guests
          _buildSummaryItem(
            Icons.people,
            totalGuests.toString(),
            Colors.blue,
            'Gosti',
            cellWidth,
          ),
          // Meals
          _buildSummaryItem(
            Icons.restaurant,
            meals.toString(),
            Colors.orange,
            'Obroci',
            cellWidth,
          ),
          // Check-ins
          _buildSummaryItem(
            Icons.login,
            checkIns.toString(),
            Colors.green,
            'Dolasci',
            cellWidth,
          ),
          // Check-outs
          _buildSummaryItem(
            Icons.logout,
            checkOuts.toString(),
            Colors.red,
            'Odlasci',
            cellWidth,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String value,
    Color color,
    String tooltip,
    double cellWidth,
  ) {
    // Responsive sizing based on cell width
    final isNarrow = cellWidth < 80;
    final iconSize = isNarrow ? 12.0 : 14.0;
    final fontSize = isNarrow ? 10.0 : 12.0;
    final spacing = isNarrow ? 2.0 : 4.0;

    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          SizedBox(width: spacing),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
