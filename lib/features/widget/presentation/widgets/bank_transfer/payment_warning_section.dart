import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/minimalist_colors.dart';

/// Reusable payment warning section for bank transfers
/// Displays deposit amount and payment deadline with warning styling
class PaymentWarningSection extends StatelessWidget {
  final bool isDarkMode;
  final String depositAmount;
  final String deadline;

  const PaymentWarningSection({
    super.key,
    required this.isDarkMode,
    required this.depositAmount,
    required this.deadline,
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
                  'Uplata: $depositAmount',
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeL,
                    fontWeight: TypographyTokens.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xxs),
                Text(
                  'Rok: $deadline',
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
