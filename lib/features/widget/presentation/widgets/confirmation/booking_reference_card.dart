import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../../shared/utils/ui/snackbar_helper.dart';

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
class BookingReferenceCard extends StatelessWidget {
  /// The booking reference number to display
  final String bookingReference;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const BookingReferenceCard({
    super.key,
    required this.bookingReference,
    required this.colors,
  });

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: bookingReference));
    if (context.mounted) {
      SnackBarHelper.showSuccess(
        context: context,
        message: 'Booking reference copied to clipboard!',
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(
          color: colors.borderDefault,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Booking Reference',
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
                icon: Icon(
                  Icons.copy,
                  color: colors.textSecondary,
                ),
                onPressed: () => _copyToClipboard(context),
                tooltip: 'Copy reference',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
