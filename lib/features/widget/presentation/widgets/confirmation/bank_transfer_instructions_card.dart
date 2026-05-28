import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/design/tokens.dart';
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
      margin: const EdgeInsets.only(bottom: BBSpace.md),
      padding: const EdgeInsets.all(BBSpace.sm),
      decoration: BoxDecoration(
        // Dark mode: pure black background matching parent
        color: isDark ? Colors.black : colors.backgroundSecondary,
        borderRadius: const BorderRadius.all(
          Radius.circular(BBRadiusBridges.medium),
        ),
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
              const SizedBox(width: BBSpace.xs),
              Text(
                tr.bankTransferInstructions,
                style: TextStyle(
                  fontSize: BBTypeBridges.fontSizeL,
                  fontWeight: BBTypeBridges.weightBold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpace.sm),
          // Bug #2 Fix: Add null checks to prevent crash when bankName is null
          if (bankConfig.bankName != null) ...[
            _BankTransferDetailRow(
              label: tr.bankName,
              value: bankConfig.bankName!,
              colors: colors,
              tr: tr,
            ),
            const SizedBox(height: BBSpace.xs),
          ],
          // Bug #2 Fix: Add null checks to prevent crash when accountHolder is null
          if (bankConfig.accountHolder != null) ...[
            _BankTransferDetailRow(
              label: tr.accountHolder,
              value: bankConfig.accountHolder!,
              colors: colors,
              tr: tr,
            ),
            const SizedBox(height: BBSpace.xs),
          ],
          // Bug #3 Fix: Use tr.labelIban instead of hardcoded 'IBAN'
          if (bankConfig.iban != null)
            _BankTransferDetailRow(
              label: tr.labelIban,
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
          // Bug #3 Fix: Use tr.labelSwiftBic instead of hardcoded 'SWIFT/BIC'
          if (bankConfig.swift != null) ...[
            const SizedBox(height: BBSpace.xs),
            _BankTransferDetailRow(
              label: tr.labelSwiftBic,
              value: bankConfig.swift!,
              colors: colors,
              copyable: true,
              tr: tr,
            ),
          ],
          const SizedBox(height: BBSpace.xs),
          _BankTransferDetailRow(
            label: tr.reference,
            value: bookingReference,
            colors: colors,
            copyable: true,
            highlight: true,
            tr: tr,
          ),
          const SizedBox(height: BBSpace.sm),
          Container(
            padding: const EdgeInsets.all(BBSpace.xs),
            decoration: BoxDecoration(
              color: colors.backgroundTertiary,
              borderRadius: BBRadius.xsAll,
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: colors.textSecondary),
                const SizedBox(width: BBSpace.xxs),
                Expanded(
                  child: Text(
                    tr.bankTransferNote,
                    style: TextStyle(
                      fontSize: BBTypeBridges.fontSizeS,
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
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (context.mounted) {
        SnackBarHelper.showSuccess(
          context: context,
          message: tr.labelCopied(label),
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      // Clipboard API can fail on some browsers (e.g., Safari in iframe)
      // Silently fail - user can still see the value on screen
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
              fontSize: BBTypeBridges.fontSizeS,
              fontWeight: BBTypeBridges.weightSemiBold,
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: BBSpace.xs),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: highlight
                      ? const EdgeInsets.symmetric(
                          horizontal: BBSpace.xxs,
                          vertical: BBSpaceBridges.xxs2,
                        )
                      : null,
                  decoration: highlight
                      ? BoxDecoration(
                          color: colors.backgroundTertiary,
                          borderRadius: BBRadius.xsAll,
                          border: Border.all(color: colors.borderDefault),
                        )
                      : null,
                  child: SelectableText(
                    value,
                    style: TextStyle(
                      fontSize: BBTypeBridges.fontSizeS,
                      fontWeight: highlight
                          ? BBTypeBridges.weightBold
                          : BBTypeBridges.weightMedium,
                      color: colors.textPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              if (copyable) ...[
                const SizedBox(width: BBSpace.xxs),
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
