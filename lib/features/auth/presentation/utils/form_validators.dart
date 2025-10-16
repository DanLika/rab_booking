/// Form validation utilities
class FormValidators {
  /// Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email je obavezan';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Unesite validnu email adresu';
    }

    return null;
  }

  /// Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lozinka je obavezna';
    }

    if (value.length < 8) {
      return 'Lozinka mora imati najmanje 8 karaktera';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Lozinka mora sadržavati barem jedno veliko slovo';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Lozinka mora sadržavati barem jedan broj';
    }

    return null;
  }

  /// Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Potvrda lozinke je obavezna';
    }

    if (value != password) {
      return 'Lozinke se ne poklapaju';
    }

    return null;
  }

  /// Name validation
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName je obavezan';
    }

    if (value.length < 2) {
      return '$fieldName mora imati najmanje 2 karaktera';
    }

    if (!value.contains(RegExp(r'^[a-zA-ZčćžšđČĆŽŠĐ\s]+$'))) {
      return '$fieldName može sadržavati samo slova';
    }

    return null;
  }

  /// Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName je obavezan';
    }

    return null;
  }

  /// Password strength (0-4: weak to strong)
  static int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;

    // Length check
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // Complexity checks
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    // Cap at 4
    return strength > 4 ? 4 : strength;
  }

  /// Get password strength label
  static String getPasswordStrengthLabel(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Slaba';
      case 2:
        return 'Srednja';
      case 3:
        return 'Jaka';
      case 4:
        return 'Vrlo jaka';
      default:
        return '';
    }
  }

  /// Get password strength color
  static int getPasswordStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 0xFFE57373; // Red
      case 2:
        return 0xFFFFB74D; // Orange
      case 3:
        return 0xFF81C784; // Light green
      case 4:
        return 0xFF4CAF50; // Green
      default:
        return 0xFFBDBDBD; // Grey
    }
  }
}
