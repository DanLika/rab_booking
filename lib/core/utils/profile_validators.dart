/// Validation utilities for user profile fields
class ProfileValidators {
  ProfileValidators._();

  // ========== NAME VALIDATION ==========

  /// Validate display name (2-80 characters)
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (trimmed.length > 80) {
      return 'Name must be less than 80 characters';
    }

    return null;
  }

  // ========== EMAIL VALIDATION ==========

  /// Validate email (RFC 5322 compliant)
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final trimmedValue = value.trim();

    // Pre-emptive check for '@' for a more specific error message.
    if (!trimmedValue.contains('@')) {
      return 'Email address must contain an "@" symbol';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(trimmedValue)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // ========== PHONE VALIDATION ==========

  /// Validate phone number (flexible format)
  /// Accepts: +385911234567, 0911234567, 091-123-4567, (091) 123 4567
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }

    // Remove common formatting characters for validation
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-\(\)\.]+'), '');

    // Must have at least 6 digits (shortest valid phone numbers)
    // and at most 15 digits (E.164 max)
    // Can optionally start with +
    final phoneRegex = RegExp(r'^\+?[0-9]{6,15}$');

    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // ========== ADDRESS VALIDATION ==========

  /// Validate address field (2-120 characters)
  static String? validateAddressField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return null; // Address fields are optional
    }

    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    if (trimmed.length > 120) {
      return '$fieldName must be less than 120 characters';
    }

    return null;
  }

  /// Validate postal code (alphanumeric, 2-20 characters)
  static String? validatePostalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }

    final trimmed = value.trim();
    if (trimmed.length < 2 || trimmed.length > 20) {
      return 'Postal code must be 2-20 characters';
    }

    // Allow alphanumeric and spaces/dashes
    final postalRegex = RegExp(r'^[a-zA-Z0-9\s-]+$');
    if (!postalRegex.hasMatch(trimmed)) {
      return 'Invalid postal code format';
    }

    return null;
  }

  // ========== WEBSITE VALIDATION ==========

  /// Validate website URL
  static String? validateWebsite(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL (starting with http:// or https://)';
    }

    return null;
  }

  // ========== TAX/VAT VALIDATION ==========

  /// Validate Tax ID (alphanumeric, 5-20 characters)
  static String? validateTaxId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }

    final trimmed = value.trim();
    if (trimmed.length < 5 || trimmed.length > 20) {
      return 'Tax ID must be 5-20 characters';
    }

    // Alphanumeric only
    final taxIdRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!taxIdRegex.hasMatch(trimmed)) {
      return 'Tax ID can only contain letters and numbers';
    }

    return null;
  }

  /// Validate VAT ID (alphanumeric, 5-20 characters)
  static String? validateVatId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }

    final trimmed = value.trim();
    if (trimmed.length < 5 || trimmed.length > 20) {
      return 'VAT ID must be 5-20 characters';
    }

    // Alphanumeric only (some countries use letters)
    final vatIdRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!vatIdRegex.hasMatch(trimmed)) {
      return 'VAT ID can only contain letters and numbers';
    }

    return null;
  }

  // ========== IBAN VALIDATION ==========

  /// Validate IBAN (simplified - allows alphanumeric, 15-34 characters)
  static String? validateIban(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }

    // Remove spaces
    final trimmed = value.replaceAll(' ', '').toUpperCase();

    if (trimmed.length < 15 || trimmed.length > 34) {
      return 'IBAN must be 15-34 characters';
    }

    // IBAN starts with 2 letters (country code) followed by alphanumeric
    final ibanRegex = RegExp(r'^[A-Z]{2}[0-9A-Z]+$');
    if (!ibanRegex.hasMatch(trimmed)) {
      return 'Invalid IBAN format';
    }

    return null;
  }

  // ========== SWIFT/BIC VALIDATION ==========

  /// Validate SWIFT/BIC code (8 or 11 alphanumeric characters)
  static String? validateSwift(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }

    final trimmed = value.replaceAll(' ', '').toUpperCase();

    // SWIFT is either 8 or 11 characters
    if (trimmed.length != 8 && trimmed.length != 11) {
      return 'SWIFT code must be 8 or 11 characters';
    }

    // Alphanumeric only
    final swiftRegex = RegExp(r'^[A-Z0-9]+$');
    if (!swiftRegex.hasMatch(trimmed)) {
      return 'SWIFT code can only contain letters and numbers';
    }

    return null;
  }
}
