import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/enums.dart';
import '../../../../../../../../shared/models/booking_model.dart';

/// Header section for booking card showing status badge and booking ID
class BookingCardHeader extends StatelessWidget {
  final BookingModel booking;
  final bool isMobile;

  const BookingCardHeader({super.key, required this.booking, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        // Neutralna pozadina - samo badge ima status boju
        color: isDark ? Colors.white.withAlpha((0.03 * 255).toInt()) : Colors.black.withAlpha((0.02 * 255).toInt()),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withAlpha((0.08 * 255).toInt()) : Colors.black.withAlpha((0.06 * 255).toInt()),
          ),
        ),
      ),
      child: Row(
        children: [
          // Status badge with icon - Minimalist
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: booking.status.color, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getStatusIcon(booking.status), color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  booking.status.displayName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Booking ID - Minimalist
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tag, size: 16, color: theme.colorScheme.onSurface.withAlpha((0.5 * 255).toInt())),
              const SizedBox(width: 4),
              Text(
                '#${booking.id.length > 8 ? booking.id.substring(0, 8) : booking.id}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha((0.65 * 255).toInt()),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Get icon for booking status
  static IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.completed:
        return Icons.task_alt;
    }
  }
}
