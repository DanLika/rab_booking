import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design/tokens.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import 'widget_card_decoration.dart';
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
    // Bug #64 Fix: Use UTC consistently for timezone-safe comparison
    // Cloud Function returns ISO 8601 string in UTC format (with 'Z' suffix)
    // DateTime.parse() preserves timezone, so checkInDate might already be UTC
    // Normalize to UTC to be safe (handles edge cases where string might not have 'Z')
    final checkInUtc = checkInDate.isUtc ? checkInDate : checkInDate.toUtc();
    // Use UTC for current time to ensure consistent comparison
    final nowUtc = DateTime.now().toUtc();
    final hoursUntilCheckIn = checkInUtc.difference(nowUtc).inHours;
    final canCancel = hoursUntilCheckIn >= deadlineHours;
    final statusColor = canCancel ? colors.success : colors.warning;

    // Detect dark mode for better contrast
    final isDark = colors.backgroundPrimary.computeLuminance() < 0.5;
    return Container(
      padding: const EdgeInsets.all(BBSpace.sm),
      decoration: premiumWidgetCardDecoration(colors: colors, isDark: isDark),
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
              const SizedBox(width: BBSpace.xxs),
              Text(
                tr.cancellationPolicy,
                style: TextStyle(
                  fontSize: BBTypeBridges.fontSizeM,
                  fontWeight: BBTypeBridges.weightBold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpace.xs),
          Container(
            padding: const EdgeInsets.all(BBSpace.xs),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BBRadius.xsAll,
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
                    fontSize: BBTypeBridges.fontSizeS,
                    fontWeight: BBTypeBridges.weightSemiBold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: BBSpace.xxs),
                Text(
                  _formatCancellationDeadline(deadlineHours, tr),
                  style: TextStyle(
                    fontSize: BBTypeBridges.fontSizeS,
                    color: colors.textSecondary,
                  ),
                ),
                if (!canCancel) ...[
                  const SizedBox(height: BBSpace.xxs),
                  Text(
                    tr.cancellationDeadlinePassedContactOwner,
                    style: TextStyle(
                      fontSize: BBTypeBridges.fontSizeS,
                      color: colors.warning,
                      fontWeight: BBTypeBridges.weightMedium,
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
      // Bug #68 Fix: Use integer division for better precision
      // Avoid floating point precision issues by using integer arithmetic
      final days = hours ~/ 24; // Integer division
      final remainingHours = hours % 24;
      // Round up if more than half a day (12 hours)
      final roundedDays = remainingHours >= 12 ? days + 1 : days;
      return tr.canCancelUpToDays(roundedDays);
    }

    // Otherwise show in hours
    return tr.canCancelUpToHours(hours);
  }
}
