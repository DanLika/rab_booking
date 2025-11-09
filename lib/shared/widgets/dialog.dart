import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/constants/app_dimensions.dart';
import 'button.dart';

/// Premium dialog component with animations and custom styling
/// Features: Multiple variants, animations, glass effects, responsive sizing
class PremiumDialog {
  /// Show confirmation dialog
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    IconData? icon,
    Color? iconColor,
    bool isDanger = false,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => _PremiumDialogWidget(
        title: title,
        content: Text(
          message,
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        icon: icon,
        iconColor: iconColor,
        actions: [
          PremiumButton.text(
            label: cancelText ?? 'Cancel',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(width: AppDimensions.spaceS),
          PremiumButton.primary(
            label: confirmText ?? 'Confirm',
            onPressed: () => Navigator.of(context).pop(true),
            backgroundColor: isDanger ? AppColors.error : null,
          ),
        ],
      ),
    );
  }

  /// Show alert dialog
  static Future<void> showAlert(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    IconData? icon,
    Color? iconColor,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (context) => _PremiumDialogWidget(
        title: title,
        content: Text(
          message,
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        icon: icon,
        iconColor: iconColor,
        actions: [
          PremiumButton.primary(
            label: buttonText ?? 'OK',
            onPressed: () => Navigator.of(context).pop(),
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  /// Show custom dialog
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    List<Widget>? actions,
    IconData? icon,
    Color? iconColor,
    bool barrierDismissible = true,
    double? width,
    double? height,
  }) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _PremiumDialogWidget(
        title: title,
        content: content,
        icon: icon,
        iconColor: iconColor,
        actions: actions,
        width: width,
        height: height,
      ),
    );
  }

  /// Show loading dialog
  static void showLoading(
    BuildContext context, {
    String? message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LoadingDialog(message: message),
    );
  }

  /// Hide loading dialog
  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// Internal premium dialog widget
class _PremiumDialogWidget extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final IconData? icon;
  final Color? iconColor;
  final double? width;
  final double? height;

  const _PremiumDialogWidget({
    required this.title,
    required this.content,
    this.actions,
    this.icon,
    this.iconColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppDimensions.spaceM),
      child: Container(
        width: width ?? AppDimensions.maxDialogWidth,
        height: height,
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.maxDialogWidth,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: AppShadows.elevation4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppDimensions.spaceL,
                  bottom: AppDimensions.spaceS,
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor?.withValues(alpha: 0.1) ??
                        AppColors.authPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: iconColor ?? AppColors.authPrimary,
                  ),
                ),
              ),

            // Title
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.spaceL,
                icon == null ? AppDimensions.spaceL : 0,
                AppDimensions.spaceL,
                AppDimensions.spaceS,
              ),
              child: Text(
                title,
                style: AppTypography.h3.copyWith(
                  fontWeight: AppTypography.weightBold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceL,
                ),
                child: content,
              ),
            ),

            // Actions
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceL),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: actions!.length == 1
                      ? actions!
                      : actions!
                          .expand((action) => [action, const SizedBox(width: AppDimensions.spaceS)])
                          .take(actions!.length * 2 - 1)
                          .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Internal loading dialog widget
class _LoadingDialog extends StatelessWidget {
  final String? message;

  const _LoadingDialog({this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: AppShadows.elevation3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.authPrimary),
            ),
            if (message != null) ...[
              const SizedBox(height: AppDimensions.spaceM),
              Text(
                message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
