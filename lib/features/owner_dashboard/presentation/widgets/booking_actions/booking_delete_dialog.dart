import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import 'base_booking_dialog.dart';

/// Dialog for confirming booking deletion
///
/// Returns `true` if user confirms, `false` or `null` if cancelled
class BookingDeleteDialog extends StatelessWidget {
  final String guestName;

  const BookingDeleteDialog({super.key, required this.guestName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BaseBookingDialog(
      icon: Icons.delete_outline,
      title: l10n.calendarActionsDeleteTitle,
      content: Text(
        l10n.calendarActionsDeleteConfirm(guestName),
        style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
      ),
      cancelLabel: l10n.calendarActionsCancel,
      confirmLabel: l10n.calendarActionsDelete,
      confirmButtonColor: AppColors.error,
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    );
  }
}
