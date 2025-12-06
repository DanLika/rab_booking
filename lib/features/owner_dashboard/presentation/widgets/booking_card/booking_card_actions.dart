import 'package:flutter/material.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../l10n/app_localizations.dart';

/// Action buttons section for booking card
///
/// Displays context-appropriate action buttons based on booking status
/// - Pending: 2x2 grid (Approve, Reject, Details, Cancel)
/// - Others: Dynamic row/column layout (Details, Complete, Cancel)
///
/// Callbacks are required for each action
class BookingCardActions extends StatelessWidget {
  final BookingModel booking;
  final bool isMobile;
  final VoidCallback onShowDetails;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const BookingCardActions({
    super.key,
    required this.booking,
    required this.isMobile,
    required this.onShowDetails,
    this.onApprove,
    this.onReject,
    this.onComplete,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 16, 0, isMobile ? 12 : 16, isMobile ? 12 : 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final theme = Theme.of(context);

          // More granular responsive sizing based on available width
          final availableWidth = constraints.maxWidth;
          final isVeryNarrow = availableWidth < 350;
          final isNarrow = availableWidth < 450;
          final isActionMobile = availableWidth < 600;

          // Adjust button padding and size based on available width
          final horizontalPadding = isVeryNarrow ? 10.0 : (isNarrow ? 12.0 : (isActionMobile ? 14.0 : 16.0));
          final verticalPadding = isVeryNarrow ? 9.0 : (isNarrow ? 10.0 : (isActionMobile ? 11.0 : 13.0));
          final iconSize = isVeryNarrow ? 15.0 : 17.0;
          final fontSize = isVeryNarrow ? 12.0 : 14.0;

          // Define buttons
          final detailsBtn = OutlinedButton.icon(
            onPressed: onShowDetails,
            icon: Icon(
              Icons.visibility_outlined,
              size: iconSize,
              color: theme.brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
            ),
            label: Text(
              l10n.ownerBookingCardDetails,
              style: TextStyle(
                color: theme.brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
                fontSize: fontSize,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[50],
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide(color: theme.brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
          );

          final approveBtn = FilledButton.icon(
            onPressed: onApprove,
            icon: Icon(Icons.check_circle_outline, size: iconSize),
            label: Text(l10n.ownerBookingCardApprove, style: TextStyle(fontSize: fontSize)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF66BB6A), // Confirmed badge color
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          );

          final rejectBtn = FilledButton.icon(
            onPressed: onReject,
            icon: Icon(Icons.cancel_outlined, size: iconSize),
            label: Text(l10n.ownerBookingCardReject, style: TextStyle(fontSize: fontSize)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350), // Cancelled badge color
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          );

          final completeBtn = FilledButton.icon(
            onPressed: onComplete,
            icon: Icon(Icons.done_all_outlined, size: iconSize),
            label: Text(l10n.ownerBookingCardComplete, style: TextStyle(fontSize: fontSize)),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          );

          final cancelBtn = OutlinedButton.icon(
            onPressed: onCancel,
            icon: Icon(
              Icons.close,
              size: iconSize,
              color: theme.brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
            ),
            label: Text(
              l10n.ownerBookingCardCancel,
              style: TextStyle(
                color: theme.brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
                fontSize: fontSize,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[50],
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide(color: theme.brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
          );

          // Custom layout for Pending status (2x2 grid)
          if (booking.status == BookingStatus.pending) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: approveBtn),
                    const SizedBox(width: 8),
                    Expanded(child: rejectBtn),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: detailsBtn),
                    const SizedBox(width: 8),
                    Expanded(child: cancelBtn),
                  ],
                ),
              ],
            );
          }

          // Default layout for other statuses
          final actionButtons = <Widget>[];

          // Always show details
          actionButtons.add(detailsBtn);

          // Mark as Completed button (only for confirmed and past check-out)
          if (booking.status == BookingStatus.confirmed && booking.isPast && onComplete != null) {
            actionButtons.add(completeBtn);
          }

          // Cancel button (only if cancellable and not pending - pending handled above)
          if (booking.canBeCancelled && booking.status != BookingStatus.pending && onCancel != null) {
            actionButtons.add(cancelBtn);
          }

          if (actionButtons.isEmpty) return const SizedBox.shrink();

          // Responsive layout:
          // 1 button: Full width
          // 2 buttons: Row with Expanded
          // >2 buttons: Column (fallback)
          if (actionButtons.length == 1) {
            return SizedBox(width: double.infinity, child: actionButtons.first);
          }

          if (actionButtons.length == 2) {
            return Row(
              children: [
                Expanded(child: actionButtons[0]),
                const SizedBox(width: 8),
                Expanded(child: actionButtons[1]),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: actionButtons
                .map((btn) => Padding(padding: const EdgeInsets.only(bottom: 8), child: btn))
                .toList(),
          );
        },
      ),
    );
  }
}
