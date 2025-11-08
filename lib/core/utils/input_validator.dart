/// Input validation and sanitization utilities
///
/// Provides security-focused validation and sanitization methods
/// to prevent injection attacks and ensure data integrity
class InputValidator {
  InputValidator._(); // Private constructor

  /// Maximum allowed length for search queries
  static const int maxSearchLength = 100;

  /// Maximum allowed length for location strings
  static const int maxLocationLength = 100;

  /// Regex for detecting potential SQL injection patterns
  static final RegExp _sqlInjectionPattern = RegExp(
    r'(\bOR\b|\bAND\b|\bUNION\b|\bSELECT\b|\bDROP\b|\bINSERT\b|\bUPDATE\b|\bDELETE\b|--|;|\/\*|\*\/)',
    caseSensitive: false,
  );

  /// Regex for detecting XSS patterns
  static final RegExp _xssPattern = RegExp(
    r'(<script|<iframe|javascript:|onerror=|onload=)',
    caseSensitive: false,
  );

  // ==========================================================================
  // SEARCH INPUT VALIDATION
  // ==========================================================================

  /// Sanitize search query input
  ///
  /// - Trims whitespace
  /// - Limits length
  /// - Removes dangerous characters
  /// - Returns null if invalid
  static String? sanitizeSearchQuery(String? input) {
    if (input == null || input.trim().isEmpty) {
      return null;
    }

    // Trim and limit length
    String sanitized = input.trim();
    if (sanitized.length > maxSearchLength) {
      sanitized = sanitized.substring(0, maxSearchLength);
    }

    // Check for SQL injection patterns
    if (_sqlInjectionPattern.hasMatch(sanitized)) {
      return null; // Reject suspicious input
    }

    // Check for XSS patterns
    if (_xssPattern.hasMatch(sanitized)) {
      return null; // Reject suspicious input
    }

    // Remove special characters except allowed ones
    sanitized = sanitized.replaceAll(RegExp(r"[^\w\s\-.,'()]"), '');

    // Collapse multiple spaces
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Sanitize location input
  ///
  /// Similar to search query but allows more location-specific characters
  static String? sanitizeLocation(String? input) {
    if (input == null || input.trim().isEmpty) {
      return null;
    }

    String sanitized = input.trim();

    // Limit length
    if (sanitized.length > maxLocationLength) {
      sanitized = sanitized.substring(0, maxLocationLength);
    }

    // Check for injection patterns
    if (_sqlInjectionPattern.hasMatch(sanitized) ||
        _xssPattern.hasMatch(sanitized)) {
      return null;
    }

    // Allow letters, numbers, spaces, and common location characters
    sanitized = sanitized.replaceAll(
      RegExp(r"[^\w\s\-.,'()čćžšđČĆŽŠĐäöüÄÖÜßàéèêëïôùûîç]"),
      '',
    );

    // Collapse multiple spaces
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    return sanitized.isEmpty ? null : sanitized;
  }

  // ==========================================================================
  // NUMERIC VALIDATION
  // ==========================================================================

  /// Validate and sanitize price input
  ///
  /// Returns null if invalid, clamped value if valid
  static double? sanitizePrice(double? price, {
    double min = 0,
    double max = 10000,
  }) {
    if (price == null) return null;

    // Check for NaN or Infinity
    if (price.isNaN || price.isInfinite) return null;

    // Clamp to range
    if (price < min) return min;
    if (price > max) return max;

    return price;
  }

  /// Validate and sanitize integer input (guests, rooms, etc.)
  static int? sanitizeInteger(int? value, {
    int min = 0,
    int max = 100,
  }) {
    if (value == null) return null;

    // Clamp to range
    if (value < min) return min;
    if (value > max) return max;

    return value;
  }

  // ==========================================================================
  // STRING VALIDATION
  // ==========================================================================

  /// Check if string is safe (no injection patterns)
  static bool isSafeString(String? input) {
    if (input == null || input.isEmpty) return true;

    return !_sqlInjectionPattern.hasMatch(input) &&
        !_xssPattern.hasMatch(input);
  }

  /// Escape special characters for SQL LIKE queries
  ///
  /// Escapes: % _ [ ]
  static String escapeLikePattern(String input) {
    return input
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_')
        .replaceAll('[', '\\[')
        .replaceAll(']', '\\]');
  }

  // ==========================================================================
  // ARRAY VALIDATION
  // ==========================================================================

  /// Validate amenities list
  ///
  /// - Removes empty/null values
  /// - Limits list size
  /// - Validates each item
  static List<String> sanitizeAmenities(List<String>? amenities, {
    int maxCount = 20,
  }) {
    if (amenities == null || amenities.isEmpty) {
      return [];
    }

    // Remove empty values and limit count
    final sanitized = amenities
        .where((a) => a.trim().isNotEmpty)
        .where((a) => isSafeString(a))
        .take(maxCount)
        .toList();

    return sanitized;
  }

  // ==========================================================================
  // DATE VALIDATION
  // ==========================================================================

  /// Validate date range
  ///
  /// Ensures:
  /// - Check-in is not in the past
  /// - Check-out is after check-in
  /// - Stay duration is reasonable
  static DateRangeValidationResult validateDateRange(
    DateTime? checkIn,
    DateTime? checkOut, {
    int maxDurationDays = 365,
  }) {
    if (checkIn == null || checkOut == null) {
      return DateRangeValidationResult.success();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check-in cannot be in the past
    if (checkIn.isBefore(today)) {
      return DateRangeValidationResult.error(
        'Check-in date cannot be in the past',
      );
    }

    // Check-out must be after check-in
    if (checkOut.isBefore(checkIn) || checkOut.isAtSameMomentAs(checkIn)) {
      return DateRangeValidationResult.error(
        'Check-out must be after check-in',
      );
    }

    // Check duration
    final duration = checkOut.difference(checkIn).inDays;
    if (duration > maxDurationDays) {
      return DateRangeValidationResult.error(
        'Stay duration cannot exceed $maxDurationDays days',
      );
    }

    // Minimum 1 night stay
    if (duration < 1) {
      return DateRangeValidationResult.error(
        'Minimum stay is 1 night',
      );
    }

    return DateRangeValidationResult.success();
  }
}

/// Date range validation result
class DateRangeValidationResult {
  final bool isValid;
  final String? errorMessage;

  DateRangeValidationResult.success()
      : isValid = true,
        errorMessage = null;

  DateRangeValidationResult.error(this.errorMessage) : isValid = false;
}
