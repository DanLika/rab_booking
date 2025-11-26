import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../theme/minimalist_colors.dart';
import '../../common/theme_colors_helper.dart';

/// Error info container displayed when no payment methods are configured.
///
/// Extracted from booking_widget_screen.dart payment methods section.
/// Shows error styling with icon and message.
///
/// Usage:
/// ```dart
/// NoPaymentInfo(
///   isDarkMode: isDarkMode,
///   message: 'Custom error message', // Optional
/// )
/// ```
class NoPaymentInfo extends StatelessWidget {
  /// Whether dark mode is active
  final bool isDarkMode;

  /// Custom error message (optional)
  final String? message;

  /// Default error message
  static const String defaultMessage =
      'No payment methods are currently configured. Please contact the property owner to complete your booking.';

  const NoPaymentInfo({
    super.key,
    required this.isDarkMode,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final getColor = ThemeColorsHelper.createColorGetter(isDarkMode);

    return Container(
      margin: const EdgeInsets.only(top: SpacingTokens.m),
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: getColor(
          MinimalistColors.error.withValues(alpha: 0.1),
          MinimalistColorsDark.error.withValues(alpha: 0.2),
        ),
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(
          color: getColor(
            MinimalistColors.error,
            MinimalistColorsDark.error,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: getColor(
              MinimalistColors.error,
              MinimalistColorsDark.error,
            ),
          ),
          const SizedBox(width: SpacingTokens.s),
          Expanded(
            child: Text(
              message ?? defaultMessage,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeS,
                color: getColor(
                  MinimalistColors.error,
                  MinimalistColorsDark.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
