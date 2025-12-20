import 'package:flutter/material.dart';

/// Custom painter for skewed (parallelogram) booking blocks
/// Creates BedBooking-style visual with angled left and right edges
///
/// TURNOVER DAY SUPPORT:
/// The skewOffset is calculated based on dayWidth so that on turnover days
/// (checkout + checkin same day), the diagonals meet at the center of the cell:
/// - Checkout diagonal (right edge) covers TOP-RIGHT of the cell
/// - Checkin diagonal (left edge) covers BOTTOM-LEFT of the cell
/// - Small gap (turnoverGap) between them at the center
///
/// Mathematical basis:
/// - For left edge from (skewOffset, 0) to (0, height), at y=height/2, x = skewOffset/2
/// - For diagonals to meet at x = dayWidth/2, we need skewOffset = dayWidth - gap
class SkewedBookingPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final bool hasConflict;

  /// Color for the diagonal separator lines (should match theme)
  /// Light theme: use darker color, Dark theme: use lighter color
  final Color separatorColor;

  /// The width of a single day cell - used to calculate skew for turnover alignment
  final double dayWidth;

  /// Gap between checkout and checkin diagonals on turnover day (in pixels)
  /// Set to 4px for visible but subtle turnover separation
  static const double turnoverGap = 4.0;

  /// Calculate skew offset based on day width
  /// Formula: dayWidth - turnoverGap ensures diagonals meet at center with gap
  ///
  /// At y = height/2:
  /// - Left edge (checkin) is at x = skewOffset/2 = (dayWidth - gap) / 2
  /// - Right edge (checkout) is at x = dayWidth - skewOffset/2 = dayWidth - (dayWidth - gap) / 2 = (dayWidth + gap) / 2
  /// - Gap between them = (dayWidth + gap) / 2 - (dayWidth - gap) / 2 = gap
  double get skewOffset => dayWidth - turnoverGap;

  /// Legacy static accessor for backward compatibility
  /// Use dynamic skewOffset property when possible
  static const double defaultSkewOffset = 24.0;

  SkewedBookingPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.dayWidth,
    this.borderWidth = 1.5,
    this.hasConflict = false,
    this.separatorColor = const Color(0x80000000), // Default: black 50% opacity
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Defensive check: ensure size is valid before painting
    if (!size.width.isFinite || !size.height.isFinite ||
        size.width <= 0 || size.height <= 0) {
      return; // Skip painting if size is invalid
    }

    final path = _createSkewedPath(size);

    // Draw filled background
    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw border - red (2.5px) for conflicts, normal border otherwise
    // This provides visual feedback for overbooking conflicts
    final effectiveBorderColor = hasConflict ? Colors.red : borderColor;
    final effectiveBorderWidth = hasConflict ? 2.5 : borderWidth;

    final borderPaint = Paint()
      ..color = effectiveBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = effectiveBorderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawPath(path, borderPaint);

    // Draw semi-transparent diagonal separators for turnover visibility
    // Color adapts to theme: darker on light theme, lighter on dark theme
    final separatorPaint = Paint()
      ..color = separatorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Left diagonal (check-in edge): from (skewOffset, 0) to (0, height)
    canvas.drawLine(
      Offset(skewOffset, 0),
      Offset(0, size.height),
      separatorPaint,
    );

    // Right diagonal (check-out edge): from (width, 0) to (width - skewOffset, height)
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - skewOffset, size.height),
      separatorPaint,
    );
  }

  /// Creates parallelogram path with skewed left and right edges
  ///
  /// Shape visual (slants left-to-right):
  ///       skewOffset    width
  ///            +----------+
  ///           /          /
  ///          /          /
  ///         +----------+
  ///         0      width-skewOffset
  ///
  /// TURNOVER DAY CELL BEHAVIOR:
  /// When checkout (Booking A) and checkin (Booking B) share a cell:
  ///
  ///     ┌────────────────────┐
  ///     │\\\\\\ Checkout \\\\│  ← Booking A's right diagonal (top-right area)
  ///     │ \\\\\\\\\\\\\\\\\\\│
  ///     │─ ─ ─ GAP ─ ─ ─ ─ ─ │  ← 2px diagonal gap at center
  ///     │///////////////////│
  ///     │//// Checkin //////│  ← Booking B's left diagonal (bottom-left area)
  ///     └────────────────────┘
  ///
  /// The skewOffset = dayWidth - turnoverGap ensures the diagonals meet
  /// at the center of the cell with a visible gap between them.
  Path _createSkewedPath(Size size) {
    final path = Path();

    // Start at top-left (skewed inward from left edge)
    path.moveTo(skewOffset, 0);

    // Top edge (straight) to top-right corner
    path.lineTo(size.width, 0);

    // Right edge (skewed) - goes down and left
    path.lineTo(size.width - skewOffset, size.height);

    // Bottom edge (straight) to bottom-left corner
    path.lineTo(0, size.height);

    // Left edge (skewed) - closes back to start
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant SkewedBookingPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.hasConflict != hasConflict ||
        oldDelegate.dayWidth != dayWidth ||
        oldDelegate.separatorColor != separatorColor;
  }
}

/// Custom clipper for skewed booking blocks
/// Ensures content is clipped to the parallelogram shape
///
/// TURNOVER DAY SUPPORT:
/// Uses dynamic skewOffset based on dayWidth for proper turnover display
class SkewedBookingClipper extends CustomClipper<Path> {
  /// The width of a single day cell - used to calculate skew for turnover alignment
  final double dayWidth;

  /// Gap between checkout and checkin diagonals on turnover day
  static const double turnoverGap = SkewedBookingPainter.turnoverGap;

  /// Calculate skew offset based on day width (same as painter)
  double get skewOffset => dayWidth - turnoverGap;

  SkewedBookingClipper({required this.dayWidth});

  @override
  Path getClip(Size size) {
    final path = Path();

    // Same parallelogram path as painter
    path.moveTo(skewOffset, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width - skewOffset, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant SkewedBookingClipper oldClipper) =>
      oldClipper.dayWidth != dayWidth;
}
