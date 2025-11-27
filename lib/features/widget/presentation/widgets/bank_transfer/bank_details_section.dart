import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/minimalist_colors.dart';
import '../../../domain/models/widget_settings.dart';
import '../common/copyable_text_field.dart';
import '../../../../../../shared/utils/ui/snackbar_helper.dart';

/// Reusable bank details section for bank transfers
/// Displays IBAN, SWIFT, account holder, bank name with copy functionality
class BankDetailsSection extends StatelessWidget {
  final bool isDarkMode;
  final BankTransferConfig bankConfig;

  const BankDetailsSection({
    super.key,
    required this.isDarkMode,
    required this.bankConfig,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: _getColor(
          MinimalistColors.backgroundSecondary,
          MinimalistColorsDark.backgroundSecondary,
        ),
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(
          color: _getColor(
            MinimalistColors.borderDefault,
            MinimalistColorsDark.borderDefault,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: SpacingTokens.m),
          if (bankConfig.accountHolder != null)
            CopyableTextField(
              label: 'Vlasnik Računa',
              value: bankConfig.accountHolder!,
              icon: Icons.person_outline,
              isDarkMode: isDarkMode,
              onCopy: () => _copyToClipboard(
                context,
                bankConfig.accountHolder!,
                'Vlasnik Računa kopiran',
              ),
            ),
          if (bankConfig.bankName != null) ...[
            const SizedBox(height: SpacingTokens.s),
            CopyableTextField(
              label: 'Naziv Banke',
              value: bankConfig.bankName!,
              icon: Icons.account_balance_outlined,
              isDarkMode: isDarkMode,
              onCopy: () => _copyToClipboard(
                context,
                bankConfig.bankName!,
                'Naziv Banke kopiran',
              ),
            ),
          ],
          if (bankConfig.iban != null) ...[
            const SizedBox(height: SpacingTokens.s),
            CopyableTextField(
              label: 'IBAN',
              value: bankConfig.iban!,
              icon: Icons.credit_card,
              isDarkMode: isDarkMode,
              onCopy: () => _copyToClipboard(
                context,
                bankConfig.iban!,
                'IBAN kopiran',
              ),
            ),
          ],
          if (bankConfig.swift != null) ...[
            const SizedBox(height: SpacingTokens.s),
            CopyableTextField(
              label: 'SWIFT/BIC',
              value: bankConfig.swift!,
              icon: Icons.language,
              isDarkMode: isDarkMode,
              onCopy: () => _copyToClipboard(
                context,
                bankConfig.swift!,
                'SWIFT/BIC kopiran',
              ),
            ),
          ],
          if (bankConfig.accountNumber != null) ...[
            const SizedBox(height: SpacingTokens.s),
            CopyableTextField(
              label: 'Broj Računa',
              value: bankConfig.accountNumber!,
              icon: Icons.numbers,
              isDarkMode: isDarkMode,
              onCopy: () => _copyToClipboard(
                context,
                bankConfig.accountNumber!,
                'Broj Računa kopiran',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.account_balance,
          color: _getColor(
            MinimalistColors.buttonPrimary,
            MinimalistColorsDark.buttonPrimary,
          ),
          size: IconSizeTokens.medium,
        ),
        const SizedBox(width: SpacingTokens.xs),
        Text(
          'Podaci za Uplatu',
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeL,
            fontWeight: TypographyTokens.semiBold,
            color: _getColor(
              MinimalistColors.textPrimary,
              MinimalistColorsDark.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    SnackBarHelper.showSuccess(
      context: context,
      message: message,
      duration: const Duration(seconds: 2),
    );
  }

  Color _getColor(Color lightColor, Color darkColor) {
    return isDarkMode ? darkColor : lightColor;
  }
}
