import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_animations.dart';
import '../../core/constants/app_dimensions.dart';

/// Premium text field component with floating label and validation
/// Features: Floating labels, validation states, icons, helper text, custom styling
class PremiumTextField extends StatefulWidget {
  /// Text editing controller
  final TextEditingController? controller;

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

  /// Suffix icon
  final IconData? suffixIcon;

  /// Suffix icon callback
  final VoidCallback? onSuffixIconTap;

  /// Text input type
  final TextInputType keyboardType;

  /// Obscure text (for passwords)
  final bool obscureText;

  /// Enable/disable field
  final bool enabled;

  /// Read-only field
  final bool readOnly;

  /// Max lines (for multiline text)
  final int maxLines;

  /// Min lines
  final int minLines;

  /// Max length
  final int? maxLength;

  /// Auto focus
  final bool autofocus;

  /// On changed callback
  final ValueChanged<String>? onChanged;

  /// On submitted callback
  final ValueChanged<String>? onSubmitted;

  /// On tap callback
  final VoidCallback? onTap;

  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Text input action
  final TextInputAction? textInputAction;

  /// Auto validate mode
  final AutovalidateMode? autovalidateMode;

  /// Validator function
  final String? Function(String?)? validator;

  /// Field variant
  final TextFieldVariant variant;

  /// Enable floating label
  final bool enableFloatingLabel;

  const PremiumTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.textInputAction,
    this.autovalidateMode,
    this.validator,
    this.variant = TextFieldVariant.outlined,
    this.enableFloatingLabel = true,
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _obscureText = widget.obscureText;
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

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
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
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: _obscureText,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            maxLines: _obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            inputFormatters: widget.inputFormatters,
            textInputAction: widget.textInputAction,
            style: AppTypography.bodyMedium.copyWith(
              color: !widget.enabled
                  ? AppColors.textDisabled
                  : isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
            ),
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
              suffixIcon: _buildSuffixIcon(isDark, hasError),
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
              counterText: '',
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

  Widget? _buildSuffixIcon(bool isDark, bool hasError) {
    // Password visibility toggle
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: AppDimensions.iconM,
        ),
        color: _getSuffixIconColor(isDark, hasError),
        onPressed: _toggleObscureText,
      );
    }

    // Custom suffix icon
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          size: AppDimensions.iconM,
        ),
        color: _getSuffixIconColor(isDark, hasError),
        onPressed: widget.onSuffixIconTap,
      );
    }

    return null;
  }

  Color _getPrefixIconColor(bool isDark, bool hasError) {
    if (!widget.enabled) return AppColors.textDisabled;
    if (hasError) return AppColors.error;
    if (_isFocused) return AppColors.authPrimary;
    return isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  }

  Color _getSuffixIconColor(bool isDark, bool hasError) {
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

/// Text field variant enum
enum TextFieldVariant {
  /// Outlined variant with border
  outlined,

  /// Filled variant with background color
  filled,
}
