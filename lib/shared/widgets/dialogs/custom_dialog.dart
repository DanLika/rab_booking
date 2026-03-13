import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/utils/responsive_dialog_utils.dart';
import '../../../core/theme/theme_extensions.dart';

/// Standardized custom dialog for the BookBed application.
/// Follows the design system requirements:
/// - Footer: AppColors.dialogFooterDark/Light with border: AppColors.sectionDividerDark/Light
/// - Padding: 12px mobile (<400px), 16-20px desktop
/// - Border radius: 11-12px
/// - Shadows: AppShadows.elevation4Dark/elevation4
class CustomDialog extends StatelessWidget {
  final Widget? title;
  final Widget content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;

  const CustomDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use responsive padding if not explicitly provided
    final padding =
        contentPadding ??
        EdgeInsets.all(ResponsiveDialogUtils.getContentPadding(context));

    // Footer decoration
    final footerDecoration = BoxDecoration(
      color: isDark ? AppColors.dialogFooterDark : AppColors.dialogFooterLight,
      border: Border(
        top: BorderSide(
          color: isDark
              ? AppColors.sectionDividerDark
              : AppColors.sectionDividerLight,
        ),
      ),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0, // We use custom container shadow instead
      backgroundColor:
          Colors.transparent, // Background handled by inner Container
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveDialogUtils.getDialogWidth(context),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isDark
                ? AppShadows.elevation4Dark
                : AppShadows.elevation4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title section
              if (title != null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    top: 20,
                    right: 20,
                    bottom: 8,
                  ),
                  child: DefaultTextStyle(
                    style: theme.textTheme.titleLarge!,
                    child: title!,
                  ),
                ),

              // Content section
              Flexible(
                child: SingleChildScrollView(
                  padding: title != null
                      ? padding
                            .resolve(Directionality.of(context))
                            .copyWith(top: 8)
                      : padding,
                  child: content,
                ),
              ),

              // Actions section (Footer)
              if (actions != null && actions!.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveDialogUtils.getContentPadding(
                      context,
                    ),
                    vertical: 12,
                  ),
                  decoration: footerDecoration,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!.map((action) {
                      // Add spacing between actions
                      final index = actions!.indexOf(action);
                      if (index > 0) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: action,
                        );
                      }
                      return action;
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
