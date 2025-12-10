import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../l10n/widget_translations.dart';

/// Reusable cancellation policy section for booking confirmation
/// Displays cancellation deadline and instructions for guests
class CancellationPolicySection extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;
    final tr = WidgetTranslations.of(context, ref);
    // Use backgroundTertiary in dark mode for better contrast
    final cardBackground = isDarkMode
        ? colors.backgroundTertiary
        : colors.backgroundSecondary;
    final cardBorder = isDarkMode ? colors.borderMedium : colors.borderDefault;

    return Padding(
      padding: const EdgeInsets.only(top: SpacingTokens.l),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.m),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderTokens.circularMedium,
          border: Border.all(color: cardBorder, width: isDarkMode ? 1.5 : 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors, tr),
            const SizedBox(height: SpacingTokens.s),
            Text(
              tr.freeCancellationUpTo(deadlineHours),
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                fontWeight: TypographyTokens.semiBold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              tr.toCancelYourBooking,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            _buildCancellationStep(colors, tr.replyToConfirmationEmail),
            _buildCancellationStep(
              colors,
              tr.includeBookingReference(bookingReference),
            ),
            if (fromEmail != null)
              _buildCancellationStep(colors, tr.orEmailTo(fromEmail!)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic colors, WidgetTranslations tr) {
    return Row(
      children: [
        Icon(Icons.event_available, color: colors.textPrimary, size: 24),
        const SizedBox(width: SpacingTokens.s),
        Text(
          tr.cancellationPolicy,
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
