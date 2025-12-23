import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/embed_url_params.dart';
import '../theme/minimalist_theme.dart';

/// Provider for widget configuration
///
/// Initialize this with URL parameters at app startup:
/// ```dart
/// final uri = Uri.parse(window.location.href);
/// final config = EmbedUrlParams.fromUrlParameters(uri);
/// ref.read(widgetConfigProvider.notifier).state = config;
/// ```
final widgetConfigProvider = StateProvider<EmbedUrlParams>((ref) {
  // Default configuration
  return const EmbedUrlParams();
});

/// Provider for theme mode based on widget configuration
final widgetThemeModeProvider = Provider<ThemeMode>((ref) {
  final config = ref.watch(widgetConfigProvider);

  switch (config.themeMode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
});

/// Provider for light theme based on widget configuration
final widgetLightThemeProvider = Provider<ThemeData>((ref) {
  final config = ref.watch(widgetConfigProvider);

  // Start with Minimalist light theme
  ThemeData theme = MinimalistTheme.light;

  // Apply custom colors if provided
  if (config.primaryColor != null) {
    theme = theme.copyWith(
      primaryColor: config.primaryColor,
      colorScheme: theme.colorScheme.copyWith(primary: config.primaryColor),
    );
  }

  if (config.accentColor != null) {
    theme = theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(secondary: config.accentColor),
    );
  }

  if (config.backgroundColor != null) {
    theme = theme.copyWith(scaffoldBackgroundColor: config.backgroundColor);
  }

  if (config.textColor != null) {
    theme = theme.copyWith(
      textTheme: theme.textTheme.apply(
        bodyColor: config.textColor,
        displayColor: config.textColor,
      ),
    );
  }

  return theme;
});

/// Provider for dark theme based on widget configuration
final widgetDarkThemeProvider = Provider<ThemeData>((ref) {
  final config = ref.watch(widgetConfigProvider);

  // Start with Minimalist dark theme
  ThemeData theme = MinimalistTheme.dark;

  // Apply custom colors if provided
  if (config.primaryColor != null) {
    theme = theme.copyWith(
      primaryColor: config.primaryColor,
      colorScheme: theme.colorScheme.copyWith(primary: config.primaryColor),
    );
  }

  if (config.accentColor != null) {
    theme = theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(secondary: config.accentColor),
    );
  }

  if (config.backgroundColor != null) {
    theme = theme.copyWith(scaffoldBackgroundColor: config.backgroundColor);
  }

  if (config.textColor != null) {
    theme = theme.copyWith(
      textTheme: theme.textTheme.apply(
        bodyColor: config.textColor,
        displayColor: config.textColor,
      ),
    );
  }

  return theme;
});
