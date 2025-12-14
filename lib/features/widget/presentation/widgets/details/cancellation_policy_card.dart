import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/utils/date_time_parser.dart';
import '../../l10n/widget_translations.dart';

/// Card displaying cancellation policy information.
///
/// Shows whether booking can still be cancelled and deadline info.
class CancellationPolicyCard extends ConsumerWidget {
  /// Hours before check-in when cancellation is no longer allowed
  final int deadlineHours;

  /// Check-in date string (ISO format)
  final String checkIn;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const CancellationPolicyCard({
    super.key,
    required this.deadlineHours,
    required this.checkIn,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = WidgetTranslations.of(context, ref);
    final checkInDate = DateTimeParser.parseOrThrow(
      checkIn,
      context: 'CancellationPolicyCard.checkIn',
    );
    final hoursUntilCheckIn = checkInDate.difference(DateTime.now()).inHours;
    final canCancel = hoursUntilCheckIn >= deadlineHours;
    final statusColor = canCancel ? colors.success : colors.warning;

    // Detect dark mode for better contrast
    final isDark = colors.backgroundPrimary.computeLuminance() < 0.5;
    final cardBackground = isDark
        ? colors.backgroundTertiary
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                canCancel ? Icons.event_available : Icons.event_busy,
                size: 20,
                color: statusColor,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                tr.cancellationPolicy,
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
                  canCancel
                      ? tr.freeCancellationAvailable
                      : tr.cancellationDeadlinePassedShort,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeS,
                    fontWeight: TypographyTokens.semiBold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  _formatCancellationDeadline(deadlineHours, tr),
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeS,
                    color: colors.textSecondary,
                  ),
                ),
                if (!canCancel) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    tr.cancellationDeadlinePassedContactOwner,
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

  /// Format cancellation deadline - show in days if >= 24 hours, otherwise in hours
  String _formatCancellationDeadline(int hours, WidgetTranslations tr) {
    // If deadline is 24 hours or more, show in days
    if (hours >= 24) {
      final days = (hours / 24).round();
      return tr.canCancelUpToDays(days);
    }
    
    // Otherwise show in hours
    return tr.canCancelUpToHours(hours);
  }
}
