import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/minimalist_colors.dart';
import '../../../domain/models/widget_settings.dart';
import '../common/copyable_text_field.dart';
import '../../../../../../shared/utils/ui/snackbar_helper.dart';
import '../../l10n/widget_translations.dart';

/// Reusable bank details section for bank transfers
/// Displays IBAN, SWIFT, account holder, bank name with copy functionality
class BankDetailsSection extends ConsumerWidget {
  final bool isDarkMode;
  final BankTransferConfig bankConfig;

  const BankDetailsSection({
    super.key,
    required this.isDarkMode,
    required this.bankConfig,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final tr = WidgetTranslations.of(context, ref);

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.backgroundTertiary,
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors, tr),
          const SizedBox(height: SpacingTokens.m),
          if (bankConfig.accountHolder != null)
            CopyableTextField(
              label: tr.accountHolder,
              value: bankConfig.accountHolder!,
              icon: Icons.person_outline,
              isDarkMode: isDarkMode,
              onCopy: () => _copyToClipboard(
                context,
                ref,
                bankConfig.accountHolder!,
                tr.accountHolderCopied,
              ),
              translations: tr, // Bug #40 Fix: Localized tooltip
            ),
          if (bankConfig.bankName != null) ...[
            const SizedBox(height: SpacingTokens.s),
            CopyableTextField(
              label: tr.bankName,
              value: bankConfig.bankName!,
              icon: Icons.account_balance_outlined,
              isDarkMode: isDarkMode,
              onCopy: () => _copyToClipboard(
                context,
                ref,
                bankConfig.bankName!,
                tr.bankNameCopied,
              ),
              translations: tr, // Bug #40 Fix: Localized tooltip
            ),
          ],
          if (bankConfig.iban != null) ...[
            const SizedBox(height: SpacingTokens.s),
            CopyableTextField(
              label: tr
                  .labelIban, // Bug Fix: Use localized label instead of hardcoded 'IBAN'
              value: bankConfig.iban!,
              icon: Icons.credit_card,
              isDarkMode: isDarkMode,
              onCopy: () => _copyToClipboard(
                context,
                ref,
                bankConfig.iban!,
                tr.ibanCopied,
              ),
              translations: tr, // Bug #40 Fix: Localized tooltip
            ),
          ],
          if (bankConfig.swift != null) ...[
            const SizedBox(height: SpacingTokens.s),
            CopyableTextField(
              label: tr
                  .labelSwiftBic, // Bug Fix: Use localized label instead of hardcoded 'SWIFT/BIC'
              value: bankConfig.swift!,
              icon: Icons.language,
              isDarkMode: isDarkMode,
              onCopy: () => _copyToClipboard(
                context,
                ref,
                bankConfig.swift!,
                tr.swiftBicCopied,
              ),
              translations: tr, // Bug #40 Fix: Localized tooltip
            ),
          ],
          if (bankConfig.accountNumber != null) ...[
            const SizedBox(height: SpacingTokens.s),
            CopyableTextField(
              label: tr.accountNumber,
              value: bankConfig.accountNumber!,
              icon: Icons.numbers,
              isDarkMode: isDarkMode,
              onCopy: () => _copyToClipboard(
                context,
                ref,
                bankConfig.accountNumber!,
                tr.accountNumberCopied,
              ),
              translations: tr, // Bug #40 Fix: Localized tooltip
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    MinimalistColorSchemeAdapter colors,
    WidgetTranslations tr,
  ) {
    return Row(
      children: [
        Icon(
          Icons.account_balance,
          color: colors.buttonPrimary,
          size: IconSizeTokens.medium,
        ),
        const SizedBox(width: SpacingTokens.xs),
        Text(
          tr.paymentDetails,
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeL,
            fontWeight: TypographyTokens.semiBold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _copyToClipboard(
    BuildContext context,
    WidgetRef ref,
    String text,
    String message,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        SnackBarHelper.showSuccess(
          context: context,
          message: message,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      // Bug #42 Fix: Handle clipboard errors gracefully
      if (context.mounted) {
        final tr = WidgetTranslations.of(context, ref);
        SnackBarHelper.showError(
          context: context,
          message: tr.errorOccurred,
          duration: const Duration(seconds: 3),
        );
      }
      debugPrint('Error copying to clipboard: $e');
    }
  }
}
