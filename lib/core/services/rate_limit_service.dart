import 'package:cloud_firestore/cloud_firestore.dart';

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
      'lockedUntil': lockedUntil != null ? Timestamp.fromDate(lockedUntil!) : null,
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
    try {
      final doc = await _attemptsCollection.doc(_sanitizeEmail(email)).get();

      if (!doc.exists || doc.data() == null) {
        return null; // No attempts recorded
      }

      final attempt = LoginAttempt.fromFirestore(doc.data() as Map<String, dynamic>);

      // Reset attempts if last attempt was > 1 hour ago
      if (DateTime.now().difference(attempt.lastAttemptAt) > attemptResetDuration) {
        await _resetAttempts(email);
        return null;
      }

      return attempt;
    } catch (e) {
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
        final existing = LoginAttempt.fromFirestore(doc.data() as Map<String, dynamic>);

        // Reset if last attempt was > 1 hour ago
        if (DateTime.now().difference(existing.lastAttemptAt) > attemptResetDuration) {
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
    try {
      await _attemptsCollection.doc(_sanitizeEmail(email)).delete();
    } catch (e) {
      // Ignore deletion errors
    }
  }

  /// Sanitize email for use as Firestore document ID
  String _sanitizeEmail(String email) {
    return email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9@._-]'), '_');
  }

  /// Get user-friendly error message for locked account
  String getRateLimitMessage(LoginAttempt attempt) {
    if (!attempt.isLocked) {
      return 'Invalid email or password. ${maxAttempts - attempt.attemptCount} attempts remaining.';
    }

    final remainingMinutes = (attempt.remainingLockTime!.inSeconds / 60).ceil();
    return 'Too many failed attempts. Try again in $remainingMinutes minutes.';
  }
}
