import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../domain/models/settings/payment/bank_transfer_config.dart';
import '../../../../../../shared/utils/ui/snackbar_helper.dart';

/// Card displaying bank transfer instructions for payment.
///
/// Shows bank details (name, account holder, IBAN/account number, SWIFT)
/// with copy functionality for each field.
///
/// Usage:
/// ```dart
/// BankTransferInstructionsCard(
///   bankConfig: widgetSettings.bankTransferConfig!,
///   bookingReference: 'ABC123',
///   colors: ColorTokens.light,
/// )
/// ```
class BankTransferInstructionsCard extends StatelessWidget {
  /// Bank transfer configuration with account details
  final BankTransferConfig bankConfig;

  /// Booking reference to include in payment
  final String bookingReference;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const BankTransferInstructionsCard({
    super.key,
    required this.bankConfig,
    required this.bookingReference,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.l),
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(
          color: colors.borderDefault,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance,
                color: colors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: SpacingTokens.s),
              Text(
                'Bank Transfer Instructions',
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeL,
                  fontWeight: TypographyTokens.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.m),
          _BankTransferDetailRow(
            label: 'Bank Name',
            value: bankConfig.bankName!,
            colors: colors,
          ),
          const SizedBox(height: SpacingTokens.s),
          _BankTransferDetailRow(
            label: 'Account Holder',
            value: bankConfig.accountHolder!,
            colors: colors,
          ),
          const SizedBox(height: SpacingTokens.s),
          if (bankConfig.iban != null)
            _BankTransferDetailRow(
              label: 'IBAN',
              value: bankConfig.iban!,
              colors: colors,
              copyable: true,
            )
          else if (bankConfig.accountNumber != null)
            _BankTransferDetailRow(
              label: 'Account Number',
              value: bankConfig.accountNumber!,
              colors: colors,
              copyable: true,
            ),
          if (bankConfig.swift != null) ...[
            const SizedBox(height: SpacingTokens.s),
            _BankTransferDetailRow(
              label: 'SWIFT/BIC',
              value: bankConfig.swift!,
              colors: colors,
              copyable: true,
            ),
          ],
          const SizedBox(height: SpacingTokens.s),
          _BankTransferDetailRow(
            label: 'Reference',
            value: bookingReference,
            colors: colors,
            copyable: true,
            highlight: true,
          ),
          const SizedBox(height: SpacingTokens.m),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s),
            decoration: BoxDecoration(
              color: colors.backgroundSecondary,
              borderRadius: BorderTokens.circularSmall,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: SpacingTokens.xs),
                Expanded(
                  child: Text(
                    'Please complete the transfer within 3 days and include the reference number.',
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeS,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal widget for displaying a single bank transfer detail row.
class _BankTransferDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final WidgetColorScheme colors;
  final bool copyable;
  final bool highlight;

  const _BankTransferDetailRow({
    required this.label,
    required this.value,
    required this.colors,
    this.copyable = false,
    this.highlight = false,
  });

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      SnackBarHelper.showSuccess(
        context: context,
        message: '$label copied to clipboard',
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeS,
              fontWeight: TypographyTokens.semiBold,
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: SpacingTokens.s),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: highlight
                      ? const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.xs,
                          vertical: SpacingTokens.xxs,
                        )
                      : null,
                  decoration: highlight
                      ? BoxDecoration(
                          color: colors.backgroundSecondary,
                          borderRadius: BorderTokens.circularSmall,
                          border: Border.all(
                            color: colors.borderDefault,
                          ),
                        )
                      : null,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeS,
                      fontWeight: highlight
                          ? TypographyTokens.bold
                          : TypographyTokens.medium,
                      color: colors.textPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              if (copyable) ...[
                const SizedBox(width: SpacingTokens.xs),
                IconButton(
                  icon: Icon(
                    Icons.copy,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  onPressed: () => _copyToClipboard(context),
                  tooltip: 'Copy $label',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
