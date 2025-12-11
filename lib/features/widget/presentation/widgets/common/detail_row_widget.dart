import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/minimalist_colors.dart';

/// A row displaying a label and value for booking details.
///
/// Used in booking confirmation, bank transfer, and other detail screens
/// to show key-value pairs like check-in dates, guest info, prices, etc.
///
/// Usage:
/// ```dart
/// // Bank transfer style (semiBold value, no padding)
/// DetailRowWidget(
///   label: 'Check-in',
///   value: '15.01.2025',
///   isDarkMode: isDarkMode,
/// )
///
/// // Booking confirmation style (regular value, with padding)
/// DetailRowWidget(
///   label: 'Guest',
///   value: 'John Doe',
///   isDarkMode: isDarkMode,
///   hasPadding: true,
///   valueFontWeight: FontWeight.w400,
/// )
///
/// // With highlighting for important values (always bold)
/// DetailRowWidget(
///   label: 'Total',
///   value: '€500.00',
///   isDarkMode: isDarkMode,
///   isHighlighted: true,
/// )
/// ```
class DetailRowWidget extends StatelessWidget {
  /// Label text displayed on the left
  final String label;

  /// Value text displayed on the right
  final String value;

  /// Whether dark mode is active
  final bool isDarkMode;

  /// Whether to highlight the value (bolder font, primary color)
  final bool isHighlighted;

  /// Whether to add vertical padding around the row
  final bool hasPadding;

  /// Font weight for non-highlighted value text.
  /// Defaults to semiBold for bank transfer style.
  /// Use FontWeight.w400 (regular) for booking confirmation style.
  final FontWeight valueFontWeight;

  const DetailRowWidget({
    super.key,
    required this.label,
    required this.value,
    required this.isDarkMode,
    this.isHighlighted = false,
    this.hasPadding = false,
    this.valueFontWeight = TypographyTokens.semiBold,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeM,
            color: colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeM,
            fontWeight: isHighlighted ? TypographyTokens.bold : valueFontWeight,
            color: isHighlighted ? colors.buttonPrimary : colors.textPrimary,
          ),
        ),
      ],
    );

    if (hasPadding) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xxs),
        child: row,
      );
    }

    return row;
  }
}
