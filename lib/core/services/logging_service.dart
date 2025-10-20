import 'package:flutter/foundation.dart';
import 'analytics_service.dart';

/// Service for logging messages throughout the application
///
/// Provides tagged logging with different severity levels.
/// In debug mode, logs to console. In production, can be extended
/// to send logs to external services (Firebase, Sentry, etc.)
class LoggingService {
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
      // Send to error tracking services (Sentry, Firebase Crashlytics)
      await AnalyticsService.reportError(
        error,
        stackTrace,
        extra: {
          'source': 'LoggingService',
          'log_message': message,
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
  static void logNetworkRequest(
    String method,
    String url, {
    Map<String, dynamic>? params,
  }) {
    if (kDebugMode) {
      log('$method $url${params != null ? ' - Params: $params' : ''}',
          tag: 'NETWORK');
    }
  }

  /// Log a network response
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
  }

  /// Log user action/event
  static void logUserAction(String action, {Map<String, dynamic>? data}) {
    log('User action: $action${data != null ? ' - Data: $data' : ''}',
        tag: 'USER_ACTION');
  }

  /// Log navigation event
  static void logNavigation(String route, {Map<String, dynamic>? params}) {
    logDebug('Navigation to: $route${params != null ? ' - Params: $params' : ''}');
  }

  /// Log performance metrics
  static void logPerformance(String operation, Duration duration) {
    if (kDebugMode) {
      log('$operation took ${duration.inMilliseconds}ms', tag: 'PERFORMANCE');
    }
  }
}
