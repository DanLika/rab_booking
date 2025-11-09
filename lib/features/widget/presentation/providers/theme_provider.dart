import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// Provider for theme mode (light/dark)
final themeProvider = StateProvider<bool>((ref) => false); // false = light, true = dark

/// Provider for widget color scheme based on current theme
final widgetColorsProvider = Provider<WidgetColorScheme>((ref) {
  final isDark = ref.watch(themeProvider);
  return isDark ? ColorTokens.dark : ColorTokens.light;
});
