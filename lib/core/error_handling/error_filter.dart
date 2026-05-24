import 'package:flutter/foundation.dart';

/// Audit/20 — shared filter predicates for ErrorBoundary, GlobalErrorHandler,
/// and Sentry `beforeSend` sinks. Rejects infrastructure / test-harness noise
/// (VM service extension dispatch, `dart:developer`, Marionette matcher
/// failures, framework `silent` errors).

/// Safely convert exception to string, handling null and edge cases.
/// Prevents "Null check operator used on a null value" errors.
String safeExceptionToString(dynamic exception) {
  if (exception == null) {
    return 'Unknown error';
  }
  try {
    return exception.toString();
  } catch (e) {
    return 'Error: Unable to display error details';
  }
}

/// Stack-frame patterns that indicate infrastructure / debug-bridge / test
/// harness origin — never user-triggered. Audit/20 §2.
const List<String> _blockedFramePatterns = <String>[
  'dart:developer',
  'dart:vm_service',
  'marionette_extension',
  'registerExtension',
];

bool _stackMatchesBlockedFrame(String stackString) {
  for (final pattern in _blockedFramePatterns) {
    if (stackString.contains(pattern)) return true;
  }
  return false;
}

bool _messageMatchesBlockedException(String msg) {
  if (msg.startsWith('Exception: Element matching {')) return true;
  if (msg.contains('VM service extension')) return true;
  return false;
}

/// Core predicate — accepts any exception-shape via optional stringified inputs.
/// Returns true if the error represents a user-facing failure that should
/// surface to UI and/or production logging. False for infrastructure noise.
///
/// Used directly by Sentry `beforeSend` (which gets `event.throwable` +
/// stringified stack) and as the base for the Flutter-specific wrappers.
bool isUserFacingException({
  Object? throwable,
  String? messageString,
  String? stackString,
}) {
  if (stackString != null && _stackMatchesBlockedFrame(stackString)) {
    return false;
  }
  final msg = messageString ?? safeExceptionToString(throwable);
  if (_messageMatchesBlockedException(msg)) return false;
  return true;
}

/// `FlutterError.onError` variant — applies the framework `silent` convention
/// in addition to stack/message filters.
bool isUserFacingFlutterError(FlutterErrorDetails details) {
  if (details.silent) return false;
  return isUserFacingException(
    throwable: details.exception,
    stackString: details.stack?.toString(),
  );
}

/// `PlatformDispatcher.onError` variant — raw `(error, stack)` shape.
bool isUserFacingAsyncError(Object error, StackTrace? stack) {
  return isUserFacingException(
    throwable: error,
    stackString: stack?.toString(),
  );
}
