/// Language preference provider with persistent storage.
///
/// Manages app locale with SharedPreferences persistence.
///
/// Usage:
/// ```dart
/// // Watch current locale
/// final locale = ref.watch(currentLocaleProvider);
///
/// // Change language
/// ref.read(languageNotifierProvider.notifier).setLanguage('en');
///
/// // Get supported locales for MaterialApp
/// MaterialApp(
///   supportedLocales: LanguageNotifier.supportedLocales,
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/providers/repository_providers.dart';

part 'language_provider.g.dart';

/// Storage key for language preference
const String _languageKey = 'selected_language';

/// Default language code
const String _defaultLanguage = 'hr'; // Croatian as default for RAB Booking

/// Provider for managing language preferences with persistent storage
///
/// ## AutoDispose Decision: TRUE (current) - SHOULD BE keepAlive
/// Language preference is app-wide and used in MaterialApp.locale.
/// AutoDispose is acceptable because:
/// - SharedPreferences persists the value across sessions
/// - State rebuilds quickly from cached SharedPreferences
///
/// Consider @Riverpod(keepAlive: true) if locale flickering occurs on navigation
@riverpod
class LanguageNotifier extends _$LanguageNotifier {
  static const _supportedLanguages = ['en', 'hr'];

  @override
  Future<Locale> build() async {
    // Try to use the provider first (initialized in main.dart)
    final prefsFromProvider = ref.read(sharedPreferencesProvider);
    
    // If provider has SharedPreferences, use it
    if (prefsFromProvider != null) {
      final savedLanguageCode = prefsFromProvider.getString(_languageKey) ?? _defaultLanguage;
      return _parseLocale(savedLanguageCode);
    }
    
    // Fallback: try to get instance directly (for widget_main.dart or if provider not ready)
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageKey) ?? _defaultLanguage;
      return _parseLocale(savedLanguageCode);
    } catch (e) {
      // If SharedPreferences is not available, return default
      return const Locale(_defaultLanguage);
    }
  }

  /// Parse language code to Locale with validation
  Locale _parseLocale(String languageCode) {
    // Validate that the saved language is supported
    if (!_supportedLanguages.contains(languageCode)) {
      return const Locale(_defaultLanguage);
    }
    return Locale(languageCode);
  }

  /// Change the app language and persist the preference
  Future<void> setLanguage(String languageCode) async {
    if (!_supportedLanguages.contains(languageCode)) {
      throw ArgumentError('Unsupported language: $languageCode');
    }

    // Update the state
    state = AsyncValue.data(Locale(languageCode));

    // Try to use the provider first
    final prefsFromProvider = ref.read(sharedPreferencesProvider);
    
    if (prefsFromProvider != null) {
      await prefsFromProvider.setString(_languageKey, languageCode);
      return;
    }
    
    // Fallback: try to get instance directly
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      // If SharedPreferences is not available, just update state (no persistence)
      // This can happen during initialization or on web if not properly set up
    }
  }

  /// Get list of supported locales
  static List<Locale> get supportedLocales {
    return _supportedLanguages.map(Locale.new).toList();
  }
}

/// Provider to get the current locale synchronously (with fallback to default)
@riverpod
Locale currentLocale(Ref ref) {
  final localeAsync = ref.watch(languageNotifierProvider);

  return localeAsync.when(
    data: (locale) => locale,
    loading: () => const Locale(_defaultLanguage),
    error: (error, stackTrace) => const Locale(_defaultLanguage),
  );
}
