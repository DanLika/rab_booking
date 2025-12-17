import 'package:flutter/material.dart';

/// Shared constants and utilities for calendar painters.
///
/// Extracted to eliminate duplication across DiagonalLinePainter,
/// PendingPatternPainter, and PartialBothPainter.
mixin DiagonalPatternMixin on CustomPainter {
  /// Spacing between diagonal pattern lines.
  static const double patternSpacing = 4.0;

  /// Stroke width for pattern lines.
  static const double patternStrokeWidth = 1.0;

  /// Draws diagonal lines from top-left to bottom-right across the canvas.
  ///
  /// Used to indicate pending status on calendar date cells.
  void drawDiagonalPattern(Canvas canvas, Size size, Color lineColor) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = patternStrokeWidth;

    for (
      double i = -size.height;
      i < size.width + size.height;
      i += patternSpacing
    ) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }
}

/// Simple painter for diagonal lines on check-in/check-out days (year calendar).
///
/// Uses [DiagonalPatternMixin] for pending pattern rendering.
/// Creates a diagonal split with optional pending pattern overlay.
class DiagonalLinePainter extends CustomPainter with DiagonalPatternMixin {
  final Color diagonalColor;
  final bool isCheckIn;
  final bool isPending;
  final Color? patternLineColor;

  DiagonalLinePainter({
    required this.diagonalColor,
    required this.isCheckIn,
    this.isPending = false,
    this.patternLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Defensive check: ensure size is valid before painting
    if (!size.width.isFinite || !size.height.isFinite || 
        size.width <= 0 || size.height <= 0) {
      return; // Skip painting if size is invalid
    }

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = diagonalColor;

    final path = isCheckIn ? _buildCheckInPath(size) : _buildCheckOutPath(size);

    canvas.drawPath(path, paint);

    // Draw pending pattern on booked triangle
    if (isPending && patternLineColor != null) {
      canvas.save();
      canvas.clipPath(path);
      drawDiagonalPattern(canvas, size, patternLineColor!);
      canvas.restore();
    }
  }

  /// Check-in: diagonal from bottom-left to top-right (green to pink/pending)
  Path _buildCheckInPath(Size size) {
    return Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
  }

  /// Check-out: diagonal from top-left to bottom-right (pink/pending to green)
  Path _buildCheckOutPath(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldRepaint(DiagonalLinePainter oldDelegate) {
    return oldDelegate.diagonalColor != diagonalColor ||
        oldDelegate.isCheckIn != isCheckIn ||
        oldDelegate.isPending != isPending ||
        oldDelegate.patternLineColor != patternLineColor;
  }
}

/// Painter for full-cell pending pattern (diagonal lines) in year calendar.
///
/// Uses [DiagonalPatternMixin] for consistent pattern rendering.
/// Creates diagonal stripe pattern across the entire cell.
class PendingPatternPainter extends CustomPainter with DiagonalPatternMixin {
  final Color lineColor;

  PendingPatternPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Bug #42 Fix: Defensive check - ensure size is valid before painting
    if (!size.width.isFinite || !size.height.isFinite ||
        size.width <= 0 || size.height <= 0) {
      return; // Skip painting if size is invalid
    }
    drawDiagonalPattern(canvas, size, lineColor);
  }

  @override
  bool shouldRepaint(PendingPatternPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}

/// Painter for partialBoth (turnover day) with split colors in year calendar.
///
/// Uses [DiagonalPatternMixin] for pending pattern rendering.
/// Top-left triangle = checkout (previous booking ends)
/// Bottom-right triangle = checkin (new booking starts)
class PartialBothPainter extends CustomPainter with DiagonalPatternMixin {
  final Color checkoutColor;
  final Color checkinColor;
  final bool isCheckOutPending;
  final bool isCheckInPending;
  final Color? patternLineColor;

  PartialBothPainter({
    required this.checkoutColor,
    required this.checkinColor,
    this.isCheckOutPending = false,
    this.isCheckInPending = false,
    this.patternLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Bug #42 Fix: Defensive check - ensure size is valid before painting
    if (!size.width.isFinite || !size.height.isFinite ||
        size.width <= 0 || size.height <= 0) {
      return; // Skip painting if size is invalid
    }

    final paint = Paint()..style = PaintingStyle.fill;

    final checkoutPath = _buildCheckoutPath(size);
    final checkinPath = _buildCheckinPath(size);

    // Draw triangles
    paint.color = checkoutColor;
    canvas.drawPath(checkoutPath, paint);

    paint.color = checkinColor;
    canvas.drawPath(checkinPath, paint);

    // Draw pending patterns
    _drawPendingPatternIfNeeded(canvas, size, checkoutPath, isCheckOutPending);
    _drawPendingPatternIfNeeded(canvas, size, checkinPath, isCheckInPending);
  }

  /// Top-left triangle (checkout - previous booking ends)
  Path _buildCheckoutPath(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
  }

  /// Bottom-right triangle (checkin - new booking starts)
  Path _buildCheckinPath(Size size) {
    return Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();
  }

  void _drawPendingPatternIfNeeded(
    Canvas canvas,
    Size size,
    Path clipPath,
    bool isPending,
  ) {
    if (!isPending || patternLineColor == null) return;

    canvas.save();
    canvas.clipPath(clipPath);
    drawDiagonalPattern(canvas, size, patternLineColor!);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PartialBothPainter oldDelegate) {
    return oldDelegate.checkoutColor != checkoutColor ||
        oldDelegate.checkinColor != checkinColor ||
        oldDelegate.isCheckOutPending != isCheckOutPending ||
        oldDelegate.isCheckInPending != isCheckInPending ||
        oldDelegate.patternLineColor != patternLineColor;
  }
}
