import 'package:flutter/material.dart';
import '../../domain/models/calendar_date_status.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// Custom painter for calendar cells with diagonal split for check-in/check-out days
/// This creates the "half-booked" visual effect like in BedBooking
class SplitDayCalendarPainter extends CustomPainter {
  final DateStatus status;
  final Color borderColor;
  final String? priceText; // Price to display in cell (e.g., "€50")
  final WidgetColorScheme colors;
  final bool isInRange; // Whether this date is in a selected range

  SplitDayCalendarPainter({
    required this.status,
    required this.borderColor,
    this.priceText,
    required this.colors,
    this.isInRange = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    switch (status) {
      case DateStatus.available:
        // Solid available color
        paint.color = status.getColor(colors);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          paint,
        );
        break;

      case DateStatus.booked:
        // Solid booked color
        paint.color = status.getColor(colors);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          paint,
        );
        break;

      case DateStatus.pending:
        // Solid pending color (orange)
        paint.color = status.getColor(colors);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          paint,
        );
        break;

      case DateStatus.blocked:
        // Solid blocked color
        paint.color = status.getColor(colors);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          paint,
        );
        break;

      case DateStatus.disabled:
        // Solid disabled color (past dates)
        paint.color = status.getColor(colors);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          paint,
        );
        break;

      case DateStatus.pastReservation:
        // Past reservation - red with reduced opacity (50%)
        paint.color = status.getColor(colors);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          paint,
        );
        break;

      case DateStatus.partialCheckIn:
        // Check-in day: Top-left triangle is available (green), bottom-right is booked (pink)
        // This means: previous guest checks out, new guest checks in

        // Draw bottom-right triangle (booked - pink)
        paint.color = status.getDiagonalColor(colors); // Pink
        final Path bookedPath = Path()
          ..moveTo(0, size.height) // Bottom-left
          ..lineTo(size.width, size.height) // Bottom-right
          ..lineTo(size.width, 0) // Top-right
          ..close();
        canvas.drawPath(bookedPath, paint);

        // Draw top-left triangle (available - green)
        paint.color = status.getColor(colors); // Green
        final Path availablePath = Path()
          ..moveTo(0, 0) // Top-left
          ..lineTo(size.width, 0) // Top-right
          ..lineTo(0, size.height) // Bottom-left
          ..close();
        canvas.drawPath(availablePath, paint);

        // Diagonal line removed for cleaner visual - triangles are self-explanatory
        break;

      case DateStatus.partialCheckOut:
        // Check-out day: Top-left triangle is booked (pink), bottom-right is available (green)
        // This means: current guest checks out, becomes available

        // Draw top-left triangle (booked - pink)
        paint.color = status.getDiagonalColor(colors); // Pink
        final Path bookedPath = Path()
          ..moveTo(0, 0) // Top-left
          ..lineTo(size.width, 0) // Top-right
          ..lineTo(0, size.height) // Bottom-left
          ..close();
        canvas.drawPath(bookedPath, paint);

        // Draw bottom-right triangle (available - green)
        paint.color = status.getColor(colors); // Green
        final Path availablePath = Path()
          ..moveTo(0, size.height) // Bottom-left
          ..lineTo(size.width, size.height) // Bottom-right
          ..lineTo(size.width, 0) // Top-right
          ..close();
        canvas.drawPath(availablePath, paint);

        // Diagonal line removed for cleaner visual - triangles are self-explanatory
        break;

      case DateStatus.partialBoth:
        // Turnover day: Both check-out and check-in on same day
        // Property is fully occupied - render as solid booked
        paint.color = status.getColor(colors);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          paint,
        );
        break;
    }

    // Draw range overlay with reduced opacity if date is in selected range
    if (isInRange) {
      final overlayPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = colors.buttonPrimary.withOpacity(0.2);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        overlayPaint,
      );
    }

    // Draw price text in center of cell - prominent and readable
    if (priceText != null && priceText!.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: priceText,
          style: TextStyle(
            // Use theme-aware text color for maximum contrast and readability
            color: colors.textPrimary,
            // Responsive font sizes based on cell size - uses design token breakpoints
            fontSize: size.width > ConstraintTokens.calendarDayCellMinSize
                ? TypographyTokens.fontSizeS2
                : (size.width > ConstraintTokens.calendarDayCellMinSize * 0.75
                    ? TypographyTokens.fontSizeXS2
                    : TypographyTokens.poweredBySize),
            // Bold font weight for prominence (was w600)
            fontWeight: TypographyTokens.bold,
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
           oldDelegate.priceText != priceText ||
           oldDelegate.colors != colors ||
           oldDelegate.isInRange != isInRange;
  }
}

/// Widget wrapper for split day calendar cell
class SplitDayCalendarCell extends StatelessWidget {
  final DateStatus status;
  final VoidCallback? onTap;
  final double size;
  final bool isSelected;
  final WidgetColorScheme colors;

  const SplitDayCalendarCell({
    super.key,
    required this.status,
    this.onTap,
    this.size = IconSizeTokens.large,
    this.isSelected = false,
    required this.colors,
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
              ? Border.all(color: colors.borderFocus, width: BorderTokens.widthThick)
              : null,
        ),
        child: CustomPaint(
          painter: SplitDayCalendarPainter(
            status: status,
            borderColor: status.getBorderColor(colors),
            colors: colors,
          ),
        ),
      ),
    );
  }
}
