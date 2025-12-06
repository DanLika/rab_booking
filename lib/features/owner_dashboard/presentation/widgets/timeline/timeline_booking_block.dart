import 'package:flutter/material.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/utils/platform_utils.dart';
import '../../../utils/calendar_grid_calculator.dart';
import '../../../utils/booking_overlap_detector.dart';
import '../calendar/skewed_booking_painter.dart';
import '../calendar/smart_booking_tooltip.dart';
import '../../../../../l10n/app_localizations.dart';

/// Timeline booking block widget
///
/// Displays a booking as a skewed parallelogram block in the timeline calendar.
/// Includes check-in/out diagonal indicators, guest info, and hover tooltips.
///
/// Extracted from timeline_calendar_widget.dart for better maintainability.
class TimelineBookingBlock extends StatefulWidget {
  /// The booking to display
  final BookingModel booking;

  /// Width of the booking block (based on number of nights)
  final double width;

  /// Height of the unit row (used to calculate block height)
  final double unitRowHeight;

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
    required this.allBookingsByUnit,
    required this.onTap,
    required this.onLongPress,
  });

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
    final allBookingsByUnit = widget.allBookingsByUnit;
    final blockHeight = unitRowHeight - 16;
    final nights = calculateNights(booking.checkIn, booking.checkOut);
    final screenWidth = MediaQuery.of(context).size.width;

    // Get responsive dimensions from CalendarGridCalculator
    final guestNameFontSize = CalendarGridCalculator.getBookingGuestNameFontSize(screenWidth);
    final metadataFontSize = CalendarGridCalculator.getBookingMetadataFontSize(screenWidth);
    final bookingPadding = CalendarGridCalculator.getBookingPadding(screenWidth);

    // ENHANCED: Detect conflicts with other bookings in the same unit
    final hasConflict = hasBookingConflict(booking, allBookingsByUnit);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: PlatformUtils.supportsHover
          ? (event) {
              setState(() => _isHovered = true);
              SmartBookingTooltip.show(context: context, booking: booking, position: event.position);
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
          width: width - 2,
          height: blockHeight,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          transform: _isHovered ? (Matrix4.identity()..scale(1.02)) : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _isHovered ? 1.0 : 0.92,
            child: Stack(
              children: [
                // Background layer with skewed parallelogram
                CustomPaint(
                  painter: SkewedBookingPainter(
                    backgroundColor: booking.status.color,
                    borderColor: booking.status.color,
                    hasConflict: hasConflict,
                  ),
                  size: Size(width - 2, blockHeight),
                ),

                // Content layer - clipped to skewed shape
                ClipPath(
                  clipper: SkewedBookingClipper(),
                  child: Padding(
                    padding: bookingPadding.copyWith(
                      left: bookingPadding.left + 12,
                    ), // Increased from 8 to 12 for better spacing
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        // Determine text color based on background luminance
                        final textColor = _getContrastTextColor(booking.status.color);
                        final secondaryTextColor = textColor.withValues(alpha: 0.85);
                        final iconColor = textColor.withValues(alpha: 0.7);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              booking.guestName ?? l10n.ownerCalendarDefaultGuest,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: guestNameFontSize,
                                shadows: _shouldAddTextShadow(booking.status.color)
                                    ? [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 2)]
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person, size: metadataFontSize + 2, color: iconColor),
                                const SizedBox(width: 2),
                                Text(
                                  '${booking.guestCount}',
                                  style: TextStyle(color: secondaryTextColor, fontSize: metadataFontSize),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.nights_stay, size: metadataFontSize + 2, color: iconColor),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    '$nights',
                                    style: TextStyle(color: secondaryTextColor, fontSize: metadataFontSize),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
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
    final conflicts = BookingOverlapDetector.getConflictingBookings(
      unitId: booking.unitId,
      newCheckIn: booking.checkIn,
      newCheckOut: booking.checkOut,
      bookingIdToExclude: booking.id,
      allBookings: allBookingsByUnit,
    );

    return conflicts.isNotEmpty;
  }

  /// Get contrasting text color based on background luminance
  static Color _getContrastTextColor(Color backgroundColor) {
    // Calculate relative luminance
    final luminance = backgroundColor.computeLuminance();
    // Use white text for dark backgrounds, dark text for light backgrounds
    return luminance > 0.5 ? const Color(0xFF1A1A1A) : Colors.white;
  }

  /// Determine if text shadow should be added for better readability
  static bool _shouldAddTextShadow(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    // Add shadow for medium luminance colors where contrast might be borderline
    return luminance > 0.3 && luminance < 0.7;
  }
}
