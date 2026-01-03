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
    if (!password.contains(RegExp(r'[A-Z]'))) {
      missing.add('One uppercase letter');
    }

    // Check for lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      missing.add('One lowercase letter');
    }

    // Check for digit
    if (!password.contains(RegExp(r'[0-9]'))) {
      missing.add('One number');
    }

    // Check for special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      missing.add('One special character');
    }

    // If any requirements are missing, return invalid
    if (missing.isNotEmpty) {
      return PasswordValidationResult.invalid(
        'Password must contain:\n• ${missing.join('\n• ')}',
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

    // Complexity score
    if (password.contains(RegExp(r'[A-Z]'))) score += 1;
    if (password.contains(RegExp(r'[a-z]'))) score += 1;
    if (password.contains(RegExp(r'[0-9]'))) score += 1;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 1;

    // Multiple digits/special chars bonus
    if (password.split('').where((c) => c.contains(RegExp(r'[0-9]'))).length >=
        2) {
      score += 1;
    }
    if (password
            .split('')
            .where((c) => c.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))
            .length >=
        2) {
      score += 1;
    }

    // Determine strength
    if (score >= 7) {
      return PasswordStrength.strong;
    } else if (score >= 5) {
      return PasswordStrength.medium;
    } else {
      return PasswordStrength.weak;
    }
  }

  /// Simple validation for form fields (returns error message or null)
  static String? validateSimple(String? password) {
    final result = validate(password);
    return result.isValid ? null : result.errorMessage;
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
