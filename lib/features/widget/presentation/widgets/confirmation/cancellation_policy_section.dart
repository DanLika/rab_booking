import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// Reusable cancellation policy section for booking confirmation
/// Displays cancellation deadline and instructions for guests
class CancellationPolicySection extends StatelessWidget {
  final bool isDarkMode;
  final int deadlineHours;
  final String bookingReference;
  final String? fromEmail;

  const CancellationPolicySection({
    super.key,
    required this.isDarkMode,
    required this.deadlineHours,
    required this.bookingReference,
    this.fromEmail,
  });

  @override
  Widget build(BuildContext context) {
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    return Padding(
      padding: const EdgeInsets.only(top: SpacingTokens.l),
      child: Container(
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
            _buildHeader(colors),
            const SizedBox(height: SpacingTokens.s),
            Text(
              'Free cancellation up to $deadlineHours hours before check-in',
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                fontWeight: TypographyTokens.semiBold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              'To cancel your booking:',
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            _buildCancellationStep(colors, 'Reply to the confirmation email'),
            _buildCancellationStep(
              colors,
              'Include your booking reference: $bookingReference',
            ),
            if (fromEmail != null)
              _buildCancellationStep(colors, 'Or email: $fromEmail'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic colors) {
    return Row(
      children: [
        Icon(
          Icons.event_available,
          color: colors.textPrimary,
          size: 24,
        ),
        const SizedBox(width: SpacingTokens.s),
        Text(
          'Cancellation Policy',
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeL,
            fontWeight: TypographyTokens.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCancellationStep(dynamic colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(
        left: SpacingTokens.m,
        top: SpacingTokens.xxs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeM,
              color: colors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
