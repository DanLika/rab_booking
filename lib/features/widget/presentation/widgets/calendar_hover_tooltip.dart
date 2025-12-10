import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_date_status.dart';
import '../l10n/widget_translations.dart';
import '../../../../core/design_tokens/design_tokens.dart';

/// Reusable hover/tap tooltip for calendar cells
/// Shows date, price, and availability status with close button
class CalendarHoverTooltip extends ConsumerWidget {
  final DateTime date;
  final double? price;
  final DateStatus status;
  final VoidCallback? onClose;
  final WidgetColorScheme colors;
  final WidgetTranslations? translations;

  const CalendarHoverTooltip({
    super.key,
    required this.date,
    required this.price,
    required this.status,
    required this.colors,
    this.onClose,
    this.translations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = translations ?? WidgetTranslations.of(context, ref);

    // Format date: "Monday, Oct 27, 2025" (localized to widget language)
    final dateFormatter = DateFormat('EEEE, MMM d, y', t.locale.languageCode);
    final formattedDate = dateFormatter.format(date);

    // Format price: "€85 / night" (localized)
    final formattedPrice = price != null
        ? '${t.currencySymbol}${price!.toStringAsFixed(0)} / ${t.perNightShort}'
        : t.notAvailableShort;

    // Get status label (localized)
    final statusLabel = _getStatusLabel(status, t);
    final statusColor = _getStatusColor(status);

    return Material(
      elevation: 8,
      borderRadius: BorderTokens.circularSmall,
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 180),
        padding: const EdgeInsets.all(SpacingTokens.s),
        decoration: BoxDecoration(
          color: colors.backgroundPrimary,
          borderRadius: BorderTokens.circularSmall,
          border: Border.all(
            color: colors.borderStrong,
            width: BorderTokens.widthMedium,
          ),
          boxShadow: colors.shadowMedium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: SpacingTokens.l), // Spacer for alignment
                if (onClose != null)
                  InkWell(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.all(SpacingTokens.xxs),
                      decoration: BoxDecoration(
                        color: colors.backgroundTertiary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: TypographyTokens.fontSizeS,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: SpacingTokens.xxs),
            // Date
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeS,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),

            // Price
            Text(
              formattedPrice,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeXL,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),

            // Status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status dot - with pattern for pending
                _buildStatusDot(status, statusColor),
                const SizedBox(width: SpacingTokens.xxs),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeXS,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),

            // Additional info for selectable dates
            if (status == DateStatus.available ||
                status == DateStatus.partialCheckIn ||
                status == DateStatus.partialCheckOut) ...[
              const SizedBox(height: SpacingTokens.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.xs,
                  vertical: SpacingTokens.xxs,
                ),
                decoration: BoxDecoration(
                  color: colors.backgroundTertiary,
                  borderRadius: BorderTokens.circularTiny,
                ),
                child: Text(
                  t.tooltipClickToSelect,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeXS,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build status dot - with diagonal pattern for pending status
  Widget _buildStatusDot(DateStatus status, Color statusColor) {
    if (status == DateStatus.pending) {
      // Pending shows red dot with diagonal pattern
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.borderDefault, width: 0.5),
        ),
        child: ClipOval(
          child: CustomPaint(
            size: const Size(10, 10),
            painter: _TooltipPendingPatternPainter(
              backgroundColor: colors.statusPendingBackground,
              lineColor: colors.backgroundPrimary.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    // Regular solid dot for other statuses
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
    );
  }

  String _getStatusLabel(DateStatus status, WidgetTranslations t) =>
      switch (status) {
        DateStatus.available => t.available,
        DateStatus.booked => t.booked,
        DateStatus.pending => t.tooltipPending,
        DateStatus.blocked => t.semanticBlocked,
        DateStatus.partialCheckIn => t.tooltipCheckInDay,
        DateStatus.partialCheckOut => t.tooltipCheckOutDay,
        DateStatus.partialBoth => t.tooltipTurnoverDay,
        DateStatus.disabled => t.tooltipPastDate,
        DateStatus.pastReservation => t.tooltipPastReservation,
      };

  Color _getStatusColor(DateStatus status) => switch (status) {
    DateStatus.available => colors.statusAvailableBorder,
    DateStatus.booked => colors.statusBookedBorder,
    DateStatus.pending => colors.statusPendingBorder,
    DateStatus.blocked =>
      colors.textPrimary, // Changed from textSecondary for better visibility
    DateStatus.partialCheckIn ||
    DateStatus.partialCheckOut => colors.statusPendingBorder,
    DateStatus.partialBoth =>
      colors.statusBookedBorder, // Turnover day - fully booked
    DateStatus.disabled =>
      colors.textPrimary, // Changed from textSecondary for better visibility
    DateStatus.pastReservation =>
      colors.textPrimary, // Theme-aware: black for light, white for dark
  };
}

/// Custom painter for pending pattern in tooltip status dot
class _TooltipPendingPatternPainter extends CustomPainter {
  final Color backgroundColor;
  final Color lineColor;

  _TooltipPendingPatternPainter({
    required this.backgroundColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background with red
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw diagonal lines
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 3.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TooltipPendingPatternPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.lineColor != lineColor;
  }
}
