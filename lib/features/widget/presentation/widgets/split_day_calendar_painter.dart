import 'package:flutter/material.dart';
import '../../domain/models/calendar_date_status.dart';
import '../l10n/widget_translations.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// Custom painter for calendar cells with diagonal split for check-in/check-out days
/// This creates the "half-booked" visual effect like in BedBooking
class SplitDayCalendarPainter extends CustomPainter {
  final DateStatus status;
  final Color borderColor;
  final String? priceText; // Price to display in cell (e.g., "€50")
  final WidgetColorScheme colors;
  final bool isInRange; // Whether this date is in a selected range
  final bool isPendingBooking; // Whether this date is from a pending booking (diagonal pattern)
  // For partialBoth (turnover day) - track which half is pending
  final bool isCheckOutPending; // Is the checkout half (top-left triangle) pending?
  final bool isCheckInPending; // Is the checkin half (bottom-right triangle) pending?

  SplitDayCalendarPainter({
    required this.status,
    required this.borderColor,
    this.priceText,
    required this.colors,
    this.isInRange = false,
    this.isPendingBooking = false,
    this.isCheckOutPending = false,
    this.isCheckInPending = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    switch (status) {
      case DateStatus.available:
        // Solid available color
        paint.color = status.getColor(colors);
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;

      case DateStatus.booked:
        // Solid booked color (or pending yellow if isPendingBooking)
        paint.color = isPendingBooking ? colors.statusPendingBackground : status.getColor(colors);
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        // Draw diagonal pattern for pending bookings
        if (isPendingBooking) {
          _drawDiagonalPattern(canvas, size, DateStatus.pending.getPatternLineColor(colors));
        }
        break;

      case DateStatus.pending:
        // Pending uses RED background (same as booked) with diagonal pattern
        // This visually indicates "blocks dates" while distinguishing from confirmed bookings
        paint.color = status.getColor(colors);
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

        // Draw diagonal line pattern on top
        _drawDiagonalPattern(canvas, size, status.getPatternLineColor(colors));
        break;

      case DateStatus.blocked:
        // Solid blocked color
        paint.color = status.getColor(colors);
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;

      case DateStatus.disabled:
        // Solid disabled color (past dates)
        paint.color = status.getColor(colors);
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;

      case DateStatus.pastReservation:
        // Past reservation - red with reduced opacity (50%)
        paint.color = status.getColor(colors);
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;

      case DateStatus.partialCheckIn:
        // Check-in day: Top-left triangle is available (green), bottom-right is booked (pink/pending)
        // This means: previous guest checks out, new guest checks in

        // Draw bottom-right triangle (booked - pink, or pending - red with pattern)
        paint.color = isPendingBooking
            ? colors.statusPendingBackground
            : status.getDiagonalColor(colors); // Pink or pending red
        final Path bookedPathCI = Path()
          ..moveTo(0, size.height) // Bottom-left
          ..lineTo(size.width, size.height) // Bottom-right
          ..lineTo(size.width, 0) // Top-right
          ..close();
        canvas.drawPath(bookedPathCI, paint);

        // Draw top-left triangle (available - green)
        paint.color = status.getColor(colors); // Green
        final Path availablePathCI = Path()
          ..moveTo(0, 0) // Top-left
          ..lineTo(size.width, 0) // Top-right
          ..lineTo(0, size.height) // Bottom-left
          ..close();
        canvas.drawPath(availablePathCI, paint);

        // Draw diagonal pattern for pending bookings (only on booked half)
        if (isPendingBooking) {
          _drawDiagonalPatternClipped(canvas, size, DateStatus.pending.getPatternLineColor(colors), isCheckIn: true);
        }
        break;

      case DateStatus.partialCheckOut:
        // Check-out day: Top-left triangle is booked (pink/pending), bottom-right is available (green)
        // This means: current guest checks out, becomes available

        // Draw top-left triangle (booked - pink, or pending - red with pattern)
        paint.color = isPendingBooking
            ? colors.statusPendingBackground
            : status.getDiagonalColor(colors); // Pink or pending red
        final Path bookedPathCO = Path()
          ..moveTo(0, 0) // Top-left
          ..lineTo(size.width, 0) // Top-right
          ..lineTo(0, size.height) // Bottom-left
          ..close();
        canvas.drawPath(bookedPathCO, paint);

        // Draw bottom-right triangle (available - green)
        paint.color = status.getColor(colors); // Green
        final Path availablePathCO = Path()
          ..moveTo(0, size.height) // Bottom-left
          ..lineTo(size.width, size.height) // Bottom-right
          ..lineTo(size.width, 0) // Top-right
          ..close();
        canvas.drawPath(availablePathCO, paint);

        // Draw diagonal pattern for pending bookings (only on booked half)
        if (isPendingBooking) {
          _drawDiagonalPatternClipped(canvas, size, DateStatus.pending.getPatternLineColor(colors), isCheckIn: false);
        }
        break;

      case DateStatus.partialBoth:
        // Turnover day: Both check-out and check-in on same day
        // Top-left triangle = checkout (previous booking ends)
        // Bottom-right triangle = checkin (new booking starts)

        // Draw top-left triangle (checkout half)
        paint.color = isCheckOutPending
            ? colors
                  .statusPendingBackground // Yellow for pending checkout
            : colors.statusBookedBackground; // Red for confirmed checkout
        final Path checkoutPath = Path()
          ..moveTo(0, 0) // Top-left
          ..lineTo(size.width, 0) // Top-right
          ..lineTo(0, size.height) // Bottom-left
          ..close();
        canvas.drawPath(checkoutPath, paint);

        // Draw bottom-right triangle (checkin half)
        paint.color = isCheckInPending
            ? colors
                  .statusPendingBackground // Yellow for pending checkin
            : colors.statusBookedBackground; // Red for confirmed checkin
        final Path checkinPath = Path()
          ..moveTo(0, size.height) // Bottom-left
          ..lineTo(size.width, size.height) // Bottom-right
          ..lineTo(size.width, 0) // Top-right
          ..close();
        canvas.drawPath(checkinPath, paint);

        // Draw diagonal pattern for pending checkout (top-left triangle)
        if (isCheckOutPending) {
          _drawDiagonalPatternClipped(canvas, size, DateStatus.pending.getPatternLineColor(colors), isCheckIn: false);
        }

        // Draw diagonal pattern for pending checkin (bottom-right triangle)
        if (isCheckInPending) {
          _drawDiagonalPatternClipped(canvas, size, DateStatus.pending.getPatternLineColor(colors), isCheckIn: true);
        }
        break;
    }

    // Draw range overlay with reduced opacity if date is in selected range
    if (isInRange) {
      final overlayPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = colors.buttonPrimary.withValues(alpha: 0.2);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);
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

  /// Draw diagonal line pattern for pending status
  /// Creates thin diagonal lines from top-left to bottom-right
  void _drawDiagonalPattern(Canvas canvas, Size size, Color lineColor) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0; // Increased from 1.5 for better visibility

    // Spacing between diagonal lines
    const double spacing = 6.0;

    // Draw diagonal lines from top-left to bottom-right
    // Start from negative to cover the entire cell
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  /// Draw diagonal line pattern clipped to only the booked half of split day
  /// isCheckIn: true = bottom-right triangle, false = top-left triangle
  void _drawDiagonalPatternClipped(Canvas canvas, Size size, Color lineColor, {required bool isCheckIn}) {
    canvas.save();

    // Create clipping path for the booked triangle
    final Path clipPath = Path();
    if (isCheckIn) {
      // Check-in day: clip to bottom-right triangle
      clipPath
        ..moveTo(0, size.height) // Bottom-left
        ..lineTo(size.width, size.height) // Bottom-right
        ..lineTo(size.width, 0) // Top-right
        ..close();
    } else {
      // Check-out day: clip to top-left triangle
      clipPath
        ..moveTo(0, 0) // Top-left
        ..lineTo(size.width, 0) // Top-right
        ..lineTo(0, size.height) // Bottom-left
        ..close();
    }

    canvas.clipPath(clipPath);

    // Draw diagonal pattern (will be clipped to triangle)
    _drawDiagonalPattern(canvas, size, lineColor);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SplitDayCalendarPainter oldDelegate) {
    return oldDelegate.status != status ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.priceText != priceText ||
        oldDelegate.colors != colors ||
        oldDelegate.isInRange != isInRange ||
        oldDelegate.isPendingBooking != isPendingBooking ||
        oldDelegate.isCheckOutPending != isCheckOutPending ||
        oldDelegate.isCheckInPending != isCheckInPending;
  }
}

/// Widget wrapper for split day calendar cell
class SplitDayCalendarCell extends StatelessWidget {
  final DateStatus status;
  final VoidCallback? onTap;
  final double size;
  final bool isSelected;
  final WidgetColorScheme colors;
  final DateTime? date; // For semantic label
  final bool isPending; // For semantic label
  final WidgetTranslations? translations; // For localized semantic labels

  const SplitDayCalendarCell({
    super.key,
    required this.status,
    this.onTap,
    this.size = IconSizeTokens.large,
    this.isSelected = false,
    required this.colors,
    this.date,
    this.isPending = false,
    this.translations,
  });

  /// Generate semantic label for screen readers (localized)
  String _getSemanticLabel(WidgetTranslations t) {
    final statusStr = status == DateStatus.available
        ? t.semanticAvailable
        : status == DateStatus.booked
        ? t.semanticBooked
        : status == DateStatus.partialCheckIn
        ? t.semanticCheckIn
        : status == DateStatus.partialCheckOut
        ? t.semanticCheckOut
        : status == DateStatus.partialBoth
        ? t.semanticTurnover
        : status == DateStatus.blocked
        ? t.semanticBlocked
        : status == DateStatus.disabled
        ? t.semanticUnavailable
        : t.semanticPastReservation;

    final pendingStr = isPending ? ', ${t.semanticPendingApproval}' : '';

    if (date != null) {
      final dateStr = t.formatDateForSemantic(date!);
      return '$dateStr, $statusStr$pendingStr';
    }

    return '$statusStr$pendingStr';
  }

  @override
  Widget build(BuildContext context) {
    final t = translations ?? WidgetTranslations.of(context);
    return Semantics(
      label: _getSemanticLabel(t),
      button: onTap != null,
      enabled: status == DateStatus.available && onTap != null,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: isSelected ? Border.all(color: colors.borderFocus, width: BorderTokens.widthThick) : null,
          ),
          child: CustomPaint(
            painter: SplitDayCalendarPainter(
              status: status,
              borderColor: status.getBorderColor(colors),
              colors: colors,
            ),
          ),
        ),
      ),
    );
  }
}
