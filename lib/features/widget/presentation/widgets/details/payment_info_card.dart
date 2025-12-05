import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/utils/date_time_parser.dart';
import '../../l10n/widget_translations.dart';

/// Card displaying payment information for a booking.
///
/// Shows total, deposit, paid, remaining amounts, payment status, and method.
///
/// Usage:
/// ```dart
/// PaymentInfoCard(
///   totalPrice: 500.00,
///   depositAmount: 100.00,
///   paidAmount: 100.00,
///   remainingAmount: 400.00,
///   paymentStatus: 'pending',
///   paymentMethod: 'bank_transfer',
///   paymentDeadline: '2024-01-10',
///   colors: ColorTokens.light,
/// )
/// ```
class PaymentInfoCard extends StatelessWidget {
  /// Total booking price
  final double totalPrice;

  /// Deposit amount
  final double depositAmount;

  /// Amount already paid
  final double paidAmount;

  /// Remaining amount to pay
  final double remainingAmount;

  /// Payment status (paid, pending, failed, refunded)
  final String paymentStatus;

  /// Payment method (bank_transfer, stripe, cash)
  final String paymentMethod;

  /// Optional payment deadline (ISO format)
  final String? paymentDeadline;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const PaymentInfoCard({
    super.key,
    required this.totalPrice,
    required this.depositAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    this.paymentDeadline,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final tr = WidgetTranslations.of(context);
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.paymentInformation,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeL,
              fontWeight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          _buildPaymentRow(tr.total, totalPrice, bold: true),
          const SizedBox(height: SpacingTokens.xs),
          _buildPaymentRow(tr.deposit, depositAmount),
          const SizedBox(height: SpacingTokens.xs),
          _buildPaymentRow(tr.paid, paidAmount, color: colors.success),
          const SizedBox(height: SpacingTokens.xs),
          _buildPaymentRow(tr.remaining, remainingAmount, color: remainingAmount > 0 ? colors.error : colors.success),
          const SizedBox(height: SpacingTokens.s),
          Divider(color: colors.borderDefault),
          const SizedBox(height: SpacingTokens.s),
          _buildStatusRow(tr),
          const SizedBox(height: SpacingTokens.xs),
          _buildMethodRow(tr),
          if (paymentDeadline != null) ...[const SizedBox(height: SpacingTokens.xs), _buildDeadlineRow(tr)],
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? TypographyTokens.fontSizeM : TypographyTokens.fontSizeS,
            fontWeight: bold ? TypographyTokens.bold : TypographyTokens.regular,
            color: color ?? colors.textSecondary,
          ),
        ),
        Text(
          '€${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: bold ? TypographyTokens.fontSizeL : TypographyTokens.fontSizeM,
            fontWeight: bold ? TypographyTokens.bold : TypographyTokens.semiBold,
            color: color ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(WidgetTranslations tr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr.paymentStatusLabel,
          style: TextStyle(fontSize: TypographyTokens.fontSizeS, color: colors.textSecondary),
        ),
        _buildPaymentStatusChip(tr),
      ],
    );
  }

  Widget _buildMethodRow(WidgetTranslations tr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr.paymentMethodLabel,
          style: TextStyle(fontSize: TypographyTokens.fontSizeS, color: colors.textSecondary),
        ),
        Text(
          _formatPaymentMethod(tr),
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeS,
            fontWeight: TypographyTokens.medium,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineRow(WidgetTranslations tr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr.paymentDeadline,
          style: TextStyle(fontSize: TypographyTokens.fontSizeS, color: colors.textSecondary),
        ),
        Text(
          DateFormat(
            'MMM d, yyyy',
          ).format(DateTimeParser.parseOrThrow(paymentDeadline, context: 'PaymentInfoCard.paymentDeadline')),
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeS,
            fontWeight: TypographyTokens.semiBold,
            color: colors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusChip(WidgetTranslations tr) {
    Color statusColor;
    String statusText;

    switch (paymentStatus.toLowerCase()) {
      case 'paid':
      case 'completed':
        statusColor = colors.success;
        statusText = tr.paid;
        break;
      case 'pending':
        statusColor = colors.warning;
        statusText = tr.statusPending;
        break;
      case 'failed':
      case 'refunded':
        statusColor = colors.error;
        statusText = paymentStatus;
        break;
      default:
        statusColor = colors.textSecondary;
        statusText = paymentStatus;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.s, vertical: SpacingTokens.xxs),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderTokens.circularRounded,
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: TypographyTokens.fontSizeXS,
          fontWeight: TypographyTokens.semiBold,
          color: statusColor,
        ),
      ),
    );
  }

  String _formatPaymentMethod(WidgetTranslations tr) {
    switch (paymentMethod.toLowerCase()) {
      case 'bank_transfer':
        return tr.bankTransfer;
      case 'stripe':
        return tr.creditCard;
      case 'cash':
        return tr.cash;
      default:
        return paymentMethod;
    }
  }
}
