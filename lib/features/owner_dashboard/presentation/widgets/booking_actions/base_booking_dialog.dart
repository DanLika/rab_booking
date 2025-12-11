import 'package:flutter/material.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';

/// Reusable base dialog for booking actions
///
/// Provides consistent header, content, and footer styling across all
/// booking action dialogs (approve, reject, cancel, complete).
///
/// Features:
/// - Gradient header with icon and title
/// - Scrollable content area
/// - Footer with cancel/confirm buttons
/// - Responsive sizing and padding
class BaseBookingDialog extends StatelessWidget {
  const BaseBookingDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.content,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.headerGradient,
    this.confirmButtonColor,
    this.maxWidth = 400,
  });

  /// Icon displayed in the header
  final IconData icon;

  /// Title text in the header
  final String title;

  /// Main content widget (scrollable)
  final Widget content;

  /// Label for the cancel button
  final String cancelLabel;

  /// Label for the confirm button
  final String confirmLabel;

  /// Callback when cancel is pressed
  final VoidCallback onCancel;

  /// Callback when confirm is pressed
  final VoidCallback onConfirm;

  /// Optional custom gradient for header (defaults to brandPrimary)
  final Gradient? headerGradient;

  /// Optional custom color for confirm button (defaults to primary)
  final Color? confirmButtonColor;

  /// Maximum width of the dialog
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogWidth = ResponsiveDialogUtils.getDialogWidth(
      context,
      maxWidth: maxWidth,
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
            color: context.gradients.sectionBorder.withAlpha(128),
          ),
          boxShadow: isDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, headerPadding),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(contentPadding),
                child: content,
              ),
            ),
            _buildFooter(context, contentPadding, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: headerGradient ?? context.gradients.brandPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, double padding, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF8F8FA),
        border: Border(
          top: BorderSide(
            color: context.gradients.sectionBorder.withAlpha(128),
          ),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: onCancel, child: Text(cancelLabel)),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: confirmButtonColor ?? theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}
