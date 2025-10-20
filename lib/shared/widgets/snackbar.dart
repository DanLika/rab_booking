import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_dimensions.dart';

/// Premium snackbar component with animations and custom styling
/// Features: Multiple variants, icons, actions, custom styling
class PremiumSnackbar {
  /// Show success snackbar
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      variant: SnackbarVariant.success,
    );
  }

  /// Show error snackbar
  static void showError(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      variant: SnackbarVariant.error,
    );
  }

  /// Show warning snackbar
  static void showWarning(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      variant: SnackbarVariant.warning,
    );
  }

  /// Show info snackbar
  static void showInfo(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      variant: SnackbarVariant.info,
    );
  }

  /// Show custom snackbar
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    SnackbarVariant variant = SnackbarVariant.info,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
  }) {
    _show(
      context,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      variant: variant,
      backgroundColor: backgroundColor,
      textColor: textColor,
      icon: icon,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    required Duration duration,
    required SnackbarVariant variant,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _getVariantConfig(variant, isDark);

    final snackBar = SnackBar(
      content: Row(
        children: [
          if (icon != null || config.icon != null)
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.spaceS),
              child: Icon(
                icon ?? config.icon,
                color: textColor ?? config.textColor,
                size: AppDimensions.iconM,
              ),
            ),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: textColor ?? config.textColor,
                fontWeight: AppTypography.weightMedium,
              ),
            ),
          ),
        ],
      ),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: textColor ?? config.textColor,
              onPressed: onAction ?? () {},
            )
          : null,
      backgroundColor: backgroundColor ?? config.backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      margin: const EdgeInsets.all(AppDimensions.spaceS),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceS,
        vertical: AppDimensions.spaceS,
      ),
      duration: duration,
      elevation: 0,
      dismissDirection: DismissDirection.horizontal,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static _SnackbarConfig _getVariantConfig(SnackbarVariant variant, bool isDark) {
    switch (variant) {
      case SnackbarVariant.success:
        return const _SnackbarConfig(
          backgroundColor: AppColors.success,
          textColor: Colors.white,
          icon: Icons.check_circle_outline,
        );
      case SnackbarVariant.error:
        return const _SnackbarConfig(
          backgroundColor: AppColors.error,
          textColor: Colors.white,
          icon: Icons.error_outline,
        );
      case SnackbarVariant.warning:
        return const _SnackbarConfig(
          backgroundColor: AppColors.warning,
          textColor: AppColors.textPrimaryDark,
          icon: Icons.warning_amber_outlined,
        );
      case SnackbarVariant.info:
        return const _SnackbarConfig(
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
          icon: Icons.info_outline,
        );
    }
  }
}

/// Snackbar variant enum
enum SnackbarVariant {
  success,
  error,
  warning,
  info,
}

/// Internal snackbar configuration
class _SnackbarConfig {
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const _SnackbarConfig({
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });
}
