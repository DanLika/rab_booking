import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_animations.dart';
import '../../core/constants/app_dimensions.dart';
import 'text_field.dart' show TextFieldVariant;

/// Premium dropdown component with custom styling
/// Features: Custom styling, validation, icons, helper text
class PremiumDropdown<T> extends StatefulWidget {
  /// Current selected value
  final T? value;

  /// List of dropdown items
  final List<DropdownMenuItem<T>> items;

  /// On changed callback
  final ValueChanged<T?>? onChanged;

  /// Label text (floating label)
  final String? label;

  /// Hint text (placeholder)
  final String? hint;

  /// Helper text (below field)
  final String? helperText;

  /// Error text (validation error)
  final String? errorText;

  /// Prefix icon
  final IconData? prefixIcon;

  /// Enable/disable field
  final bool enabled;

  /// Field variant
  final TextFieldVariant variant;

  /// Enable floating label
  final bool enableFloatingLabel;

  const PremiumDropdown({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.enabled = true,
    this.variant = TextFieldVariant.outlined,
    this.enableFloatingLabel = true,
  });

  @override
  State<PremiumDropdown<T>> createState() => _PremiumDropdownState<T>();
}

class _PremiumDropdownState<T> extends State<PremiumDropdown<T>> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.smooth,
          decoration: _buildDecoration(isDark, hasError),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<T>(
              key: ValueKey(widget.value),
              initialValue: widget.value,
              items: widget.items,
              onChanged: widget.enabled ? widget.onChanged : null,
              focusNode: _focusNode,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _getIconColor(isDark, hasError),
                size: AppDimensions.iconM,
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: !widget.enabled
                    ? AppColors.textDisabled
                    : isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
              ),
              dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              decoration: InputDecoration(
                labelText: widget.enableFloatingLabel ? widget.label : null,
                hintText: widget.hint ?? (!widget.enableFloatingLabel ? widget.label : null),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _getPrefixIconColor(isDark, hasError),
                        size: AppDimensions.iconM,
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: widget.prefixIcon != null
                      ? AppDimensions.spaceXS
                      : AppDimensions.spaceS,
                  vertical: AppDimensions.spaceS,
                ),
                labelStyle: AppTypography.bodyMedium.copyWith(
                  color: _getLabelColor(isDark, hasError),
                ),
                floatingLabelStyle: AppTypography.small.copyWith(
                  color: _getLabelColor(isDark, hasError),
                  fontWeight: AppTypography.weightMedium,
                ),
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
        ),
        if (widget.helperText != null || hasError)
          Padding(
            padding: const EdgeInsets.only(
              left: AppDimensions.spaceS,
              top: AppDimensions.spaceXXS,
            ),
            child: Text(
              hasError ? widget.errorText! : widget.helperText!,
              style: AppTypography.helperText.copyWith(
                color: hasError ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  BoxDecoration _buildDecoration(bool isDark, bool hasError) {
    final Color borderColor;
    final List<BoxShadow>? boxShadow;
    final Color? backgroundColor;

    if (!widget.enabled) {
      borderColor = AppColors.borderLight;
      boxShadow = null;
      backgroundColor = isDark
          ? AppColors.surfaceVariantDark
          : AppColors.surfaceVariantLight;
    } else if (hasError) {
      borderColor = AppColors.error;
      boxShadow = _isFocused ? AppShadows.errorShadow : null;
      backgroundColor = widget.variant == TextFieldVariant.filled
          ? (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight)
          : null;
    } else if (_isFocused) {
      borderColor = AppColors.authPrimary;
      boxShadow = AppShadows.glowPrimary;
      backgroundColor = widget.variant == TextFieldVariant.filled
          ? (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight)
          : null;
    } else {
      borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
      boxShadow = null;
      backgroundColor = widget.variant == TextFieldVariant.filled
          ? (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight)
          : null;
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      border: widget.variant == TextFieldVariant.outlined
          ? Border.all(
              color: borderColor,
              width: _isFocused || hasError
                  ? AppDimensions.borderWidthFocus
                  : AppDimensions.borderWidth,
            )
          : null,
      boxShadow: boxShadow,
    );
  }

  Color _getPrefixIconColor(bool isDark, bool hasError) {
    if (!widget.enabled) return AppColors.textDisabled;
    if (hasError) return AppColors.error;
    if (_isFocused) return AppColors.authPrimary;
    return isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  }

  Color _getIconColor(bool isDark, bool hasError) {
    if (!widget.enabled) return AppColors.textDisabled;
    if (hasError) return AppColors.error;
    if (_isFocused) return AppColors.authPrimary;
    return isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  }

  Color _getLabelColor(bool isDark, bool hasError) {
    if (!widget.enabled) return AppColors.textDisabled;
    if (hasError) return AppColors.error;
    if (_isFocused) return AppColors.authPrimary;
    return isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  }
}
