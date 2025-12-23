import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../theme/minimalist_colors.dart';

/// A card displaying a single payment method with icon, title, and optional subtitle.
///
/// Used when only one payment method is enabled (no selector needed).
class PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDarkMode;

  // Bug #29 Fix: Removed const to allow assert validation for non-empty title
  PaymentMethodCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isDarkMode,
  }) : assert(title.isNotEmpty, 'Title cannot be empty');

  static const _iconSize = 24.0;
  static const _titleFontSize = 14.0;
  static const _titleMinFontSize = 11.0;
  static const _subtitleFontSize = 12.0;
  static const _subtitleMinFontSize = 10.0;

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Semantics(
      label: title,
      hint: subtitle,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.m),
        decoration: BoxDecoration(
          color: colors.backgroundTertiary,
          borderRadius: BorderTokens.circularMedium,
          border: Border.all(color: colors.borderDefault),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.textPrimary, size: _iconSize),
            const SizedBox(width: SpacingTokens.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    title,
                    maxLines: 1,
                    minFontSize: _titleMinFontSize,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  // Bug #29 Fix: Only render subtitle if it's not null and not empty
                  if (subtitle != null && subtitle!.isNotEmpty)
                    AutoSizeText(
                      subtitle!,
                      maxLines: 2,
                      minFontSize: _subtitleMinFontSize,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _subtitleFontSize,
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
