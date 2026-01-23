import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../../shared/utils/ui/snackbar_helper.dart';
import '../../l10n/widget_translations.dart';

/// Card displaying booking reference with copy functionality.
///
/// Shows the booking reference prominently with copy button.
///
/// Usage:
/// ```dart
/// DetailsReferenceCard(
///   bookingReference: 'ABC123',
///   colors: ColorTokens.light,
/// )
/// ```
class DetailsReferenceCard extends ConsumerWidget {
  /// The booking reference number
  final String bookingReference;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const DetailsReferenceCard({
    super.key,
    required this.bookingReference,
    required this.colors,
  });

  Future<void> _copyToClipboard(BuildContext context, WidgetRef ref) async {
    final tr = WidgetTranslations.of(context, ref);
    try {
      // Bug #65 Fix: Handle clipboard errors gracefully
      await Clipboard.setData(ClipboardData(text: bookingReference));
      if (context.mounted) {
        SnackBarHelper.showSuccess(
          context: context,
          message: tr.bookingReferenceCopied,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
      if (context.mounted) {
        SnackBarHelper.showError(
          context: context,
          message: tr.errorOccurred,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bug #70 Fix: Check for empty string to prevent layout issues
    if (bookingReference.isEmpty) {
      return const SizedBox.shrink();
    }

    final tr = WidgetTranslations.of(context, ref);
    // Detect dark mode for better contrast
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
              Text(
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
                onPressed: () => _copyToClipboard(context, ref),
                tooltip: tr.copyReference,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
