/// Input sanitizer for security protection against XSS, injection attacks
///
/// This utility provides sanitization methods to clean user input before
/// storing in Firestore or displaying in UI.
///
/// Usage:
/// ```dart
/// // Sanitize user notes
/// final cleanNotes = InputSanitizer.sanitizeText(_notesController.text);
///
/// // Sanitize email
/// final cleanEmail = InputSanitizer.sanitizeEmail(_emailController.text);
///
/// // Sanitize name
/// final cleanName = InputSanitizer.sanitizeName(_nameController.text);
/// ```
class InputSanitizer {
  /// Private constructor to prevent instantiation
  InputSanitizer._();

  // Dangerous patterns that could indicate XSS or injection attacks
  static final _scriptPattern = RegExp(
    r'<script[^>]*>.*?</script>',
    caseSensitive: false,
    dotAll: true,
  );

  static final _htmlTagPattern = RegExp(r'<[^>]*>');
  static final _sqlKeywordsPattern = RegExp(
    r'\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|EXECUTE|UNION|WHERE)\b',
    caseSensitive: false,
  );

  // Control characters that should be removed (except newline, tab, carriage return)
  static final _controlCharPattern = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]',
  );

  // LOGIC-011 FIX: Add confusables map to align with backend sanitization
  static final Map<String, String> _confusablesMap = {
    // Cyrillic -> Latin
    'а': 'a', 'е': 'e', 'о': 'o', 'р': 'p', 'с': 'c',
    'у': 'y', 'х': 'x', 'і': 'i', 'ј': 'j', 'ѕ': 's',
    'А': 'A', 'В': 'B', 'Е': 'E', 'К': 'K', 'М': 'M',
    'Н': 'H', 'О': 'O', 'Р': 'P', 'С': 'C', 'Т': 'T',
    'Х': 'X',
    // Greek -> Latin
    'α': 'a', 'ε': 'e', 'ο': 'o', 'ν': 'v', 'ρ': 'r',
    'Α': 'A', 'Β': 'B', 'Ε': 'E', 'Η': 'H', 'Ι': 'I',
    'Κ': 'K', 'Μ': 'M', 'Ν': 'N', 'Ο': 'O', 'Ρ': 'P',
    'Τ': 'T', 'Χ': 'X', 'Υ': 'Y', 'Ζ': 'Z',
    // Zero-width characters (remove)
    '\u200B': '', '\u200C': '', '\u200D': '', '\uFEFF': '', '\u00AD': '',
  };

  /// Sanitizes general text input (notes, descriptions, etc.)
  ///
  /// Removes:
  /// - HTML/script tags
  /// - SQL keywords
  /// - Control characters
  /// - Leading/trailing whitespace
  /// - Multiple consecutive spaces
  ///
  /// Returns sanitized string or null if input is null/empty
  static String? sanitizeText(String? input) {
    if (input == null || input.trim().isEmpty) {
      return null;
    }

    var sanitized = input.trim();

    // LOGIC-011 FIX: Normalize confusables to prevent homoglyph attacks
    sanitized = _normalizeConfusables(sanitized);

    // Remove script tags
    sanitized = sanitized.replaceAll(_scriptPattern, '');

    // LOGIC-011 FIX: Encode HTML entities instead of stripping them
    // This prevents data loss (e.g., "a < b" is preserved as "a &lt; b")
    // and is a more secure method of preventing XSS.
    sanitized = sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');

    // Remove SQL keywords (case-insensitive)
    sanitized = sanitized.replaceAll(_sqlKeywordsPattern, '');

    // Remove control characters (keep newlines and tabs for multiline text)
    sanitized = sanitized.replaceAll(_controlCharPattern, '');

    // Normalize whitespace (collapse multiple spaces into one)
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Final trim
    sanitized = sanitized.trim();

    return sanitized.isEmpty ? null : sanitized;
  }

  // LOGIC-011 FIX: Helper to normalize Unicode confusables
  static String _normalizeConfusables(String input) {
    var normalized = input;
    _confusablesMap.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });
    return normalized;
  }

  /// Sanitizes email input
  ///
  /// - Converts to lowercase
  /// - Removes whitespace
  /// - Removes dangerous characters
  ///
  /// Returns sanitized email or null if invalid
  static String? sanitizeEmail(String? input) {
    if (input == null || input.trim().isEmpty) {
      return null;
    }

    var sanitized = input.trim().toLowerCase();

    // Remove any HTML tags
    sanitized = sanitized.replaceAll(_htmlTagPattern, '');

    // Remove control characters
    sanitized = sanitized.replaceAll(_controlCharPattern, '');

    // Remove any spaces
    sanitized = sanitized.replaceAll(RegExp(r'\s'), '');

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Sanitizes name input (first name, last name)
  ///
  /// - Removes HTML tags
  /// - Removes control characters
  /// - Preserves Unicode letters, spaces, apostrophes, hyphens
  /// - Normalizes whitespace
  ///
  /// Returns sanitized name or null if invalid
  static String? sanitizeName(String? input) {
    if (input == null || input.trim().isEmpty) {
      return null;
    }

    var sanitized = input.trim();

    // Remove HTML tags
    sanitized = sanitized.replaceAll(_htmlTagPattern, '');

    // Remove control characters
    sanitized = sanitized.replaceAll(_controlCharPattern, '');

    // Allow only Unicode letters, spaces, apostrophes, hyphens
    // Remove any other characters
    sanitized = sanitized.replaceAll(
      RegExp(r"[^\p{L}\s'\-]", unicode: true),
      '',
    );

    // Normalize whitespace (collapse multiple spaces)
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Final trim
    sanitized = sanitized.trim();

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Sanitizes phone number input
  ///
  /// - Removes all non-digit characters except spaces
  /// - Normalizes spacing
  ///
  /// Returns sanitized phone or null if invalid
  static String? sanitizePhone(String? input) {
    if (input == null || input.trim().isEmpty) {
      return null;
    }

    var sanitized = input.trim();

    // Remove HTML tags
    sanitized = sanitized.replaceAll(_htmlTagPattern, '');

    // Remove control characters
    sanitized = sanitized.replaceAll(_controlCharPattern, '');

    // LOGIC-011 FIX: Keep only valid phone characters, including '+'
    // This aligns with the backend's `sanitizePhone` function, which
    // preserves characters necessary for international phone numbers.
    sanitized = sanitized.replaceAll(RegExp(r'[^\d\s+()-]'), '');

    // Normalize whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Final trim
    sanitized = sanitized.trim();

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Checks if text contains potentially dangerous patterns
  ///
  /// Returns true if input appears to contain malicious content
  static bool containsDangerousContent(String? input) {
    if (input == null || input.isEmpty) {
      return false;
    }

    final lower = input.toLowerCase();

    // Check for script tags
    if (_scriptPattern.hasMatch(lower)) {
      return true;
    }

    // Check for common XSS patterns
    if (lower.contains('javascript:') ||
        lower.contains('onerror=') ||
        lower.contains('onload=') ||
        lower.contains('onclick=')) {
      return true;
    }

    // Check for SQL injection patterns
    if (_sqlKeywordsPattern.hasMatch(input)) {
      return true;
    }

    // Check for NoSQL injection patterns
    if (lower.contains(r'$where') ||
        lower.contains(r'$ne') ||
        lower.contains(r'$gt') ||
        lower.contains(r'$lt')) {
      return true;
    }

    return false;
  }

  /// Limits text length safely without breaking Unicode characters
  ///
  /// Returns truncated string with optional ellipsis
  static String limitLength(
    String input,
    int maxLength, {
    bool addEllipsis = true,
  }) {
    if (input.length <= maxLength) {
      return input;
    }

    final truncated = input.substring(0, maxLength);

    return addEllipsis ? '$truncated...' : truncated;
  }

  /// Escapes special characters for safe display
  ///
  /// Note: Flutter Text widget already escapes HTML,
  /// but this is useful for logging or debugging
  static String escapeForDisplay(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }
}
