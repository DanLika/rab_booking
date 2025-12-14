import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/minimalist_colors.dart';

/// A row displaying a label and amount for price breakdowns.
///
/// Used in price summary sections to show individual line items
/// like room price, additional services, and totals.
///
/// Usage:
/// ```dart
/// PriceRowWidget(
///   label: 'Room (3 nights)',
///   amount: '€300.00',
///   isDarkMode: isDarkMode,
/// )
/// ```
class PriceRowWidget extends StatelessWidget {
  /// Label text (left side)
  final String label;

  /// Amount text (right side)
  final String amount;

  /// Whether dark mode is active
  final bool isDarkMode;

  /// Optional custom color for both label and amount
  final Color? color;

  /// Whether to use bold/larger styling (for totals)
  final bool isBold;

  const PriceRowWidget({
    super.key,
    required this.label,
    required this.amount,
    required this.isDarkMode,
    this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? TypographyTokens.fontSizeM : TypographyTokens.fontSizeS,
            color: color ?? colors.textSecondary,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            fontFamily: TypographyTokens.primaryFont,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isBold ? TypographyTokens.fontSizeL : TypographyTokens.fontSizeS,
            color: color ?? colors.textPrimary,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            fontFamily: TypographyTokens.primaryFont,
          ),
        ),
      ],
    );
  }
}
