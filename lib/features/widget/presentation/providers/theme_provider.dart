import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// Provider for theme mode (light/dark)
final themeProvider = StateProvider<bool>(
  (ref) => false,
); // false = light, true = dark

/// Resolves the INITIAL dark flag for [themeProvider]: an explicit
/// `?theme=dark|light` embed parameter wins; `system` (or anything else)
/// falls back to the platform brightness. Manual moon-toggle writes to
/// [themeProvider] afterwards are unaffected.
bool initialDarkFromConfig(String themeMode, Brightness platformBrightness) {
  switch (themeMode.toLowerCase()) {
    case 'dark':
      return true;
    case 'light':
      return false;
    default:
      return platformBrightness == Brightness.dark;
  }
}

/// Provider for widget color scheme based on current theme
final widgetColorsProvider = Provider<WidgetColorScheme>((ref) {
  final isDark = ref.watch(themeProvider);
  return isDark ? ColorTokens.dark : ColorTokens.light;
});
