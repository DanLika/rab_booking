import 'package:flutter/material.dart';

/// Diagonal line indicators for Check-In (left) and Check-Out (right)
/// Shows visual markers where booking starts and ends
class CheckInDiagonalIndicator extends StatelessWidget {
  final double height;
  final Color color;

  const CheckInDiagonalIndicator({
    super.key,
    required this.height,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(8, height),
      painter: _CheckInDiagonalPainter(color: color),
    );
  }
}

class CheckOutDiagonalIndicator extends StatelessWidget {
  final double height;
  final Color color;

  const CheckOutDiagonalIndicator({
    super.key,
    required this.height,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(8, height),
      painter: _CheckOutDiagonalPainter(color: color),
    );
  }
}

/// Custom painter for Check-In diagonal line (top-left to bottom)
class _CheckInDiagonalPainter extends CustomPainter {
  final Color color;

  _CheckInDiagonalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Defensive check: ensure size is valid before painting
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return; // Skip painting if size is invalid
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Draw diagonal line from top-left corner to bottom
    canvas.drawLine(
      const Offset(0, 0), // Top-left
      Offset(size.width, size.height), // Bottom-right
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for Check-Out diagonal line (top to bottom-right)
class _CheckOutDiagonalPainter extends CustomPainter {
  final Color color;

  _CheckOutDiagonalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Defensive check: ensure size is valid before painting
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return; // Skip painting if size is invalid
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Draw diagonal line from top-right corner to bottom-left
    canvas.drawLine(
      Offset(size.width, 0), // Top-right
      Offset(0, size.height), // Bottom-left
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
