import 'package:flutter/material.dart';
import '../../../../../core/design/tokens.dart';
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

    // Label gives way first (ellipsis); amount is FittedBox-scaled so the
    // full price (e.g. "€120.00") never visually clips at narrow widths.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isBold
                  ? BBTypeBridges.fontSizeM
                  : BBTypeBridges.fontSizeS,
              color: color ?? colors.textSecondary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              fontFamily: BBTypeBridges.primaryFont,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              amount,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: isBold
                    ? BBTypeBridges.fontSizeL
                    : BBTypeBridges.fontSizeS,
                color: color ?? colors.textPrimary,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                fontFamily: BBTypeBridges.primaryFont,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
