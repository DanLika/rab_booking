import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../l10n/widget_translations.dart';

/// Confirmation dialog for booking cancellation.
///
/// Extracted from BookingDetailsScreen for better organization.
/// Shows warning and booking reference before cancellation.
///
/// Usage:
/// ```dart
/// final confirmed = await showDialog<bool>(
///   context: context,
///   builder: (context) => CancelConfirmationDialog(
///     bookingReference: 'BK-ABC123',
///     colors: colors,
///     isDarkMode: isDarkMode,
///   ),
/// );
///
/// if (confirmed == true) {
///   // Proceed with cancellation
/// }
/// ```
class CancelConfirmationDialog extends ConsumerWidget {
  final String bookingReference;
  final WidgetColorScheme colors;
  final bool isDarkMode;

  const CancelConfirmationDialog({
    super.key,
    required this.bookingReference,
    required this.colors,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bug #62 Fix: Check for empty bookingReference string
    if (bookingReference.isEmpty) {
      return const SizedBox.shrink();
    }

    final tr = WidgetTranslations.of(context, ref);
    // Use pure black background for dark theme
    final dialogBg = isDarkMode
        ? ColorTokens.pureBlack
        : colors.backgroundPrimary;

    // Use calendar status colors for consistency
    // Red from booked days, green from available days
    final cancelColor =
        colors.statusBookedBorder; // #ef4444 - calendar booked red
    final keepColor = colors
        .statusAvailableBorder; // #83e6bf/#15b8a6 - calendar available green

    return AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderTokens.circularLarge),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: cancelColor, size: 28),
          const SizedBox(width: SpacingTokens.s),
          Text(
            tr.cancelBooking,
            style: TextStyle(
              fontWeight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.areYouSureCancelBooking,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeM,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SpacingTokens.m),
            decoration: BoxDecoration(
              // Dark mode: pure black background matching dialog, with visible border
              color: isDarkMode
                  ? ColorTokens.pureBlack
                  : colors.backgroundSecondary,
              borderRadius: BorderTokens.circularMedium,
              border: Border.all(
                color: isDarkMode ? colors.borderMedium : colors.borderDefault,
                width: isDarkMode ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.bookingReference,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeXS,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xxs),
                Text(
                  bookingReference,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeM,
                    fontWeight: TypographyTokens.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s),
            decoration: BoxDecoration(
              color: cancelColor.withValues(alpha: 0.08),
              borderRadius: BorderTokens.circularSmall,
              border: Border.all(color: cancelColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: cancelColor, size: 18),
                const SizedBox(width: SpacingTokens.xs),
                Expanded(
                  child: Text(
                    tr.actionCannotBeUndone,
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeXS,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            tr.keepBooking,
            style: TextStyle(
              color: keepColor,
              fontWeight: TypographyTokens.medium,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: cancelColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderTokens.circularMedium,
            ),
          ),
          child: Text(
            tr.cancelBooking,
            style: const TextStyle(fontWeight: TypographyTokens.semiBold),
          ),
        ),
      ],
    );
  }
}
