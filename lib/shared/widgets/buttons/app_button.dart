import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';

/// Base button widget with consistent styling
/// Provides standard button appearance and behavior across the app
abstract class AppButton extends StatelessWidget {
  const AppButton({
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.size = AppButtonSize.medium,
    super.key,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final AppButtonSize size;

  /// Get button height based on size
  double get height {
    switch (size) {
      case AppButtonSize.small:
        return AppDimensions.buttonHeightSmall;
      case AppButtonSize.medium:
        return AppDimensions.buttonHeight;
      case AppButtonSize.large:
        return AppDimensions.buttonHeightLarge;
    }
  }

  /// Get horizontal padding based on size
  double get horizontalPadding {
    switch (size) {
      case AppButtonSize.small:
        return AppDimensions.spaceS;
      case AppButtonSize.medium:
        return AppDimensions.spaceM;
      case AppButtonSize.large:
        return AppDimensions.spaceL;
    }
  }

  /// Get text style based on size
  TextStyle get textStyle {
    switch (size) {
      case AppButtonSize.small:
        return const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
      case AppButtonSize.medium:
        return const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
      case AppButtonSize.large:
        return const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
    }
  }

  /// Build button style - to be implemented by subclasses
  ButtonStyle buildStyle(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: AppDimensions.spaceXS),
                  Text(label),
                ],
              )
            : Text(label);

    final button = icon != null && !isLoading
        ? ElevatedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
            style: buildStyle(context),
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: buildStyle(context),
            child: child,
          );

    return isFullWidth
        ? SizedBox(
            width: double.infinity,
            child: button,
          )
        : button;
  }
}

/// Primary button - filled with primary color
class PrimaryButton extends AppButton {
  const PrimaryButton({
    required super.onPressed,
    required super.label,
    super.icon,
    super.isLoading,
    super.isFullWidth,
    super.size,
    super.key,
  });

  @override
  ButtonStyle buildStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.primary.withAlpha((0.5 * 255).toInt()),
      disabledForegroundColor: Colors.white.withAlpha((0.7 * 255).toInt()),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppDimensions.spaceS,
      ),
      minimumSize: Size(0, height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      elevation: AppDimensions.elevation2,
      textStyle: textStyle,
    );
  }
}

/// Secondary button - outlined with primary color
class SecondaryButton extends AppButton {
  const SecondaryButton({
    required super.onPressed,
    required super.label,
    super.icon,
    super.isLoading,
    super.isFullWidth,
    super.size,
    super.key,
  });

  @override
  ButtonStyle buildStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      disabledForegroundColor: AppColors.textDisabled,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppDimensions.spaceS,
      ),
      minimumSize: Size(0, height),
      side: const BorderSide(color: AppColors.primary, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      textStyle: textStyle,
    );
  }
}

/// Danger button - filled with error color
class DangerButton extends AppButton {
  const DangerButton({
    required super.onPressed,
    required super.label,
    super.icon,
    super.isLoading,
    super.isFullWidth,
    super.size,
    super.key,
  });

  @override
  ButtonStyle buildStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.error,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.error.withAlpha((0.5 * 255).toInt()),
      disabledForegroundColor: Colors.white.withAlpha((0.7 * 255).toInt()),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppDimensions.spaceS,
      ),
      minimumSize: Size(0, height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      elevation: AppDimensions.elevation2,
      textStyle: textStyle,
    );
  }
}

/// Text button - no background, just text
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.size = AppButtonSize.medium,
    super.key,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    return icon != null
        ? TextButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: _getTextStyle(),
            ),
          )
        : TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: _getTextStyle(),
            ),
            child: Text(label),
          );
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
      case AppButtonSize.medium:
        return const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
      case AppButtonSize.large:
        return const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
    }
  }
}

/// Button size options
enum AppButtonSize {
  small,
  medium,
  large,
}
