/// URL sanitization and validation helpers for booking widget routing.
///
/// Defense-in-depth utilities that guard against malformed query parameters,
/// stray path segments, and unexpected error-to-string failures before any
/// value reaches Firestore, Stripe, or a UI surface.
library;

/// Sanitize ID from URL by removing any trailing path segments (e.g. a
/// stray `/calendar` suffix). Returns the input unchanged when null or empty.
///
/// Prevents Firestore "invalid document reference" errors when an ID is
/// pasted with extra path segments.
String? sanitizeId(String? id) {
  if (id == null || id.isEmpty) return id;
  final slashIndex = id.indexOf('/');
  if (slashIndex > 0) {
    return id.substring(0, slashIndex);
  }
  return id;
}

/// Validates a booking reference of the form `BK-XXXXXXXXXXXX` where the
/// 12-character suffix is alphanumeric (case-insensitive).
bool isValidBookingReference(String? ref) {
  if (ref == null || ref.isEmpty) return false;
  return RegExp(r'^BK-[A-Za-z0-9]{12}$').hasMatch(ref);
}

/// Validates a Firestore auto-generated document ID — 20 alphanumeric chars.
bool isValidFirestoreId(String? id) {
  if (id == null || id.isEmpty) return false;
  return RegExp(r'^[A-Za-z0-9]{20}$').hasMatch(id);
}

/// Validates a Stripe Checkout Session ID of the form `cs_test_…` or
/// `cs_live_…` followed by alphanumerics.
bool isValidStripeSessionId(String? sessionId) {
  if (sessionId == null || sessionId.isEmpty) return false;
  return RegExp(r'^cs_(test|live)_[A-Za-z0-9]+$').hasMatch(sessionId);
}

/// Safely render an arbitrary error to a display string. Falls back to a
/// fixed message when the input is null or its own `toString()` throws.
String safeErrorToString(dynamic error) {
  if (error == null) {
    return 'Unknown error';
  }
  try {
    return error.toString();
  } catch (_) {
    return 'Error: Unable to display error details';
  }
}

/// Is this failure the guest's connectivity rather than our backend?
///
/// A guest who loses wifi mid-submit used to be shown
/// "Error creating booking: BookingServiceException: Failed to create
/// booking: internal" — developer text that tells them nothing and hides the
/// one thing they can act on. Callables surface a dropped connection as
/// `unavailable` / `deadline-exceeded` / a raw `SocketException`, all of which
/// reach us wrapped in a service exception, so match on the rendered text.
bool isConnectivityError(dynamic error) {
  final text = safeErrorToString(error).toLowerCase();
  return text.contains('unavailable') ||
      text.contains('deadline-exceeded') ||
      text.contains('deadline exceeded') ||
      text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('network') ||
      text.contains('connection') ||
      text.contains('client is offline');
}
