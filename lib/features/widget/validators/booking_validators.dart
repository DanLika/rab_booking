/// Validators for booking form fields
class BookingValidators {
  /// Validate name field
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validate email field
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      caseSensitive: false,
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate phone field
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces and special characters for validation
    final cleanedPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it starts with + and has at least 8 digits
    if (cleanedPhone.startsWith('+') && cleanedPhone.length >= 9) {
      return null;
    }

    // Or check if it's a valid local format (at least 8 digits)
    if (cleanedPhone.length >= 8 && RegExp(r'^\d+$').hasMatch(cleanedPhone)) {
      return null;
    }

    return 'Please enter a valid phone number (e.g., +38512345678)';
  }

  /// Validate message (optional, but has character limit)
  static String? validateMessage(String? value, {int maxLength = 255}) {
    if (value == null || value.isEmpty) {
      return null; // Message is optional
    }

    if (value.length > maxLength) {
      return 'Message must not exceed $maxLength characters';
    }

    return null;
  }
}
