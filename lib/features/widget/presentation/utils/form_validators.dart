import 'package:flutter/services.dart';

/// Form validation utilities for guest booking form
/// Includes name, email, and phone validation with real-time feedback

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
/// - Validates phone number length based on country
/// - Requires digits only (no letters or special characters except spaces)
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

    // Country-specific length validation
    final minLength = _getMinPhoneLength(dialCode);
    final maxLength = _getMaxPhoneLength(dialCode);

    if (digitsOnly.length < minLength) {
      return 'Phone number is too short (minimum $minLength digits)';
    }

    if (digitsOnly.length > maxLength) {
      return 'Phone number is too long (maximum $maxLength digits)';
    }

    return null; // Valid
  }

  /// Get minimum phone length for country
  static int _getMinPhoneLength(String dialCode) {
    // Most countries: 8-15 digits
    // Some exceptions for shorter numbers
    switch (dialCode) {
      case '+1': // US, Canada
        return 10;
      case '+7': // Russia, Kazakhstan
        return 10;
      case '+44': // UK
        return 10;
      case '+33': // France
        return 9;
      case '+49': // Germany
        return 10;
      case '+39': // Italy
        return 9;
      case '+34': // Spain
        return 9;
      case '+385': // Croatia
        return 8;
      case '+381': // Serbia
        return 8;
      case '+387': // Bosnia
        return 8;
      case '+386': // Slovenia
        return 8;
      default:
        return 7; // Default minimum
    }
  }

  /// Get maximum phone length for country
  static int _getMaxPhoneLength(String dialCode) {
    // Most countries: 8-15 digits
    switch (dialCode) {
      case '+1': // US, Canada
        return 10;
      case '+7': // Russia, Kazakhstan
        return 10;
      case '+44': // UK
        return 10;
      case '+385': // Croatia
        return 9;
      case '+381': // Serbia
        return 9;
      case '+387': // Bosnia
        return 9;
      case '+386': // Slovenia
        return 9;
      default:
        return 15; // Default maximum
    }
  }
}

/// Phone number input formatter
/// - Auto-formats phone numbers with spaces (no parentheses)
/// - Formats as user types for better UX
/// - Example: "61234567" -> "61 234 567"
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

    // Format based on country
    final formatted = _formatPhoneNumber(digitsOnly, dialCode);

    // Calculate new cursor position
    final newCursorPosition = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }

  /// Format phone number with spaces based on country patterns
  String _formatPhoneNumber(String digits, String dialCode) {
    switch (dialCode) {
      case '+385': // Croatia: XX XXX XXXX or XXX XXX XXX
        return _formatCroatiaPhone(digits);
      case '+381': // Serbia: XX XXX XXXX
        return _formatSerbiaPhone(digits);
      case '+387': // Bosnia: XX XXX XXX
        return _formatBosniaPhone(digits);
      case '+1': // US/Canada: XXX XXX XXXX
        return _formatUSPhone(digits);
      case '+44': // UK: XXXX XXX XXX
        return _formatUKPhone(digits);
      case '+49': // Germany: XXX XXX XXXX
        return _formatGermanyPhone(digits);
      default:
        // Default formatting: Groups of 3
        return _formatDefaultPhone(digits);
    }
  }

  /// Croatia phone format: XX XXX XXXX or XXX XXX XXX
  String _formatCroatiaPhone(String digits) {
    if (digits.length <= 2) return digits;
    if (digits.length <= 5) {
      return '${digits.substring(0, 2)} ${digits.substring(2)}';
    }
    if (digits.length <= 9) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
    }
    // Limit to 9 digits
    return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 9)}';
  }

  /// Serbia phone format: XX XXX XXXX
  String _formatSerbiaPhone(String digits) {
    if (digits.length <= 2) return digits;
    if (digits.length <= 5) {
      return '${digits.substring(0, 2)} ${digits.substring(2)}';
    }
    if (digits.length <= 9) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
    }
    // Limit to 9 digits
    return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 9)}';
  }

  /// Bosnia phone format: XX XXX XXX
  String _formatBosniaPhone(String digits) {
    if (digits.length <= 2) return digits;
    if (digits.length <= 5) {
      return '${digits.substring(0, 2)} ${digits.substring(2)}';
    }
    if (digits.length <= 8) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
    }
    // Limit to 8 digits
    return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 8)}';
  }

  /// US/Canada phone format: XXX XXX XXXX
  String _formatUSPhone(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) {
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    }
    if (digits.length <= 10) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
    // Limit to 10 digits
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 10)}';
  }

  /// UK phone format: XXXX XXX XXX
  String _formatUKPhone(String digits) {
    if (digits.length <= 4) return digits;
    if (digits.length <= 7) {
      return '${digits.substring(0, 4)} ${digits.substring(4)}';
    }
    if (digits.length <= 10) {
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    }
    // Limit to 10 digits
    return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7, 10)}';
  }

  /// Germany phone format: XXX XXX XXXX
  String _formatGermanyPhone(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) {
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    }
    if (digits.length <= 10) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
    // Limit to 10 digits
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 10)}';
  }

  /// Default phone format: XXX XXX XXX... (groups of 3)
  String _formatDefaultPhone(String digits) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
