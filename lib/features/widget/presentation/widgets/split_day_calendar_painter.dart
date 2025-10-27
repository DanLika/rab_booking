import 'package:flutter/material.dart';
import '../../domain/models/calendar_date_status.dart';

/// Custom painter for calendar cells with diagonal split for check-in/check-out days
/// This creates the "half-booked" visual effect like in BedBooking
class SplitDayCalendarPainter extends CustomPainter {
  final DateStatus status;
  final Color borderColor;
  final String? priceText; // Price to display in cell (e.g., "€50")

  SplitDayCalendarPainter({
    required this.status,
    required this.borderColor,
    this.priceText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    switch (status) {
      case DateStatus.available:
        // Solid available color
        paint.color = status.getColor();
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          paint,
        );
        break;

      case DateStatus.booked:
        // Solid booked color
        paint.color = status.getColor();
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          paint,
        );
        break;

      case DateStatus.blocked:
        // Solid blocked color
        paint.color = status.getColor();
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          paint,
        );
        break;

      case DateStatus.partialCheckIn:
        // Check-in day: Top-left triangle is available (green), bottom-right is booked (pink)
        // This means: previous guest checks out, new guest checks in

        // Draw bottom-right triangle (booked - pink)
        paint.color = status.getDiagonalColor(); // Pink
        final Path bookedPath = Path()
          ..moveTo(0, size.height) // Bottom-left
          ..lineTo(size.width, size.height) // Bottom-right
          ..lineTo(size.width, 0) // Top-right
          ..close();
        canvas.drawPath(bookedPath, paint);

        // Draw top-left triangle (available - green)
        paint.color = status.getColor(); // Green
        final Path availablePath = Path()
          ..moveTo(0, 0) // Top-left
          ..lineTo(size.width, 0) // Top-right
          ..lineTo(0, size.height) // Bottom-left
          ..close();
        canvas.drawPath(availablePath, paint);

        // Draw diagonal line
        final diagonalPaint = Paint()
          ..color = Colors.grey.shade600
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(0, 0),
          Offset(size.width, size.height),
          diagonalPaint,
        );
        break;

      case DateStatus.partialCheckOut:
        // Check-out day: Top-left triangle is booked (pink), bottom-right is available (green)
        // This means: current guest checks out, becomes available

        // Draw top-left triangle (booked - pink)
        paint.color = status.getDiagonalColor(); // Pink
        final Path bookedPath = Path()
          ..moveTo(0, 0) // Top-left
          ..lineTo(size.width, 0) // Top-right
          ..lineTo(0, size.height) // Bottom-left
          ..close();
        canvas.drawPath(bookedPath, paint);

        // Draw bottom-right triangle (available - green)
        paint.color = status.getColor(); // Green
        final Path availablePath = Path()
          ..moveTo(0, size.height) // Bottom-left
          ..lineTo(size.width, size.height) // Bottom-right
          ..lineTo(size.width, 0) // Top-right
          ..close();
        canvas.drawPath(availablePath, paint);

        // Draw diagonal line
        final diagonalPaint = Paint()
          ..color = Colors.grey.shade600
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(0, 0),
          Offset(size.width, size.height),
          diagonalPaint,
        );
        break;
    }

    // Draw price text in center of cell
    if (priceText != null && priceText!.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: priceText,
          style: TextStyle(
            color: status == DateStatus.booked ? Colors.black54 : Colors.black87,
            fontSize: size.width > 30 ? 10 : 8,
            fontWeight: FontWeight.w600,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Center the text
      final xOffset = (size.width - textPainter.width) / 2;
      final yOffset = (size.height - textPainter.height) / 2;

      textPainter.paint(canvas, Offset(xOffset, yOffset));
    }
  }

  @override
  bool shouldRepaint(covariant SplitDayCalendarPainter oldDelegate) {
    return oldDelegate.status != status ||
           oldDelegate.borderColor != borderColor ||
           oldDelegate.priceText != priceText;
  }
}

/// Widget wrapper for split day calendar cell
class SplitDayCalendarCell extends StatelessWidget {
  final DateStatus status;
  final VoidCallback? onTap;
  final double size;
  final bool isSelected;

  const SplitDayCalendarCell({
    super.key,
    required this.status,
    this.onTap,
    this.size = 24.0,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: Colors.blue, width: 2)
              : null,
        ),
        child: CustomPaint(
          painter: SplitDayCalendarPainter(
            status: status,
            borderColor: status.getBorderColor(),
          ),
        ),
      ),
    );
  }
}
