import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/widgets/platform_icon.dart';
import '../../../../../core/utils/platform_utils.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../providers/overbooking_detection_provider.dart';
import '../calendar/skewed_booking_painter.dart';
import '../calendar/smart_booking_tooltip.dart';
import 'timeline_constants.dart';

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
/// CONFLICT DETECTION:
/// Uses overbookingDetectionProvider for consistent conflict detection across
/// all calendar views (Timeline, Month, Year, Bookings page).
///
/// Extracted from timeline_calendar_widget.dart for better maintainability.
class TimelineBookingBlock extends ConsumerStatefulWidget {
  /// The booking to display
  final BookingModel booking;

  /// Width of the booking block (based on number of nights)
  final double width;

  /// Height of the unit row (used to calculate block height)
  final double unitRowHeight;

  /// Width of a single day cell (used for turnover day diagonal alignment)
  final double dayWidth;

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
    required this.onTap,
    required this.onLongPress,
  });

  /// Calculate number of nights between check-in and check-out
  ///
  /// Normalizes dates to midnight UTC for accurate day difference calculation.
  /// IMPORTANT: Uses UTC to match timeline position calculations and avoid
  /// timezone-related off-by-one errors.
  static int calculateNights(DateTime checkIn, DateTime checkOut) {
    final normalizedCheckIn = DateTime.utc(
      checkIn.year,
      checkIn.month,
      checkIn.day,
    );
    final normalizedCheckOut = DateTime.utc(
      checkOut.year,
      checkOut.month,
      checkOut.day,
    );
    return normalizedCheckOut.difference(normalizedCheckIn).inDays;
  }

  @override
  ConsumerState<TimelineBookingBlock> createState() =>
      _TimelineBookingBlockState();
}

class _TimelineBookingBlockState extends ConsumerState<TimelineBookingBlock> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final width = widget.width;
    final unitRowHeight = widget.unitRowHeight;
    final dayWidth = widget.dayWidth;
    final blockHeight = unitRowHeight - kTimelineBookingBlockHeightPadding;

    // Use centralized overbooking detection provider for consistent conflict detection
    // across all calendar views (Timeline, Month, Year, Bookings page)
    final hasConflict = ref.watch(isBookingInConflictProvider(booking.id));

    // Get conflicting bookings for tooltip display
    final conflictsAsync = ref.watch(overbookingConflictsProvider);
    final allConflicts = conflictsAsync.valueOrNull ?? [];
    final conflictingBookings = allConflicts
        .where(
          (c) => c.booking1.id == booking.id || c.booking2.id == booking.id,
        )
        .expand((c) => [c.booking1, c.booking2])
        .where((b) => b.id != booking.id)
        .toList();

    // Build semantic label for accessibility
    final semanticLabel = _buildSemanticLabel(booking, hasConflict);

    // GHOST DATA LOGIC
    final isGhost = booking.id.startsWith('ghost_');
    if (isGhost) {
      return RepaintBoundary(
        child: IgnorePointer(
          child: Container(
            width: width - (kTimelineBookingBlockHorizontalMargin * 2),
            height: blockHeight,
            margin: const EdgeInsets.symmetric(
              horizontal: kTimelineBookingBlockHorizontalMargin,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                style: BorderStyle.solid,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                'Example Booking',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: Semantics(
        label: semanticLabel,
        button: true,
        enabled: true,
        child: MouseRegion(
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
              duration: kTimelineBookingBlockHoverAnimationDuration,
              curve: Curves.easeOut,
              width: width - (kTimelineBookingBlockHorizontalMargin * 2),
              height: blockHeight,
              margin: const EdgeInsets.symmetric(
                horizontal: kTimelineBookingBlockHorizontalMargin,
              ),
              transform: _isHovered
                  ? Matrix4.diagonal3Values(
                      kTimelineBookingBlockHoverScale,
                      kTimelineBookingBlockHoverScale,
                      1.0,
                    )
                  : Matrix4.identity(),
              transformAlignment: Alignment.center,
              child: AnimatedOpacity(
                duration: kTimelineBookingBlockHoverAnimationDuration,
                opacity: _isHovered
                    ? kTimelineBookingBlockHoverOpacity
                    : kTimelineBookingBlockNormalOpacity,
                child: Stack(
                  alignment: Alignment
                      .topLeft, // Explicit alignment to avoid TextDirection dependency on Chrome Mobile
                  children: [
                    // Background layer with skewed parallelogram
                    // dayWidth is used to calculate skewOffset for turnover day alignment
                    CustomPaint(
                      painter: SkewedBookingPainter(
                        backgroundColor: booking.status.color,
                        borderColor: booking.status.color,
                        dayWidth: dayWidth,
                        hasConflict: hasConflict,
                        // Theme-aware separator color for diagonal lines
                        separatorColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.2),
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
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
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

                    // Platform icon for external bookings (Booking.com, Airbnb, etc.)
                    // Only show for external platforms, not for widget/direct bookings
                    if (PlatformIcon.shouldShowIcon(booking.source))
                      Positioned(
                        top: 2,
                        right: hasConflict
                            ? 28
                            : 4, // Offset if conflict icon present
                        child: PlatformIcon(
                          source: booking.source,
                          size: 14,
                          showTooltip:
                              false, // Tooltip handled by SmartBookingTooltip
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build semantic label for screen readers
  String _buildSemanticLabel(BookingModel booking, bool hasConflict) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final checkInStr = DateFormat(
      'd. MMM',
      locale.toString(),
    ).format(booking.checkIn);
    final checkOutStr = DateFormat(
      'd. MMM',
      locale.toString(),
    ).format(booking.checkOut);
    final nights = booking.checkOut.difference(booking.checkIn).inDays;
    final guestName = booking.guestName ?? l10n.bookingActionUnknownGuest;
    final conflictText = hasConflict ? ', ${l10n.bookingBlockHasConflict}' : '';

    return l10n.bookingBlockSemanticLabel(
      guestName,
      checkInStr,
      checkOutStr,
      nights,
      booking.guestCount,
      conflictText,
    );
  }
}
