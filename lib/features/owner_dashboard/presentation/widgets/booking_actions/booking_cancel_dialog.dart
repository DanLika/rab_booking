import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final dialogWidth = ResponsiveDialogUtils.getDialogWidth(context, maxWidth: 450);
    final contentPadding = ResponsiveDialogUtils.getContentPadding(context);
    final headerPadding = ResponsiveDialogUtils.getHeaderPadding(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(context),
      child: Container(
        width: dialogWidth,
        decoration: BoxDecoration(
          gradient: context.gradients.sectionBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
          boxShadow: isDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient Header
            Container(
              padding: EdgeInsets.all(headerPadding),
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
                    child: const Icon(Icons.cancel_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.bookingCancelTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.bookingCancelMessage, style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reasonController,
                      decoration: InputDecorationHelper.buildDecoration(
                        labelText: l10n.bookingCancelReason,
                        hintText: l10n.bookingCancelReasonHint,
                        prefixIcon: const Icon(Icons.edit_note),
                        context: context,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: Text(l10n.bookingCancelSendEmail, style: TextStyle(color: theme.colorScheme.onSurface)),
                      value: _sendEmail,
                      onChanged: (value) {
                        setState(() {
                          _sendEmail = value ?? true;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.symmetric(horizontal: contentPadding, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF8F8FA),
                border: Border(top: BorderSide(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt()))),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.bookingCancelCancel)),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        'reason': _reasonController.text.trim().isEmpty
                            ? l10n.bookingCancelDefaultReason
                            : _reasonController.text.trim(),
                        'sendEmail': _sendEmail,
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(l10n.bookingCancelConfirm),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
