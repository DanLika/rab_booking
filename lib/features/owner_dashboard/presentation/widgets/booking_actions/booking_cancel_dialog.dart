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
    final dialogWidth = ResponsiveDialogUtils.getDialogWidth(
      context,
      maxWidth: 450,
    );
    final contentPadding = ResponsiveDialogUtils.getContentPadding(context);
    final headerPadding = ResponsiveDialogUtils.getHeaderPadding(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(context),
      child: Container(
        width: dialogWidth,
        decoration: BoxDecoration(
          gradient: context.gradients.sectionBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.gradients.sectionBorder.withAlpha(
              (0.5 * 255).toInt(),
            ),
          ),
          boxShadow: isDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient Header with error color
            Container(
              padding: EdgeInsets.all(headerPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.error,
                    theme.colorScheme.error.withAlpha((0.8 * 255).toInt()),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.bookingCancelTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

                    // Send email checkbox with better styling
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(
                          (0.08 * 255).toInt(),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(
                            (0.2 * 255).toInt(),
                          ),
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
                        onChanged: (value) {
                          setState(() {
                            _sendEmail = value ?? true;
                          });
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: contentPadding,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E2A)
                    : const Color(0xFFF8F8FA),
                border: Border(
                  top: BorderSide(
                    color: context.gradients.sectionBorder.withAlpha(
                      (0.5 * 255).toInt(),
                    ),
                  ),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(l10n.bookingCancelCancel),
                  ),
                  const SizedBox(width: 12),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
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
