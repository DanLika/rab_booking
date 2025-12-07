import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/models/booking_model.dart';
import '../../../../utils/date_range_utils.dart';

/// Shared Calendar Summary Bar Widget
/// Displays daily statistics: guests, check-ins, check-outs
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
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      physics: scrollController != null
          ? const NeverScrollableScrollPhysics() // Synced scroll
          : const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A24) : const Color(0xFFFAFAFC),
          border: Border(
            top: BorderSide(color: isDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight),
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
    final isDark = theme.brightness == Brightness.dark;

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

    final isToday = DateRangeUtils.isToday(date);
    final isWeekend = DateRangeUtils.isWeekend(date);
    final isNarrow = cellWidth < 60;

    return Container(
      width: cellWidth,
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primary.withAlpha((0.15 * 255).toInt())
            : isWeekend
            ? (isDark ? const Color(0xFF2A2A35) : const Color(0xFFF5F5FA))
            : (isDark ? const Color(0xFF1E1E28) : Colors.white),
        border: Border(left: BorderSide(color: isDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight)),
      ),
      padding: EdgeInsets.symmetric(vertical: isNarrow ? 4 : 6, horizontal: isNarrow ? 2 : 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Guests badge
          _buildStatBadge(
            context,
            Icons.people_alt_outlined,
            totalGuests.toString(),
            theme.colorScheme.primary,
            'Gosti',
            isNarrow,
          ),
          SizedBox(height: isNarrow ? 4 : 6),
          // Check-ins/Check-outs combined badge
          _buildCheckInOutBadge(context, checkIns, checkOuts, isNarrow),
        ],
      ),
    );
  }

  /// Build a stat badge with background
  Widget _buildStatBadge(
    BuildContext context,
    IconData icon,
    String value,
    Color color,
    String tooltip,
    bool isNarrow,
  ) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 4 : 6, vertical: isNarrow ? 2 : 3),
        decoration: BoxDecoration(color: color.withAlpha((0.15 * 255).toInt()), borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isNarrow ? 12 : 14, color: color),
            SizedBox(width: isNarrow ? 2 : 4),
            Text(
              value,
              style: TextStyle(fontSize: isNarrow ? 10 : 12, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }

  /// Build combined check-in/check-out badge
  Widget _buildCheckInOutBadge(BuildContext context, int checkIns, int checkOuts, bool isNarrow) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: 'Dolasci: $checkIns / Odlasci: $checkOuts',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 4 : 6, vertical: isNarrow ? 2 : 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D3A) : const Color(0xFFF0F0F5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: isNarrow ? 10 : 12, color: AppColors.success),
            SizedBox(width: isNarrow ? 1 : 2),
            Text(
              '$checkIns',
              style: TextStyle(fontSize: isNarrow ? 9 : 11, fontWeight: FontWeight.w600, color: AppColors.success),
            ),
            Text(
              '/',
              style: TextStyle(
                fontSize: isNarrow ? 9 : 11,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '$checkOuts',
              style: TextStyle(fontSize: isNarrow ? 9 : 11, fontWeight: FontWeight.w600, color: AppColors.error),
            ),
            SizedBox(width: isNarrow ? 1 : 2),
            Icon(Icons.logout, size: isNarrow ? 10 : 12, color: AppColors.error),
          ],
        ),
      ),
    );
  }
}
