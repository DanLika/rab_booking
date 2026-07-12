part of 'enhanced_auth_provider.dart';

/// Session lifecycle: anonymous sign-in, sign-out (single + all devices),
/// account deletion and password reset.
///
/// Extracted verbatim from EnhancedAuthNotifier on 2026-07-12 — file split
/// only, ZERO behavior change.
mixin _SessionMixin on _EnhancedAuthNotifierBase {
  /// Sign in anonymously (for demo purposes)
  Future<void> signInAnonymously() async {
    state = state.copyWith(isLoading: true);

    try {
      // Set persistence to LOCAL for anonymous sign in (web only)
      if (kIsWeb) {
        await _auth.setPersistence(Persistence.LOCAL);
      }

      final UserCredential userCredential = await _auth.signInAnonymously();

      final user = userCredential.user;
      if (user == null) {
        throw AuthException.noUserReturned('Anonymous');
      }

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        // Create anonymous user profile
        // SECURITY FIX: Don't use toJson() - it includes protected fields
        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'email': 'anonymous@demo.com',
          'first_name': 'Demo',
          'last_name': 'User',
          'role': UserRole.owner.name,
          'accountType': AccountType.trial.name,
          'emailVerified': false,
          'displayName': 'Demo User',
          'onboardingCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
          'profileCompleted': true,
        });
      } else {
        // Update last login for existing users
        await _updateLastLogin(user.uid);
      }

      // Log security event (non-blocking)
      try {
        await _security.logEvent(
          userId: userCredential.user!.uid,
          type: SecurityEventType.login,
          metadata: {'provider': 'anonymous', 'isNewUser': isNewUser},
        );
      } catch (e) {
        LoggingService.log(
          'Security event logging failed: $e',
          tag: 'AUTH_WARNING',
        );
      }

      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      LoggingService.log(
        'Anonymous Sign-In error: ${e.code} - ${e.message}',
        tag: 'AUTH_ERROR',
      );
      final errorMessage = _getAuthErrorMessage(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message instead of FirebaseAuthException
    } catch (e) {
      LoggingService.log(
        'Anonymous Sign-In unexpected error: $e',
        tag: 'AUTH_ERROR',
      );
      const errorMessage = 'Failed to sign in anonymously. Please try again.';
      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message
    }
  }

  /// Sign out.
  ///
  /// [clearSavedEmail] — when true, also wipes the SecureStorage email +
  /// rememberMe flag so the next login screen does NOT pre-fill the
  /// just-logged-out user. Default false preserves the legacy convenience
  /// behavior for session-expiry / credential-revoke paths. Explicit user-
  /// initiated logout (e.g., Profil → Odjava) should pass true.
  /// Audit ref: F-62-03 / F-58c-14.
  @override
  Future<void> signOut({bool clearSavedEmail = false}) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _security.logLogout(userId);
    }

    // Remove FCM token before signing out (prevents notifications to logged-out user)
    try {
      await fcmService.removeToken();
    } catch (e) {
      LoggingService.log(
        'FCM token removal failed (non-critical): $e',
        tag: 'FCM_CLEANUP',
      );
    }

    // Clear user context for Sentry/Crashlytics error tracking
    LoggingService.clearUser();

    if (clearSavedEmail) {
      try {
        await SecureStorageService().clearCredentials();
      } catch (e) {
        LoggingService.log(
          'SecureStorage clearCredentials failed (non-critical): $e',
          tag: 'AUTH_LOGOUT',
        );
      }
    }

    await _auth.signOut();

    // F-58c-14: signOut() only clears the firebaseLocalStorageDb IDB store.
    // sessionStorage + localStorage + cookies survive — a shared-kiosk
    // attacker can still read leftover "remember me" / cached PII. Web-only
    // multi-store wipe closes the gap. Mobile/desktop stub is a no-op.
    if (kIsWeb) {
      await wipeWebStorageOnLogout(reload: clearSavedEmail);
    }

    // Keep isLoading false after sign out (not an initial check)
    state = const EnhancedAuthState(isLoading: false);
  }

  /// Sign out from all devices
  ///
  /// Revokes all refresh tokens for the current user, effectively signing them
  /// out from all devices. The user will need to re-authenticate on each device.
  ///
  /// Use this for:
  /// - Compromised account recovery
  /// - Security concerns after password change
  /// - User-requested "sign out everywhere" feature
  ///
  /// Throws [String] error message on failure.
  Future<void> signOutFromAllDevices() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw 'No user is currently signed in';
    }

    try {
      // Call Cloud Function to revoke all refresh tokens
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('revokeAllRefreshTokens');
      await callable.call();

      LoggingService.log(
        'All refresh tokens revoked for user',
        tag: 'ENHANCED_AUTH',
      );

      // Log security event locally
      await _security.logLogout(userId);

      // Clear user context for Sentry/Crashlytics error tracking
      LoggingService.clearUser();

      // Sign out locally after tokens are revoked
      await _auth.signOut();
      state = const EnhancedAuthState(isLoading: false);
    } on FirebaseFunctionsException catch (e) {
      LoggingService.log(
        'Failed to revoke tokens: ${e.message}',
        tag: 'ENHANCED_AUTH',
      );
      throw e.message ?? 'Failed to sign out from all devices';
    } catch (e) {
      LoggingService.log(
        'Failed to sign out from all devices: $e',
        tag: 'ENHANCED_AUTH',
      );
      throw 'Failed to sign out from all devices. Please try again.';
    }
  }

  /// Delete user account permanently
  ///
  /// This action is irreversible. All user data will be deleted:
  /// - User profile and preferences
  /// - All owned properties, units, and bookings
  /// - Platform connections (Booking.com, Airbnb)
  /// - Guest bookings made by this user will be anonymized (GDPR compliance)
  ///
  /// Required for Apple App Store compliance (mandatory since 2022).
  ///
  /// For email/password users: provide [password]
  /// For social sign-in users: provide [credential] from reauthenticateWithGoogle/Apple
  ///
  /// Throws [String] error message on failure.
  Future<void> deleteAccount({
    String? password,
    AuthCredential? credential,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user is currently signed in';
    }

    // Determine auth method for logging
    final authMethod = credential != null
        ? 'social'
        : (password != null ? 'email' : 'unknown');

    // SENTRY: Log delete account attempt
    LoggingService.log(
      'DELETE_ACCOUNT_ATTEMPT: uid=${user.uid}, method=$authMethod',
      tag: 'AUTH_SECURITY',
    );

    // Re-authenticate user before deletion (security measure)
    try {
      if (credential != null) {
        // Social sign-in re-authentication (Google/Apple)
        await user.reauthenticateWithCredential(credential);
      } else if (password != null) {
        // Email/password re-authentication
        if (user.email == null) {
          // SENTRY: Log anomaly - user has no email
          unawaited(
            LoggingService.logError(
              'DELETE_ACCOUNT_ANOMALY: User has no email',
              Exception('User email is null during delete account'),
            ),
          );
          throw 'User email is missing';
        }
        final emailCredential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(emailCredential);
      } else {
        // SENTRY: Log invalid delete attempt (no credentials provided)
        unawaited(
          _security.logEvent(
            userId: user.uid,
            type: SecurityEventType.suspicious,
            metadata: {
              'reason': 'delete_account_no_credentials',
              'action': 'delete_attempt',
            },
          ),
        );
        throw 'Re-authentication required';
      }

      // SENTRY: Log successful re-authentication for delete
      LoggingService.log(
        'DELETE_ACCOUNT_REAUTH_SUCCESS: uid=${user.uid}, method=$authMethod',
        tag: 'AUTH_SECURITY',
      );
    } on FirebaseAuthException catch (e) {
      // SENTRY: Log failed re-authentication attempt
      unawaited(
        LoggingService.logError('DELETE_ACCOUNT_REAUTH_FAILED: ${e.code}', e),
      );
      unawaited(
        _security.logEvent(
          userId: user.uid,
          type: SecurityEventType.suspicious,
          metadata: {
            'reason': 'delete_account_reauth_failed',
            'error_code': e.code,
            'auth_method': authMethod,
          },
        ),
      );
      throw _getAuthErrorMessage(e);
    }

    try {
      // Call Cloud Function to delete all user data
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('deleteUserAccount');
      await callable.call();

      // SENTRY: Log successful account deletion
      LoggingService.log(
        'DELETE_ACCOUNT_SUCCESS: uid=${user.uid}',
        tag: 'AUTH_SECURITY',
      );

      // Clear user context for error tracking
      LoggingService.clearUser();

      // Clear saved credentials from secure storage
      try {
        await SecureStorageService().clearCredentials();
      } catch (_) {
        // Non-critical, continue
      }

      // Sign out locally (account already deleted on server)
      await _auth.signOut();
      state = const EnhancedAuthState(isLoading: false);
    } on FirebaseFunctionsException catch (e) {
      // SENTRY: Log Cloud Function error during deletion
      unawaited(
        LoggingService.logError(
          'DELETE_ACCOUNT_FUNCTION_ERROR: ${e.code} - ${e.message}',
          e,
        ),
      );
      throw e.message ?? 'Failed to delete account';
    } catch (e) {
      // SENTRY: Log unexpected error during deletion
      unawaited(LoggingService.logError('DELETE_ACCOUNT_ERROR', e));
      throw 'Failed to delete account. Please try again or contact support.';
    }
  }

  /// Reset password using custom email template
  Future<void> resetPassword(String email) async {
    // SENTRY: Log password reset attempt
    LoggingService.log(
      'PASSWORD_RESET_ATTEMPT: email_hash=${email.hashCode}',
      tag: 'AUTH_SECURITY',
    );

    try {
      // Use Cloud Function for custom email template instead of default Firebase Auth email
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendPasswordResetEmail');

      await callable.call({'email': email});

      // SENTRY: Log successful password reset request
      LoggingService.log(
        'PASSWORD_RESET_SENT: email_hash=${email.hashCode}',
        tag: 'AUTH_SECURITY',
      );
    } on FirebaseFunctionsException catch (e) {
      // SENTRY: Log Cloud Function error
      unawaited(
        LoggingService.logError('PASSWORD_RESET_FUNCTION_ERROR: ${e.code}', e),
      );
      throw e.message ?? 'Failed to send password reset email';
    } on FirebaseAuthException catch (e) {
      // SENTRY: Log Firebase Auth error
      unawaited(
        LoggingService.logError('PASSWORD_RESET_AUTH_ERROR: ${e.code}', e),
      );
      throw _getAuthErrorMessage(e);
    } catch (e) {
      // SENTRY: Log unexpected error
      unawaited(LoggingService.logError('PASSWORD_RESET_ERROR', e));
      throw 'Failed to send password reset email: $e';
    }
  }
}
