import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../l10n/widget_translations.dart';
import '../../../theme/minimalist_colors.dart';

/// Error info container displayed when no payment methods are configured.
///
/// Shows error styling with icon and message.
class NoPaymentInfo extends ConsumerWidget {
  final bool isDarkMode;

  /// Custom error message (optional, uses translation by default)
  final String? message;

  const NoPaymentInfo({super.key, required this.isDarkMode, this.message});

  static const _darkModeAlpha = 0.2;
  static const _lightModeAlpha = 0.1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final tr = WidgetTranslations.of(context, ref);

    return Container(
      margin: const EdgeInsets.only(top: SpacingTokens.m),
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.error.withValues(
          alpha: isDarkMode ? _darkModeAlpha : _lightModeAlpha,
        ),
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(color: colors.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.error),
          const SizedBox(width: SpacingTokens.s),
          Expanded(
            child: Text(
              message ?? tr.noPaymentMethodsAvailable,
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
