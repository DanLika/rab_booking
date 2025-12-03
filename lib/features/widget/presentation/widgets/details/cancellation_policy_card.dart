import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

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
/// )
/// ```
class CancellationPolicyCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final checkInDate = DateTime.parse(checkIn);
    final now = DateTime.now();
    final hoursUntilCheckIn = checkInDate.difference(now).inHours;
    final canCancel = hoursUntilCheckIn >= deadlineHours;

    final statusColor = canCancel ? colors.success : colors.warning;

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
              Icon(
                canCancel ? Icons.event_available : Icons.event_busy,
                size: 20,
                color: statusColor,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Cancellation Policy',
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
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canCancel
                      ? '✓ Free cancellation available'
                      : '✗ Cancellation deadline passed',
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeS,
                    fontWeight: TypographyTokens.semiBold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  'You can cancel free of charge up to $deadlineHours hours before check-in.',
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeS,
                    color: colors.textSecondary,
                  ),
                ),
                if (!canCancel) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    'The cancellation deadline has passed. Please contact the property owner if you need to cancel.',
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
