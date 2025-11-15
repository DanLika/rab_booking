import 'package:flutter/material.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/constants/enums.dart';

/// Enhanced Booking Drag Feedback Widget
/// Shows a visually appealing preview while dragging a booking
class EnhancedBookingDragFeedback extends StatelessWidget {
  final BookingModel booking;
  final double width;
  final double height;

  const EnhancedBookingDragFeedback({
    super.key,
    required this.booking,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(8),
      color: Colors.transparent,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getStatusColor(booking.status).withAlpha((0.9 * 255).toInt()),
              _getStatusColor(booking.status).withAlpha((0.7 * 255).toInt()),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary, width: 3),
          boxShadow: [
            ...AppShadows.getElevation(4, isDark: isDark),
            BoxShadow(
              color: AppColors.primary.withAlpha((0.5 * 255).toInt()),
              blurRadius: 20,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Drag indicator icon (top-left)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.9 * 255).toInt()),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.drag_indicator,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ),

            // Content
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Guest name
                    Text(
                      booking.guestName ?? 'Gost',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),

                    if (height > 50) ...[
                      const SizedBox(height: 8),

                      // Duration info
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.2 * 255).toInt()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.nightlight_round,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${booking.numberOfNights} noći',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom instruction text
            if (height > 70)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Text(
                  'Pusti na željenu poziciju',
                  style: TextStyle(
                    color: Colors.white.withAlpha((0.9 * 255).toInt()),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.statusPending;
      case BookingStatus.confirmed:
        return AppColors.statusConfirmed;
      case BookingStatus.checkedIn:
        return AppColors.primary.withAlpha((0.8 * 255).toInt());
      case BookingStatus.checkedOut:
        return AppColors.authSecondary.withAlpha((0.5 * 255).toInt());
      case BookingStatus.inProgress:
        return AppColors.authSecondary.withAlpha((0.7 * 255).toInt());
      case BookingStatus.completed:
        return AppColors.statusCompleted;
      case BookingStatus.cancelled:
        return AppColors.statusCancelled;
      case BookingStatus.blocked:
        return AppColors.statusCompleted.withAlpha((0.6 * 255).toInt());
    }
  }
}
