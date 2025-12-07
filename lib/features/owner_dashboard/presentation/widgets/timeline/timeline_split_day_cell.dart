import 'package:flutter/material.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../l10n/app_localizations.dart';

/// Timeline split day cell widget
///
/// Displays CheckOut (top triangle) and CheckIn (bottom triangle) when they occur on the same day.
/// Uses diagonal split with CustomPainter for clean visual separation.
class TimelineSplitDayCell extends StatelessWidget {
  /// The booking that is checking out (top triangle)
  final BookingModel checkOutBooking;

  /// The booking that is checking in (bottom triangle)
  final BookingModel checkInBooking;

  /// Width of the cell (one day width)
  final double width;

  /// Height of the unit row
  final double height;

  /// Callback when CheckOut booking is tapped
  final VoidCallback? onCheckOutTap;

  /// Callback when CheckIn booking is tapped
  final VoidCallback? onCheckInTap;

  const TimelineSplitDayCell({
    super.key,
    required this.checkOutBooking,
    required this.checkInBooking,
    required this.width,
    required this.height,
    this.onCheckOutTap,
    this.onCheckInTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cellHeight = height - 16; // Minus padding

    return SizedBox(
      width: width,
      height: cellHeight,
      child: Stack(
        children: [
          // Background with diagonal split
          CustomPaint(
            painter: SplitDayCellPainter(
              checkOutColor: checkOutBooking.status.color,
              checkInColor: checkInBooking.status.color,
            ),
            size: Size(width, cellHeight),
          ),

          // Top triangle - CheckOut (clickable)
          Positioned.fill(
            child: ClipPath(
              clipper: TopTriangleClipper(),
              child: GestureDetector(
                onTap: onCheckOutTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  alignment: Alignment.topLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          checkOutBooking.guestName ?? l10n.ownerCalendarDefaultGuest,
                          style: TextStyle(
                            color: _getContrastTextColor(checkOutBooking.status.color),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.logout,
                        size: 10,
                        color: _getContrastTextColor(checkOutBooking.status.color).withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom triangle - CheckIn (clickable)
          Positioned.fill(
            child: ClipPath(
              clipper: BottomTriangleClipper(),
              child: GestureDetector(
                onTap: onCheckInTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.only(right: 8, bottom: 4),
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.login,
                        size: 10,
                        color: _getContrastTextColor(checkInBooking.status.color).withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          checkInBooking.guestName ?? l10n.ownerCalendarDefaultGuest,
                          style: TextStyle(
                            color: _getContrastTextColor(checkInBooking.status.color),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get contrasting text color based on background luminance
  static Color _getContrastTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? const Color(0xFF1A1A1A) : Colors.white;
  }
}

/// Custom painter for diagonal split cell
/// Matches widget's split_day_calendar_painter.dart orientation:
/// - Diagonal: top-left → bottom-right
/// - Top-left triangle = checkout (previous booking ends)
/// - Bottom-right triangle = checkin (new booking starts)
class SplitDayCellPainter extends CustomPainter {
  final Color checkOutColor;
  final Color checkInColor;

  SplitDayCellPainter({required this.checkOutColor, required this.checkInColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Top-left triangle (CheckOut) - matches widget orientation
    // Path: top-left → top-right → bottom-left → close
    final checkoutPath = Path()
      ..moveTo(0, 0) // Top-left
      ..lineTo(size.width, 0) // Top-right
      ..lineTo(0, size.height) // Bottom-left
      ..close();
    canvas.drawPath(
      checkoutPath,
      Paint()
        ..color = checkOutColor
        ..style = PaintingStyle.fill,
    );

    // Bottom-right triangle (CheckIn) - matches widget orientation
    // Path: bottom-left → bottom-right → top-right → close
    final checkinPath = Path()
      ..moveTo(0, size.height) // Bottom-left
      ..lineTo(size.width, size.height) // Bottom-right
      ..lineTo(size.width, 0) // Top-right
      ..close();
    canvas.drawPath(
      checkinPath,
      Paint()
        ..color = checkInColor
        ..style = PaintingStyle.fill,
    );

    // Diagonal divider line (top-left to bottom-right)
    final dividerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), dividerPaint);
  }

  @override
  bool shouldRepaint(SplitDayCellPainter oldDelegate) {
    return oldDelegate.checkOutColor != checkOutColor || oldDelegate.checkInColor != checkInColor;
  }
}

/// Clipper for top-left triangle (CheckOut area)
/// Matches widget orientation: top-left → top-right → bottom-left
class TopTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0) // Top-left
      ..lineTo(size.width, 0) // Top-right
      ..lineTo(0, size.height) // Bottom-left
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Clipper for bottom-right triangle (CheckIn area)
/// Matches widget orientation: bottom-left → bottom-right → top-right
class BottomTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, size.height) // Bottom-left
      ..lineTo(size.width, size.height) // Bottom-right
      ..lineTo(size.width, 0) // Top-right
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
