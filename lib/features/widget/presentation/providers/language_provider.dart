import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for current language code
///
/// Priority order:
/// 1. URL parameter (?lang=hr|en|de|it) - highest priority
/// 2. Browser language detection (PlatformDispatcher.instance.locale)
/// 3. Default to Croatian (hr) if not specified or invalid
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

  // Priority 1: URL parameter (highest priority)
  if (kIsWeb) {
    final uri = Uri.base;
    final langParam = uri.queryParameters['lang']?.toLowerCase();
    if (langParam != null && supportedLanguages.contains(langParam)) {
      return langParam;
    }

    // Priority 2: Browser language detection
    final browserLang = PlatformDispatcher.instance.locale.languageCode;
    if (supportedLanguages.contains(browserLang)) {
      return browserLang;
    }
  }

  // Priority 3: Default to Croatian
  return 'hr';
});
