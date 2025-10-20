import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

/// Storage key for theme preference
const String _themeKey = 'theme_mode';

/// Provider for managing theme mode (light/dark) with persistent storage
@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  Future<ThemeMode> build() async {
    // Load saved theme preference from storage
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

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

    // Persist the preference
    final prefs = await SharedPreferences.getInstance();
    final modeString = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await prefs.setString(_themeKey, modeString);
  }

  /// Toggle between light and dark modes
  Future<void> toggleTheme() async {
    final currentMode = state.value ?? ThemeMode.system;
    final newMode = currentMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await setThemeMode(newMode);
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
