import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
class DetailsReferenceCard extends StatelessWidget {
  /// The booking reference number
  final String bookingReference;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const DetailsReferenceCard({super.key, required this.bookingReference, required this.colors});

  Future<void> _copyToClipboard(BuildContext context) async {
    final tr = WidgetTranslations.of(context);
    await Clipboard.setData(ClipboardData(text: bookingReference));
    if (context.mounted) {
      SnackBarHelper.showSuccess(
        context: context,
        message: tr.bookingReferenceCopied,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = WidgetTranslations.of(context);
    // Detect dark mode for better contrast
    final isDark = colors.backgroundPrimary.computeLuminance() < 0.5;
    final cardBackground = isDark ? colors.backgroundTertiary : colors.backgroundSecondary;
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
            style: TextStyle(fontSize: TypographyTokens.fontSizeS, color: colors.textSecondary),
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
                onPressed: () => _copyToClipboard(context),
                tooltip: tr.copyReference,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
