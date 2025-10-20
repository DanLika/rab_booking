import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Retry utility with exponential backoff
/// Implements best practices for handling transient failures in network requests
class RetryUtils {
  RetryUtils._(); // Private constructor

  /// Execute a function with retry logic and exponential backoff
  ///
  /// [operation] - The async operation to retry
  /// [maxAttempts] - Maximum number of retry attempts (default: 3)
  /// [initialDelay] - Initial delay before first retry in milliseconds (default: 1000ms)
  /// [maxDelay] - Maximum delay between retries in milliseconds (default: 10000ms)
  /// [factor] - Exponential backoff factor (default: 2.0)
  /// [shouldRetry] - Optional function to determine if error is retryable
  ///
  /// Example:
  /// ```dart
  /// final data = await RetryUtils.retry(
  ///   () => supabase.from('users').select(),
  ///   maxAttempts: 3,
  /// );
  /// ```
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    int initialDelay = 1000,
    int maxDelay = 10000,
    double factor = 2.0,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    int delay = initialDelay;

    while (true) {
      attempt++;

      try {
        return await operation();
      } catch (e) {
        // Check if we should retry this error
        final isRetryable = shouldRetry?.call(e) ?? _isRetryableError(e);

        // If this is the last attempt or error is not retryable, throw
        if (attempt >= maxAttempts || !isRetryable) {
          rethrow;
        }

        // Calculate delay with exponential backoff and jitter
        final jitter = Random().nextInt(500); // 0-500ms random jitter
        final currentDelay = min(delay + jitter, maxDelay);

        // Log retry attempt (in production, use proper logging)
        print('Retry attempt $attempt/$maxAttempts after ${currentDelay}ms. Error: $e');

        // Wait before next attempt
        await Future.delayed(Duration(milliseconds: currentDelay));

        // Increase delay exponentially
        delay = (delay * factor).round();
      }
    }
  }

  /// Determine if an error is retryable (transient failure)
  static bool _isRetryableError(dynamic error) {
    // Network errors - retryable
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException) {
      return true;
    }

    // Supabase errors
    if (error is PostgrestException) {
      // Retry on server errors (5xx), not client errors (4xx)
      final code = error.code;
      if (code != null) {
        // Retry on 500, 502, 503, 504 (server errors)
        if (code.startsWith('5')) return true;
        // Retry on 408 (Request Timeout) and 429 (Too Many Requests)
        if (code == '408' || code == '429') return true;
      }
      return false;
    }

    // Auth errors - usually not retryable
    if (error is AuthException) {
      return false;
    }

    // Storage errors
    if (error is StorageException) {
      // Retry on server errors, not client errors
      final statusCode = error.statusCode;
      if (statusCode != null) {
        final code = int.tryParse(statusCode) ?? 0;
        return code >= 500 || code == 408 || code == 429;
      }
      return false;
    }

    // Unknown errors - don't retry by default
    return false;
  }

  /// Execute with retry and fallback value on complete failure
  ///
  /// Useful when you want to provide a default value if all retries fail
  ///
  /// Example:
  /// ```dart
  /// final data = await RetryUtils.retryOrDefault(
  ///   () => supabase.from('stats').select(),
  ///   defaultValue: [],
  /// );
  /// ```
  static Future<T> retryOrDefault<T>(
    Future<T> Function() operation, {
    required T defaultValue,
    int maxAttempts = 3,
    int initialDelay = 1000,
    int maxDelay = 10000,
  }) async {
    try {
      return await retry(
        operation,
        maxAttempts: maxAttempts,
        initialDelay: initialDelay,
        maxDelay: maxDelay,
      );
    } catch (e) {
      // Log error and return default value
      print('All retry attempts failed. Returning default value. Error: $e');
      return defaultValue;
    }
  }

  /// Execute with retry and timeout
  ///
  /// Combines retry logic with timeout to prevent hanging requests
  ///
  /// Example:
  /// ```dart
  /// final data = await RetryUtils.retryWithTimeout(
  ///   () => supabase.from('users').select(),
  ///   timeout: Duration(seconds: 30),
  /// );
  /// ```
  static Future<T> retryWithTimeout<T>(
    Future<T> Function() operation, {
    required Duration timeout,
    int maxAttempts = 3,
    int initialDelay = 1000,
    int maxDelay = 10000,
  }) async {
    return retry(
      () => operation().timeout(timeout),
      maxAttempts: maxAttempts,
      initialDelay: initialDelay,
      maxDelay: maxDelay,
    );
  }
}

/// Import for network errors
class SocketException implements Exception {
  final String message;
  SocketException(this.message);
  @override
  String toString() => 'SocketException: $message';
}

/// Import for HTTP errors
class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => 'HttpException: $message';
}
