import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/minimalist_colors.dart';
import '../../l10n/widget_translations.dart';
import '../../../../../../shared/utils/ui/snackbar_helper.dart';

/// A text field with a label, value, icon, and copy button.
///
/// Extracted from bank_transfer_screen.dart _buildBankField method.
/// Used to display copyable information like IBAN, reference numbers, etc.
///
/// Usage:
/// ```dart
/// CopyableTextField(
///   label: 'IBAN',
///   value: 'HR1234567890123456789',
///   icon: Icons.account_balance,
///   isDarkMode: isDarkMode,
///   onCopy: () async {
///     await Clipboard.setData(ClipboardData(text: value));
///     // Show snackbar
///   },
///   translations: tr, // Optional: for localized error messages
/// )
/// ```
class CopyableTextField extends StatelessWidget {
  /// Label text displayed above the value
  final String label;

  /// Value text to display and copy
  final String value;

  /// Icon displayed on the left
  final IconData icon;

  /// Whether dark mode is active
  final bool isDarkMode;

  /// Callback when copy button is pressed
  /// Bug #42 Fix: Changed to async function to support error handling
  final Future<void> Function() onCopy;

  /// Optional translations for localized tooltip
  /// Bug #40 Fix: Localized copy tooltip
  final WidgetTranslations? translations;

  const CopyableTextField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.isDarkMode,
    required this.onCopy,
    this.translations,
  });

  /// Check if label should use monospace font based on case-insensitive keyword matching
  ///
  /// Returns true if label contains any of the following keywords (case-insensitive):
  /// - IBAN, SWIFT, BIC (banking codes)
  /// - Reference, Referenca, Referenz, Riferimento (reference numbers)
  /// - Account, Broj, Number, Numero, Kontonummer (account numbers)
  bool _shouldUseMonospace(String label) {
    final lowerLabel = label.toLowerCase();

    // Banking codes (IBAN, SWIFT, BIC)
    if (lowerLabel.contains('iban') ||
        lowerLabel.contains('swift') ||
        lowerLabel.contains('bic')) {
      return true;
    }

    // Reference numbers (all languages)
    if (lowerLabel.contains('reference') ||
        lowerLabel.contains('referenca') ||
        lowerLabel.contains('referenz') ||
        lowerLabel.contains('riferimento')) {
      return true;
    }

    // Account numbers (all languages)
    if (lowerLabel.contains('account') ||
        lowerLabel.contains('broj') ||
        lowerLabel.contains('number') ||
        lowerLabel.contains('numero') ||
        lowerLabel.contains('kontonummer')) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Bug #47 Fix: Return empty widget if value is empty to prevent layout issues
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    // Bug #41 Fix: Use case-insensitive helper method for monospace font detection
    final useMonospace = _shouldUseMonospace(label);

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.s),
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        borderRadius: BorderRadius.circular(BorderTokens.radiusSubtle),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.buttonPrimary, size: IconSizeTokens.small),
          const SizedBox(width: SpacingTokens.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeXS,
                    color: colors.textSecondary,
                    fontWeight: TypographyTokens.medium,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeM,
                    fontWeight: TypographyTokens.semiBold,
                    color: colors.textPrimary,
                    fontFamily: useMonospace ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.content_copy,
              size: IconSizeTokens.small,
              color: colors.buttonPrimary,
            ),
            onPressed: () async {
              try {
                await onCopy();
              } catch (e) {
                // Bug #42 Fix: Handle clipboard errors gracefully
                if (context.mounted) {
                  final errorMessage =
                      translations?.errorOccurred ??
                      'Failed to copy to clipboard';
                  SnackBarHelper.showError(
                    context: context,
                    message: errorMessage,
                    duration: const Duration(seconds: 3),
                  );
                }
                debugPrint('Error copying to clipboard: $e');
              }
            },
            tooltip:
                translations?.copy ?? 'Copy', // Bug #40 Fix: Localized tooltip
          ),
        ],
      ),
    );
  }
}
