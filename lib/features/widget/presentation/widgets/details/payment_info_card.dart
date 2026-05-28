import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/design/tokens.dart';
import '../../../../../core/utils/date_time_parser.dart';
import '../../l10n/widget_translations.dart';
import '../../../domain/constants/widget_constants.dart';

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
class PaymentInfoCard extends ConsumerWidget {
  /// Total booking price
  final double totalPrice;

  /// Nightly accommodation price (optional, for breakdown)
  final double? roomPrice;

  /// Extra guest fees (optional, for breakdown)
  final double? extraGuestFees;

  /// Pet fees (optional, for breakdown)
  final double? petFees;

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
    this.roomPrice,
    this.extraGuestFees,
    this.petFees,
    required this.depositAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    this.paymentDeadline,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = WidgetTranslations.of(context, ref);
    // Detect dark mode for better contrast
    final isDark = colors.backgroundPrimary.computeLuminance() < 0.5;
    // Dark mode: pure black background matching parent, with visible border
    final cardBackground = isDark ? Colors.black : colors.backgroundSecondary;
    final cardBorder = isDark ? colors.borderMedium : colors.borderDefault;

    return Container(
      padding: const EdgeInsets.all(BBSpace.sm),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: const BorderRadius.all(
          Radius.circular(BBRadiusBridges.medium),
        ),
        border: Border.all(color: cardBorder, width: isDark ? 1.5 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.paymentInformation,
            style: TextStyle(
              fontSize: BBTypeBridges.fontSizeL,
              fontWeight: BBTypeBridges.weightBold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: BBSpace.sm),
          _buildPaymentRow(tr.total, totalPrice, bold: true),
          if (roomPrice != null && roomPrice! > 0) ...[
            const SizedBox(height: BBSpace.xxs),
            _buildPaymentRow(tr.room, roomPrice!),
          ],
          if (extraGuestFees != null && extraGuestFees! > 0) ...[
            const SizedBox(height: BBSpace.xxs),
            _buildPaymentRow(tr.extraGuestFees, extraGuestFees!),
          ],
          if (petFees != null && petFees! > 0) ...[
            const SizedBox(height: BBSpace.xxs),
            _buildPaymentRow(tr.petFees, petFees!),
          ],
          const SizedBox(height: BBSpace.xxs),
          _buildPaymentRow(tr.deposit, depositAmount),
          const SizedBox(height: BBSpace.xxs),
          _buildPaymentRow(tr.paid, paidAmount, color: colors.success),
          const SizedBox(height: BBSpace.xxs),
          _buildPaymentRow(
            tr.remaining,
            remainingAmount,
            color: remainingAmount.abs() > WidgetConstants.priceTolerance
                ? colors.error
                : colors.success,
          ),
          const SizedBox(height: BBSpace.xs),
          Divider(color: colors.borderDefault),
          const SizedBox(height: BBSpace.xs),
          _buildStatusRow(tr),
          const SizedBox(height: BBSpace.xxs),
          _buildMethodRow(tr),
          if (paymentDeadline != null) ...[
            const SizedBox(height: BBSpace.xxs),
            _buildDeadlineRow(tr),
          ],
        ],
      ),
    );
  }

  /// Format amount with fallback for non-finite values
  /// Bug #72 Fix: Handle NaN and Infinity values gracefully
  String _formatAmount(double amount) {
    if (!amount.isFinite) {
      return '€0.00'; // Fallback za NaN/Infinity
    }
    return '€${amount.toStringAsFixed(2)}';
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
          style: TextStyle(
            fontSize: bold ? BBTypeBridges.fontSizeM : BBTypeBridges.fontSizeS,
            fontWeight: bold
                ? BBTypeBridges.weightBold
                : BBTypeBridges.weightRegular,
            color: color ?? colors.textSecondary,
          ),
        ),
        Text(
          _formatAmount(amount),
          style: TextStyle(
            fontSize: bold ? BBTypeBridges.fontSizeL : BBTypeBridges.fontSizeM,
            fontWeight: bold
                ? BBTypeBridges.weightBold
                : BBTypeBridges.weightSemiBold,
            color: color ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(WidgetTranslations tr) {
    // Hide row when payment is not required - cleaner UI for guests
    if (paymentStatus.toLowerCase() == 'not_required') {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr.paymentStatusLabel,
          style: TextStyle(
            fontSize: BBTypeBridges.fontSizeS,
            color: colors.textSecondary,
          ),
        ),
        _buildPaymentStatusChip(tr),
      ],
    );
  }

  Widget _buildMethodRow(WidgetTranslations tr) {
    // Hide row when no payment method selected - cleaner UI for guests
    if (paymentMethod.toLowerCase() == 'none') {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr.paymentMethodLabel,
          style: TextStyle(
            fontSize: BBTypeBridges.fontSizeS,
            color: colors.textSecondary,
          ),
        ),
        Text(
          _formatPaymentMethod(tr),
          style: TextStyle(
            fontSize: BBTypeBridges.fontSizeS,
            fontWeight: BBTypeBridges.weightMedium,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Bug #67 Fix: Format deadline with error handling
  String _formatDeadline(String? deadline, WidgetTranslations tr) {
    if (deadline == null || deadline.isEmpty) return '';

    try {
      final date = DateTimeParser.parseOrThrow(
        deadline,
        context: 'PaymentInfoCard.paymentDeadline',
      );
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      debugPrint('Error formatting deadline: $deadline, error: $e');
      // Fallback to original string if formatting fails
      return deadline;
    }
  }

  Widget _buildDeadlineRow(WidgetTranslations tr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr.paymentDeadline,
          style: TextStyle(
            fontSize: BBTypeBridges.fontSizeS,
            color: colors.textSecondary,
          ),
        ),
        Text(
          _formatDeadline(paymentDeadline, tr),
          style: TextStyle(
            fontSize: BBTypeBridges.fontSizeS,
            fontWeight: BBTypeBridges.weightSemiBold,
            color: colors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusChip(WidgetTranslations tr) {
    final (statusColor, statusText) = switch (paymentStatus.toLowerCase()) {
      'paid' || 'completed' => (colors.success, tr.paid),
      'pending' => (colors.warning, tr.statusPending),
      'failed' => (colors.error, tr.statusFailed),
      'refunded' => (colors.error, tr.statusRefunded),
      _ => (colors.textSecondary, paymentStatus),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpace.xs,
        vertical: BBSpaceBridges.xxs2,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BBRadius.smAll,
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: BBTypeBridges.fontSizeXS,
          fontWeight: BBTypeBridges.weightSemiBold,
          color: statusColor,
        ),
      ),
    );
  }

  String _formatPaymentMethod(WidgetTranslations tr) =>
      switch (paymentMethod.toLowerCase()) {
        'bank_transfer' => tr.bankTransfer,
        'stripe' => tr.creditCard,
        'cash' => tr.cash,
        _ => paymentMethod,
      };
}
