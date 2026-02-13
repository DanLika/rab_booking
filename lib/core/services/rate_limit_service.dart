import 'package:cloud_functions/cloud_functions.dart';

/// Rate limiting model for login attempts
class LoginAttempt {
  final String email;
  final int attemptCount;
  final DateTime? lockedUntil;

  LoginAttempt({
    required this.email,
    required this.attemptCount,
    this.lockedUntil,
  });

  factory LoginAttempt.fromJson(Map<String, dynamic> data, String email) {
    return LoginAttempt(
      email: email,
      attemptCount: data['attemptCount'] as int? ?? 0,
      lockedUntil: data['lockedUntil'] != null
          ? DateTime.tryParse(data['lockedUntil'] as String)
          : null,
    );
  }

  bool get isLocked {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }

  Duration? get remainingLockTime {
    if (!isLocked) return null;
    return lockedUntil!.difference(DateTime.now());
  }
}

/// Service for rate limiting login attempts.
///
/// Implements BookBed security policy:
/// - Max 5 failed attempts
/// - 15 minute lockout period
/// - Attempts reset after 1 hour of inactivity
///
/// Uses Cloud Functions for secure server-side tracking.
///
/// Usage:
/// ```dart
/// final service = RateLimitService();
///
/// // Check if user is locked out
/// final attempt = await service.checkRateLimit('user@example.com');
/// if (attempt?.isLocked ?? false) {
///   showError(service.getRateLimitMessage(attempt!));
///   return;
/// }
///
/// // Record failed attempt
/// await service.recordFailedAttempt('user@example.com');
///
/// // Reset after successful login
/// await service.resetAttempts('user@example.com');
/// ```
class RateLimitService {
  final FirebaseFunctions _functions;

  // In-memory cache for locked accounts to prevent redundant Cloud Function calls
  // Key: sanitized email, Value: LoginAttempt
  final Map<String, LoginAttempt> _memoryCache = {};

  static const int maxAttempts = 5;

  RateLimitService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// Check if email is currently locked
  Future<LoginAttempt?> checkRateLimit(String email) async {
    final sanitizedEmail = _sanitizeEmail(email);

    // OPTIMIZATION: Check memory cache first
    // If we know the user is locked locally, we don't need to check server
    final cachedAttempt = _memoryCache[sanitizedEmail];
    if (cachedAttempt != null && cachedAttempt.isLocked) {
      return cachedAttempt;
    }

    try {
      final result = await _functions
          .httpsCallable('getLoginRateLimitStatus')
          .call({'email': email});

      final data = result.data as Map;
      final attemptCount = data['attemptCount'] as int? ?? 0;

      // If attemptCount is 0, it means no record or expired.
      if (attemptCount == 0) {
        _memoryCache.remove(sanitizedEmail); // Ensure clean state
        return null; // No attempts recorded
      }

      final attempt = LoginAttempt.fromJson(
        Map<String, dynamic>.from(data),
        email,
      );

      // Update cache if locked
      if (attempt.isLocked) {
        _memoryCache[sanitizedEmail] = attempt;
      } else {
        // Ensure we don't hold stale locked state if now unlocked
        _memoryCache.remove(sanitizedEmail);
      }

      return attempt;
    } catch (e) {
      // If we can't check rate limit (network error), allow the attempt (fail open)
      return null;
    }
  }

  /// Record a failed login attempt
  Future<LoginAttempt> recordFailedAttempt(String email) async {
    final sanitizedEmail = _sanitizeEmail(email);

    try {
      final result = await _functions
          .httpsCallable('recordFailedLoginAttempt')
          .call({'email': email});

      final data = result.data as Map;
      final attempt = LoginAttempt.fromJson(
        Map<String, dynamic>.from(data),
        email,
      );

      // Update cache if locked
      if (attempt.isLocked) {
        _memoryCache[sanitizedEmail] = attempt;
      }

      return attempt;
    } catch (e) {
      // Rethrow to allow caller to handle error
      rethrow;
    }
  }

  /// Reset attempts after successful login
  Future<void> resetAttempts(String email) async {
    final sanitizedEmail = _sanitizeEmail(email);
    try {
      await _functions
          .httpsCallable('resetLoginAttempts')
          .call({'email': email});
      _memoryCache.remove(sanitizedEmail); // Clear cache
    } catch (e) {
      // Ignore deletion errors
    }
  }

  /// Sanitize email for cache key
  String _sanitizeEmail(String email) {
    return email
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9@._-]'), '_');
  }

  /// Get user-friendly error message for locked account
  /// Returns a coded message for rate limit lockout that can be parsed and localized by UI
  String getRateLimitMessage(LoginAttempt attempt) {
    if (!attempt.isLocked) {
      return 'Invalid email or password. ${maxAttempts - attempt.attemptCount} attempts remaining.';
    }

    final remainingSeconds = attempt.remainingLockTime?.inSeconds ?? 0;
    // Return a coded message that the UI can parse and localize
    return 'RATE_LIMIT_LOCKOUT:$remainingSeconds';
  }
}
