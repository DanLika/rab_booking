import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';

/// Dialog for confirming booking completion
///
/// Returns `true` if user confirms, `false` or `null` if cancelled
class BookingCompleteDialog extends StatelessWidget {
  const BookingCompleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final dialogWidth = ResponsiveDialogUtils.getDialogWidth(
      context,
      maxWidth: 400,
    );
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
            // Gradient Header
            Container(
              padding: EdgeInsets.all(headerPadding),
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.task_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.bookingCompleteDialogTitle,
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
            Padding(
              padding: EdgeInsets.all(contentPadding),
              child: Text(
                l10n.bookingCompleteDialogMessage,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: contentPadding,
                vertical: 12,
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
                  bottom: Radius.circular(11),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.bookingCompleteDialogCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(l10n.bookingCompleteDialogConfirm),
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
