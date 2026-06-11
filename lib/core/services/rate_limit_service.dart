import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Rate limiting model for login attempts.
///
/// F-50-02: The underlying storage moved server-side (loginLockout CFs).
/// This model still represents the client-facing view returned by those
/// CFs — fields preserved so existing callers (enhanced_auth_provider.dart,
/// login screen UI) don't need to change.
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

  /// Build from the CF response payload (`AttemptStateResponse` in
  /// functions/src/loginLockout.ts).
  factory LoginAttempt.fromCfResponse(
    String email,
    Map<dynamic, dynamic> data,
  ) {
    final lockedUntilMs = data['lockedUntilMs'];
    return LoginAttempt(
      email: email,
      attemptCount: (data['attemptCount'] as num?)?.toInt() ?? 0,
      lockedUntil: lockedUntilMs is num
          ? DateTime.fromMillisecondsSinceEpoch(lockedUntilMs.toInt())
          : null,
      lastAttemptAt: DateTime.now(),
    );
  }

  /// Legacy factory kept for compatibility with any direct Firestore reads
  /// during the migration window. Not used by the refactored service.
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
/// F-50-02: Pre-fix this wrote `loginAttempts/{email}` Firestore documents
/// directly from the client; the rule `allow get, create, update: if true`
/// allowed any anonymous caller to write arbitrary lockout state — pre-auth
/// account-lockout DoS. Post-fix the rule is locked (`read, write: if false`)
/// and all access routes through `functions/src/loginLockout.ts` callables.
///
/// Public API preserved (`checkRateLimit`, `recordFailedAttempt`,
/// `resetAttempts`, `getRateLimitMessage`) so call sites in
/// `enhanced_auth_provider.dart` don't need to change.
///
/// Implements BookBed security policy:
/// - Max 5 failed attempts
/// - 15 minute lockout period
/// - Attempts reset after 1 hour of inactivity
class RateLimitService {
  /// Cloud Functions instance — login lockout CFs live in europe-west1
  /// (per `.claude/rules/cloud-functions.md` § Region split).
  final FirebaseFunctions _functions;

  /// In-memory cache for recently observed lock state. Bounded by
  /// the implicit Firebase callable timeout; staleness is OK because the
  /// CF is the source of truth on each call site that matters.
  final Map<String, LoginAttempt> _memoryCache = {};

  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration attemptResetDuration = Duration(hours: 1);

  RateLimitService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// Sanitize email so the cache key matches the CF's emailToDocId
  /// normalization.
  String _sanitizeEmail(String email) {
    return email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9@._-]'), '_');
  }

  /// Check if email is currently locked.
  ///
  /// Returns `null` when no attempts have been recorded (no lockout state).
  /// Fail-open on errors: a CF outage should not lock all users out — IP-based
  /// `checkLoginRateLimit` remains active independently.
  Future<LoginAttempt?> checkRateLimit(String email) async {
    final sanitizedEmail = _sanitizeEmail(email);

    // OPTIMIZATION: serve cached locked state without a round-trip.
    final cached = _memoryCache[sanitizedEmail];
    if (cached != null && cached.isLocked) {
      return cached;
    }

    try {
      final callable = _functions.httpsCallable('getLoginLockoutStatus');
      final result = await callable.call<Map<dynamic, dynamic>>({
        'email': email,
      });
      final data = result.data;
      final attempt = LoginAttempt.fromCfResponse(email, data);

      // Cache locked state; clear stale.
      if (attempt.isLocked) {
        _memoryCache[sanitizedEmail] = attempt;
      } else {
        _memoryCache.remove(sanitizedEmail);
      }

      // Treat "no attempts" as null (matches pre-fix semantics).
      return attempt.attemptCount == 0 ? null : attempt;
    } catch (_) {
      // Fail-open: allow login attempt; IP rate limit still active.
      return null;
    }
  }

  /// Record a failed login attempt.
  ///
  /// Calls the server-side `recordLoginFailure` callable. On rate-limit /
  /// network error, returns a synthetic LoginAttempt that doesn't show
  /// the user a lockout — the next successful auth will reset the counter.
  Future<LoginAttempt> recordFailedAttempt(String email) async {
    final sanitizedEmail = _sanitizeEmail(email);
    try {
      final callable = _functions.httpsCallable('recordLoginFailure');
      final result = await callable.call<Map<dynamic, dynamic>>({
        'email': email,
      });
      final attempt = LoginAttempt.fromCfResponse(email, result.data);

      if (attempt.isLocked) {
        _memoryCache[sanitizedEmail] = attempt;
      }
      return attempt;
    } catch (_) {
      // Network / rate-limit failure: surface a non-locked attempt so the
      // UI shows the standard "invalid credentials" path rather than a
      // misleading lockout message. The server-side counter is unaffected
      // when our call doesn't reach it.
      return LoginAttempt(
        email: email,
        attemptCount: 1,
        lastAttemptAt: DateTime.now(),
      );
    }
  }

  /// Reset attempts after successful login.
  ///
  /// Calls the auth-required `clearLoginAttempts` callable. Should be called
  /// AFTER Firebase Auth signIn succeeds (so request.auth.token.email is set).
  Future<void> resetAttempts(String email) async {
    final sanitizedEmail = _sanitizeEmail(email);
    _memoryCache.remove(sanitizedEmail);
    try {
      final callable = _functions.httpsCallable('clearLoginAttempts');
      await callable.call<Map<dynamic, dynamic>>({'email': email});
    } catch (_) {
      // Server-side attempts will auto-reset after 1 hour of inactivity
      // even if this call fails; not worth surfacing to UI.
    }
  }

  /// Get user-friendly error message for locked account.
  /// Returns a coded message for rate limit lockout that can be parsed and
  /// localized by UI.
  String getRateLimitMessage(LoginAttempt attempt) {
    if (!attempt.isLocked) {
      return 'Invalid email or password. ${maxAttempts - attempt.attemptCount} attempts remaining.';
    }

    final remainingSeconds = attempt.remainingLockTime!.inSeconds;
    // Coded message — UI parses to localize.
    return 'RATE_LIMIT_LOCKOUT:$remainingSeconds';
  }
}
