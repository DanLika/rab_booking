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
///
/// // Stacked layout for long values (email, URLs)
/// DetailRowWidget(
///   label: 'Email',
///   value: 'verylongemail@example.com',
///   isDarkMode: isDarkMode,
///   stacked: true,
/// )
/// ```
class DetailRowWidget extends StatelessWidget {
  /// Label text displayed on the left (or top if stacked)
  final String label;

  /// Value text displayed on the right (or below if stacked)
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

  /// Whether to stack label and value vertically (label on top, value below).
  /// Use for long values like email addresses that would overflow horizontally.
  final bool stacked;

  // Bug #45 Fix: Removed const to allow assert validation for non-empty label and value
  DetailRowWidget({
    super.key,
    required this.label,
    required this.value,
    required this.isDarkMode,
    this.isHighlighted = false,
    this.hasPadding = false,
    this.valueFontWeight = TypographyTokens.semiBold,
    this.stacked = false,
  }) : assert(label.isNotEmpty, 'Label cannot be empty'),
       assert(value.isNotEmpty, 'Value cannot be empty');

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    final labelWidget = Text(
      label,
      style: TextStyle(
        fontSize: TypographyTokens.fontSizeM,
        color: colors.textSecondary,
      ),
    );

    final valueWidget = Text(
      value,
      style: TextStyle(
        fontSize: TypographyTokens.fontSizeM,
        fontWeight: isHighlighted ? TypographyTokens.bold : valueFontWeight,
        color: isHighlighted ? colors.buttonPrimary : colors.textPrimary,
      ),
      // Allow text to wrap for stacked layout
      softWrap: stacked,
    );

    // Bug #46 Fix: Add Semantics widget for accessibility (screen readers)
    final Widget content;
    if (stacked) {
      // Stacked layout: label on top, value below (for long values like email)
      content = Semantics(
        label: label,
        value: value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelWidget,
            const SizedBox(height: SpacingTokens.xxs),
            valueWidget,
          ],
        ),
      );
    } else {
      // Horizontal layout: label left, value right
      content = Semantics(
        label: label,
        value: value,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            labelWidget,
            Flexible(child: valueWidget),
          ],
        ),
      );
    }

    if (hasPadding) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xxs),
        child: content,
      );
    }

    return content;
  }
}
