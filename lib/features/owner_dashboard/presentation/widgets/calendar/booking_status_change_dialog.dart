import 'package:flutter/material.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/constants/booking_status_extensions.dart';
import '../../../../../core/utils/responsive_spacing_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/gradient_extensions.dart';

/// Reusable dialog for changing booking status
///
/// Displays all available [BookingStatus] options with visual indicators
/// for the current status. Returns selected status or null on cancel.
///
/// Usage:
/// ```dart
/// final newStatus = await showDialog<BookingStatus>(
///   context: context,
///   builder: (context) => BookingStatusChangeDialog(booking: booking),
/// );
/// ```
class BookingStatusChangeDialog extends StatelessWidget {
  /// The booking whose status may be changed
  final BookingModel booking;

  const BookingStatusChangeDialog({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Constrain dialog height for landscape mode on phones
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight =
        screenHeight *
        ResponsiveSpacingHelper.getDialogMaxHeightPercent(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 320,
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        decoration: BoxDecoration(
          gradient: context.gradients.sectionBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.gradients.sectionBorder.withAlpha(
              (0.5 * 255).toInt(),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient (includes close button)
            _buildHeader(context, l10n, theme),

            // Status options list (scrollable for small screens)
            Flexible(child: _buildStatusOptions(context, l10n, theme)),
          ],
        ),
      ),
    );
  }

  /// Gradient header with icon and title
  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: context.gradients.brandPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.ownerCalendarChangeStatus,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// List of all status options with colored indicators (scrollable)
  Widget _buildStatusOptions(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: BookingStatus.values.map((status) {
          final isCurrentStatus = status == booking.status;
          return ListTile(
            title: Text(
              status.displayNameLocalized(context),
              style: TextStyle(
                fontWeight: isCurrentStatus
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
                border: isCurrentStatus
                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                    : null,
              ),
              child: isCurrentStatus
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            trailing: isCurrentStatus
                ? Text(
                    l10n.calendarStatusCurrent,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : null,
            onTap: isCurrentStatus
                ? null
                : () => Navigator.of(context).pop(status),
          );
        }).toList(),
      ),
    );
  }
}
