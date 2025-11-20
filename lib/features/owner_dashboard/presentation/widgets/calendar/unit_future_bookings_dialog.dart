import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/constants/app_dimensions.dart';

/// Dialog showing all future bookings for a specific unit
class UnitFutureBookingsDialog extends StatelessWidget {
  final UnitModel unit;
  final List<BookingModel> bookings;
  final Function(BookingModel) onBookingTap;

  const UnitFutureBookingsDialog({
    required this.unit,
    required this.bookings,
    required this.onBookingTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppDimensions.mobile;

    return Dialog(
      child: Container(
        width: isMobile ? screenWidth * 0.95 : 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(
                isMobile ? AppDimensions.spaceS : AppDimensions.spaceM,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: isMobile ? 20 : 24,
                  ),
                  const SizedBox(width: AppDimensions.spaceS),
                  Expanded(
                    child: AutoSizeText(
                      'Nadolazeće rezervacije - ${unit.name}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      minFontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Zatvori',
                  ),
                ],
              ),
            ),

            // Bookings list
            Flexible(
              child: bookings.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      padding: EdgeInsets.all(
                        isMobile ? AppDimensions.spaceS : AppDimensions.spaceM,
                      ),
                      itemCount: bookings.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return _buildBookingTile(context, booking, isMobile);
                      },
                    ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceM),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${bookings.length} rezervacija',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Zatvori'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              'Nema nadolazećih rezervacija',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: AppDimensions.spaceXS),
            Text(
              'Sve buduce rezervacije za ${unit.name} ce se prikazati ovdje',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTile(
    BuildContext context,
    BookingModel booking,
    bool isMobile,
  ) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isInProgress =
        booking.checkIn.isBefore(now) && booking.checkOut.isAfter(now);
    final nights = booking.checkOut.difference(booking.checkIn).inDays;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onBookingTap(booking);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXS),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: isMobile ? 20 : 24,
              backgroundColor: booking.status.color.withOpacity(0.2),
              child: Icon(
                isInProgress ? Icons.person : Icons.person_outline,
                color: booking.status.color,
                size: isMobile ? 20 : 24,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceS),

            // Booking info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guest name
                  AutoSizeText(
                    booking.guestName ?? 'Unknown Guest',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: AppDimensions.spaceXXS / 2),

                  // Check-in
                  Row(
                    children: [
                      const Icon(Icons.login, size: 14, color: Colors.green),
                      const SizedBox(width: AppDimensions.spaceXXS),
                      Expanded(
                        child: AutoSizeText(
                          'Check-in: ${booking.checkIn.day}.${booking.checkIn.month}.${booking.checkIn.year}.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          maxLines: 1,
                          minFontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceXXS / 4),

                  // Check-out
                  Row(
                    children: [
                      const Icon(Icons.logout, size: 14, color: Colors.red),
                      const SizedBox(width: AppDimensions.spaceXXS),
                      Expanded(
                        child: AutoSizeText(
                          'Check-out: ${booking.checkOut.day}.${booking.checkOut.month}.${booking.checkOut.year}.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          maxLines: 1,
                          minFontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceXXS / 2),

                  // Guest count and nights
                  AutoSizeText(
                    '${booking.guestCount} gost${booking.guestCount > 1 ? 'a' : ''} • $nights noć${nights > 1 ? 'i' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    maxLines: 1,
                    minFontSize: 9,
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppDimensions.spaceS),

            // Status chip - FIXED: SizedBox with specific width to prevent layout errors
            SizedBox(
              width: 100,
              height: 32,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceXS,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: booking.status.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  booking.status.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: booking.status.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
