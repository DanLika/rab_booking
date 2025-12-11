import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/utils/platform_utils.dart';
import 'enhanced_booking_drag_feedback.dart';
import 'skewed_booking_painter.dart';
import 'smart_booking_tooltip.dart';
import 'check_in_out_diagonal_indicator.dart';

/// Draggable booking block widget for calendar grid
/// Shows booking information as a colored block spanning multiple days
///
/// TURNOVER DAY SUPPORT:
/// Uses dayWidth (or derives it from width/nights) to calculate skewOffset
/// for proper diagonal alignment on turnover days.
class BookingBlockWidget extends StatelessWidget {
  final BookingModel booking;
  final double width;
  final double height;

  /// Optional: Width of a single day cell for turnover diagonal alignment.
  /// If not provided, calculated as width / (numberOfNights + 1).
  final double? dayWidth;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(TapDownDetails)? onSecondaryTapDown;
  final bool isDraggable;
  final bool showGuestName;
  final bool showCheckInOut;
  final bool hasConflict;

  /// ENHANCED: Resize functionality
  final bool isResizable;
  final void Function(DragStartDetails)? onResizeStartLeft;
  final void Function(DragUpdateDetails)? onResizeUpdateLeft;
  final void Function(DragEndDetails)? onResizeEndLeft;
  final void Function(DragStartDetails)? onResizeStartRight;
  final void Function(DragUpdateDetails)? onResizeUpdateRight;
  final void Function(DragEndDetails)? onResizeEndRight;
  final bool isResizing; // Show visual feedback during resize

  /// ENHANCED: Multi-select functionality
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;

  const BookingBlockWidget({
    super.key,
    required this.booking,
    required this.width,
    required this.height,
    this.dayWidth,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTapDown,
    this.isDraggable = true,
    this.showGuestName = true,
    this.showCheckInOut = true,
    this.hasConflict = false,
    this.isResizable = false,
    this.onResizeStartLeft,
    this.onResizeUpdateLeft,
    this.onResizeEndLeft,
    this.onResizeStartRight,
    this.onResizeUpdateRight,
    this.onResizeEndRight,
    this.isResizing = false,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final isCompact = height < 50 || width < 80;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ENHANCED: Get source border color for left stripe indicator
    final sourceBorderColor = _getSourceBorderColor(booking.source);
    final showSourceBorder = sourceBorderColor != null;

    // ENHANCED: Read-only logic for external sources (iCal, Airbnb, Booking.com)
    final isFromExternalSource = _isFromExternalSource(booking.source);

    // FIXED: Add accessibility semantics
    final semanticsLabel = _buildSemanticLabel();

    final block = Semantics(
      label: semanticsLabel,
      button: true,
      enabled: true,
      child: MouseRegion(
        // Smart hover - automatically works only on desktop
        cursor: SystemMouseCursors.click,
        onEnter: PlatformUtils.supportsHover
            ? (event) => SmartBookingTooltip.show(
                context: context,
                booking: booking,
                position: event.position,
              )
            : null,
        onExit: PlatformUtils.supportsHover
            ? (_) => SmartBookingTooltip.hide()
            : null,
        child: GestureDetector(
          // In multi-select mode, tap toggles selection
          // If no onTap callback provided, show tooltip on tap (mobile)
          onTap: isMultiSelectMode
              ? onSelectionToggle
              : onTap ??
                    () => SmartBookingTooltip.show(
                      context: context,
                      booking: booking,
                    ),
          onLongPress: onLongPress,
          onSecondaryTapDown: onSecondaryTapDown,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                // Background layer with skewed parallelogram shape
                // Calculate dayWidth for turnover day alignment
                CustomPaint(
                  painter: SkewedBookingPainter(
                    backgroundColor: statusColor.withAlpha((0.9 * 255).toInt()),
                    borderColor: hasConflict ? Colors.red : statusColor,
                    dayWidth:
                        dayWidth ?? (width / (booking.numberOfNights + 1)),
                    borderWidth: hasConflict ? 2.5 : 1.5,
                    hasConflict: hasConflict,
                  ),
                  size: Size(width, height),
                ),

                // Content layer - clipped to skewed shape
                ClipPath(
                  clipper: SkewedBookingClipper(
                    dayWidth:
                        dayWidth ?? (width / (booking.numberOfNights + 1)),
                  ),
                  child: Stack(
                    children: [
                      // Check-in diagonal indicator (left edge)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: CheckInDiagonalIndicator(
                          height: height,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),

                      // Check-out diagonal indicator (right edge)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: CheckOutDiagonalIndicator(
                          height: height,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),

                      // ENHANCED: Resize visual feedback overlay
                      if (isResizing)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),

                      // ENHANCED: Multi-select overlay (selected state)
                      if (isMultiSelectMode && isSelected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(
                                (0.2 * 255).toInt(),
                              ),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),

                      // ENHANCED: Left border stripe for booking source
                      if (showSourceBorder)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: sourceBorderColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                bottomLeft: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),

                      // Main content - BedBooking style: minimal and clean
                      Padding(
                        padding: EdgeInsets.only(
                          left: showSourceBorder ? 10 : 6,
                          right: 6,
                          top: 4,
                          bottom: 4,
                        ),
                        child: _buildContent(context, isCompact),
                      ),

                      // Conflict warning indicator - always visible if conflict exists
                      if (hasConflict)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Tooltip(
                            message: 'UPOZORENJE: Preklapanje rezervacija!',
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: AppShadows.getElevation(
                                  2,
                                  isDark: isDark,
                                ),
                              ),
                              child: const Icon(
                                Icons.warning,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                      // ENHANCED: Read-only lock icon for external sources
                      if (isFromExternalSource && !isCompact)
                        Positioned(
                          left: hasConflict ? 4 : null,
                          right: hasConflict ? null : 4,
                          top: hasConflict ? 24 : 4,
                          child: Tooltip(
                            message:
                                'Rezervacija iz vanjskog izvora (${_getSourceName(booking.source)}) - nije moguće editirati ovdje',
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade700,
                                shape: BoxShape.circle,
                                boxShadow: AppShadows.getElevation(
                                  2,
                                  isDark: isDark,
                                ),
                              ),
                              child: const Icon(
                                Icons.lock,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                      // ENHANCED: Multi-select checkbox (top-left)
                      if (isMultiSelectMode && width >= 50)
                        Positioned(
                          left: 4,
                          top: 4,
                          child: GestureDetector(
                            onTap: onSelectionToggle,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white.withAlpha(
                                        (0.9 * 255).toInt(),
                                      ),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: AppShadows.getElevation(
                                  1,
                                  isDark: isDark,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                    ], // Close children of inner Stack
                  ), // Close inner Stack (child of ClipPath)
                ), // Close ClipPath
              ], // Close children of outer Stack
            ), // Close outer Stack (child of SizedBox)
          ), // Close SizedBox (child of GestureDetector)
        ), // Close GestureDetector (child of MouseRegion)
      ), // Close MouseRegion (child of Semantics)
    ); // Close Semantics

    // Wrap in Draggable if enabled (but not in multi-select mode)
    if (isDraggable && !isMultiSelectMode) {
      return LongPressDraggable<BookingModel>(
        data: booking,
        onDragStarted:
            onLongPress, // Call onLongPress when drag starts (optional)
        feedback: EnhancedBookingDragFeedback(
          booking: booking,
          width: width,
          height: height,
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: block),
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
          booking.guestName ?? 'Gost',
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
    final isCrossMonth =
        booking.checkIn.month != booking.checkOut.month ||
        booking.checkIn.year != booking.checkOut.year;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showGuestName)
          Text(
            booking.guestName ?? 'Gost',
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
    final dateFormat = DateFormat('d MMM', 'hr_HR');
    return '${dateFormat.format(checkIn)} - ${dateFormat.format(checkOut)}';
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.statusPending;
      case BookingStatus.confirmed:
        return AppColors.statusConfirmed;
      case BookingStatus.completed:
        return AppColors.statusCompleted;
      case BookingStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  Color _getTextColor(BookingStatus status) {
    // White text works well on all status colors for contrast
    return Colors.white;
  }

  /// FIXED: Build semantic label for screen readers
  String _buildSemanticLabel() {
    final checkInStr = DateFormat('d. MMM', 'hr_HR').format(booking.checkIn);
    final checkOutStr = DateFormat('d. MMM', 'hr_HR').format(booking.checkOut);
    final statusStr = _getStatusName(booking.status);
    final guestName = booking.guestName ?? 'Nepoznati gost';
    final nights = booking.checkOut.difference(booking.checkIn).inDays;

    return 'Rezervacija za $guestName, od $checkInStr do $checkOutStr, $nights noći, ${booking.guestCount} gostiju, status: $statusStr. Tapni za detalje.';
  }

  String _getStatusName(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }

  /// ENHANCED: Get source border color for visual distinction (BedBooking-style left stripe)
  Color? _getSourceBorderColor(String? source) {
    if (source == null) return null;

    switch (source.toLowerCase()) {
      case 'airbnb':
        return const Color(0xFFFF5A5F); // Airbnb red
      case 'booking_com':
      case 'booking.com':
        return AppColors.authSecondary; // Blue
      case 'ical':
        return AppColors.warning; // Orange
      case 'direct':
        return AppColors.success; // Green
      case 'admin':
        return AppColors.tertiary; // Golden
      case 'api':
        return AppColors.info; // Cyan/Blue
      case 'widget':
        return AppColors.primary; // Purple
      case 'manual':
        return AppColors.primaryDark; // Dark Purple
      default:
        return null;
    }
  }

  /// Check if booking is from external source (iCal, Airbnb, Booking.com)
  /// External bookings are read-only and cannot be edited/moved/resized
  bool _isFromExternalSource(String? source) {
    if (source == null) return false;
    final normalizedSource = source.toLowerCase();
    return normalizedSource == 'ical' ||
        normalizedSource == 'airbnb' ||
        normalizedSource == 'booking_com' ||
        normalizedSource == 'booking.com';
  }

  /// Get user-friendly source name for tooltip/messages
  String _getSourceName(String? source) {
    if (source == null) return 'nepoznat izvor';
    switch (source.toLowerCase()) {
      case 'airbnb':
        return 'Airbnb';
      case 'booking_com':
      case 'booking.com':
        return 'Booking.com';
      case 'ical':
        return 'iCal sync';
      default:
        return source;
    }
  }
}
