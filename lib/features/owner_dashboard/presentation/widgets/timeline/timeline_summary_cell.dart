import 'package:flutter/material.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';

/// Timeline summary cell widget
///
/// Displays daily statistics (guests, meals, check-ins, check-outs) in summary row.
/// Extracted from timeline_calendar_widget.dart for better maintainability.
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
        if (_isSameDay(booking.checkIn, date)) {
          checkIns++;
        }

        // Count check-outs (checkOut == date)
        if (_isSameDay(booking.checkOut, date)) {
          checkOuts++;
        }
      }
    }

    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    return Container(
      width: dayWidth,
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primary.withValues(alpha: 0.1)
            : isWeekend
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : theme.cardColor,
        border: Border(
          left: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.spaceXS,
        horizontal: AppDimensions.spaceXXS,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Guests
          _buildSummaryItem(
            Icons.people,
            totalGuests.toString(),
            Colors.blue,
            'Gosti',
          ),
          const SizedBox(height: 8),
          // Check-ins/Check-outs (combined)
          _buildCombinedCheckInOut(checkIns, checkOuts),
        ],
      ),
    );
  }

  /// Helper to check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Build a summary item row with icon, value, and tooltip
  Widget _buildSummaryItem(
    IconData icon,
    String value,
    Color color,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build combined check-in/check-out item
  Widget _buildCombinedCheckInOut(int checkIns, int checkOuts) {
    return Tooltip(
      message: '$checkIns dolazak • $checkOuts odlazak',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.swap_vert, size: 14, color: Colors.purple),
          const SizedBox(width: 4),
          Text(
            '$checkIns/$checkOuts',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }
}
