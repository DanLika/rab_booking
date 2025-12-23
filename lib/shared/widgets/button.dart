import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_animations.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/haptic_service.dart';

/// Premium button component with multiple variants and states
/// Supports: Primary, Secondary, Outline, Text, Icon buttons
/// Features: Gradient backgrounds, shadows, loading states, hover effects
class PremiumButton extends StatefulWidget {
  /// Button label text
  final String? label;

  /// Button icon (optional)
  final IconData? icon;

  /// Icon position (left or right of label)
  final IconPosition iconPosition;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Button variant style
  final ButtonVariant variant;

  /// Button size
  final ButtonSize size;

  /// Loading state
  final bool isLoading;

  /// Full width button
  final bool isFullWidth;

  /// Custom background color (overrides variant color)
  final Color? backgroundColor;

  /// Custom text color (overrides variant color)
  final Color? textColor;

  const PremiumButton({
    super.key,
    this.label,
    this.icon,
    this.iconPosition = IconPosition.left,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.textColor,
  }) : assert(
         label != null || icon != null,
         'Either label or icon must be provided',
       );

  /// Primary button (gradient background)
  factory PremiumButton.primary({
    String? label,
    IconData? icon,
    IconPosition iconPosition = IconPosition.left,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = false,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return PremiumButton(
      label: label,
      icon: icon,
      iconPosition: iconPosition,
      onPressed: onPressed,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  /// Secondary button (gold gradient background)
  factory PremiumButton.secondary({
    String? label,
    IconData? icon,
    IconPosition iconPosition = IconPosition.left,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return PremiumButton(
      label: label,
      icon: icon,
      iconPosition: iconPosition,
      onPressed: onPressed,
      variant: ButtonVariant.secondary,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  /// Outline button (transparent with border)
  factory PremiumButton.outline({
    String? label,
    IconData? icon,
    IconPosition iconPosition = IconPosition.left,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return PremiumButton(
      label: label,
      icon: icon,
      iconPosition: iconPosition,
      onPressed: onPressed,
      variant: ButtonVariant.outline,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  /// Text button (no background, just text)
  factory PremiumButton.text({
    String? label,
    IconData? icon,
    IconPosition iconPosition = IconPosition.left,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return PremiumButton(
      label: label,
      icon: icon,
      iconPosition: iconPosition,
      onPressed: onPressed,
      variant: ButtonVariant.text,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  /// Icon button (circular, icon only)
  factory PremiumButton.icon({
    required IconData icon,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    ButtonVariant variant = ButtonVariant.primary,
  }) {
    return PremiumButton(
      icon: icon,
      onPressed: onPressed,
      variant: variant,
      size: size,
      isLoading: isLoading,
    );
  }

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final buttonConfig = _getButtonConfig();
    final bool isIconOnly = widget.label == null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed && !_isDisabled ? 0.95 : 1.0,
          duration: AppAnimations.buttonPress.duration,
          curve: AppAnimations.buttonPress.curve,
          child: AnimatedContainer(
            duration: AppAnimations.hover.duration,
            curve: AppAnimations.hover.curve,
            height: buttonConfig.height,
            width: widget.isFullWidth
                ? double.infinity
                : isIconOnly
                ? buttonConfig.height
                : null,
            decoration: _buildDecoration(buttonConfig),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isDisabled
                    ? null
                    : () async {
                        // Haptic feedback
                        await HapticService.buttonPress();
                        // Execute callback
                        widget.onPressed?.call();
                      },
                borderRadius: BorderRadius.circular(() {
                  if (isIconOnly) {
                    // For icon-only buttons, use half of height (pill shape)
                    // Ensure height is valid and finite
                    final height = buttonConfig.height;
                    if (height.isFinite && height > 0) {
                      return height / 2;
                    }
                    // Fallback to default radius if height is invalid
                    return AppDimensions.radiusL;
                  }
                  return AppDimensions.radiusL;
                }()),
                child: Container(
                  padding: _getPadding(isIconOnly, buttonConfig),
                  child: _buildContent(buttonConfig),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(_ButtonConfig config) {
    // Defensive check: ensure height is valid before calculating borderRadius
    double borderRadius;
    if (widget.label == null) {
      // For icon-only buttons, use half of height (pill shape)
      // Ensure height is valid and finite
      final height = config.height;
      if (height.isFinite && height > 0) {
        borderRadius = height / 2;
      } else {
        // Fallback to default radius if height is invalid
        borderRadius = AppDimensions.radiusL;
      }
    } else {
      borderRadius = AppDimensions.radiusL;
    }

    // Ensure borderRadius is valid (finite and non-negative)
    if (!borderRadius.isFinite || borderRadius < 0) {
      borderRadius = AppDimensions.radiusL;
    }

    if (_isDisabled) {
      return BoxDecoration(
        color: AppColors.disabled,
        borderRadius: BorderRadius.circular(borderRadius),
        border: widget.variant == ButtonVariant.outline
            ? Border.all(color: AppColors.borderLight, width: 1.5)
            : null,
      );
    }

    return BoxDecoration(
      gradient: config.gradient,
      color: config.backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: config.borderColor != null
          ? Border.all(color: config.borderColor!, width: 1.5)
          : null,
      boxShadow: _isHovered && config.shadow != null
          ? config.shadow
          : widget.variant == ButtonVariant.primary ||
                widget.variant == ButtonVariant.secondary
          ? AppShadows.elevation1
          : null,
    );
  }

  EdgeInsets _getPadding(bool isIconOnly, _ButtonConfig config) {
    if (isIconOnly) {
      return EdgeInsets.zero;
    }

    final horizontalPadding = config.horizontalPadding;
    return EdgeInsets.symmetric(horizontal: horizontalPadding);
  }

  Widget _buildContent(_ButtonConfig config) {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: config.iconSize,
          height: config.iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(config.textColor),
          ),
        ),
      );
    }

    if (widget.label == null) {
      // Icon only button
      return Center(
        child: Icon(
          widget.icon,
          size: config.iconSize,
          color: _isDisabled ? AppColors.textDisabled : config.textColor,
        ),
      );
    }

    // Button with label (and optional icon)
    final textWidget = Text(
      widget.label!,
      style: config.textStyle.copyWith(
        color: _isDisabled ? AppColors.textDisabled : config.textColor,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    if (widget.icon == null) {
      return Center(child: textWidget);
    }

    // Button with label and icon
    final iconWidget = Icon(
      widget.icon,
      size: config.iconSize,
      color: _isDisabled ? AppColors.textDisabled : config.textColor,
    );

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.iconPosition == IconPosition.left
            ? [
                iconWidget,
                SizedBox(width: config.iconSpacing),
                Flexible(child: textWidget),
              ]
            : [
                Flexible(child: textWidget),
                SizedBox(width: config.iconSpacing),
                iconWidget,
              ],
      ),
    );
  }

  _ButtonConfig _getButtonConfig() {
    // Size configurations
    final double height;
    final double horizontalPadding;
    final double iconSize;
    final double iconSpacing;
    final TextStyle textStyle;

    switch (widget.size) {
      case ButtonSize.small:
        height = AppDimensions.buttonHeightSmall;
        horizontalPadding = AppDimensions.spaceS;
        iconSize = AppDimensions.iconS;
        iconSpacing = AppDimensions.spaceXXS;
        textStyle = AppTypography.small.copyWith(
          fontWeight: AppTypography.weightSemibold,
        );
        break;
      case ButtonSize.medium:
        height = AppDimensions.buttonHeight;
        horizontalPadding = AppDimensions.spaceM;
        iconSize = AppDimensions.iconM;
        iconSpacing = AppDimensions.spaceXS;
        textStyle = AppTypography.bodyMedium.copyWith(
          fontWeight: AppTypography.weightSemibold,
        );
        break;
      case ButtonSize.large:
        height = AppDimensions.buttonHeightLarge;
        horizontalPadding = AppDimensions.spaceL;
        iconSize = AppDimensions.iconL;
        iconSpacing = AppDimensions.spaceXS;
        textStyle = AppTypography.bodyLarge.copyWith(
          fontWeight: AppTypography.weightBold,
        );
        break;
    }

    // Variant configurations
    final Gradient? gradient;
    final Color? backgroundColor;
    final Color? borderColor;
    final Color textColor;
    final List<BoxShadow>? shadow;

    switch (widget.variant) {
      case ButtonVariant.primary:
        gradient = widget.backgroundColor == null
            ? AppColors.authPrimaryGradient
            : null;
        backgroundColor = widget.backgroundColor;
        borderColor = null;
        textColor = widget.textColor ?? Colors.white;
        shadow = _isHovered ? AppShadows.glowPrimary : AppShadows.elevation2;
        break;
      case ButtonVariant.secondary:
        gradient = widget.backgroundColor == null
            ? AppColors.ctaGradient
            : null;
        backgroundColor = widget.backgroundColor;
        borderColor = null;
        textColor = widget.textColor ?? AppColors.textPrimaryDark;
        shadow = _isHovered ? AppShadows.glowSecondary : AppShadows.elevation2;
        break;
      case ButtonVariant.outline:
        gradient = null;
        backgroundColor = Colors.transparent;
        borderColor = widget.backgroundColor ?? AppColors.authPrimary;
        textColor = widget.textColor ?? AppColors.authPrimary;
        shadow = _isHovered ? AppShadows.elevation1 : null;
        break;
      case ButtonVariant.text:
        gradient = null;
        backgroundColor = Colors.transparent;
        borderColor = null;
        textColor = widget.textColor ?? AppColors.authPrimary;
        shadow = null;
        break;
    }

    return _ButtonConfig(
      height: height,
      horizontalPadding: horizontalPadding,
      iconSize: iconSize,
      iconSpacing: iconSpacing,
      textStyle: textStyle,
      gradient: gradient,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      textColor: textColor,
      shadow: shadow,
    );
  }
}

/// Button variant enum
enum ButtonVariant { primary, secondary, outline, text }

/// Button size enum
enum ButtonSize { small, medium, large }

/// Icon position enum
enum IconPosition { left, right }

/// Internal button configuration class
class _ButtonConfig {
  final double height;
  final double horizontalPadding;
  final double iconSize;
  final double iconSpacing;
  final TextStyle textStyle;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color textColor;
  final List<BoxShadow>? shadow;

  const _ButtonConfig({
    required this.height,
    required this.horizontalPadding,
    required this.iconSize,
    required this.iconSpacing,
    required this.textStyle,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    required this.textColor,
    this.shadow,
  });
}
