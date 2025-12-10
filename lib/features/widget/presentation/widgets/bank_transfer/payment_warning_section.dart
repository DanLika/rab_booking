import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/minimalist_colors.dart';
import '../../l10n/widget_translations.dart';

/// Reusable payment warning section for bank transfers
/// Displays deposit amount and payment deadline with warning styling
class PaymentWarningSection extends StatelessWidget {
  final bool isDarkMode;
  final String depositAmount;
  final String deadline;
  final WidgetTranslations translations;

  const PaymentWarningSection({
    super.key,
    required this.isDarkMode,
    required this.depositAmount,
    required this.deadline,
    required this.translations,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(
          color: colors.warning,
          width: BorderTokens.widthMedium,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: colors.warning,
            size: IconSizeTokens.large,
          ),
          const SizedBox(width: SpacingTokens.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translations.paymentAmount(depositAmount),
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeL,
                    fontWeight: TypographyTokens.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xxs),
                Text(
                  translations.deadlineLabel(deadline),
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeM,
                    color: colors.textSecondary,
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
