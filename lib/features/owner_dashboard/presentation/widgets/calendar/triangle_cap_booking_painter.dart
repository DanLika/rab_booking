import 'package:flutter/material.dart';

/// Custom painter for booking blocks with triangle caps on check-in/check-out edges
/// Creates visual indicators showing where booking starts and ends
class TriangleCapBookingPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final bool hasLeftCap;
  final bool hasRightCap;
  final double borderWidth;
  final bool hasConflict;

  static const double capWidth = 12.0;

  TriangleCapBookingPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.hasLeftCap,
    required this.hasRightCap,
    this.borderWidth = 1.5,
    this.hasConflict = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _createTrianglePath(size);

    // 1. Draw shadow
    if (!hasConflict) {
      canvas.drawShadow(
        path,
        Colors.black.withAlpha((0.1 * 255).toInt()),
        2.0,
        false,
      );
    } else {
      // Stronger shadow for conflicts
      canvas.drawShadow(
        path,
        Colors.red.withAlpha((0.3 * 255).toInt()),
        4.0,
        false,
      );
    }

    // 2. Draw filled background
    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. Draw border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawPath(path, borderPaint);
  }

  Path _createTrianglePath(Size size) {
    final path = Path();
    final radius = 4.0; // Border radius for non-triangle corners

    if (hasLeftCap) {
      // Start with triangle cap on left side
      path.moveTo(0, size.height / 2); // Middle-left point (triangle tip)
      path.lineTo(capWidth, 0); // Top of left cap
    } else {
      // Start with rounded corner top-left
      path.moveTo(radius, 0);
    }

    // Top edge
    final topRightX = hasRightCap ? size.width - capWidth : size.width - radius;
    path.lineTo(topRightX, 0);

    if (hasRightCap) {
      // Triangle cap on right side
      path.lineTo(size.width, size.height / 2); // Middle-right point (triangle tip)
      path.lineTo(size.width - capWidth, size.height); // Bottom of right cap
    } else {
      // Rounded corner top-right
      path.arcToPoint(
        Offset(size.width, radius),
        radius: Radius.circular(radius),
      );
      path.lineTo(size.width, size.height - radius);
      // Rounded corner bottom-right
      path.arcToPoint(
        Offset(size.width - radius, size.height),
        radius: Radius.circular(radius),
      );
    }

    // Bottom edge
    final bottomLeftX = hasLeftCap ? capWidth : radius;
    path.lineTo(bottomLeftX, size.height);

    if (hasLeftCap) {
      // Close back to left cap tip
      path.close();
    } else {
      // Rounded corner bottom-left
      path.arcToPoint(
        Offset(0, size.height - radius),
        radius: Radius.circular(radius),
      );
      path.lineTo(0, radius);
      // Rounded corner top-left
      path.arcToPoint(
        Offset(radius, 0),
        radius: Radius.circular(radius),
      );
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant TriangleCapBookingPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.borderColor != borderColor ||
           oldDelegate.hasLeftCap != hasLeftCap ||
           oldDelegate.hasRightCap != hasRightCap ||
           oldDelegate.borderWidth != borderWidth ||
           oldDelegate.hasConflict != hasConflict;
  }
}

/// Custom clipper for triangle cap booking blocks
/// Ensures content is clipped to the triangle shape
class TriangleCapClipper extends CustomClipper<Path> {
  final bool hasLeftCap;
  final bool hasRightCap;

  static const double capWidth = 12.0;

  TriangleCapClipper({
    required this.hasLeftCap,
    required this.hasRightCap,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = 4.0;

    if (hasLeftCap) {
      path.moveTo(0, size.height / 2);
      path.lineTo(capWidth, 0);
    } else {
      path.moveTo(radius, 0);
    }

    final topRightX = hasRightCap ? size.width - capWidth : size.width - radius;
    path.lineTo(topRightX, 0);

    if (hasRightCap) {
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - capWidth, size.height);
    } else {
      path.arcToPoint(
        Offset(size.width, radius),
        radius: Radius.circular(radius),
      );
      path.lineTo(size.width, size.height - radius);
      path.arcToPoint(
        Offset(size.width - radius, size.height),
        radius: Radius.circular(radius),
      );
    }

    final bottomLeftX = hasLeftCap ? capWidth : radius;
    path.lineTo(bottomLeftX, size.height);

    if (hasLeftCap) {
      path.close();
    } else {
      path.arcToPoint(
        Offset(0, size.height - radius),
        radius: Radius.circular(radius),
      );
      path.lineTo(0, radius);
      path.arcToPoint(
        Offset(radius, 0),
        radius: Radius.circular(radius),
      );
    }

    return path;
  }

  @override
  bool shouldReclip(covariant TriangleCapClipper oldClipper) {
    return oldClipper.hasLeftCap != hasLeftCap ||
           oldClipper.hasRightCap != hasRightCap;
  }
}
