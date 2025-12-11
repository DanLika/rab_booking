import 'package:flutter/material.dart';
import '../../../../../../../../shared/models/booking_model.dart';
import '../../../../../../../../l10n/app_localizations.dart';
import '../../../../../../../../core/theme/app_colors.dart';

/// Notes/special requests section for booking card
///
/// Displays booking notes with note icon (conditional - only if notes exist)
class BookingCardNotes extends StatelessWidget {
  final BookingModel booking;
  final bool isMobile;

  const BookingCardNotes({super.key, required this.booking, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    // Don't render if no notes
    if (booking.notes == null || booking.notes!.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Divider(
          height: isMobile ? 16 : 24,
          color: isDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.note_outlined, size: 20, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label
                  Text(
                    l10n.ownerBookingCardNotes,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Notes text
                  Text(
                    booking.notes!,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
