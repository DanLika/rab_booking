import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/constants/enums.dart';

/// Draggable booking block widget for calendar grid
/// Shows booking information as a colored block spanning multiple days
class BookingBlockWidget extends StatelessWidget {
  final BookingModel booking;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final bool isDraggable;
  final bool showGuestName;
  final bool showCheckInOut;

  const BookingBlockWidget({
    super.key,
    required this.booking,
    required this.width,
    required this.height,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.isDraggable = true,
    this.showGuestName = true,
    this.showCheckInOut = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final isCompact = height < 50 || width < 80;

    // FIXED: Add accessibility semantics
    final semanticsLabel = _buildSemanticLabel();

    final block = Semantics(
      label: semanticsLabel,
      button: true,
      enabled: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: onSecondaryTap,
        child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: statusColor.withAlpha((0.9 * 255).toInt()),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: statusColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: _buildContent(context, isCompact),
              ),

              // Check-in indicator (modern badge)
              if (showCheckInOut)
                Positioned(
                  left: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.95 * 255).toInt()),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.1 * 255).toInt()),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.login,
                          size: 10,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'IN',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Check-out indicator (modern badge)
              if (showCheckInOut)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.95 * 255).toInt()),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.1 * 255).toInt()),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout,
                          size: 10,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'OUT',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Source badge (if iCal, Booking.com, Airbnb)
              if (booking.source != null && booking.source != 'widget' && booking.source != 'manual')
                Positioned(
                  right: 4,
                  top: 4,
                  child: _buildSourceBadge(booking.source!),
                ),
            ],
          ),
        ),
      ),  // Close Container
    ),  // Close GestureDetector
    );  // Close Semantics

    // Wrap in Draggable if enabled
    if (isDraggable) {
      return LongPressDraggable<BookingModel>(
        data: booking,
        onDragStarted: onLongPress, // Call onLongPress when drag starts (optional)
        feedback: Opacity(
          opacity: 0.7,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: width,
              height: height,
              child: block,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: block,
        ),
        child: block,
      );
    }

    return block;
  }

  Widget _buildContent(BuildContext context, bool isCompact) {
    final textColor = _getTextColor(booking.status);

    if (isCompact) {
      // Compact view: only guest name
      return Center(
        child: Text(
          booking.guestName ?? 'Guest',
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // Full view: guest name + date range (if cross-month) + nights + guests
    final isCrossMonth = booking.checkIn.month != booking.checkOut.month ||
        booking.checkIn.year != booking.checkOut.year;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showGuestName)
          Text(
            booking.guestName ?? 'Guest',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 2),

        // Show date range for cross-month bookings
        if (isCrossMonth && width > 100) ...[
          Text(
            _getDateRangeString(booking.checkIn, booking.checkOut),
            style: TextStyle(
              color: textColor.withAlpha((0.9 * 255).toInt()),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
        ],

        // Nights + guests count
        Row(
          children: [
            Icon(
              Icons.nightlight_round,
              size: 12,
              color: textColor.withAlpha((0.8 * 255).toInt()),
            ),
            const SizedBox(width: 2),
            Text(
              '${booking.numberOfNights}n',
              style: TextStyle(
                color: textColor.withAlpha((0.9 * 255).toInt()),
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.person,
              size: 12,
              color: textColor.withAlpha((0.8 * 255).toInt()),
            ),
            const SizedBox(width: 2),
            Text(
              '${booking.guestCount}',
              style: TextStyle(
                color: textColor.withAlpha((0.9 * 255).toInt()),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Get formatted date range string (e.g., "31 Oct - 28 Nov")
  String _getDateRangeString(DateTime checkIn, DateTime checkOut) {
    final dateFormat = DateFormat('d MMM');
    return '${dateFormat.format(checkIn)} - ${dateFormat.format(checkOut)}';
  }

  Widget _buildSourceBadge(String source) {
    IconData icon;
    Color color;

    switch (source.toLowerCase()) {
      case 'ical':
        icon = Icons.sync;
        color = Colors.orange;
        break;
      case 'booking_com':
      case 'booking.com':
        icon = Icons.business;
        color = Colors.blue;
        break;
      case 'airbnb':
        icon = Icons.home;
        color = Colors.red;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Icon(
        icon,
        size: 10,
        color: color,
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange.shade400;
      case BookingStatus.confirmed:
        return Colors.green.shade400;
      case BookingStatus.inProgress:
        return Colors.blue.shade400;
      case BookingStatus.completed:
        return Colors.grey.shade400;
      case BookingStatus.cancelled:
        return Colors.red.shade400;
      case BookingStatus.blocked:
        return Colors.grey.shade600;
    }
  }

  Color _getTextColor(BookingStatus status) {
    // White text on most colors, dark text on light colors
    switch (status) {
      case BookingStatus.completed:
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  /// FIXED: Build semantic label for screen readers
  String _buildSemanticLabel() {
    final checkInStr = DateFormat('d. MMM').format(booking.checkIn);
    final checkOutStr = DateFormat('d. MMM').format(booking.checkOut);
    final statusStr = _getStatusName(booking.status);
    final guestName = booking.guestName ?? 'Unknown guest';

    return 'Booking for $guestName, from $checkInStr to $checkOutStr, ${booking.numberOfNights} nights, ${booking.guestCount} guests, status: $statusStr. Tap to view details.';
  }

  String _getStatusName(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.blocked:
        return 'Blocked';
    }
  }
}

