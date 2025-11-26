import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../theme/minimalist_colors.dart';
import '../../common/theme_colors_helper.dart';

/// A card displaying a single payment method with icon, title, and optional subtitle.
///
/// Extracted from booking_widget_screen.dart simplified payment info section.
/// Used when only one payment method is enabled (no selector needed).
///
/// Usage:
/// ```dart
/// PaymentMethodCard(
///   icon: Icons.credit_card,
///   title: 'Credit Card',
///   subtitle: '€50.00 deposit',
///   isDarkMode: isDarkMode,
/// )
/// ```
class PaymentMethodCard extends StatelessWidget {
  /// Icon to display on the left
  final IconData icon;

  /// Title text (payment method name)
  final String title;

  /// Optional subtitle text (e.g., deposit amount)
  final String? subtitle;

  /// Whether dark mode is active
  final bool isDarkMode;

  const PaymentMethodCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final getColor = ThemeColorsHelper.createColorGetter(isDarkMode);

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: getColor(
          MinimalistColors.backgroundSecondary,
          MinimalistColorsDark.backgroundSecondary,
        ),
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(
          color: getColor(
            MinimalistColors.borderDefault,
            MinimalistColorsDark.borderDefault,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: getColor(
              MinimalistColors.textPrimary,
              MinimalistColorsDark.textPrimary,
            ),
            size: 24,
          ),
          const SizedBox(width: SpacingTokens.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: getColor(
                      MinimalistColors.textPrimary,
                      MinimalistColorsDark.textPrimary,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: getColor(
                        MinimalistColors.textSecondary,
                        MinimalistColorsDark.textSecondary,
                      ),
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
