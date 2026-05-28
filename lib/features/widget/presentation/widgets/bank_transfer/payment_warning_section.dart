import 'package:flutter/material.dart';
import '../../../../../core/design/tokens.dart';
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
      padding: const EdgeInsets.all(BBSpace.sm),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BBRadiusBridges.medium),
        border: Border.all(color: colors.warning, width: BBBorderWidth.medium),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: colors.warning,
            size: BBIconSize.large,
          ),
          const SizedBox(width: BBSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translations.paymentAmount(depositAmount),
                  style: TextStyle(
                    fontSize: BBTypeBridges.fontSizeL,
                    fontWeight: BBTypeBridges.weightBold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: BBSpaceBridges.xxs2),
                Text(
                  translations.deadlineLabel(deadline),
                  style: TextStyle(
                    fontSize: BBTypeBridges.fontSizeM,
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
