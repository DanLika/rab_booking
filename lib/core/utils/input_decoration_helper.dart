import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/gradient_extensions.dart';

/// Centralized helper for creating consistent InputDecoration across the app
class InputDecorationHelper {
  InputDecorationHelper._();

  /// Get dropdown menu color based on theme
  /// Uses inputFillColor from gradients for consistency with input fields
  static Color getDropdownColor(BuildContext context) {
    return context.gradients.inputFillColor;
  }

  /// Get dropdown border radius
  static BorderRadius get dropdownBorderRadius => BorderRadius.circular(12);

  /// Build dropdown menu decoration
  static BoxDecoration getDropdownDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: getDropdownColor(context),
      borderRadius: dropdownBorderRadius,
      border: Border.all(
        color: isDark
            ? AppColors.sectionDividerDark
            : AppColors.sectionDividerLight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha((0.15 * 255).toInt()),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Creates modern input decoration for form fields
  /// Uses design system colors: inputFillColor for background, sectionBorder for borders
  static InputDecoration buildDecoration({
    required String labelText,
    String? hintText,
    String? helperText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isMobile = false,
    required BuildContext context,
    ValueNotifier<bool>? showClearButtonNotifier,
    VoidCallback? onClear,
  }) {
    final theme = Theme.of(context);

    Widget? finalSuffixIcon = suffixIcon;
    if (showClearButtonNotifier != null && onClear != null) {
      finalSuffixIcon = ValueListenableBuilder<bool>(
        valueListenable: showClearButtonNotifier,
        builder: (context, showClear, child) {
          if (showClear) {
            return IconButton(
              icon: const Icon(Icons.clear),
              onPressed: onClear,
              tooltip: 'Očisti',
            );
          }
          return suffixIcon ?? const SizedBox.shrink();
        },
      );
    }

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      suffixIcon: finalSuffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.gradients.sectionBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.gradients.sectionBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      filled: true,
      fillColor: context.gradients.inputFillColor,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 12 : 16,
      ),
    );
  }

  /// Creates filter-specific input decoration (simplified variant)
  static InputDecoration buildFilterDecoration({
    required String labelText,
    Widget? prefixIcon,
    bool isMobile = false,
    required BuildContext context,
  }) {
    return buildDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon,
      isMobile: isMobile,
      context: context,
    );
  }
}
