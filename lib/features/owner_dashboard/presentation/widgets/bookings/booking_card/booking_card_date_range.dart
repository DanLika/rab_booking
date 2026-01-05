import 'package:flutter/material.dart';
import '../../../../../../../../shared/models/booking_model.dart';
import '../../../../../../../../l10n/app_localizations.dart';

/// Date range information section for booking card
///
/// Displays check-in and check-out dates with number of nights
class BookingCardDateRange extends StatelessWidget {
  final BookingModel booking;
  final bool isMobile;

  const BookingCardDateRange({
    super.key,
    required this.booking,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon container
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.calendar_today_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: [
              // Check-in to check-out dates
              Text(
                '${booking.checkIn.day}.${booking.checkIn.month}.${booking.checkIn.year}. - '
                '${booking.checkOut.day}.${booking.checkOut.month}.${booking.checkOut.year}.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Number of nights
              Text(
                '(${booking.numberOfNights} ${booking.numberOfNights == 1 ? l10n.ownerBookingCardNight : l10n.ownerBookingCardNights})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.6 * 255).toInt(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
