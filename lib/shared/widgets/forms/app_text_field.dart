import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// Reusable text field widget with validation and consistent styling
///
/// Example usage:
/// ```dart
/// AppTextField(
///   label: 'Email',
///   hint: 'Enter your email',
///   validator: (value) {
///     if (value == null || value.isEmpty) {
///       return 'Email is required';
///     }
///     if (!value.contains('@')) {
///       return 'Enter a valid email';
///     }
///     return null;
///   },
///   onChanged: (value) => print(value),
/// )
/// ```
class AppTextField extends StatelessWidget {
  const AppTextField({
    this.controller,
    this.label,
    this.hint,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
    super.key,
  });

  /// Text editing controller
  final TextEditingController? controller;

  /// Field label
  final String? label;

  /// Placeholder hint text
  final String? hint;

  /// Initial value
  final String? initialValue;

  /// Validation function
  final String? Function(String?)? validator;

  /// Called when text changes
  final void Function(String)? onChanged;

  /// Called when form is saved
  final void Function(String?)? onSaved;

  /// Keyboard type
  final TextInputType? keyboardType;

  /// Text input action
  final TextInputAction? textInputAction;

  /// Hide text (for passwords)
  final bool obscureText;

  /// Enable/disable field
  final bool enabled;

  /// Maximum number of lines
  final int? maxLines;

  /// Minimum number of lines
  final int? minLines;

  /// Maximum character length
  final int? maxLength;

  /// Icon before text
  final Widget? prefixIcon;

  /// Icon after text
  final Widget? suffixIcon;

  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Auto focus on mount
  final bool autofocus;

  /// Read only mode
  final bool readOnly;

  /// Called when field is tapped
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        // Use design system border radius (8px)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryLight : AppColors.primary,
            width: AppDimensions.borderWidthFocus,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: BorderSide(
            color: isDark ? AppColors.errorLight : AppColors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: BorderSide(
            color: isDark ? AppColors.errorLight : AppColors.error,
            width: AppDimensions.borderWidthFocus,
          ),
        ),
        filled: true,
        fillColor: enabled
            ? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
            : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight),
        counterText: maxLength != null ? null : '',
        // Use design system constraints for height (48px)
        constraints: const BoxConstraints(minHeight: AppDimensions.inputHeight),
      ),
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      onTap: onTap,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      autofocus: autofocus,
      readOnly: readOnly,
    );
  }
}
