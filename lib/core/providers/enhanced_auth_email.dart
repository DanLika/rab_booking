part of 'enhanced_auth_provider.dart';

/// Email/password authentication: sign-in, registration (incl. cloud
/// registration rate-limit seam) and email-verification flows.
///
/// Extracted verbatim from EnhancedAuthNotifier on 2026-07-12 — file split
/// only, ZERO behavior change. PII-redaction and SF-007 handling untouched.
mixin _EmailAuthMixin on _EnhancedAuthNotifierBase {
  /// Sign in with email and password (with rate limiting)
  Future<void> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    LoggingService.log(
      'signInWithEmail called, rememberMe=$rememberMe',
      tag: 'ENHANCED_AUTH',
    );
    try {
      state = state.copyWith(isLoading: true);

      // PERFORMANCE: Run Cloud and Local checks in PARALLEL to reduce wait time

      // 1. Cloud Rate Limit Future (wrapped to handle errors internally)
      final cloudRateLimitFuture = (() async {
        try {
          final functions = FirebaseFunctions.instanceFor(
            region: 'europe-west1',
          );
          final callable = functions.httpsCallable('checkLoginRateLimit');
          await callable.call({'email': email});
        } on FirebaseFunctionsException catch (e) {
          if (e.code == 'resource-exhausted') {
            LoggingService.log(
              'IP-based rate limit exceeded for login',
              tag: 'ENHANCED_AUTH',
            );
            // Throw message string to be caught by outer try/catch
            throw e.message ??
                'Too many login attempts. Please wait before trying again.';
          }
          // Continue with login if rate limit check fails (fail-open for availability)
          LoggingService.log(
            'IP rate limit check failed, continuing: ${e.message}',
            tag: 'AUTH_WARNING',
          );
        }
      })();

      // 2. Local Rate Limit & Persistence Future (run in parallel)
      final localChecksFuture = Future.wait([
        _rateLimit.checkRateLimit(email),
        kIsWeb
            ? _auth.setPersistence(
                rememberMe ? Persistence.LOCAL : Persistence.SESSION,
              )
            : Future<void>.value(),
      ]);

      // Wait for ALL checks to complete
      // If Cloud limit throws, this await will throw and be caught by outer try/catch
      final results = await Future.wait([
        cloudRateLimitFuture,
        localChecksFuture,
      ]);

      // Extract local results
      final localResults = results[1] as List<dynamic>;
      final rateLimit = localResults[0] as LoginAttempt?;

      // Check rate limit result
      if (rateLimit != null && rateLimit.isLocked) {
        LoggingService.log(
          'Email-based rate limit exceeded for $email',
          tag: 'ENHANCED_AUTH',
        );
        throw _rateLimit.getRateLimitMessage(rateLimit);
      }

      // Attempt sign in
      LoggingService.log(
        'Calling Firebase signInWithEmailAndPassword: email=$email',
        tag: 'ENHANCED_AUTH',
      );

      UserCredential credential;
      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        // SENTRY: Enhanced error tracking with specific error codes
        LoggingService.log(
          'AUTH_LOGIN_FAILED: code=${e.code}, method=email',
          tag: 'AUTH_ERROR',
        );
        unawaited(LoggingService.logError('AUTH_LOGIN_FAILED: ${e.code}', e));

        // PROVIDER MISMATCH DETECTION
        // When user tries email/password but account was created with Google/Apple
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          // Check if this email might be linked to a social provider
          // by checking if user exists in Firestore with a different provider
          try {
            final userQuery = await _firestore
                .collection('users')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();

            if (userQuery.docs.isNotEmpty) {
              final userData = userQuery.docs.first.data();
              final lastProvider = userData['last_provider'] as String?;

              if (lastProvider == 'google.com' || lastProvider == 'apple.com') {
                // Log provider mismatch for Sentry tracking
                unawaited(
                  _security.logEvent(
                    userId: userQuery.docs.first.id,
                    type: SecurityEventType.suspicious,
                    metadata: {
                      'reason': 'provider_mismatch',
                      'attempted_method': 'email',
                      'actual_provider': lastProvider,
                      'action': 'login_attempt',
                    },
                  ),
                );

                // Throw specific error for provider mismatch
                final providerName = lastProvider == 'google.com'
                    ? 'Google'
                    : 'Apple';
                throw 'This account uses $providerName Sign-In. Please use the "$providerName" button to log in.';
              }
            }
          } catch (queryError) {
            if (queryError is String) rethrow;
            // If Firestore query fails, continue with normal error handling
            LoggingService.log(
              'Provider mismatch check failed: $queryError',
              tag: 'AUTH_WARNING',
            );
          }
        }

        // Re-throw for normal error handling
        rethrow;
      }

      LoggingService.log(
        'Firebase sign in successful for ${credential.user?.uid}',
        tag: 'ENHANCED_AUTH',
      );

      // Explicitly load user profile immediately
      // (Don't rely solely on auth state listener which may not trigger)
      // _loadUserProfile will set isLoading=false when profile is loaded
      LoggingService.log(
        'Explicitly loading user profile...',
        tag: 'ENHANCED_AUTH',
      );
      await _loadUserProfile(credential.user!);
      LoggingService.log(
        'User profile loaded, isLoading should be false now',
        tag: 'ENHANCED_AUTH',
      );

      // ANALYTICS: Log successful login
      unawaited(AnalyticsService.instance.logLogin('email'));

      // Save or clear credentials based on Remember Me setting (non-blocking)
      // SECURITY FIX SF-007: Only save email, never password
      unawaited(() async {
        try {
          if (rememberMe) {
            await SecureStorageService().saveEmail(email);
            LoggingService.log(
              'Email saved to secure storage (SF-007: password not stored)',
              tag: 'ENHANCED_AUTH',
            );
          } else {
            await SecureStorageService().clearCredentials();
            LoggingService.log(
              'Credentials cleared from secure storage',
              tag: 'ENHANCED_AUTH',
            );
          }
        } catch (e) {
          // Don't block login if secure storage fails
          LoggingService.log(
            'Secure storage operation failed: $e',
            tag: 'AUTH_WARNING',
          );
        }
      }());

      // Reset rate limit on success (non-blocking)
      unawaited(
        _rateLimit.resetAttempts(email).catchError((e) {
          LoggingService.log(
            'Rate limit reset failed: $e',
            tag: 'AUTH_WARNING',
          );
        }),
      );

      // Get geolocation and log security event (completely non-blocking)
      unawaited(() async {
        String? location;
        try {
          final geoResult = await _geolocation.getCurrentLocation().timeout(
            const Duration(seconds: 3),
            onTimeout: () => null,
          );
          location = geoResult?.locationString;
        } catch (e) {
          // Ignore geolocation errors
          location = null;
        }

        // Log security event with location (non-blocking)
        try {
          await _security.logLogin(credential.user!, location: location);
        } catch (e) {
          // Don't block login if security logging fails
          LoggingService.log(
            'Security event logging failed: $e',
            tag: 'AUTH_WARNING',
          );
        }
      }());

      // Auth state listener will handle the rest
      LoggingService.log(
        'Sign in completed, redirecting to dashboard...',
        tag: 'ENHANCED_AUTH',
      );
    } on FirebaseAuthException catch (e) {
      unawaited(
        LoggingService.logError(
          'Firebase sign in FAILED: ${e.code} - ${e.message}',
          e,
        ),
      );

      // Determine error message, with rate limit check wrapped in try-catch
      // to ensure isLoading is ALWAYS reset even if rate limit operations fail
      String errorMessage;
      try {
        // Record failed attempt
        await _rateLimit.recordFailedAttempt(email);

        // Get updated rate limit info
        final updatedLimit = await _rateLimit.checkRateLimit(email);
        errorMessage = updatedLimit != null && updatedLimit.isLocked
            ? _rateLimit.getRateLimitMessage(updatedLimit)
            : _getAuthErrorMessage(e);
      } catch (rateLimitError) {
        // If rate limit check fails, just use the original auth error message
        LoggingService.log(
          'Rate limit check failed: $rateLimitError',
          tag: 'ENHANCED_AUTH',
        );
        errorMessage = _getAuthErrorMessage(e);
      }

      // CRITICAL: Always reset isLoading to prevent infinite loading state
      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message instead of FirebaseAuthException
    } catch (e) {
      unawaited(LoggingService.logError('Sign in ERROR', e));
      final errorMessage = e.toString();
      // CRITICAL: Always reset isLoading to prevent infinite loading state
      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message
    }
  }

  /// Register with email and password
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? avatarUrl,
    Uint8List? profileImageBytes,
    String? profileImageName,
    bool acceptedTerms = false,
    bool acceptedPrivacy = false,
    bool newsletterOptIn = false,
  }) async {
    // Validate firstName and lastName
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      throw 'First name and last name are required';
    }

    // Validate password minimum length (8+ characters)
    final passwordError = PasswordValidator.validateMinimumLength(password);
    if (passwordError != null) {
      throw passwordError;
    }

    if (!acceptedTerms || !acceptedPrivacy) {
      throw 'You must accept the Terms & Conditions and Privacy Policy';
    }

    try {
      state = state.copyWith(isLoading: true);

      // PERFORMANCE: Run Cloud and Local checks in PARALLEL

      // 1. Cloud Rate Limit Future (wrapped to handle errors internally).
      // Extracted to an overridable method so unit tests can bypass the
      // FirebaseFunctions.instanceFor call (which needs a live Firebase app).
      final cloudRateLimitFuture = checkCloudRegistrationRateLimit(email);

      // 2. Local Rate Limit Future
      final localRateLimitFuture = _rateLimit.checkRateLimit(email);

      // Wait for both in parallel
      final (_, rateLimit) = await (
        cloudRateLimitFuture,
        localRateLimitFuture,
      ).wait;

      // Check email-based rate limit
      if (rateLimit != null && rateLimit.isLocked) {
        throw _rateLimit.getRateLimitMessage(rateLimit);
      }

      // NOTE: fetchSignInMethodsForEmail is deprecated and disabled by default
      // for security (email enumeration protection). Instead, we handle the
      // email-already-in-use error with an improved message that mentions
      // Google/Apple Sign-In as potential alternatives.

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // credential.user is guaranteed non-null after successful registration
      final user = credential.user;
      if (user == null) {
        throw Exception('User creation succeeded but user is null');
      }

      // Upload profile image if provided
      String? finalAvatarUrl = avatarUrl;
      if (profileImageBytes != null && profileImageName != null) {
        try {
          final storageService = StorageService();
          finalAvatarUrl = await storageService.uploadProfileImage(
            userId: user.uid,
            imageBytes: profileImageBytes,
            fileName: profileImageName,
          );
        } catch (e) {
          // If image upload fails, continue without image
          LoggingService.log(
            'Failed to upload profile image during registration: $e',
            tag: 'AUTH_ERROR',
          );
        }
      }

      // Create user profile
      // Note: onboardingCompleted defaults to false (show onboarding wizard for new users)
      final userModel = UserModel(
        id: user.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: UserRole.owner, // Default to owner for registration
        phone: phone,
        avatarUrl: finalAvatarUrl,
        displayName: '$firstName $lastName',
        createdAt: DateTime.now(),
      );

      // SECURITY FIX: Don't use toJson() spread - it includes protected fields
      // like admin_override_account_type, lifetime_license_granted_at, etc.
      // which are blocked by Firestore security rules on user creation.
      // Explicitly list only the fields allowed for new user registration.
      //
      // CRITICAL: this profile doc MUST land. The Auth user already exists
      // (created just above) — if this write is denied/fails and we let the
      // account stand, it is orphaned: Auth succeeds but every later login
      // dies in _loadUserProfile ("access denied", no users/{uid} doc). So we
      // fail LOUD and roll the Auth user back, keeping registration atomic and
      // freeing the email for a clean retry instead of breaking login later.
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'id': userModel.id,
          'email': userModel.email,
          'first_name': userModel.firstName,
          'last_name': userModel.lastName,
          'role': userModel.role.name,
          'accountType': userModel.accountType.name,
          'emailVerified': userModel.emailVerified,
          'phone': userModel.phone,
          'avatar_url': userModel.avatarUrl,
          'displayName': userModel.displayName,
          'onboardingCompleted': userModel.onboardingCompleted,
          // Canonical schema field — see _createUserProfile note.
          'created_at': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'profileCompleted': userModel.profileCompleted,
          'newsletterOptIn': newsletterOptIn,
        });
      } catch (profileError, profileStack) {
        unawaited(
          LoggingService.logError(
            'REGISTER_PROFILE_WRITE_FAILED — rolling back orphaned Auth user',
            profileError,
            profileStack,
          ),
        );
        // Best-effort rollback so login can't break later. The user was just
        // created, so delete() still has a fresh credential. If even the
        // rollback fails we still surface the error — an orphan we logged for
        // manual cleanup beats a silent half-account the user can't recover.
        try {
          await user.delete();
        } catch (rollbackError) {
          unawaited(
            LoggingService.logError(
              'REGISTER_ROLLBACK_FAILED — Auth user orphaned, manual cleanup needed',
              rollbackError,
            ),
          );
        }
        throw 'Registration could not be completed. Please try again.';
      }

      // Update display name in Firebase Auth
      await user.updateDisplayName('$firstName $lastName');

      // ANALYTICS: Log successful sign up
      unawaited(AnalyticsService.instance.logSignUp('email'));

      // Reset rate limit on success
      await _rateLimit.resetAttempts(email);

      // Send email verification (non-blocking - user can resend from verification screen)
      // DISABLED: Only send verification email if flag is enabled
      if (AuthFeatureFlags.requireEmailVerification) {
        try {
          await user.sendEmailVerification();
        } catch (e) {
          // Don't block registration if email verification fails
          LoggingService.log(
            'Failed to send verification email: $e',
            tag: 'AUTH_WARNING',
          );
        }
      }

      // Get geolocation (with timeout to avoid blocking registration)
      String? location;
      try {
        final geoResult = await _geolocation.getCurrentLocation().timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );
        location = geoResult?.locationString;
      } catch (e) {
        // Ignore geolocation errors, don't block registration
        location = null;
      }

      // Log registration with location (non-blocking)
      try {
        await _security.logEvent(
          userId: user.uid,
          type: SecurityEventType.registration,
          location: location,
          metadata: {'email': email, 'accountType': AccountType.trial.name},
        );

        // Log email verification sent
        await _security.logEvent(
          userId: user.uid,
          type: SecurityEventType.emailVerification,
          location: location,
          metadata: {'action': 'sent'},
        );
      } catch (e) {
        // Don't block registration if security logging fails
        LoggingService.log(
          'Security event logging failed during registration: $e',
          tag: 'AUTH_WARNING',
        );
      }

      // SECURITY: Set state with requiresEmailVerification flag
      // This ensures newly registered users are redirected to email verification screen
      state = EnhancedAuthState(
        firebaseUser: credential.user,
        userModel: userModel,
        requiresEmailVerification: AuthFeatureFlags.requireEmailVerification,
      );

      // BUG FIX: Initialize FCM for newly registered users
      // The authStateChanges listener calls _loadUserProfile() but the optimization
      // at line 145-152 skips it because userModel is already set above.
      // This means fcmService.initialize() (line 305) never gets called for new users.
      // We need to initialize FCM explicitly here.
      unawaited(
        fcmService.initialize().catchError((e) {
          LoggingService.log(
            'FCM initialization failed during registration (non-critical): $e',
            tag: 'FCM_INIT',
          );
        }),
      );
    } on FirebaseAuthException catch (e) {
      // SENTRY: Log registration failure with error code
      LoggingService.log('REGISTER_FAILED: code=${e.code}', tag: 'AUTH_ERROR');
      unawaited(LoggingService.logError('REGISTER_FAILED: ${e.code}', e));

      // PRIORITY: Critical errors like email-already-in-use should ALWAYS
      // be shown to user, not hidden behind rate limit messages.
      // This fixes the bug where users registering with Google-linked emails
      // see "try again in X seconds" instead of "email already exists".
      if (e.code == 'email-already-in-use') {
        // SENTRY: Log email conflict - check if it's a provider mismatch
        try {
          final userQuery = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (userQuery.docs.isNotEmpty) {
            final userData = userQuery.docs.first.data();
            final lastProvider = userData['last_provider'] as String?;

            // Log the provider conflict for analytics
            LoggingService.log(
              'REGISTER_EMAIL_CONFLICT: provider=$lastProvider',
              tag: 'AUTH_SECURITY',
            );
          }
        } catch (_) {
          // Ignore query errors, continue with standard error message
        }

        final errorMessage = _getAuthErrorMessage(e);
        state = state.copyWith(isLoading: false, error: errorMessage);
        throw errorMessage;
      }

      // Handle account-exists-with-different-credential (rare but possible)
      if (e.code == 'account-exists-with-different-credential') {
        LoggingService.log(
          'REGISTER_CREDENTIAL_CONFLICT: Different auth provider exists',
          tag: 'AUTH_SECURITY',
        );
        const errorMessage =
            'An account already exists with this email using a different sign-in method. '
            'Please use Google or Apple Sign-In instead.';
        state = state.copyWith(isLoading: false, error: errorMessage);
        throw errorMessage;
      }

      // For other errors, apply rate limiting logic
      String errorMessage;
      try {
        // Record failed attempt
        await _rateLimit.recordFailedAttempt(email);

        // Get updated rate limit info
        final updatedLimit = await _rateLimit.checkRateLimit(email);
        errorMessage = updatedLimit != null && updatedLimit.isLocked
            ? _rateLimit.getRateLimitMessage(updatedLimit)
            : _getAuthErrorMessage(e);
      } catch (rateLimitError) {
        // If rate limit check fails, just use the original auth error message
        LoggingService.log(
          'Rate limit check failed: $rateLimitError',
          tag: 'ENHANCED_AUTH',
        );
        errorMessage = _getAuthErrorMessage(e);
      }

      // CRITICAL: Always reset isLoading to prevent infinite loading state
      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message instead of FirebaseAuthException
    } catch (e) {
      // SENTRY: Log unexpected registration error
      unawaited(LoggingService.logError('REGISTER_UNEXPECTED_ERROR', e));
      final errorMessage = e.toString();
      // CRITICAL: Always reset isLoading to prevent infinite loading state
      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message
    }
  }

  /// IP-based registration rate-limit check via the `checkRegistrationRateLimit`
  /// Cloud Function (europe-west1). Fails OPEN on transient/unknown errors so a
  /// flaky rate-limiter never blocks signup; throws a user-facing message only
  /// when the server explicitly reports `resource-exhausted`.
  ///
  /// Extracted from [registerWithEmail] as an overridable seam: it touches
  /// `FirebaseFunctions.instanceFor`, which needs an initialized Firebase app
  /// and is therefore unreachable under `flutter test`. Unit tests override
  /// this to a no-op (mirroring the repo's Fake-bypass pattern for
  /// FirebaseFunctions) so the rest of the registration flow can be exercised.
  @visibleForTesting
  @protected
  Future<void> checkCloudRegistrationRateLimit(String email) async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('checkRegistrationRateLimit');
      await callable.call({'email': email});
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        LoggingService.log(
          'IP-based rate limit exceeded for registration',
          tag: 'ENHANCED_AUTH',
        );
        throw e.message ??
            'Too many registration attempts. Please wait before trying again.';
      }
      // Continue with registration if rate limit check fails (fail-open for availability)
      LoggingService.log(
        'IP rate limit check failed, continuing: ${e.message}',
        tag: 'AUTH_WARNING',
      );
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      // SENTRY: Log anomaly - no user when trying to send verification
      unawaited(
        LoggingService.logError(
          'EMAIL_VERIFICATION_NO_USER',
          Exception(
            'Attempted to send email verification without logged in user',
          ),
        ),
      );
      throw 'No user logged in';
    }

    // SENTRY: Log verification email request
    LoggingService.log(
      'EMAIL_VERIFICATION_REQUESTED: uid=${user.uid}',
      tag: 'AUTH_SECURITY',
    );

    try {
      await user.sendEmailVerification();
      await _security.logEvent(
        userId: user.uid,
        type: SecurityEventType.emailVerification,
        metadata: {'action': 'resent'},
      );

      // SENTRY: Log successful send
      LoggingService.log(
        'EMAIL_VERIFICATION_SENT: uid=${user.uid}',
        tag: 'AUTH_SECURITY',
      );
    } catch (e) {
      // SENTRY: Log verification email failure
      unawaited(LoggingService.logError('EMAIL_VERIFICATION_SEND_FAILED', e));
      throw 'Failed to send verification email: $e';
    }
  }

  /// Resend email change verification
  ///
  /// Used when user changed their email and needs to verify the NEW email.
  /// This calls verifyBeforeUpdateEmail which sends a verification link
  /// to the new email address.
  Future<void> resendEmailChangeVerification(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user logged in';
    }

    LoggingService.log(
      'EMAIL_CHANGE_VERIFICATION_REQUESTED: uid=${user.uid}, newEmail=$newEmail',
      tag: 'AUTH_SECURITY',
    );

    try {
      await user.verifyBeforeUpdateEmail(newEmail);
      await _security.logEvent(
        userId: user.uid,
        type: SecurityEventType.emailVerification,
        metadata: {'action': 'resent_email_change', 'newEmail': newEmail},
      );

      LoggingService.log(
        'EMAIL_CHANGE_VERIFICATION_SENT: uid=${user.uid}, newEmail=$newEmail',
        tag: 'AUTH_SECURITY',
      );
    } catch (e) {
      unawaited(
        LoggingService.logError('EMAIL_CHANGE_VERIFICATION_SEND_FAILED', e),
      );
      throw 'Failed to send email change verification: $e';
    }
  }

  /// Refresh email verification status
  Future<void> refreshEmailVerificationStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await user.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        // Force refresh the auth token to ensure Firestore has updated credentials
        // This fixes permission-denied error when updating emailVerified field
        await refreshedUser.getIdToken(true); // true = force refresh

        // Update Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'emailVerified': true,
        });

        // Log verification success
        await _security.logEmailVerification(user.uid);

        // Reload profile with forceRefresh to update requiresEmailVerification state
        // Without forceRefresh, the optimization at line 122 would skip the update
        // because the profile is already loaded, leaving requiresEmailVerification=true
        await _loadUserProfile(refreshedUser, forceRefresh: true);
      }
    } on FirebaseAuthException catch (e) {
      // FLUTTER-70 triage: silence recoverable codes that would otherwise
      // flood Sentry. Auth state listener routes the user back to login,
      // and the next refresh will retry on flaky connections.
      const recoverableCodes = {
        'user-token-expired', // TTL ~1h; idle users on /email-verification hit this routinely
        'network-request-failed', // flaky network; next refresh succeeds
      };
      if (recoverableCodes.contains(e.code)) {
        LoggingService.logInfo(
          'EnhancedAuthProvider: recoverable auth error during email-verification refresh (${e.code})',
        );
        return;
      }
      rethrow; // genuine auth errors → fall into the generic catch below
    } catch (e, stackTrace) {
      // Network errors during reload are non-critical - user can retry
      // Don't crash the app, just log the error
      await LoggingService.logError(
        'EnhancedAuthProvider: Failed to refresh email verification status',
        e,
        stackTrace,
      );

      // If email is already verified in Firebase Auth (reload succeeded but
      // subsequent Firestore/token operations failed), try to complete the flow
      // rather than showing an error to the user
      final refreshedUser = _auth.currentUser;
      if (refreshedUser != null && refreshedUser.emailVerified) {
        try {
          await _loadUserProfile(refreshedUser, forceRefresh: true);
          return; // Email IS verified - don't rethrow
        } catch (_) {
          // Profile load also failed - fall through to rethrow
        }
      }

      // Rethrow only if verification status is unknown or not verified
      rethrow;
    }
  }
}
