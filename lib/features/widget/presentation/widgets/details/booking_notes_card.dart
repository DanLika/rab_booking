import 'package:flutter/material.dart';
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, size: 20, color: colors.textSecondary),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Additional Notes',
                style: TextStyle(
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
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeS,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
