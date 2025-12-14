import 'package:flutter/material.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/utils/platform_utils.dart';
import '../../../utils/booking_overlap_detector.dart';
import '../calendar/skewed_booking_painter.dart';
import '../calendar/smart_booking_tooltip.dart';

/// Timeline booking block widget
///
/// Displays a booking as a skewed parallelogram block in the timeline calendar.
/// Includes check-in/out diagonal indicators, guest info, and hover tooltips.
///
/// TURNOVER DAY SUPPORT:
/// The parallelogram shape uses dayWidth to calculate skewOffset, ensuring that
/// on turnover days (checkout + checkin same day), the diagonals meet at the
/// center of the shared cell with a small gap between them.
///
/// Extracted from timeline_calendar_widget.dart for better maintainability.
class TimelineBookingBlock extends StatefulWidget {
  /// The booking to display
  final BookingModel booking;

  /// Width of the booking block (based on number of nights)
  final double width;

  /// Height of the unit row (used to calculate block height)
  final double unitRowHeight;

  /// Width of a single day cell (used for turnover day diagonal alignment)
  final double dayWidth;

  /// All bookings by unit ID (used for conflict detection)
  final Map<String, List<BookingModel>> allBookingsByUnit;

  /// Callback when the booking block is tapped
  final VoidCallback onTap;

  /// Callback when the booking block is long-pressed (move to unit menu)
  final VoidCallback onLongPress;

  const TimelineBookingBlock({
    super.key,
    required this.booking,
    required this.width,
    required this.unitRowHeight,
    required this.dayWidth,
    required this.allBookingsByUnit,
    required this.onTap,
    required this.onLongPress,
  });

  /// Calculate number of nights between check-in and check-out
  ///
  /// Normalizes dates to midnight for accurate day difference calculation.
  static int calculateNights(DateTime checkIn, DateTime checkOut) {
    final normalizedCheckIn = DateTime(checkIn.year, checkIn.month, checkIn.day);
    final normalizedCheckOut = DateTime(checkOut.year, checkOut.month, checkOut.day);
    return normalizedCheckOut.difference(normalizedCheckIn).inDays;
  }

  /// Check if a booking has conflicts with other bookings in the same unit
  ///
  /// Uses BookingOverlapDetector to find overlapping bookings.
  static bool hasBookingConflict(BookingModel booking, Map<String, List<BookingModel>> allBookingsByUnit) {
    return getConflictingBookings(booking, allBookingsByUnit).isNotEmpty;
  }

  /// Get list of bookings that conflict with this booking
  ///
  /// Uses BookingOverlapDetector to find overlapping bookings.
  static List<BookingModel> getConflictingBookings(
    BookingModel booking,
    Map<String, List<BookingModel>> allBookingsByUnit,
  ) {
    return BookingOverlapDetector.getConflictingBookings(
      unitId: booking.unitId,
      newCheckIn: booking.checkIn,
      newCheckOut: booking.checkOut,
      bookingIdToExclude: booking.id,
      allBookings: allBookingsByUnit,
    );
  }

  /// Get list of dates within this booking that have conflicts
  ///
  /// Returns a list of DateTime objects (normalized to midnight) for each day
  /// that has an overbooking conflict.
  static List<DateTime> getConflictDates(BookingModel booking, Map<String, List<BookingModel>> allBookingsByUnit) {
    final conflictingBookings = getConflictingBookings(booking, allBookingsByUnit);

    if (conflictingBookings.isEmpty) {
      return [];
    }

    final conflictDates = <DateTime>{};

    // For each conflicting booking, find all overlapping dates
    for (final conflictBooking in conflictingBookings) {
      // Find the intersection of date ranges
      final overlapStart = booking.checkIn.isAfter(conflictBooking.checkIn) ? booking.checkIn : conflictBooking.checkIn;
      final overlapEnd = booking.checkOut.isBefore(conflictBooking.checkOut)
          ? booking.checkOut
          : conflictBooking.checkOut;

      // Add all dates in the overlap range (excluding checkout date)
      var currentDate = DateTime(overlapStart.year, overlapStart.month, overlapStart.day);
      final endDate = DateTime(overlapEnd.year, overlapEnd.month, overlapEnd.day);

      while (currentDate.isBefore(endDate)) {
        conflictDates.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    return conflictDates.toList()..sort();
  }

  @override
  State<TimelineBookingBlock> createState() => _TimelineBookingBlockState();
}

class _TimelineBookingBlockState extends State<TimelineBookingBlock> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final width = widget.width;
    final unitRowHeight = widget.unitRowHeight;
    final dayWidth = widget.dayWidth;
    final allBookingsByUnit = widget.allBookingsByUnit;
    final blockHeight = unitRowHeight - 8; // Reduced padding for smaller blocks

    // Detect conflicts with other bookings in the same unit
    final conflictingBookings = TimelineBookingBlock.getConflictingBookings(booking, allBookingsByUnit);
    final hasConflict = conflictingBookings.isNotEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: PlatformUtils.supportsHover
          ? (event) {
              setState(() => _isHovered = true);
              SmartBookingTooltip.show(
                context: context,
                booking: booking,
                position: event.position,
                hasConflict: hasConflict,
                conflictingBookings: conflictingBookings,
              );
            }
          : null,
      onExit: PlatformUtils.supportsHover
          ? (_) {
              setState(() => _isHovered = false);
              SmartBookingTooltip.hide();
            }
          : null,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: width - 4, // 2px left + 2px right gap
          height: blockHeight,
          margin: const EdgeInsets.symmetric(horizontal: 2), // 2px gap on each side
          transform: _isHovered ? Matrix4.diagonal3Values(1.02, 1.02, 1.0) : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _isHovered ? 1.0 : 0.92,
            child: Stack(
              alignment: Alignment.topLeft, // Explicit alignment to avoid TextDirection dependency on Chrome Mobile
              children: [
                // Background layer with skewed parallelogram
                // dayWidth is used to calculate skewOffset for turnover day alignment
                CustomPaint(
                  painter: SkewedBookingPainter(
                    backgroundColor: booking.status.color,
                    borderColor: booking.status.color,
                    dayWidth: dayWidth,
                    hasConflict: hasConflict,
                  ),
                  size: Size(width - 2, blockHeight),
                ),

                // Conflict indicator (single centered warning icon)
                if (hasConflict)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(80),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
