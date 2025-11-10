import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_animations.dart';
import '../../core/constants/app_dimensions.dart';
import 'text_field.dart' show TextFieldVariant;

/// Premium date picker component with custom styling
/// Features: Custom styling, validation, icons, helper text, date formatting
class PremiumDatePicker extends StatefulWidget {
  /// Selected date
  final DateTime? selectedDate;

  /// On date selected callback
  final ValueChanged<DateTime?>? onDateSelected;

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

  /// First date (earliest selectable date)
  final DateTime? firstDate;

  /// Last date (latest selectable date)
  final DateTime? lastDate;

  /// Date format pattern (default: 'dd/MM/yyyy')
  final String dateFormat;

  /// Field variant
  final TextFieldVariant variant;

  /// Enable floating label
  final bool enableFloatingLabel;

  const PremiumDatePicker({
    super.key,
    this.selectedDate,
    this.onDateSelected,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    this.dateFormat = 'dd/MM/yyyy',
    this.variant = TextFieldVariant.outlined,
    this.enableFloatingLabel = true,
  });

  @override
  State<PremiumDatePicker> createState() => _PremiumDatePickerState();
}

class _PremiumDatePickerState extends State<PremiumDatePicker> {
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

  Future<void> _selectDate() async {
    if (!widget.enabled) return;

    final now = DateTime.now();
    final firstDate = widget.firstDate ?? DateTime(1900);
    final lastDate = widget.lastDate ?? DateTime(2100);
    final initialDate = widget.selectedDate ?? now;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.authPrimary,
                    onPrimary: Colors.white,
                    onSurface: AppColors.textPrimaryDark,
                  )
                : const ColorScheme.light(
                    primary: AppColors.authPrimary,
                    onSurface: AppColors.textPrimaryLight,
                  ),
            dialogTheme: DialogThemeData(
              backgroundColor: isDark
                  ? AppColors.surfaceDark
                  : AppColors.surfaceLight,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.authPrimary,
                textStyle: AppTypography.bodyMedium.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != widget.selectedDate) {
      widget.onDateSelected?.call(picked);
    }
  }

  String _getDisplayText() {
    if (widget.selectedDate == null) {
      return widget.hint ?? widget.label ?? 'Select date';
    }
    return DateFormat(widget.dateFormat).format(widget.selectedDate!);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final hasValue = widget.selectedDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.smooth,
          decoration: _buildDecoration(isDark, hasError),
          child: InkWell(
            onTap: widget.enabled ? _selectDate : null,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: widget.enableFloatingLabel && hasValue
                    ? widget.label
                    : null,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _getPrefixIconColor(isDark, hasError),
                        size: AppDimensions.iconM,
                      )
                    : null,
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  color: _getSuffixIconColor(isDark, hasError),
                  size: AppDimensions.iconM,
                ),
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
                labelStyle: AppTypography.small.copyWith(
                  color: _getLabelColor(isDark, hasError),
                  fontWeight: AppTypography.weightMedium,
                ),
              ),
              child: Text(
                _getDisplayText(),
                style: AppTypography.bodyMedium.copyWith(
                  color: hasValue
                      ? (!widget.enabled
                            ? AppColors.textDisabled
                            : isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight)
                      : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
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
          ? (isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariantLight)
          : null;
    } else if (_isFocused) {
      borderColor = AppColors.authPrimary;
      boxShadow = AppShadows.glowPrimary;
      backgroundColor = widget.variant == TextFieldVariant.filled
          ? (isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariantLight)
          : null;
    } else {
      borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
      boxShadow = null;
      backgroundColor = widget.variant == TextFieldVariant.filled
          ? (isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariantLight)
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
