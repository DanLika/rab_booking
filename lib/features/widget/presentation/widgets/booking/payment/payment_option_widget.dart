import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../theme/minimalist_colors.dart';

/// A selectable payment option card with radio button styling.
///
/// Displays payment method information including icon(s), title, subtitle,
/// and optional deposit amount. Shows selected state with highlighted border
/// and filled radio indicator.
class PaymentOptionWidget extends StatelessWidget {
  final IconData icon;
  final IconData? secondaryIcon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDarkMode;

  /// Optional deposit amount to display (null for "Pay on Arrival")
  final String? depositAmount;

  // Bug #29 Fix: Removed const to allow assert validation for non-empty title and subtitle
  PaymentOptionWidget({
    super.key,
    required this.icon,
    this.secondaryIcon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.isDarkMode,
    this.depositAmount,
  }) : assert(title.isNotEmpty, 'Title cannot be empty'),
       assert(subtitle.isNotEmpty, 'Subtitle cannot be empty');

  // Size constants
  static const _primaryIconSize = 24.0;
  static const _secondaryIconSize = 20.0;
  static const _radioSize = 24.0;
  static const _radioInnerSize = 12.0;
  static const _radioBorderWidth = 2.0;

  // Typography constants
  static const _titleFontSize = 15.0;
  static const _titleMinFontSize = 11.0;
  static const _subtitleFontSize = 12.0;
  static const _subtitleMinFontSize = 10.0;
  static const _depositFontSize = 12.0;

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    // Build semantic label combining title, subtitle, and deposit amount
    final semanticLabel = _buildSemanticLabel();

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isSelected,
      hint: subtitle,
      value: depositAmount,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderTokens.circularMedium,
        child: Container(
          padding: const EdgeInsets.all(SpacingTokens.m),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? colors.borderFocus : colors.borderDefault,
              width: isSelected ? BorderTokens.widthMedium : BorderTokens.widthThin,
            ),
            borderRadius: BorderTokens.circularMedium,
            color: isSelected ? colors.backgroundSecondary : null,
          ),
          child: Row(
            children: [
              _RadioIndicator(isSelected: isSelected, colors: colors),
              const SizedBox(width: SpacingTokens.s),
              _buildIcons(colors),
              const SizedBox(width: SpacingTokens.s),
              Expanded(child: _buildContent(colors)),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSemanticLabel() {
    final parts = <String>[title];
    if (depositAmount != null) {
      parts.add(depositAmount!);
    }
    return parts.join(', ');
  }

  Widget _buildIcons(MinimalistColorSchemeAdapter colors) {
    final iconColor = isSelected ? colors.textPrimary : colors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: _primaryIconSize),
        if (secondaryIcon case final secIcon?) ...[
          const SizedBox(width: SpacingTokens.xxs),
          Icon(secIcon, color: iconColor, size: _secondaryIconSize),
        ],
      ],
    );
  }

  Widget _buildContent(MinimalistColorSchemeAdapter colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AutoSizeText(
                title,
                maxLines: 1,
                minFontSize: _titleMinFontSize,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: _titleFontSize, fontWeight: FontWeight.w600, color: colors.textPrimary),
              ),
            ),
            if (depositAmount case final amount?) ...[
              const SizedBox(width: SpacingTokens.xs),
              Text(
                amount,
                style: TextStyle(fontSize: _depositFontSize, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
            ],
          ],
        ),
        const SizedBox(height: SpacingTokens.xxs),
        AutoSizeText(
          subtitle,
          maxLines: 2,
          minFontSize: _subtitleMinFontSize,
          maxFontSize: _subtitleFontSize,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: _subtitleFontSize, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  final bool isSelected;
  final MinimalistColorSchemeAdapter colors;

  const _RadioIndicator({required this.isSelected, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: PaymentOptionWidget._radioSize,
      height: PaymentOptionWidget._radioSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? colors.borderFocus : colors.textSecondary,
          width: PaymentOptionWidget._radioBorderWidth,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: PaymentOptionWidget._radioInnerSize,
                height: PaymentOptionWidget._radioInnerSize,
                decoration: BoxDecoration(shape: BoxShape.circle, color: colors.buttonPrimary),
              ),
            )
          : null,
    );
  }
}
