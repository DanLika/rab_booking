import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'logging_service.dart';

/// Rate limiting model for login attempts
class LoginAttempt {
  final String email;
  final int attemptCount;
  final DateTime? lockedUntil;
  final DateTime lastAttemptAt;

  LoginAttempt({
    required this.email,
    required this.attemptCount,
    this.lockedUntil,
    required this.lastAttemptAt,
  });

  factory LoginAttempt.fromFirestore(Map<String, dynamic> data) {
    return LoginAttempt(
      email: data['email'] as String,
      attemptCount: data['attemptCount'] as int,
      lockedUntil: data['lockedUntil'] != null
          ? (data['lockedUntil'] as Timestamp).toDate()
          : null,
      lastAttemptAt: (data['lastAttemptAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'attemptCount': attemptCount,
      'lockedUntil': lockedUntil != null
          ? Timestamp.fromDate(lockedUntil!)
          : null,
      'lastAttemptAt': Timestamp.fromDate(lastAttemptAt),
    };
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
/// Implements BedBooking security policy:
/// - Max 5 failed attempts
/// - 15 minute lockout period
/// - Attempts reset after 1 hour of inactivity
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
  final FirebaseFirestore _firestore;

  // In-memory cache for locked accounts to prevent redundant Firestore reads
  // Key: sanitized email, Value: LoginAttempt
  final Map<String, LoginAttempt> _memoryCache = {};

  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration attemptResetDuration = Duration(hours: 1);

  RateLimitService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for login attempts
  CollectionReference get _attemptsCollection =>
      _firestore.collection('loginAttempts');

  /// Check if email is currently locked
  Future<LoginAttempt?> checkRateLimit(String email) async {
    final sanitizedEmail = _sanitizeEmail(email);

    // OPTIMIZATION: Check memory cache first
    // If we know the user is locked locally, we don't need to check Firestore
    final cachedAttempt = _memoryCache[sanitizedEmail];
    if (cachedAttempt != null && cachedAttempt.isLocked) {
      return cachedAttempt;
    }

    try {
      final doc = await _attemptsCollection.doc(sanitizedEmail).get();

      if (!doc.exists || doc.data() == null) {
        _memoryCache.remove(sanitizedEmail); // Ensure clean state
        return null; // No attempts recorded
      }

      final attempt = LoginAttempt.fromFirestore(
        doc.data() as Map<String, dynamic>,
      );

      // Reset attempts if last attempt was > 1 hour ago
      if (DateTime.now().difference(attempt.lastAttemptAt) >
          attemptResetDuration) {
        await _resetAttempts(email);
        return null;
      }

      // Update cache if locked
      if (attempt.isLocked) {
        _memoryCache[sanitizedEmail] = attempt;
      } else {
        // Ensure we don't hold stale locked state if now unlocked
        _memoryCache.remove(sanitizedEmail);
      }

      return attempt;
    } catch (e) {
      unawaited(LoggingService.logError(
        'Failed to check rate limit for $sanitizedEmail', e,
      ));
      // If we can't check rate limit, allow the attempt (fail open)
      return null;
    }
  }

  /// Record a failed login attempt
  Future<LoginAttempt> recordFailedAttempt(String email) async {
    final sanitizedEmail = _sanitizeEmail(email);
    final docRef = _attemptsCollection.doc(sanitizedEmail);

    try {
      final doc = await docRef.get();

      LoginAttempt attempt;

      if (!doc.exists || doc.data() == null) {
        // First failed attempt
        attempt = LoginAttempt(
          email: email,
          attemptCount: 1,
          lastAttemptAt: DateTime.now(),
        );
      } else {
        final existing = LoginAttempt.fromFirestore(
          doc.data() as Map<String, dynamic>,
        );

        // Reset if last attempt was > 1 hour ago
        if (DateTime.now().difference(existing.lastAttemptAt) >
            attemptResetDuration) {
          attempt = LoginAttempt(
            email: email,
            attemptCount: 1,
            lastAttemptAt: DateTime.now(),
          );
        } else {
          // Increment attempt count
          final newCount = existing.attemptCount + 1;
          final lockedUntil = newCount >= maxAttempts
              ? DateTime.now().add(lockoutDuration)
              : null;

          attempt = LoginAttempt(
            email: email,
            attemptCount: newCount,
            lockedUntil: lockedUntil,
            lastAttemptAt: DateTime.now(),
          );
        }
      }

      // Save to Firestore
      await docRef.set(attempt.toFirestore());

      // Update cache if locked
      if (attempt.isLocked) {
        _memoryCache[sanitizedEmail] = attempt;
      }

      return attempt;
    } catch (e) {
      rethrow;
    }
  }

  /// Reset attempts after successful login
  Future<void> resetAttempts(String email) async {
    await _resetAttempts(email);
  }

  Future<void> _resetAttempts(String email) async {
    final sanitizedEmail = _sanitizeEmail(email);
    try {
      await _attemptsCollection.doc(sanitizedEmail).delete();
      _memoryCache.remove(sanitizedEmail); // Clear cache
    } catch (e) {
      unawaited(LoggingService.logError(
        'Failed to reset login attempts for $sanitizedEmail', e,
      ));
      // Ignore deletion errors
    }
  }

  /// Sanitize email for use as Firestore document ID
  String _sanitizeEmail(String email) {
    return email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9@._-]'), '_');
  }

  /// Get user-friendly error message for locked account
  /// Returns a coded message for rate limit lockout that can be parsed and localized by UI
  String getRateLimitMessage(LoginAttempt attempt) {
    if (!attempt.isLocked) {
      return 'Invalid email or password. ${maxAttempts - attempt.attemptCount} attempts remaining.';
    }

    final remainingSeconds = attempt.remainingLockTime!.inSeconds;
    // Return a coded message that the UI can parse and localize
    return 'RATE_LIMIT_LOCKOUT:$remainingSeconds';
  }
}
