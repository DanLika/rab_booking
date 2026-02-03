import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../../shared/utils/ui/snackbar_helper.dart';
import '../../l10n/widget_translations.dart';

/// Card displaying the booking reference with copy functionality.
///
/// Shows the booking reference number prominently with a copy button.
/// Used in booking confirmation screen.
///
/// Usage:
/// ```dart
/// BookingReferenceCard(
///   bookingReference: 'ABC123',
///   colors: ColorTokens.light,
/// )
/// ```
class BookingReferenceCard extends ConsumerWidget {
  /// The booking reference number to display
  final String bookingReference;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const BookingReferenceCard({
    super.key,
    required this.bookingReference,
    required this.colors,
  });

  Future<void> _copyToClipboard(
    BuildContext context,
    WidgetTranslations tr,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: bookingReference));
      if (context.mounted) {
        SnackBarHelper.showSuccess(
          context: context,
          message: tr.bookingReferenceCopied,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      // Clipboard API can fail on some browsers (e.g., Safari in iframe)
      // Silently fail - user can still see the reference on screen
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = WidgetTranslations.of(context, ref);
    // Detect dark mode from background color
    final isDark = colors.backgroundPrimary.computeLuminance() < 0.5;

    // Dark mode: pure black background matching parent, with visible border
    final cardBackground = isDark
        ? ColorTokens.pureBlack
        : colors.backgroundSecondary;
    final cardBorder = isDark ? colors.borderMedium : colors.borderDefault;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(color: cardBorder, width: isDark ? 1.5 : 1.0),
      ),
      child: Column(
        children: [
          Text(
            tr.bookingReference,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeS,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SelectableText(
                bookingReference,
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeXL,
                  fontWeight: TypographyTokens.bold,
                  letterSpacing: 2,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: SpacingTokens.s),
              IconButton(
                icon: Icon(Icons.copy, color: colors.textSecondary),
                onPressed: () => _copyToClipboard(context, tr),
                tooltip: tr.copyReference,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
