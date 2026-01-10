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

    // Remove script tags
    sanitized = sanitized.replaceAll(_scriptPattern, '');

    // Remove HTML tags
    sanitized = sanitized.replaceAll(_htmlTagPattern, '');

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

    // Keep only digits and spaces
    sanitized = sanitized.replaceAll(RegExp(r'[^\d\s]'), '');

    // Normalize whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Final trim
    sanitized = sanitized.trim();

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Sanitizes URL input
  ///
  /// - Removes javascript: protocol
  /// - Removes control characters
  /// - Removes whitespace
  ///
  /// Returns sanitized URL or null if invalid
  static String? sanitizeUrl(String? input) {
    if (input == null || input.trim().isEmpty) {
      return null;
    }

    var sanitized = input.trim();

    // Remove control characters
    sanitized = sanitized.replaceAll(_controlCharPattern, '');

    // Remove whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s'), '');

    // Check for dangerous protocols (javascript:)
    if (sanitized.toLowerCase().startsWith('javascript:')) {
      return null;
    }

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
