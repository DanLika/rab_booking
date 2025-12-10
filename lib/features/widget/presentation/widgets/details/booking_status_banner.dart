import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../l10n/widget_translations.dart';

/// Banner displaying booking status with appropriate color and icon.
///
/// Shows status (Confirmed, Pending, Cancelled) with visual styling.
/// Used at the top of booking details screen.
class BookingStatusBanner extends ConsumerWidget {
  /// Booking status string (confirmed, pending, cancelled, approved)
  final String status;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const BookingStatusBanner({
    super.key,
    required this.status,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = WidgetTranslations.of(context, ref);
    final (color, text, icon) = _getStatusInfo(tr);

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: SpacingTokens.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.bookingStatus,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeXS,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeL,
                    fontWeight: TypographyTokens.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Returns (color, text, icon) for the current status.
  (Color, String, IconData) _getStatusInfo(WidgetTranslations tr) =>
      switch (status.toLowerCase()) {
        'confirmed' ||
        'approved' => (colors.success, tr.statusConfirmed, Icons.check_circle),
        'pending' => (colors.warning, tr.statusPending, Icons.schedule),
        'cancelled' => (colors.error, tr.statusCancelled, Icons.cancel),
        _ => (colors.textSecondary, status, Icons.info),
      };
}
