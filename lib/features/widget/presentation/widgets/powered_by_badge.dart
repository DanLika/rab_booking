import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// "Powered by BedBooking" badge widget
/// Shows at the bottom of the widget for branding
/// Can be hidden for premium users via configuration
/// Very small and subtle - barely noticeable
class PoweredByBedBookingBadge extends ConsumerWidget {
  final WidgetColorScheme colors;

  /// Whether to show the badge
  /// Set to false for premium/white-label customers
  final bool show;

  /// Alignment of the badge
  final MainAxisAlignment alignment;

  /// Additional padding around the badge
  final EdgeInsets padding;

  const PoweredByBedBookingBadge({
    super.key,
    required this.colors,
    this.show = true,
    this.alignment = MainAxisAlignment.center,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Opacity(
        opacity: 0.5, // Very subtle - 50% opacity
        child: Row(
          mainAxisAlignment: alignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt,
              size: 8, // Very small icon
              color: colors.textTertiary,
            ),
            const SizedBox(width: SpacingTokens.xs / 2),
            Text(
              'Powered by ',
              style: GoogleFonts.inter(
                fontSize: TypographyTokens.poweredBySize, // 9px - very small
                color: colors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              'BedBooking',
              style: GoogleFonts.inter(
                fontSize: TypographyTokens.poweredBySize, // 9px - very small
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact version of the badge for tight spaces
/// Even smaller and more subtle than the regular version
class PoweredByBedBookingBadgeCompact extends ConsumerWidget {
  final WidgetColorScheme colors;
  final bool show;

  const PoweredByBedBookingBadgeCompact({
    super.key,
    required this.colors,
    this.show = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) {
      return const SizedBox.shrink();
    }

    return Opacity(
      opacity: 0.4, // Even more subtle - 40% opacity
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.s,
          vertical: SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderTokens.circularSubtle,
          border: Border.all(
            color: colors.borderLight,
            width: BorderTokens.widthThin / 2,
          ),
          boxShadow: ShadowTokens.subtle,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt,
              size: 8, // Very small
              color: colors.textSecondary,
            ),
            const SizedBox(width: SpacingTokens.xs),
            Text(
              'BedBooking',
              style: GoogleFonts.inter(
                fontSize: TypographyTokens.poweredBySize, // 9px
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
