import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'language_provider.g.dart';

/// Storage key for language preference
const String _languageKey = 'selected_language';

/// Default language code
const String _defaultLanguage = 'hr'; // Croatian as default for RAB Booking

/// Provider for managing language preferences with persistent storage
@riverpod
class LanguageNotifier extends _$LanguageNotifier {
  static const _supportedLanguages = ['en', 'hr'];

  @override
  Future<Locale> build() async {
    // Load saved language preference from storage
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_languageKey) ?? _defaultLanguage;

    // Validate that the saved language is supported
    if (!_supportedLanguages.contains(savedLanguageCode)) {
      return const Locale(_defaultLanguage);
    }

    return Locale(savedLanguageCode);
  }

  /// Change the app language and persist the preference
  Future<void> setLanguage(String languageCode) async {
    if (!_supportedLanguages.contains(languageCode)) {
      throw ArgumentError('Unsupported language: $languageCode');
    }

    // Update the state
    state = AsyncValue.data(Locale(languageCode));

    // Persist the preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  /// Get list of supported locales
  static List<Locale> get supportedLocales {
    return _supportedLanguages.map((code) => Locale(code)).toList();
  }

  /// Get list of supported language codes
  static List<String> get supportedLanguageCodes {
    return _supportedLanguages;
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
