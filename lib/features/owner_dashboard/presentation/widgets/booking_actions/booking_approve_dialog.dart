import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import 'base_booking_dialog.dart';

/// Dialog for confirming booking approval
///
/// Returns `true` if user confirms, `false` or `null` if cancelled
class BookingApproveDialog extends StatelessWidget {
  const BookingApproveDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BaseBookingDialog(
      icon: Icons.check_circle,
      title: l10n.bookingApproveTitle,
      content: Text(
        l10n.bookingApproveMessage,
        style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
      ),
      cancelLabel: l10n.bookingApproveCancel,
      confirmLabel: l10n.bookingApproveConfirm,
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    );
  }
}
