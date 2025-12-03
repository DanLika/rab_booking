import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

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
class CancelConfirmationDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Use pure black background for dark theme
    final dialogBg =
        isDarkMode ? ColorTokens.pureBlack : colors.backgroundPrimary;

    return AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderTokens.circularLarge,
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.error, size: 28),
          const SizedBox(width: SpacingTokens.s),
          Text(
            'Cancel Booking',
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
            'Are you sure you want to cancel this booking?',
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
              color: colors.backgroundSecondary,
              borderRadius: BorderTokens.circularMedium,
              border: Border.all(color: colors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Reference',
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
              color: colors.error.withValues(alpha: 0.08),
              borderRadius: BorderTokens.circularSmall,
              border: Border.all(
                color: colors.error.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colors.error, size: 18),
                const SizedBox(width: SpacingTokens.xs),
                Expanded(
                  child: Text(
                    'This action cannot be undone. You will receive a cancellation confirmation email.',
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
            'Keep Booking',
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: TypographyTokens.medium,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderTokens.circularMedium,
            ),
          ),
          child: const Text(
            'Cancel Booking',
            style: TextStyle(fontWeight: TypographyTokens.semiBold),
          ),
        ),
      ],
    );
  }
}
