import 'package:flutter/material.dart';
import '../../../../../../../../shared/models/booking_model.dart';
import '../../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../../l10n/app_localizations.dart';

/// Payment information section for booking card
///
/// Displays total price, paid amount, remaining balance,
/// payment progress bar, and payment status text
/// with responsive layout (vertical on narrow, horizontal on wide)
class BookingCardPaymentInfo extends StatelessWidget {
  final BookingModel booking;
  final bool isMobile;

  const BookingCardPaymentInfo({
    super.key,
    required this.booking,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment amounts - responsive layout
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 400;

            if (isNarrow) {
              // Vertical layout for very narrow screens
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PaymentInfoColumn(
                    label: l10n.ownerBookingCardTotal,
                    value: booking.formattedTotalPrice,
                    valueStyle: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PaymentInfoColumn(
                          label: l10n.ownerBookingCardPaid,
                          value: booking.formattedPaidAmount,
                          valueStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PaymentInfoColumn(
                          label: l10n.ownerBookingCardRemaining,
                          value: booking.formattedRemainingBalance,
                          valueStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            // Suptilnija boja - ne crvena/narančasta
                            color: booking.isFullyPaid
                                ? AppColors.success
                                : theme.colorScheme.onSurface.withAlpha(
                                    (0.7 * 255).toInt(),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            // Horizontal 3-column layout for wider screens
            return Row(
              children: [
                Expanded(
                  child: _PaymentInfoColumn(
                    label: l10n.ownerBookingCardTotal,
                    value: booking.formattedTotalPrice,
                    valueStyle: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: _PaymentInfoColumn(
                    label: l10n.ownerBookingCardPaid,
                    value: booking.formattedPaidAmount,
                    valueStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: _PaymentInfoColumn(
                    label: l10n.ownerBookingCardRemaining,
                    value: booking.formattedRemainingBalance,
                    valueStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      // Suptilnija boja - ne crvena/narančasta
                      color: booking.isFullyPaid
                          ? AppColors.success
                          : theme.colorScheme.onSurface.withAlpha(
                              (0.7 * 255).toInt(),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Payment status indicator
        SizedBox(height: isMobile ? 8 : 12),
        LinearProgressIndicator(
          value: booking.paymentPercentage / 100,
          backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(
            (0.3 * 255).toInt(),
          ),
          valueColor: AlwaysStoppedAnimation<Color>(
            booking.isFullyPaid ? AppColors.success : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          booking.isFullyPaid
              ? l10n.ownerBookingCardFullyPaid
              : l10n.ownerBookingCardPercentPaid(
                  booking.paymentPercentage.toStringAsFixed(0),
                ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Helper widget for payment info column
class _PaymentInfoColumn extends StatelessWidget {
  const _PaymentInfoColumn({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(value, style: valueStyle ?? theme.textTheme.titleMedium),
      ],
    );
  }
}
