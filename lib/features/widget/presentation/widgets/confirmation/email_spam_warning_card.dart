import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/design/tokens.dart';
import '../../l10n/widget_translations.dart';

/// Card warning user to check spam folder for confirmation email.
///
/// Displays info message about email delivery and spam folders.
///
/// Usage:
/// ```dart
/// EmailSpamWarningCard(colors: ColorTokens.light)
/// ```
class EmailSpamWarningCard extends ConsumerWidget {
  /// Color tokens for theming
  final WidgetColorScheme colors;

  const EmailSpamWarningCard({super.key, required this.colors});

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mail_outline, color: colors.textSecondary, size: 20),
          const SizedBox(width: BBSpace.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.confirmationEmailSentTitle,
                  style: TextStyle(
                    fontSize: BBTypeBridges.fontSizeM,
                    fontWeight: BBTypeBridges.weightSemiBold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: BBSpaceBridges.xxs2),
                Text(
                  tr.checkInboxForConfirmation,
                  style: TextStyle(
                    fontSize: BBTypeBridges.fontSizeS,
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
