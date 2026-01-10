import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';

class DialogFooter extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final String saveLabel;
  final String? cancelLabel;
  final bool isLoading;
  final List<Widget>? leadingActions;

  const DialogFooter({
    super.key,
    this.onCancel,
    this.onSave,
    required this.saveLabel,
    this.cancelLabel,
    this.isLoading = false,
    this.leadingActions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final contentPadding = ResponsiveDialogUtils.getContentPadding(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: contentPadding, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.dialogFooterDark
            : AppColors.dialogFooterLight,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.sectionDividerDark
                : AppColors.sectionDividerLight,
          ),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (leadingActions != null) ...leadingActions!,
          if (leadingActions != null) const Spacer(),

          Flexible(
            child: TextButton(
              onPressed: isLoading
                  ? null
                  : (onCancel ?? () => Navigator.of(context).pop()),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                minimumSize: Size.zero,
              ),
              child: Text(
                cancelLabel ??
                    'Cancel', // Should be localized by caller usually, but fallback provided
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading ? null : onSave,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            saveLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
