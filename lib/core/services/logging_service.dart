import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Service for logging messages throughout the application.
///
/// Provides tagged logging with different severity levels.
/// In debug mode, logs to console. In production, sends errors to:
/// - Firebase Crashlytics (mobile platforms)
/// - Sentry (web platform)
///
/// Usage:
/// ```dart
/// LoggingService.logInfo('User logged in');
/// LoggingService.logWarning('Low memory');
/// await LoggingService.logError('Failed to save', error, stackTrace);
/// LoggingService.logSuccess('Data saved');
/// ```
class LoggingService {
  // Prevent instantiation - all methods are static
  LoggingService._();

  /// Current user ID for Sentry context (set when user logs in)
  static String? _currentUserId;
  static String? _currentUserEmail;

  /// Set user context for error tracking
  /// Call this when user logs in
  static void setUser(String? userId, {String? email}) {
    _currentUserId = userId;
    _currentUserEmail = email;

    // Set Sentry user context (web)
    if (kIsWeb) {
      if (userId != null) {
        Sentry.configureScope((scope) {
          scope.setUser(SentryUser(id: userId, email: email));
        });
      } else {
        Sentry.configureScope((scope) {
          scope.setUser(null);
        });
      }
    }

    // Set Crashlytics user context (mobile)
    if (!kIsWeb && userId != null) {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
  }

  /// Clear user context (call on logout)
  static void clearUser() {
    setUser(null);
  }

  /// Add breadcrumb for debugging context
  /// Helps understand what user did before error
  static void addBreadcrumb(
    String message, {
    String? category,
    Map<String, dynamic>? data,
  }) {
    if (kIsWeb && kReleaseMode) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category ?? 'app',
          data: data,
          level: SentryLevel.info,
        ),
      );
    }
  }

  /// Log a message with an optional tag
  static void log(String message, {String? tag}) {
    debugPrint('[${tag ?? 'APP'}] $message');
  }

  /// Log an informational message
  static void logInfo(String message) {
    log(message, tag: 'INFO');
  }

  /// Log a warning message
  static void logWarning(String message) {
    log(message, tag: 'WARNING');
  }

  /// Log an error message with optional error object and stack trace
  static Future<void> logError(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) async {
    log(message, tag: 'ERROR');
    if (error != null) {
      debugPrint('Error details: $error');
    }
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }

    // In production, send to error tracking service
    if (kReleaseMode && error != null) {
      if (kIsWeb) {
        // Send to Sentry (web platform)
        await Sentry.captureException(
          error,
          stackTrace: stackTrace,
          withScope: (scope) {
            scope.setTag('source', 'LoggingService');
            scope.setTag('error_message', message);
            if (_currentUserId != null) {
              scope.setUser(
                SentryUser(id: _currentUserId, email: _currentUserEmail),
              );
            }
          },
        );
      } else {
        // Send to Firebase Crashlytics (mobile platforms)
        await FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: message,
          information: ['source: LoggingService'],
          printDetails: false,
        );
      }
    }
  }

  /// Log a warning to Sentry (for important warnings that should be tracked)
  static Future<void> logWarningToSentry(
    String message, {
    Map<String, dynamic>? data,
  }) async {
    if (kIsWeb && kReleaseMode) {
      await Sentry.captureMessage(
        message,
        level: SentryLevel.warning,
        withScope: (scope) {
          if (data != null) {
            // Use tags for searchable data (limited to strings)
            data.forEach((key, value) {
              scope.setTag(key, value.toString());
            });
          }
          if (_currentUserId != null) {
            scope.setUser(
              SentryUser(id: _currentUserId, email: _currentUserEmail),
            );
          }
        },
      );
    }
  }

  /// Log a debug message (only in debug mode)
  static void logDebug(String message) {
    if (kDebugMode) {
      log(message, tag: 'DEBUG');
    }
  }

  /// Log a network request
  /// Also adds breadcrumb for Sentry tracking
  static void logNetworkRequest(
    String method,
    String url, {
    Map<String, dynamic>? params,
  }) {
    // Redact sensitive data from URL and params
    final sanitizedUrl = _redactUrl(url);
    final sanitizedParams = params != null ? _redactMap(params) : null;

    if (kDebugMode) {
      log(
        '$method $sanitizedUrl${sanitizedParams != null ? ' - Params: $sanitizedParams' : ''}',
        tag: 'NETWORK',
      );
    }

    // Add breadcrumb for Sentry (helps debug API-related errors)
    addBreadcrumb(
      '$method $sanitizedUrl',
      category: 'http',
      data: {
        'method': method,
        'url': sanitizedUrl,
        if (sanitizedParams != null) 'params': sanitizedParams,
      },
    );
  }

  // Keys to redact in logs
  static const _sensitiveKeys = {
    'password',
    'token',
    'access_token',
    'refresh_token',
    'auth',
    'key',
    'secret',
    'authorization',
    'api_key',
    'session_id',
    'cvv',
    'card_number',
    'stripe_session_id',
    'code', // OTP or Auth codes
  };

  /// Redact sensitive query parameters from URL
  static String _redactUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.queryParameters.isEmpty) return url;

      final sanitizedParams = Map<String, dynamic>.from(uri.queryParameters);
      bool modified = false;

      for (final key in uri.queryParameters.keys) {
        if (_isSensitiveKey(key)) {
          sanitizedParams[key] = '[REDACTED]';
          modified = true;
        }
      }

      if (!modified) return url;

      return uri.replace(queryParameters: sanitizedParams).toString();
    } catch (e) {
      return url; // Return original if parsing fails
    }
  }

  /// Redact sensitive keys from map
  static Map<String, dynamic> _redactMap(Map<String, dynamic> map) {
    final copy = Map<String, dynamic>.from(map);
    for (final key in map.keys) {
      if (_isSensitiveKey(key)) {
        copy[key] = '[REDACTED]';
      } else if (copy[key] is Map) {
        copy[key] = _redactMap(copy[key] as Map<String, dynamic>);
      } else if (copy[key] is List) {
        // Simple list redaction if needed, usually params are flat or nested maps
      }
    }
    return copy;
  }

  static bool _isSensitiveKey(String key) {
    final lowerKey = key.toLowerCase();

    // Exact matches for short/common terms to avoid false positives
    // e.g. 'zip_code', 'error_code', 'encoding' should NOT be redacted
    const exactMatches = {'key', 'code', 'auth', 'token', 'id'};
    if (exactMatches.contains(lowerKey)) return true;

    // Substring matches for explicitly sensitive terms
    for (final sensitive in _sensitiveKeys) {
      // Skip short keys handled above to prevent "zip_code" matching "code"
      if (exactMatches.contains(sensitive)) continue;

      if (lowerKey.contains(sensitive)) return true;
    }
    return false;
  }

  /// Log a network response
  /// Also adds breadcrumb for Sentry tracking
  static void logNetworkResponse(
    String url,
    int statusCode, {
    dynamic response,
  }) {
    if (kDebugMode) {
      log('Response from $url - Status: $statusCode', tag: 'NETWORK');
      if (response != null) {
        debugPrint('Response data: $response');
      }
    }

    // Add breadcrumb for Sentry (helps debug API-related errors)
    addBreadcrumb(
      'Response $statusCode from $url',
      category: 'http',
      data: {'url': url, 'status_code': statusCode},
    );
  }

  /// Log user action/event
  /// Also adds breadcrumb for Sentry tracking
  static void logUserAction(String action, {Map<String, dynamic>? data}) {
    log(
      'User action: $action${data != null ? ' - Data: $data' : ''}',
      tag: 'USER_ACTION',
    );

    // Add breadcrumb for Sentry (helps debug errors)
    addBreadcrumb(action, category: 'user_action', data: data);
  }

  /// Log navigation event
  /// Also adds breadcrumb for Sentry tracking
  static void logNavigation(String route, {Map<String, dynamic>? params}) {
    logDebug(
      'Navigation to: $route${params != null ? ' - Params: $params' : ''}',
    );

    // Add breadcrumb for Sentry (helps understand user flow before error)
    addBreadcrumb('Navigate to $route', category: 'navigation', data: params);
  }

  /// Log performance metrics
  static void logPerformance(String operation, Duration duration) {
    if (kDebugMode) {
      log('$operation took ${duration.inMilliseconds}ms', tag: 'PERFORMANCE');
    }
  }

  /// Log success message with ✅ indicator
  static void logSuccess(String message, {String? tag}) {
    log('✅ $message', tag: tag);
  }

  /// Log operation start with 🔵 indicator
  static void logOperation(String message, {String? tag}) {
    log('🔵 $message', tag: tag);
  }

  /// Log cache operation
  static void logCache(String message) {
    if (kDebugMode) {
      log(message, tag: 'CACHE');
    }
  }

  /// Log SEO operation
  static void logSEO(String message) {
    if (kDebugMode) {
      log(message, tag: 'SEO');
    }
  }

  /// Safely convert an error object to string, handling null and edge cases
  /// Prevents "Null check operator used on a null value" errors
  static String safeErrorToString(dynamic error) {
    if (error == null) {
      return 'Unknown error';
    }
    try {
      return error.toString();
    } catch (e) {
      // If toString() itself throws, return a safe fallback
      return 'Error occurred (unable to convert to string)';
    }
  }
}
