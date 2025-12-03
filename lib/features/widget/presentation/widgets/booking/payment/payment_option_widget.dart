import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../theme/minimalist_colors.dart';

/// A selectable payment option card with radio button styling.
///
/// Displays payment method information including icon, title, subtitle,
/// and optional deposit amount. Shows selected state with highlighted border
/// and filled radio indicator.
///
/// Usage:
/// ```dart
/// PaymentOptionWidget(
///   icon: Icons.credit_card,
///   title: 'Credit Card',
///   subtitle: 'Pay securely online',
///   isSelected: _selectedMethod == 'stripe',
///   onTap: () => setState(() => _selectedMethod = 'stripe'),
///   isDarkMode: isDarkMode,
///   depositAmount: '€50.00',
/// )
/// ```
class PaymentOptionWidget extends StatelessWidget {
  /// Icon representing the payment method
  final IconData icon;

  /// Payment method title
  final String title;

  /// Payment method description
  final String subtitle;

  /// Whether this option is currently selected
  final bool isSelected;

  /// Callback when option is tapped
  final VoidCallback onTap;

  /// Whether dark mode is active
  final bool isDarkMode;

  /// Optional deposit amount to display (null for "Pay on Arrival")
  final String? depositAmount;

  const PaymentOptionWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.isDarkMode,
    this.depositAmount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderTokens.circularMedium,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.m),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? colors.borderFocus
                : colors.borderDefault,
            width: isSelected
                ? BorderTokens.widthMedium
                : BorderTokens.widthThin,
          ),
          borderRadius: BorderTokens.circularMedium,
          color: isSelected ? colors.backgroundSecondary : null,
        ),
        child: Row(
          children: [
            // Radio button
            _buildRadioIndicator(colors),
            const SizedBox(width: SpacingTokens.s),

            // Icon
            Icon(
              icon,
              color: isSelected ? colors.textPrimary : colors.textSecondary,
              size: 28,
            ),
            const SizedBox(width: SpacingTokens.s),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AutoSizeText(
                    subtitle,
                    maxLines: 2,
                    minFontSize: 10,
                    maxFontSize: 12,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Deposit amount (only show if not null)
            if (depositAmount != null)
              Text(
                depositAmount!,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioIndicator(MinimalistColorSchemeAdapter colors) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? colors.borderFocus : colors.textSecondary,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.buttonPrimary,
                ),
              ),
            )
          : null,
    );
  }
}
