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

  /// Validate password and return detailed result
  static PasswordValidationResult validate(String? password) {
    if (password == null || password.isEmpty) {
      return PasswordValidationResult.invalid(
        'Password is required',
        missing: ['Enter a password'],
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
    // Check for sequential numbers (12345678, 87654321)
    if (_isSequentialNumbers(password)) {
      return 'Password cannot be sequential numbers (e.g., 12345678)';
    }

    // Check for repeating characters (11111111, aaaaaaaa)
    if (_isRepeatingCharacters(password)) {
      return 'Password cannot be repeating characters (e.g., 11111111)';
    }

    return null;
  }

  /// Check if password is sequential numbers (12345678, 87654321, etc.)
  static bool _isSequentialNumbers(String password) {
    if (password.length < 3) return false;

    // Check if all characters are digits
    if (!_digitRegex.hasMatch(password) ||
        password.length !=
            password.split('').where(_digitRegex.hasMatch).length) {
      return false;
    }

    // Check ascending sequence (12345678)
    bool isAscending = true;
    for (int i = 1; i < password.length; i++) {
      final prev = int.tryParse(password[i - 1]);
      final curr = int.tryParse(password[i]);
      if (prev == null || curr == null || curr != prev + 1) {
        isAscending = false;
        break;
      }
    }

    // Check descending sequence (87654321)
    bool isDescending = true;
    for (int i = 1; i < password.length; i++) {
      final prev = int.tryParse(password[i - 1]);
      final curr = int.tryParse(password[i]);
      if (prev == null || curr == null || curr != prev - 1) {
        isDescending = false;
        break;
      }
    }

    return isAscending || isDescending;
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
