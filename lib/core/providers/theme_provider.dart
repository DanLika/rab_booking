/// Theme mode provider with persistent storage.
///
/// Manages light/dark/system theme mode with SharedPreferences persistence.
///
/// Usage:
/// ```dart
/// // Watch current theme mode
/// final themeMode = ref.watch(currentThemeModeProvider);
///
/// // Set theme mode
/// ref.read(themeNotifierProvider.notifier).setThemeMode(ThemeMode.dark);
///
/// // Use in MaterialApp
/// MaterialApp(
///   themeMode: ref.watch(currentThemeModeProvider),
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/providers/repository_providers.dart';

part 'theme_provider.g.dart';

/// Storage key for theme preference
const String _themeKey = 'theme_mode';

/// Provider for managing theme mode (light/dark) with persistent storage
@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  Future<ThemeMode> build() async {
    // Try to use the provider first (initialized in main.dart)
    final prefsFromProvider = ref.read(sharedPreferencesProvider);

    // If provider has SharedPreferences, use it
    if (prefsFromProvider != null) {
      final savedTheme = prefsFromProvider.getString(_themeKey);
      return _parseThemeMode(savedTheme);
    }

    // Fallback: try to get instance directly (for widget_main.dart or if provider not ready)
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      return _parseThemeMode(savedTheme);
    } catch (e) {
      // If SharedPreferences is not available, return system default
      return ThemeMode.system;
    }
  }

  /// Parse theme mode string to ThemeMode enum
  ThemeMode _parseThemeMode(String? savedTheme) {
    switch (savedTheme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Set theme mode and persist the preference
  Future<void> setThemeMode(ThemeMode mode) async {
    // Update the state
    state = AsyncValue.data(mode);

    // Try to use the provider first
    final prefsFromProvider = ref.read(sharedPreferencesProvider);

    if (prefsFromProvider != null) {
      final modeString = _themeModeToString(mode);
      await prefsFromProvider.setString(_themeKey, modeString);
      return;
    }

    // Fallback: try to get instance directly
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = _themeModeToString(mode);
      await prefs.setString(_themeKey, modeString);
    } catch (e) {
      // If SharedPreferences is not available, just update state (no persistence)
      // This can happen during initialization or on web if not properly set up
    }
  }

  /// Convert ThemeMode to string
  String _themeModeToString(ThemeMode mode) {
    return mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
        ? 'dark'
        : 'system';
  }
}

/// Provider to get the current theme mode synchronously (with fallback to system)
@riverpod
ThemeMode currentThemeMode(Ref ref) {
  final themeModeAsync = ref.watch(themeNotifierProvider);

  return themeModeAsync.when(
    data: (mode) => mode,
    loading: () => ThemeMode.system,
    error: (error, stackTrace) => ThemeMode.system,
  );
}
