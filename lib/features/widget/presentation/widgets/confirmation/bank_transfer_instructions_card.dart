import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../domain/models/settings/payment/bank_transfer_config.dart';
import '../../../../../../shared/utils/ui/snackbar_helper.dart';
import '../../l10n/widget_translations.dart';

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
class BankTransferInstructionsCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = WidgetTranslations.of(context, ref);
    // Detect dark mode for better contrast
    final isDark = colors.backgroundPrimary.computeLuminance() < 0.5;

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.l),
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: isDark ? colors.backgroundTertiary : colors.backgroundSecondary,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(
          color: isDark ? colors.borderMedium : colors.borderDefault,
          width: isDark ? 1.5 : 2,
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
                tr.bankTransferInstructions,
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
            label: tr.bankName,
            value: bankConfig.bankName!,
            colors: colors,
            tr: tr,
          ),
          const SizedBox(height: SpacingTokens.s),
          _BankTransferDetailRow(
            label: tr.accountHolder,
            value: bankConfig.accountHolder!,
            colors: colors,
            tr: tr,
          ),
          const SizedBox(height: SpacingTokens.s),
          if (bankConfig.iban != null)
            _BankTransferDetailRow(
              label: 'IBAN',
              value: bankConfig.iban!,
              colors: colors,
              copyable: true,
              tr: tr,
            )
          else if (bankConfig.accountNumber != null)
            _BankTransferDetailRow(
              label: tr.accountNumber,
              value: bankConfig.accountNumber!,
              colors: colors,
              copyable: true,
              tr: tr,
            ),
          if (bankConfig.swift != null) ...[
            const SizedBox(height: SpacingTokens.s),
            _BankTransferDetailRow(
              label: 'SWIFT/BIC',
              value: bankConfig.swift!,
              colors: colors,
              copyable: true,
              tr: tr,
            ),
          ],
          const SizedBox(height: SpacingTokens.s),
          _BankTransferDetailRow(
            label: tr.reference,
            value: bookingReference,
            colors: colors,
            copyable: true,
            highlight: true,
            tr: tr,
          ),
          const SizedBox(height: SpacingTokens.m),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s),
            decoration: BoxDecoration(
              color: colors.backgroundTertiary,
              borderRadius: BorderTokens.circularSmall,
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: colors.textSecondary),
                const SizedBox(width: SpacingTokens.xs),
                Expanded(
                  child: Text(
                    tr.bankTransferNote,
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
  final WidgetTranslations tr;

  const _BankTransferDetailRow({
    required this.label,
    required this.value,
    required this.colors,
    required this.tr,
    this.copyable = false,
    this.highlight = false,
  });

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      SnackBarHelper.showSuccess(
        context: context,
        message: tr.labelCopied(label),
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
                          color: colors.backgroundTertiary,
                          borderRadius: BorderTokens.circularSmall,
                          border: Border.all(color: colors.borderDefault),
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
                  icon: Icon(Icons.copy, size: 16, color: colors.textSecondary),
                  onPressed: () => _copyToClipboard(context),
                  tooltip: tr.copyLabel(label),
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
