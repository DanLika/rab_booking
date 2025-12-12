import 'package:flutter/material.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// Daily statistics for a single date
class DailyStats {
  final int totalGuests;
  final int checkIns;
  final int checkOuts;

  const DailyStats({
    required this.totalGuests,
    required this.checkIns,
    required this.checkOuts,
  });

  /// Calculate statistics for a date from bookings
  factory DailyStats.calculate(
    DateTime date,
    Map<String, List<BookingModel>> bookingsByUnit,
  ) {
    int totalGuests = 0;
    int checkIns = 0;
    int checkOuts = 0;

    // Normalize date to midnight for accurate comparison
    final normalizedDate = DateTime(date.year, date.month, date.day);

    for (final bookings in bookingsByUnit.values) {
      for (final booking in bookings) {
        // Normalize booking dates to midnight for accurate comparison
        final normalizedCheckIn = DateTime(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
        final normalizedCheckOut = DateTime(booking.checkOut.year, booking.checkOut.month, booking.checkOut.day);

        // Count guests currently in property (checkIn <= date < checkOut)
        if (!normalizedCheckIn.isAfter(normalizedDate) && normalizedCheckOut.isAfter(normalizedDate)) {
          totalGuests += booking.guestCount;
        }

        // Count check-ins (checkIn == date)
        if (normalizedCheckIn.isAtSameMomentAs(normalizedDate)) {
          checkIns++;
        }

        // Count check-outs (checkOut == date)
        if (normalizedCheckOut.isAtSameMomentAs(normalizedDate)) {
          checkOuts++;
        }
      }
    }

    return DailyStats(
      totalGuests: totalGuests,
      checkIns: checkIns,
      checkOuts: checkOuts,
    );
  }
}

/// Stat badge with icon and value
/// Used in calendar summary rows to display guest count
class StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final String tooltip;
  final bool isNarrow;

  const StatBadge({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    required this.tooltip,
    this.isNarrow = false,
  });

  @override
  Widget build(BuildContext context) {
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
}

/// Combined check-in/check-out badge
/// Displays arrivals and departures count in a compact format
class CheckInOutBadge extends StatelessWidget {
  final int checkIns;
  final int checkOuts;
  final bool isNarrow;

  const CheckInOutBadge({
    super.key,
    required this.checkIns,
    required this.checkOuts,
    this.isNarrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

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

/// Complete daily stats cell widget
/// Combines guest count badge and check-in/out badge
class DailyStatsColumn extends StatelessWidget {
  final DailyStats stats;
  final bool isNarrow;
  final bool isVeryNarrow;

  const DailyStatsColumn({
    super.key,
    required this.stats,
    this.isNarrow = false,
    this.isVeryNarrow = false,
  });

  /// Create from raw data
  factory DailyStatsColumn.fromBookings({
    Key? key,
    required DateTime date,
    required Map<String, List<BookingModel>> bookingsByUnit,
    required double cellWidth,
  }) {
    final stats = DailyStats.calculate(date, bookingsByUnit);
    final isNarrow = cellWidth < 60;
    final isVeryNarrow = cellWidth < 45;

    return DailyStatsColumn(
      key: key,
      stats: stats,
      isNarrow: isNarrow,
      isVeryNarrow: isVeryNarrow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Guests badge
          StatBadge(
            icon: Icons.people_alt_outlined,
            value: stats.totalGuests.toString(),
            color: theme.colorScheme.primary,
            tooltip: l10n.ownerCalendarSummaryGuests,
            isNarrow: isNarrow,
          ),
          SizedBox(height: isVeryNarrow ? 4 : 6),
          // Check-ins/Check-outs combined badge
          CheckInOutBadge(
            checkIns: stats.checkIns,
            checkOuts: stats.checkOuts,
            isNarrow: isNarrow,
          ),
        ],
      ),
    );
  }
}
