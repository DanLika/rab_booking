import 'package:flutter/material.dart';

/// Custom painter for skewed (parallelogram) booking blocks
/// Creates BedBooking-style visual with angled left and right edges
class SkewedBookingPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final bool hasConflict;

  /// Skew offset in pixels - how much to angle the sides
  static const double skewOffset = 18.0;

  SkewedBookingPainter({
    required this.backgroundColor,
    required this.borderColor,
    this.borderWidth = 1.5,
    this.hasConflict = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _createSkewedPath(size);

    // 2. Draw filled background
    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  /// Creates parallelogram path with skewed left and right edges
  Path _createSkewedPath(Size size) {
    final path = Path();

    // Start at top-left (skewed inward)
    path.moveTo(skewOffset, 0);

    // Top edge (straight)
    path.lineTo(size.width, 0);

    // Right edge (skewed inward) - goes from top-right to bottom-right-inward
    path.lineTo(size.width - skewOffset, size.height);

    // Bottom edge (straight)
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
           oldDelegate.hasConflict != hasConflict;
  }
}

/// Custom clipper for skewed booking blocks
/// Ensures content is clipped to the parallelogram shape
class SkewedBookingClipper extends CustomClipper<Path> {
  static const double skewOffset = 18.0;

  @override
  Path getClip(Size size) {
    final path = Path();

    // Same path as painter
    path.moveTo(skewOffset, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width - skewOffset, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
