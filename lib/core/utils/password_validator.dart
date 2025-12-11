/// Password strength levels
enum PasswordStrength {
  weak,
  medium,
  strong,
}

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
    return PasswordValidationResult(
      isValid: true,
      strength: strength,
    );
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
  /// No complexity requirements - user can enter any password they want
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

    return null;
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
