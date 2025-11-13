import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/theme/app_colors.dart';
import 'enhanced_booking_drag_feedback.dart';
import 'check_in_out_diagonal_indicator.dart';

/// Draggable booking block widget for calendar grid
/// Shows booking information as a colored block spanning multiple days
class BookingBlockWidget extends StatelessWidget {
  final BookingModel booking;
  final double width;
  final double height;
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

    // FIXED: Prevent badge overlap on small blocks
    final showBadges = height >= 40 && width >= 60;
    final hasSourceBadge = booking.source != null &&
                          booking.source != 'widget' &&
                          booking.source != 'manual';

    // ENHANCED: Get source border color
    final sourceBorderColor = _getSourceBorderColor(booking.source);
    final showSourceBorder = sourceBorderColor != null;

    // FIXED: Add accessibility semantics
    final semanticsLabel = _buildSemanticLabel();

    final block = Semantics(
      label: semanticsLabel,
      button: true,
      enabled: true,
      child: GestureDetector(
        // In multi-select mode, tap toggles selection
        onTap: isMultiSelectMode ? onSelectionToggle : onTap,
        onLongPress: onLongPress,
        onSecondaryTapDown: onSecondaryTapDown,
        child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: statusColor.withAlpha((0.9 * 255).toInt()),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: hasConflict ? Colors.red : statusColor,
            width: hasConflict ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: hasConflict
                  ? Colors.red.withAlpha((0.3 * 255).toInt())
                  : Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: hasConflict ? 4 : 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
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
                      color: AppColors.primary.withAlpha((0.2 * 255).toInt()),
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

              // Main content
              Padding(
                padding: EdgeInsets.only(
                  left: showSourceBorder ? 10 : 6,
                  right: 6,
                  top: 4,
                  bottom: 4,
                ),
                child: _buildContent(context, isCompact),
              ),

              // ENHANCED: Check-in diagonal line indicator (left side)
              if (showCheckInOut && height >= 40)
                Positioned(
                  left: 0,
                  top: 0,
                  child: CheckInDiagonalIndicator(
                    height: height,
                    color: Colors.white.withAlpha((0.8 * 255).toInt()),
                  ),
                ),

              // Check-in indicator (modern badge) - FIXED: Only show if enough space
              if (showCheckInOut && showBadges)
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

              // ENHANCED: Check-out diagonal line indicator (right side)
              if (showCheckInOut && height >= 40)
                Positioned(
                  right: 0,
                  top: 0,
                  child: CheckOutDiagonalIndicator(
                    height: height,
                    color: Colors.white.withAlpha((0.8 * 255).toInt()),
                  ),
                ),

              // Check-out indicator (modern badge) - FIXED: Only show if enough space
              if (showCheckInOut && showBadges)
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

              // Source badge (if iCal, Booking.com, Airbnb) - FIXED: Only show if enough space
              if (hasSourceBadge && showBadges && width >= 100)
                Positioned(
                  right: 4,
                  top: showCheckInOut ? 20 : 4, // Move down if check-in badge is present
                  child: _buildSourceBadge(booking.source!),
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.3 * 255).toInt()),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.warning,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // ENHANCED: Guest count indicator (top right dots)
              if (showBadges && !hasConflict && width >= 80)
                Positioned(
                  right: 4,
                  top: 4,
                  child: _buildGuestCountIndicator(),
                ),

              // ENHANCED: Payment status indicator (bottom left)
              if (showBadges && height >= 50 && width >= 70)
                Positioned(
                  left: showSourceBorder ? 8 : 4,
                  bottom: 4,
                  child: _buildPaymentStatusIndicator(),
                ),

              // ENHANCED: Left resize handle (check-in date)
              if (isResizable && width >= 60 && !isMultiSelectMode)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onHorizontalDragStart: onResizeStartLeft,
                    onHorizontalDragUpdate: onResizeUpdateLeft,
                    onHorizontalDragEnd: onResizeEndLeft,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeLeft,
                      child: Container(
                        width: 8,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: AppColors.primary.withAlpha((0.6 * 255).toInt()),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 2,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ENHANCED: Right resize handle (check-out date)
              if (isResizable && width >= 60 && !isMultiSelectMode)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onHorizontalDragStart: onResizeStartRight,
                    onHorizontalDragUpdate: onResizeUpdateRight,
                    onHorizontalDragEnd: onResizeEndRight,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeRight,
                      child: Container(
                        width: 8,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border(
                            right: BorderSide(
                              color: AppColors.primary.withAlpha((0.6 * 255).toInt()),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 2,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
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
                            : Colors.white.withAlpha((0.9 * 255).toInt()),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey.shade400,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.2 * 255).toInt()),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
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
            ],
          ),
        ),
      ),  // Close Container
    ),  // Close GestureDetector
    );  // Close Semantics

    // Wrap in Draggable if enabled (but not in multi-select mode)
    if (isDraggable && !isMultiSelectMode) {
      return LongPressDraggable<BookingModel>(
        data: booking,
        onDragStarted: onLongPress, // Call onLongPress when drag starts (optional)
        feedback: EnhancedBookingDragFeedback(
          booking: booking,
          width: width,
          height: height,
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
    final isCrossMonth = booking.checkIn.month != booking.checkOut.month ||
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
        color = AppColors.authSecondary;
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
      case BookingStatus.checkedIn:
        return 'Checked In';
      case BookingStatus.checkedOut:
        return 'Checked Out';
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

  /// ENHANCED: Get source border color for visual distinction
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

  /// ENHANCED: Build guest count indicator with dots
  Widget _buildGuestCountIndicator() {
    final guestCount = booking.guestCount;
    if (guestCount <= 0) return const SizedBox.shrink();

    // Show up to 4 dots, then add number for 5+
    final dotsToShow = guestCount > 4 ? 4 : guestCount;

    return Tooltip(
      message: '$guestCount ${guestCount == 1 ? 'gost' : 'gostiju'}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.95 * 255).toInt()),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.15 * 255).toInt()),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dots
            ...List.generate(dotsToShow, (index) {
              return Padding(
                padding: EdgeInsets.only(right: index < dotsToShow - 1 ? 2 : 0),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _getGuestCountColor(guestCount),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
            // Add number if more than 4 guests
            if (guestCount > 4) ...[
              const SizedBox(width: 2),
              Text(
                '$guestCount',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: _getGuestCountColor(guestCount),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get color based on guest count (intensity increases with more guests)
  Color _getGuestCountColor(int guestCount) {
    if (guestCount >= 6) return AppColors.error; // Red for large groups
    if (guestCount >= 4) return AppColors.warning; // Orange for medium groups
    if (guestCount >= 2) return AppColors.info; // Blue for couples
    return AppColors.success; // Green for solo travelers
  }

  /// ENHANCED: Build payment status indicator
  Widget _buildPaymentStatusIndicator() {
    final isPaid = booking.isFullyPaid;
    final paymentPercentage = booking.paymentPercentage;

    IconData icon;
    Color color;
    String tooltip;

    if (isPaid) {
      icon = Icons.check_circle;
      color = AppColors.success;
      tooltip = 'Plaćeno';
    } else if (paymentPercentage > 0) {
      icon = Icons.schedule;
      color = AppColors.warning;
      tooltip = 'Djelomično plaćeno (${paymentPercentage.toStringAsFixed(0)}%)';
    } else {
      icon = Icons.payment;
      color = AppColors.error;
      tooltip = 'Nije plaćeno';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.95 * 255).toInt()),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.15 * 255).toInt()),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 10,
          color: color,
        ),
      ),
    );
  }
}

