/// Password strength levels
enum PasswordStrength { weak, medium, strong }

/// Password validation result
class PasswordValidationResult {
  final bool isValid;
  final String? errorMessage;
  final PasswordStrength strength;
  final List<String> missingRequirements;

  const PasswordValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.strength,
    this.missingRequirements = const [],
  });

  factory PasswordValidationResult.valid(PasswordStrength strength) {
    return PasswordValidationResult(isValid: true, strength: strength);
  }

  factory PasswordValidationResult.invalid(
    String message, {
    List<String> missing = const [],
  }) {
    return PasswordValidationResult(
      isValid: false,
      errorMessage: message,
      strength: PasswordStrength.weak,
      missingRequirements: missing,
    );
  }
}

/// Password validation utilities
class PasswordValidator {
  PasswordValidator._();

  /// Minimum password length
  static const int minLength = 8;

  /// Maximum password length
  static const int maxLength = 128;

  // Cached regex patterns for performance
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _digitRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  /// SECURITY: Common passwords blacklist
  /// These passwords are rejected regardless of complexity requirements
  static const Set<String> _commonPasswords = {
    'password',
    'password1',
    'password123',
    'qwerty123',
    'letmein',
    'welcome1',
    'admin123',
    'iloveyou',
    'sunshine',
    'princess',
    'football',
    'baseball',
    'trustno1',
    'dragon12',
    'master12',
  };

  /// Validate password and return detailed result
  static PasswordValidationResult validate(String? password) {
    if (password == null || password.isEmpty) {
      return PasswordValidationResult.invalid(
        'Password is required',
        missing: ['Enter a password'],
      );
    }

    // SECURITY: Check against common passwords blacklist
    if (_commonPasswords.contains(password.toLowerCase())) {
      return PasswordValidationResult.invalid(
        'This password is too common. Please choose a stronger password.',
        missing: ['Choose a less common password'],
      );
    }

    final missing = <String>[];

    // Check length
    if (password.length < minLength) {
      missing.add('At least $minLength characters');
    }

    if (password.length > maxLength) {
      return PasswordValidationResult.invalid(
        'Password must be less than $maxLength characters',
      );
    }

    // Check for uppercase letter
    if (!_uppercaseRegex.hasMatch(password)) {
      missing.add('One uppercase letter');
    }

    // Check for lowercase letter
    if (!_lowercaseRegex.hasMatch(password)) {
      missing.add('One lowercase letter');
    }

    // Check for digit
    if (!_digitRegex.hasMatch(password)) {
      missing.add('One number');
    }

    // Check for special character
    if (!_specialCharRegex.hasMatch(password)) {
      missing.add('One special character');
    }

    // If any requirements are missing, return invalid
    if (missing.isNotEmpty) {
      return PasswordValidationResult.invalid(
        'Password must contain: ${missing.join(', ')}',
        missing: missing,
      );
    }

    // Calculate strength
    final strength = _calculateStrength(password);

    return PasswordValidationResult.valid(strength);
  }

  /// Calculate password strength
  static PasswordStrength _calculateStrength(String password) {
    // SECURITY: Common passwords are always weak
    if (_commonPasswords.contains(password.toLowerCase())) {
      return PasswordStrength.weak;
    }

    int score = 0;

    // Length score
    if (password.length >= 12) {
      score += 2;
    } else if (password.length >= 10) {
      score += 1;
    }

    // Complexity score (using cached regex)
    if (_uppercaseRegex.hasMatch(password)) score += 1;
    if (_lowercaseRegex.hasMatch(password)) score += 1;
    if (_digitRegex.hasMatch(password)) score += 1;
    if (_specialCharRegex.hasMatch(password)) score += 1;

    // Multiple digits/special chars bonus (using efficient allMatches)
    if (_digitRegex.allMatches(password).length >= 2) score += 1;
    if (_specialCharRegex.allMatches(password).length >= 2) score += 1;

    // Determine strength using switch expression
    return switch (score) {
      >= 7 => PasswordStrength.strong,
      >= 5 => PasswordStrength.medium,
      _ => PasswordStrength.weak,
    };
  }

  /// Simple validation for form fields (returns error message or null)
  static String? validateSimple(String? password) {
    final result = validate(password);
    return result.isValid ? null : result.errorMessage;
  }

  /// Minimum length validation (8+ characters only) - for login and register
  /// Includes minimal validation to prevent weak passwords like "12345678" or "11111111"
  static String? validateMinimumLength(String? password) {
    if (password == null || password.isEmpty) {
      return 'Please enter your password';
    }

    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    if (password.length > maxLength) {
      return 'Password must be less than $maxLength characters';
    }

    // Minimal validation: Prevent obvious weak passwords
    // SECURITY FIX SF-006: Check for sequential characters (numbers AND letters)
    if (_isSequentialCharacters(password)) {
      return 'Password cannot contain sequential characters (e.g., "12345" or "abcde")';
    }

    // Check for repeating characters (11111111, aaaaaaaa)
    if (_isRepeatingCharacters(password)) {
      return 'Password cannot be repeating characters (e.g., 11111111)';
    }

    return null;
  }

  /// SECURITY FIX SF-006: Check if password contains sequential characters
  /// Detects both numeric (12345) and alphabetic (abcde) sequences
  static bool _isSequentialCharacters(String password) {
    if (password.length < 3) return false;
    final lowercased = password.toLowerCase();

    for (int i = 0; i < lowercased.length - 2; i++) {
      final c1 = lowercased.codeUnitAt(i);
      final c2 = lowercased.codeUnitAt(i + 1);
      final c3 = lowercased.codeUnitAt(i + 2);

      // Check for ascending sequence (e.g., abc, 123)
      if (c2 == c1 + 1 && c3 == c2 + 1) {
        final substr = lowercased.substring(i, i + 3);
        // Only flag if all digits or all letters (avoid mixed like '9ab')
        if (_digitRegex.allMatches(substr).length == 3 ||
            _lowercaseRegex.allMatches(substr).length == 3) {
          return true;
        }
      }

      // Check for descending sequence (e.g., cba, 321)
      if (c2 == c1 - 1 && c3 == c2 - 1) {
        final substr = lowercased.substring(i, i + 3);
        if (_digitRegex.allMatches(substr).length == 3 ||
            _lowercaseRegex.allMatches(substr).length == 3) {
          return true;
        }
      }
    }
    return false;
  }

  /// Check if password is repeating characters (11111111, aaaaaaaa, etc.)
  static bool _isRepeatingCharacters(String password) {
    if (password.length < 3) return false;

    final firstChar = password[0];
    // Check if all characters are the same
    return password.split('').every((char) => char == firstChar);
  }

  /// Check if two passwords match
  static String? validateConfirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirm) {
      return 'Passwords do not match';
    }

    return null;
  }
}
