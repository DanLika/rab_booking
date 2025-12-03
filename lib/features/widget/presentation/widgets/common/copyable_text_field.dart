import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/minimalist_colors.dart';

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
///   onCopy: () {
///     Clipboard.setData(ClipboardData(text: value));
///     // Show snackbar
///   },
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
  final VoidCallback onCopy;

  const CopyableTextField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.isDarkMode,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    // Use monospace font for IBAN and reference numbers
    final useMonospace =
        label.contains('IBAN') || label.contains('Broj') || label.contains('Reference');

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.s),
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        borderRadius: BorderRadius.circular(BorderTokens.radiusSubtle),
        border: Border.all(
          color: colors.borderDefault,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: colors.buttonPrimary,
            size: IconSizeTokens.small,
          ),
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
            onPressed: onCopy,
            tooltip: 'Kopiraj',
          ),
        ],
      ),
    );
  }
}
