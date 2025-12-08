import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/utils/date_time_parser.dart';
import '../../l10n/widget_translations.dart';

/// Card displaying cancellation policy information.
///
/// Shows whether booking can still be cancelled and deadline info.
///
/// Usage:
/// ```dart
/// CancellationPolicyCard(
///   deadlineHours: 48,
///   checkIn: '2024-01-15',
///   colors: ColorTokens.light,
///   translations: WidgetTranslations.of(context, ref),
/// )
/// ```
class CancellationPolicyCard extends StatelessWidget {
  /// Hours before check-in when cancellation is no longer allowed
  final int deadlineHours;

  /// Check-in date string (ISO format)
  final String checkIn;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  /// Translations for localization
  final WidgetTranslations translations;

  const CancellationPolicyCard({
    super.key,
    required this.deadlineHours,
    required this.checkIn,
    required this.colors,
    required this.translations,
  });

  @override
  Widget build(BuildContext context) {
    final checkInDate = DateTimeParser.parseOrThrow(checkIn, context: 'CancellationPolicyCard.checkIn');
    final now = DateTime.now();
    final hoursUntilCheckIn = checkInDate.difference(now).inHours;
    final canCancel = hoursUntilCheckIn >= deadlineHours;

    final statusColor = canCancel ? colors.success : colors.warning;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(canCancel ? Icons.event_available : Icons.event_busy, size: 20, color: statusColor),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                translations.cancellationPolicy,
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeM,
                  fontWeight: TypographyTokens.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.s),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderTokens.circularSmall,
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canCancel ? translations.freeCancellationAvailable : translations.cancellationDeadlinePassedShort,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeS,
                    fontWeight: TypographyTokens.semiBold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  translations.canCancelUpToHours(deadlineHours),
                  style: TextStyle(fontSize: TypographyTokens.fontSizeS, color: colors.textSecondary),
                ),
                if (!canCancel) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    translations.cancellationDeadlinePassedContactOwner,
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeS,
                      color: colors.warning,
                      fontWeight: TypographyTokens.medium,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
