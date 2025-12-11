import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import 'base_booking_dialog.dart';

/// Dialog for confirming booking completion
///
/// Returns `true` if user confirms, `false` or `null` if cancelled
class BookingCompleteDialog extends StatelessWidget {
  const BookingCompleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BaseBookingDialog(
      icon: Icons.task_alt,
      title: l10n.bookingCompleteDialogTitle,
      content: Text(
        l10n.bookingCompleteDialogMessage,
        style: TextStyle(
          fontSize: 15,
          color: theme.colorScheme.onSurface,
        ),
      ),
      cancelLabel: l10n.bookingCompleteDialogCancel,
      confirmLabel: l10n.bookingCompleteDialogConfirm,
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    );
  }
}
