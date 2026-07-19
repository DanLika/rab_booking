import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design/tokens.dart';
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
    final (color, textColor, text, icon) = _getStatusInfo(tr);

    return Container(
      padding: const EdgeInsets.all(BBSpace.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BBRadius.mdAll,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: BBSpace.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.bookingStatus,
                  style: TextStyle(
                    fontSize: BBTypeBridges.fontSizeXS,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: BBTypeBridges.fontSizeL,
                    fontWeight: BBTypeBridges.weightBold,
                    color: textColor,
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
  // (fill for icon/tint/border, AA-safe text colour, label, icon) —
  // audit F3.1: the status label previously reused the fill as text.
  (Color, Color, String, IconData) _getStatusInfo(WidgetTranslations tr) =>
      switch (status.toLowerCase()) {
        'confirmed' || 'approved' => (
          colors.success,
          colors.successText,
          tr.statusConfirmed,
          Icons.check_circle,
        ),
        'pending' => (
          colors.warning,
          colors.warningText,
          tr.statusPending,
          Icons.schedule,
        ),
        'cancelled' => (
          colors.error,
          colors.error,
          tr.statusCancelled,
          Icons.cancel,
        ),
        _ => (colors.textSecondary, colors.textSecondary, status, Icons.info),
      };
}
