/// Centralized error messages for internationalization
///
/// All user-facing error strings should be defined here
/// to enable future translation support.
///
/// Usage:
/// ```dart
/// Text(ErrorMessages.genericError)
/// Text(ErrorMessages.calendarError(error))
/// ```
class ErrorMessages {
  // Prevent instantiation
  ErrorMessages._();

  // ============================================================
  // GENERIC ERRORS
  // ============================================================
  static const String genericError = 'An error occurred';
  static const String loadingError = 'Failed to load data';

  // ============================================================
  // CALENDAR ERRORS
  // ============================================================

  static String calendarError(Object error) => 'Error loading calendar: $error';

  // ============================================================
  // BUTTON LABELS
  // ============================================================

  static const String verifyButton = 'Verify';
  static const String retryButton = 'Retry';
  static const String cancelButton = 'Cancel';
  static const String okButton = 'OK';

  // ============================================================
  // COMMON ACTIONS
  // ============================================================

  static const String loading = 'Loading...';
  static const String saving = 'Saving...';
  static const String deleting = 'Deleting...';

  // ============================================================
  // VALIDATION MESSAGES
  // ============================================================

  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String invalidDate = 'Please enter a valid date';
}
