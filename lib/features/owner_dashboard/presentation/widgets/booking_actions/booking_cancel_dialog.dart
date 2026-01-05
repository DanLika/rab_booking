import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/input_decoration_helper.dart';
import 'base_booking_dialog.dart';

/// Dialog for cancelling a booking with reason and email option
///
/// Returns `Map<String, dynamic>?` with:
/// - `'reason'`: String - cancellation reason (required)
/// - `'sendEmail'`: bool - whether to send email to guest
///
/// Returns `null` if user cancels the action
class BookingCancelDialog extends StatefulWidget {
  const BookingCancelDialog({super.key});

  @override
  State<BookingCancelDialog> createState() => _BookingCancelDialogState();
}

class _BookingCancelDialogState extends State<BookingCancelDialog> {
  final _reasonController = TextEditingController();
  bool _sendEmail = true;

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
      icon: Icons.cancel_outlined,
      title: l10n.bookingCancelTitle,
      maxWidth: 450,
      headerGradient: LinearGradient(
        colors: [
          theme.colorScheme.error,
          theme.colorScheme.error.withAlpha(204),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      confirmButtonColor: theme.colorScheme.error,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning message
          Text(
            l10n.bookingCancelMessage,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Reason input
          TextField(
            controller: _reasonController,
            decoration: InputDecorationHelper.buildDecoration(
              labelText: l10n.bookingCancelReason,
              hintText: l10n.bookingCancelReasonHint,
              prefixIcon: const Icon(Icons.edit_note),
              context: context,
            ),
            maxLines: 3,
            autofocus: true,
          ),

          const SizedBox(height: 16),

          // Send email checkbox
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.primary.withAlpha(51),
              ),
            ),
            child: CheckboxListTile(
              title: Text(
                l10n.bookingCancelSendEmail,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                l10n.bookingCancelSendEmailHint,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: _sendEmail,
              onChanged: (value) => setState(() => _sendEmail = value ?? true),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
        ],
      ),
      cancelLabel: l10n.bookingCancelCancel,
      confirmLabel: l10n.bookingCancelConfirm,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: () {
        Navigator.of(context).pop({
          'reason': _reasonController.text.trim().isEmpty
              ? l10n.bookingCancelDefaultReason
              : _reasonController.text.trim(),
          'sendEmail': _sendEmail,
        });
      },
    );
  }
}
