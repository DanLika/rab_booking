import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

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

  const DetailsReferenceCard({
    super.key,
    required this.bookingReference,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderTokens.circularLarge,
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.l),
        child: Column(
          children: [
            Text(
              'Booking Reference',
              style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(
                    fontSize: TypographyTokens.fontSizeXXL,
                    fontWeight: TypographyTokens.bold,
                    color: colors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: SpacingTokens.xs),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: bookingReference),
                    );
                  },
                  color: colors.primary,
                  tooltip: 'Copy reference',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
