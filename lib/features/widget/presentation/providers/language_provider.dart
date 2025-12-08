import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for current language code
///
/// Reads initial language from URL parameter (?lang=hr|en|de|it) on web.
/// Defaults to Croatian (hr) if not specified or invalid.
///
/// Supported languages: hr, en, de, it
///
/// Usage:
/// ```dart
/// // Read current language
/// final language = ref.watch(languageProvider);
///
/// // Change language
/// ref.read(languageProvider.notifier).state = 'en';
/// ```
final languageProvider = StateProvider<String>((ref) {
  // Supported language codes
  const supportedLanguages = ['hr', 'en', 'de', 'it'];

  // Read from URL on web platform
  if (kIsWeb) {
    final uri = Uri.base;
    final langParam = uri.queryParameters['lang']?.toLowerCase();
    if (langParam != null && supportedLanguages.contains(langParam)) {
      return langParam;
    }
  }

  // Default to Croatian
  return 'hr';
});
