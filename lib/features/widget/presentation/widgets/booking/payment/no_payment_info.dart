import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../theme/minimalist_colors.dart';

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
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Container(
      margin: const EdgeInsets.only(top: SpacingTokens.m),
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: isDarkMode ? 0.2 : 0.1),
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(
          color: colors.error,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colors.error,
          ),
          const SizedBox(width: SpacingTokens.s),
          Expanded(
            child: Text(
              message ?? defaultMessage,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeS,
                color: colors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
