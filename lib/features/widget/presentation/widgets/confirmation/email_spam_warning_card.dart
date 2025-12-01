import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// Card warning user to check spam folder for confirmation email.
///
/// Displays info message about email delivery and spam folders.
///
/// Usage:
/// ```dart
/// EmailSpamWarningCard(colors: ColorTokens.light)
/// ```
class EmailSpamWarningCard extends StatelessWidget {
  /// Color tokens for theming
  final WidgetColorScheme colors;

  const EmailSpamWarningCard({
    super.key,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(
          color: colors.borderDefault,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mail_outline,
            color: colors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: SpacingTokens.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirmation Email Sent',
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeM,
                    fontWeight: TypographyTokens.semiBold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xxs),
                Text(
                  'Check your inbox for booking confirmation. If you don\'t see it within a few minutes, please check your spam or junk folder.',
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeS,
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
