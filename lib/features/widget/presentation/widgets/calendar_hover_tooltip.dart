import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_date_status.dart';
import '../../../../core/design_tokens/design_tokens.dart';

/// Reusable hover/tap tooltip for calendar cells
/// Shows date, price, and availability status with close button
class CalendarHoverTooltip extends StatelessWidget {
  final DateTime date;
  final double? price;
  final DateStatus status;
  final Offset position;
  final VoidCallback? onClose;
  final WidgetColorScheme colors;

  const CalendarHoverTooltip({
    super.key,
    required this.date,
    required this.price,
    required this.status,
    required this.position,
    required this.colors,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Format date: "Monday, Oct 27, 2025"
    final dateFormatter = DateFormat('EEEE, MMM d, y');
    final formattedDate = dateFormatter.format(date);

    // Format price: "€85 / night"
    final formattedPrice = price != null ? '€${price!.toStringAsFixed(0)} / night' : 'N/A';

    // Get status label
    final statusLabel = _getStatusLabel(status);
    final statusColor = _getStatusColor(status);

    return Material(
        elevation: 8,
        borderRadius: BorderTokens.circularSmall,
        color: Colors.transparent,
        child: Container(
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
                          color: colors.backgroundSecondary,
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
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
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
                    color: colors.backgroundSecondary,
                    borderRadius: BorderTokens.circularTiny,
                  ),
                  child: Text(
                    'Click to select',
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

  String _getStatusLabel(DateStatus status) {
    switch (status) {
      case DateStatus.available:
        return 'Available';
      case DateStatus.booked:
        return 'Booked';
      case DateStatus.pending:
        return 'Pending';
      case DateStatus.blocked:
        return 'Blocked';
      case DateStatus.partialCheckIn:
        return 'Check-In Day';
      case DateStatus.partialCheckOut:
        return 'Check-Out Day';
      case DateStatus.disabled:
        return 'Past Date';
    }
  }

  Color _getStatusColor(DateStatus status) {
    switch (status) {
      case DateStatus.available:
        return colors.statusAvailableBorder;
      case DateStatus.booked:
        return colors.statusBookedBorder;
      case DateStatus.pending:
        return colors.statusPendingBorder;
      case DateStatus.blocked:
        return colors.textSecondary;
      case DateStatus.partialCheckIn:
      case DateStatus.partialCheckOut:
        return colors.statusPendingBorder;
      case DateStatus.disabled:
        return colors.textSecondary;
    }
  }
}
