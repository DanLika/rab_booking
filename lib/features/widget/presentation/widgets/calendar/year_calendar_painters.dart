import 'package:flutter/material.dart';

/// Simple painter for diagonal lines on check-in/check-out days (year calendar).
///
/// Used for partialCheckIn and partialCheckOut status in year calendar view.
/// Creates a diagonal split with optional pending pattern overlay.
class DiagonalLinePainter extends CustomPainter {
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
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = diagonalColor;

    if (isCheckIn) {
      // Check-in: diagonal from bottom-left to top-right (green to pink/pending)
      final path = Path()
        ..moveTo(0, size.height) // Bottom-left
        ..lineTo(size.width, 0) // Top-right
        ..lineTo(size.width, size.height) // Bottom-right
        ..close();
      canvas.drawPath(path, paint);

      // Draw pending pattern on booked triangle
      if (isPending && patternLineColor != null) {
        canvas.save();
        canvas.clipPath(path);
        _drawDiagonalPattern(canvas, size, patternLineColor!);
        canvas.restore();
      }
    } else {
      // Check-out: diagonal from top-left to bottom-right (pink/pending to green)
      final path = Path()
        ..moveTo(0, 0) // Top-left
        ..lineTo(size.width, size.height) // Bottom-right
        ..lineTo(0, size.height) // Bottom-left
        ..close();
      canvas.drawPath(path, paint);

      // Draw pending pattern on booked triangle
      if (isPending && patternLineColor != null) {
        canvas.save();
        canvas.clipPath(path);
        _drawDiagonalPattern(canvas, size, patternLineColor!);
        canvas.restore();
      }
    }
  }

  void _drawDiagonalPattern(Canvas canvas, Size size, Color lineColor) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double spacing = 4.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
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
/// Used for full booked days that are from pending bookings.
/// Creates diagonal stripe pattern across the entire cell.
class PendingPatternPainter extends CustomPainter {
  final Color lineColor;

  PendingPatternPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double spacing = 4.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(PendingPatternPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}

/// Painter for partialBoth (turnover day) with split colors in year calendar.
///
/// Top-left triangle = checkout (previous booking ends)
/// Bottom-right triangle = checkin (new booking starts)
/// Supports pending pattern on each triangle independently.
class PartialBothPainter extends CustomPainter {
  final Color checkoutColor; // Top-left triangle color
  final Color checkinColor; // Bottom-right triangle color
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
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw top-left triangle (checkout)
    final checkoutPath = Path()
      ..moveTo(0, 0) // Top-left
      ..lineTo(size.width, 0) // Top-right
      ..lineTo(0, size.height) // Bottom-left
      ..close();
    paint.color = checkoutColor;
    canvas.drawPath(checkoutPath, paint);

    // Draw bottom-right triangle (checkin)
    final checkinPath = Path()
      ..moveTo(0, size.height) // Bottom-left
      ..lineTo(size.width, size.height) // Bottom-right
      ..lineTo(size.width, 0) // Top-right
      ..close();
    paint.color = checkinColor;
    canvas.drawPath(checkinPath, paint);

    // Draw pending pattern on checkout triangle if pending
    if (isCheckOutPending && patternLineColor != null) {
      canvas.save();
      canvas.clipPath(checkoutPath);
      _drawDiagonalPattern(canvas, size, patternLineColor!);
      canvas.restore();
    }

    // Draw pending pattern on checkin triangle if pending
    if (isCheckInPending && patternLineColor != null) {
      canvas.save();
      canvas.clipPath(checkinPath);
      _drawDiagonalPattern(canvas, size, patternLineColor!);
      canvas.restore();
    }
  }

  void _drawDiagonalPattern(Canvas canvas, Size size, Color lineColor) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double spacing = 4.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
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
