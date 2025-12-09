import 'package:flutter/material.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// Timeline summary cell widget
///
/// Displays daily statistics (guests, check-ins, check-outs) in summary row.
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
        if (DateUtils.isSameDay(booking.checkIn, date)) {
          checkIns++;
        }

        // Count check-outs (checkOut == date)
        if (DateUtils.isSameDay(booking.checkOut, date)) {
          checkOuts++;
        }
      }
    }

    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    // Responsive sizing
    final isNarrow = dayWidth < 60;
    final isVeryNarrow = dayWidth < 45;

    return Container(
      width: dayWidth,
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primary.withAlpha((0.18 * 255).toInt())
            : isWeekend
            ? (isDark ? const Color(0xFF2A2535) : const Color(0xFFF8F5FC))
            : (isDark ? const Color(0xFF1E1E28) : Colors.white),
        border: Border(
          left: BorderSide(
            color: isDark
                ? AppColors.sectionDividerDark
                : AppColors.sectionDividerLight,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: isVeryNarrow ? 3 : 6,
        horizontal: isVeryNarrow ? 2 : 4,
      ),
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Guests badge
                _buildStatBadge(
                  context,
                  Icons.people_alt_outlined,
                  totalGuests.toString(),
                  theme.colorScheme.primary,
                  l10n.ownerCalendarSummaryGuests,
                  isNarrow,
                ),
                SizedBox(height: isVeryNarrow ? 4 : 6),
                // Check-ins/Check-outs combined badge
                _buildCheckInOutBadge(
                  context,
                  checkIns,
                  checkOuts,
                  l10n,
                  isNarrow,
                ),
              ],
            ),
          );
        },
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
        padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? 4 : 6,
          vertical: isNarrow ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: color.withAlpha((0.15 * 255).toInt()),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isNarrow ? 12 : 14, color: color),
            SizedBox(width: isNarrow ? 2 : 4),
            Text(
              value,
              style: TextStyle(
                fontSize: isNarrow ? 10 : 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build combined check-in/check-out badge
  Widget _buildCheckInOutBadge(
    BuildContext context,
    int checkIns,
    int checkOuts,
    AppLocalizations l10n,
    bool isNarrow,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: l10n.ownerCalendarSummaryArrivals(checkIns, checkOuts),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? 4 : 6,
          vertical: isNarrow ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D3A) : const Color(0xFFF0F0F5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login,
              size: isNarrow ? 10 : 12,
              color: AppColors.success,
            ),
            SizedBox(width: isNarrow ? 1 : 2),
            Text(
              '$checkIns',
              style: TextStyle(
                fontSize: isNarrow ? 9 : 11,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
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
              style: TextStyle(
                fontSize: isNarrow ? 9 : 11,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            SizedBox(width: isNarrow ? 1 : 2),
            Icon(
              Icons.logout,
              size: isNarrow ? 10 : 12,
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }
}
