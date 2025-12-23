import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/input_decoration_helper.dart';
import 'base_booking_dialog.dart';

/// Dialog for rejecting a booking with optional reason
///
/// Returns rejection reason `String?` if user confirms, `null` if cancelled
class BookingRejectDialog extends StatefulWidget {
  const BookingRejectDialog({super.key});

  @override
  State<BookingRejectDialog> createState() => _BookingRejectDialogState();
}

class _BookingRejectDialogState extends State<BookingRejectDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BaseBookingDialog(
      icon: Icons.cancel,
      title: l10n.bookingRejectTitle,
      maxWidth: 450,
      confirmButtonColor: theme.colorScheme.error,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bookingRejectMessage,
            style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            decoration: InputDecorationHelper.buildDecoration(
              labelText: l10n.bookingRejectReason,
              hintText: l10n.bookingRejectReasonHint,
              prefixIcon: const Icon(Icons.edit_note),
              context: context,
            ),
            maxLines: 3,
          ),
        ],
      ),
      cancelLabel: l10n.bookingRejectCancel,
      confirmLabel: l10n.bookingRejectConfirm,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: () => Navigator.of(context).pop(_reasonController.text.trim()),
    );
  }
}
