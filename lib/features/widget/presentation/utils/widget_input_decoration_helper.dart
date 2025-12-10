import 'package:flutter/material.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../theme/minimalist_colors.dart';

/// Centralized helper for creating consistent InputDecoration for widget feature
/// Uses MinimalistColorSchemeAdapter for black/white minimalist style
class WidgetInputDecorationHelper {
  WidgetInputDecorationHelper._();

  /// Creates minimalist input decoration for widget form fields
  static InputDecoration buildDecoration({
    required String labelText,
    String? hintText,
    String? helperText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    required bool isDarkMode,
    int? errorMaxLines,
    bool isDense = false,
    bool hideCounter = true,
  }) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      counterText: hideCounter ? '' : null,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(color: colors.textSecondary),
      hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5)),
      filled: true,
      // Pure white (light) / pure black (dark) for form containers
      fillColor: colors.backgroundPrimary,
      isDense: isDense,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderTokens.circularMedium,
        borderSide: BorderSide(color: colors.textSecondary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderTokens.circularMedium,
        borderSide: BorderSide(color: colors.textSecondary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderTokens.circularMedium,
        borderSide: BorderSide(color: colors.textPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderTokens.circularMedium,
        borderSide: BorderSide(color: colors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderTokens.circularMedium,
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
      errorStyle: TextStyle(color: colors.error, fontSize: 12, height: 1.0),
      errorMaxLines: errorMaxLines ?? 2,
    );
  }
}
