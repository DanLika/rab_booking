import 'package:flutter/services.dart';

import 'phone_config.dart';

export 'phone_config.dart';

/// First Name validator
/// - Requires at least one word
/// - Allows special characters: apostrophes (O'Brien), hyphens (Jean-Claude), umlauts (Müller)
/// - Allows letters and common diacritics (no spaces needed for first name)
class FirstNameValidator {
  /// Validates first name field
  /// Returns error message if invalid, null if valid
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your first name';
    }

    final trimmed = value.trim();

    // Allow letters (including Unicode), apostrophes, hyphens, and common diacritics
    // Pattern: Letters (any Unicode letter), apostrophes, hyphens
    final namePattern = RegExp(r"^[\p{L}'\-]+$", unicode: true);
    if (!namePattern.hasMatch(trimmed)) {
      return 'First name can only contain letters, apostrophes, and hyphens';
    }

    return null; // Valid
  }
}

/// Last Name validator
/// - Requires at least one word
/// - Allows special characters: apostrophes (O'Brien), hyphens (Jean-Claude), umlauts (Müller)
/// - Allows spaces for compound last names (e.g., "van der Berg", "de la Cruz")
/// - Allows letters and common diacritics
class LastNameValidator {
  /// Validates last name field
  /// Returns error message if invalid, null if valid
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your last name';
    }

    final trimmed = value.trim();

    // Allow letters (including Unicode), spaces, apostrophes, hyphens, and common diacritics
    // Pattern: Letters (any Unicode letter), spaces, apostrophes, hyphens
    final namePattern = RegExp(r"^[\p{L}\s'\-]+$", unicode: true);
    if (!namePattern.hasMatch(trimmed)) {
      return 'Last name can only contain letters, spaces, apostrophes, and hyphens';
    }

    return null; // Valid
  }
}

/// Full Name validator (DEPRECATED - use FirstNameValidator and LastNameValidator instead)
/// - Requires at least first and last name (minimum 2 words)
/// - Allows special characters: apostrophes (O'Brien), hyphens (Jean-Claude), umlauts (Müller)
/// - Allows spaces, letters, and common diacritics
@Deprecated('Use FirstNameValidator and LastNameValidator instead')
class NameValidator {
  /// Validates name field
  /// Returns error message if invalid, null if valid
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }

    final trimmed = value.trim();

    // Check for minimum 2 words (first + last name)
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length < 2) {
      return 'Please enter both first and last name';
    }

    // Check each word is at least 1 character (not just spaces/special chars)
    for (final word in words) {
      if (word.isEmpty) {
        return 'Please enter a valid name';
      }
    }

    // Allow letters (including Unicode), spaces, apostrophes, hyphens, and common diacritics
    // Pattern: Letters (any Unicode letter), spaces, apostrophes, hyphens
    final namePattern = RegExp(r"^[\p{L}\s'\-]+$", unicode: true);
    if (!namePattern.hasMatch(trimmed)) {
      return 'Name can only contain letters, spaces, apostrophes, and hyphens';
    }

    return null; // Valid
  }
}

/// Email validator
/// - Requires proper email format with TLD (Top Level Domain)
/// - test@test is INVALID (no TLD)
/// - test@test.com is VALID
class EmailValidator {
  /// Validates email field
  /// Returns error message if invalid, null if valid
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }

    final trimmed = value.trim();

    // Email regex pattern requiring TLD
    // Pattern breakdown:
    // - Local part: alphanumeric + dots, hyphens, underscores (before @)
    // - @ symbol required
    // - Domain: alphanumeric + dots, hyphens
    // - TLD: at least 2 characters after final dot (e.g., .com, .co.uk)
    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailPattern.hasMatch(trimmed)) {
      return 'Please enter a valid email address (e.g., user@example.com)';
    }

    return null; // Valid
  }
}

/// Phone number validator
/// - Validates phone number length based on country config
/// - Requires digits only (no letters or special characters except spaces)
/// - Uses data-driven PhoneConfigs for country-specific rules
class PhoneValidator {
  /// Validates phone number for a given country dial code
  /// Returns error message if invalid, null if valid
  static String? validate(String? value, String dialCode) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    // Remove all spaces for validation
    final digitsOnly = value.replaceAll(RegExp(r'\s'), '');

    // Check if contains only digits
    if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
      return 'Phone number can only contain digits';
    }

    // Get country-specific config (with fallback for unknown countries)
    final config = PhoneConfigs.getConfig(dialCode);

    if (digitsOnly.length < config.minLength) {
      return 'Phone number is too short (minimum ${config.minLength} digits)';
    }

    if (digitsOnly.length > config.maxLength) {
      return 'Phone number is too long (maximum ${config.maxLength} digits)';
    }

    return null; // Valid
  }
}

/// Phone number input formatter
/// - Auto-formats phone numbers with spaces based on country pattern
/// - Uses data-driven PhoneConfigs for formatting
/// - Example: "61234567" -> "61 234 567" (Croatia)
class PhoneNumberFormatter extends TextInputFormatter {
  final String dialCode;

  PhoneNumberFormatter(this.dialCode);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Get only digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    // If empty, return empty
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Get config for this country
    final config = PhoneConfigs.getConfig(dialCode);

    // Limit digits to max length
    final limitedDigits = digitsOnly.length > config.maxLength
        ? digitsOnly.substring(0, config.maxLength)
        : digitsOnly;

    // Format using pattern
    final formatted = _formatByPattern(limitedDigits, config.format.groupSizes);

    // Calculate new cursor position
    final newCursorPosition = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }

  /// Generic pattern-based phone formatter
  /// Takes digits and group sizes, returns formatted string with spaces
  String _formatByPattern(String digits, List<int> groupSizes) {
    if (digits.isEmpty) return '';

    final buffer = StringBuffer();
    var position = 0;

    for (final groupSize in groupSizes) {
      if (position >= digits.length) break;

      // Add space before group (except first)
      if (position > 0) {
        buffer.write(' ');
      }

      // Calculate end of this group
      final end = (position + groupSize).clamp(0, digits.length);

      // Add digits for this group
      buffer.write(digits.substring(position, end));
      position = end;
    }

    // If there are remaining digits beyond defined groups, add them
    if (position < digits.length) {
      buffer.write(' ');
      buffer.write(digits.substring(position));
    }

    return buffer.toString();
  }
}
