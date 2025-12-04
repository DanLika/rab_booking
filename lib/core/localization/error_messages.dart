/// Centralized error messages for internationalization
///
/// All user-facing error strings should be defined here
/// to enable future translation support.
class ErrorMessages {
  // Generic errors
  static const String genericError = 'An error occurred';
  static const String loadingError = 'Failed to load data';

  // Calendar errors
  static String calendarError(Object error) => 'Error loading calendar: $error';

  // Button labels
  static const String verifyButton = 'Verify';
  static const String retryButton = 'Retry';
  static const String cancelButton = 'Cancel';
  static const String okButton = 'OK';

  // Common actions
  static const String loading = 'Loading...';
  static const String saving = 'Saving...';
  static const String deleting = 'Deleting...';

  // Validation messages
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String invalidDate = 'Please enter a valid date';
}
