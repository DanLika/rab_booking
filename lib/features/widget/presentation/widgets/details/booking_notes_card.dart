import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// Card displaying additional booking notes.
///
/// Shows notes text from guest with icon header.
///
/// Usage:
/// ```dart
/// BookingNotesCard(
///   notes: 'Late arrival expected around 10 PM',
///   colors: ColorTokens.light,
/// )
/// ```
class BookingNotesCard extends StatelessWidget {
  /// Notes text
  final String notes;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const BookingNotesCard({
    super.key,
    required this.notes,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes, size: 20, color: colors.textSecondary),
                const SizedBox(width: SpacingTokens.xs),
                Text(
                  'Additional Notes',
                  style: GoogleFonts.inter(
                    fontSize: TypographyTokens.fontSizeM,
                    fontWeight: TypographyTokens.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.s),
            Text(
              notes,
              style: GoogleFonts.inter(
                fontSize: TypographyTokens.fontSizeS,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
