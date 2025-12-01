import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderTokens.circularLarge,
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Information',
              style: GoogleFonts.inter(
                fontSize: TypographyTokens.fontSizeM,
                fontWeight: TypographyTokens.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: SpacingTokens.m),
            _buildPaymentRow('Total', totalPrice, bold: true),
            const SizedBox(height: SpacingTokens.xs),
            _buildPaymentRow('Deposit', depositAmount),
            const SizedBox(height: SpacingTokens.xs),
            _buildPaymentRow('Paid', paidAmount, color: colors.success),
            const SizedBox(height: SpacingTokens.xs),
            _buildPaymentRow(
              'Remaining',
              remainingAmount,
              color: remainingAmount > 0 ? colors.error : colors.success,
            ),
            const SizedBox(height: SpacingTokens.s),
            Divider(color: colors.borderDefault),
            const SizedBox(height: SpacingTokens.s),
            _buildStatusRow(),
            const SizedBox(height: SpacingTokens.xs),
            _buildMethodRow(),
            if (paymentDeadline != null) ...[
              const SizedBox(height: SpacingTokens.xs),
              _buildDeadlineRow(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(
    String label,
    double amount, {
    bool bold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: bold ? TypographyTokens.fontSizeM : TypographyTokens.fontSizeS,
            fontWeight: bold ? TypographyTokens.bold : TypographyTokens.regular,
            color: color ?? colors.textSecondary,
          ),
        ),
        Text(
          '€${amount.toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontSize: bold ? TypographyTokens.fontSizeL : TypographyTokens.fontSizeM,
            fontWeight: bold ? TypographyTokens.bold : TypographyTokens.semiBold,
            color: color ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Payment Status',
          style: GoogleFonts.inter(
            fontSize: TypographyTokens.fontSizeS,
            color: colors.textSecondary,
          ),
        ),
        _buildPaymentStatusChip(),
      ],
    );
  }

  Widget _buildMethodRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Payment Method',
          style: GoogleFonts.inter(
            fontSize: TypographyTokens.fontSizeS,
            color: colors.textSecondary,
          ),
        ),
        Text(
          _formatPaymentMethod(),
          style: GoogleFonts.inter(
            fontSize: TypographyTokens.fontSizeS,
            fontWeight: TypographyTokens.medium,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Payment Deadline',
          style: GoogleFonts.inter(
            fontSize: TypographyTokens.fontSizeS,
            color: colors.textSecondary,
          ),
        ),
        Text(
          DateFormat('MMM d, yyyy').format(DateTime.parse(paymentDeadline!)),
          style: GoogleFonts.inter(
            fontSize: TypographyTokens.fontSizeS,
            fontWeight: TypographyTokens.semiBold,
            color: colors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusChip() {
    Color statusColor;
    String statusText;

    switch (paymentStatus.toLowerCase()) {
      case 'paid':
      case 'completed':
        statusColor = colors.success;
        statusText = 'Paid';
        break;
      case 'pending':
        statusColor = colors.warning;
        statusText = 'Pending';
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
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.s,
        vertical: SpacingTokens.xxs,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderTokens.circularRounded,
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusText,
        style: GoogleFonts.inter(
          fontSize: TypographyTokens.fontSizeXS,
          fontWeight: TypographyTokens.semiBold,
          color: statusColor,
        ),
      ),
    );
  }

  String _formatPaymentMethod() {
    switch (paymentMethod.toLowerCase()) {
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'stripe':
        return 'Credit Card (Stripe)';
      case 'cash':
        return 'Cash';
      default:
        return paymentMethod;
    }
  }
}
