part of 'enhanced_auth_provider.dart';

/// Social (OAuth) authentication: Google/Apple sign-in and
/// re-authentication.
///
/// Extracted verbatim from EnhancedAuthNotifier on 2026-07-12 — file split
/// only, ZERO behavior change.
mixin _SocialAuthMixin on _EnhancedAuthNotifierBase {
  /// Sign in with Google (OAuth)
  /// NOTE: Requires Firebase configuration with Google Sign-In enabled
  /// Setup steps in Firebase Console:
  /// 1. Enable Google Sign-In in Authentication > Sign-in method
  /// 2. Add SHA-1 and SHA-256 certificates (for Android)
  /// 3. Download updated google-services.json / GoogleService-Info.plist
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);

    try {
      final UserCredential userCredential;
      if (kIsWeb) {
        // Web: Use signInWithPopup with Generic IDP flow
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        await _auth.setPersistence(Persistence.LOCAL);
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile (Android/iOS): Use native Google Sign-In SDK
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
        // Clear cached account to always show account picker
        await googleSignIn.signOut();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          // User cancelled the sign-in flow
          state = state.copyWith(isLoading: false);
          return;
        }
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      if (userCredential.user == null) {
        throw AuthException.noUserReturned('Google');
      }

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        // Create user profile in Firestore for new users
        // Pass provider ID to set profileCompleted=false for profile completion flow
        await _createUserProfile(
          userCredential.user!,
          providerId: 'google.com',
        );
        unawaited(AnalyticsService.instance.logSignUp('google'));
      } else {
        // Update last login and provider for existing users
        await _updateLastLogin(
          userCredential.user!.uid,
          provider: 'google.com',
        );
        unawaited(AnalyticsService.instance.logLogin('google'));

        // Load profile to check if profile completion is needed
        await _loadUserProfile(userCredential.user!);
      }

      // Log security event (non-blocking)
      try {
        await _security.logEvent(
          userId: userCredential.user!.uid,
          type: SecurityEventType.login,
          metadata: {'provider': 'google', 'isNewUser': isNewUser},
        );
      } catch (e) {
        LoggingService.log(
          'Security event logging failed: $e',
          tag: 'AUTH_WARNING',
        );
      }

      // State is already updated by _createUserProfile or _loadUserProfile
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    } on FirebaseAuthException catch (e) {
      // SENTRY: Enhanced logging for Google Sign-In errors
      LoggingService.log(
        'GOOGLE_SIGNIN_FAILED: code=${e.code}',
        tag: 'AUTH_ERROR',
      );
      unawaited(LoggingService.logError('GOOGLE_SIGNIN_FAILED: ${e.code}', e));

      // Handle account-exists-with-different-credential
      // This happens when email is already registered with email/password or Apple
      if (e.code == 'account-exists-with-different-credential') {
        LoggingService.log(
          'GOOGLE_SIGNIN_CREDENTIAL_CONFLICT: Email exists with different provider',
          tag: 'AUTH_SECURITY',
        );
        const errorMessage =
            'An account already exists with this email. '
            'Please sign in with your email/password or Apple Sign-In instead.';
        state = state.copyWith(isLoading: false, error: errorMessage);
        throw errorMessage;
      }

      final errorMessage = _getAuthErrorMessage(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message instead of FirebaseAuthException
    } catch (e) {
      // SENTRY: Log unexpected Google Sign-In error
      unawaited(LoggingService.logError('GOOGLE_SIGNIN_UNEXPECTED_ERROR', e));
      LoggingService.log(
        'Google Sign-In unexpected error: $e',
        tag: 'AUTH_ERROR',
      );
      const errorMessage = 'Failed to sign in with Google. Please try again.';
      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message
    }
  }

  /// Generate a cryptographically secure random nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// SHA-256 hash of a string (used for Apple Sign-In nonce)
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sign in with Apple (OAuth)
  /// NOTE: Requires Firebase configuration with Apple Sign-In enabled
  /// Setup steps in Firebase Console:
  /// 1. Enable Apple Sign-In in Authentication > Sign-in method
  /// 2. Register Service ID in Apple Developer Portal
  /// 3. Configure OAuth redirect URLs
  /// 4. Add Apple Sign-In capability in Xcode (for iOS)
  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true);

    try {
      final UserCredential userCredential;
      String? firstName;
      String? lastName;

      if (kIsWeb) {
        // Web: Use signInWithPopup with AppleAuthProvider
        await _auth.setPersistence(Persistence.LOCAL);
        final appleProvider = AppleAuthProvider();
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        userCredential = await _auth.signInWithPopup(appleProvider);
      } else {
        // Mobile (iOS): Use native Sign in with Apple SDK
        // Generate nonce for security (prevents replay attacks)
        final rawNonce = _generateNonce();
        final nonce = _sha256ofString(rawNonce);

        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );

        // Capture name from Apple credential (only available on FIRST sign-in)
        firstName = appleCredential.givenName;
        lastName = appleCredential.familyName;

        // Log credential details for debugging (no PII)
        LoggingService.log(
          'APPLE_SIGNIN_CREDENTIAL: '
          'hasIdToken=${appleCredential.identityToken != null}, '
          'hasAuthCode=${appleCredential.authorizationCode.isNotEmpty}, '
          'hasEmail=${appleCredential.email != null}, '
          'hasGivenName=${appleCredential.givenName != null}',
          tag: 'AUTH_DEBUG',
        );

        // Guard against null identityToken (indicates entitlements/provisioning issue)
        if (appleCredential.identityToken == null) {
          unawaited(
            LoggingService.logError(
              'APPLE_SIGNIN_NO_IDENTITY_TOKEN',
              Exception(
                'Apple Sign-In returned null identityToken — '
                'check entitlements and provisioning profile',
              ),
            ),
          );
          const errorMessage =
              'Apple Sign-In is temporarily unavailable. '
              'Please try again or use another sign-in method.';
          state = state.copyWith(isLoading: false, error: errorMessage);
          throw errorMessage;
        }

        // Create OAuth credential for Firebase
        final oauthCredential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
          accessToken: appleCredential.authorizationCode,
        );

        userCredential = await _auth.signInWithCredential(oauthCredential);
      }

      if (userCredential.user == null) {
        throw AuthException.noUserReturned('Apple');
      }

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        // Create user profile in Firestore for new users
        // Note: Apple may not provide display name on subsequent logins (only on first sign-in)
        // Pass name explicitly from Apple credential (native only)
        await _createUserProfile(
          userCredential.user!,
          providerId: 'apple.com',
          firstName: firstName,
          lastName: lastName,
        );
        unawaited(AnalyticsService.instance.logSignUp('apple'));
      } else {
        // Update last login and provider for existing users
        await _updateLastLogin(userCredential.user!.uid, provider: 'apple.com');
        unawaited(AnalyticsService.instance.logLogin('apple'));

        // Load profile to check if profile completion is needed
        await _loadUserProfile(userCredential.user!);
      }

      // Log security event (non-blocking)
      try {
        await _security.logEvent(
          userId: userCredential.user!.uid,
          type: SecurityEventType.login,
          metadata: {'provider': 'apple', 'isNewUser': isNewUser},
        );
      } catch (e) {
        LoggingService.log(
          'Security event logging failed: $e',
          tag: 'AUTH_WARNING',
        );
      }

      // State is already updated by _createUserProfile or _loadUserProfile
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    } on FirebaseAuthException catch (e) {
      // User cancelled the Apple Sign-In sheet - not an error
      if (e.code == 'canceled' ||
          e.code == 'web-context-canceled' ||
          e.code == 'web-context-cancelled') {
        LoggingService.log('Apple Sign-In cancelled by user', tag: 'AUTH_INFO');
        state = state.copyWith(isLoading: false);
        return; // Silent return - no error shown
      }

      // SENTRY: Enhanced logging for Apple Sign-In errors
      LoggingService.log(
        'APPLE_SIGNIN_FAILED: code=${e.code}, message=${e.message}',
        tag: 'AUTH_ERROR',
      );
      unawaited(LoggingService.logError('APPLE_SIGNIN_FAILED: ${e.code}', e));

      // Handle account-exists-with-different-credential
      // This happens when email is already registered with email/password or Google
      if (e.code == 'account-exists-with-different-credential') {
        LoggingService.log(
          'APPLE_SIGNIN_CREDENTIAL_CONFLICT: Email exists with different provider',
          tag: 'AUTH_SECURITY',
        );
        const errorMessage =
            'An account already exists with this email. '
            'Please sign in with your email/password or Google Sign-In instead.';
        state = state.copyWith(isLoading: false, error: errorMessage);
        throw errorMessage;
      }

      final errorMessage = _getAuthErrorMessage(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message instead of FirebaseAuthException
    } on SignInWithAppleAuthorizationException catch (e) {
      // Native Sign in with Apple SDK: user cancelled
      if (e.code == AuthorizationErrorCode.canceled) {
        LoggingService.log(
          'Apple Sign-In cancelled by user (native SDK)',
          tag: 'AUTH_INFO',
        );
        state = state.copyWith(isLoading: false);
        return; // Silent return - no error shown
      }
      // Other Apple authorization errors (e.g., unknown, invalidResponse, notHandled, failed, notInteractive)
      unawaited(
        LoggingService.logError('APPLE_SIGNIN_AUTH_ERROR: ${e.code}', e),
      );
      const errorMessage = 'Failed to sign in with Apple. Please try again.';
      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage;
    } catch (e) {
      // Check if user cancelled (may come as PlatformException on some iOS versions)
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('cancel') ||
          errorString.contains(
            'com.apple.authenticationservices.authorizationerror error 1001',
          )) {
        LoggingService.log(
          'Apple Sign-In cancelled by user (non-Firebase exception)',
          tag: 'AUTH_INFO',
        );
        state = state.copyWith(isLoading: false);
        return; // Silent return - no error shown
      }

      // SENTRY: Log unexpected Apple Sign-In error
      unawaited(LoggingService.logError('APPLE_SIGNIN_UNEXPECTED_ERROR', e));
      LoggingService.log(
        'Apple Sign-In unexpected error: $e',
        tag: 'AUTH_ERROR',
      );
      const errorMessage = 'Failed to sign in with Apple. Please try again.';
      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message
    }
  }

  /// Re-authenticate with Google for sensitive operations (e.g., account deletion)
  ///
  /// Returns [AuthCredential] that can be used with deleteAccount() or other
  /// sensitive operations that require re-authentication.
  ///
  /// Throws [String] error message on failure.
  Future<AuthCredential> reauthenticateWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: Use popup for re-authentication
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final userCredential = await _auth.currentUser!.reauthenticateWithPopup(
          googleProvider,
        );
        final credential = userCredential.credential;
        if (credential == null) {
          throw 'Re-authentication succeeded but no credential was returned.';
        }
        return credential;
      } else {
        // Mobile (Android/iOS): Use native Google Sign-In SDK
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
        // Clear cached account to always show account picker
        await googleSignIn.signOut();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw 'Google re-authentication was cancelled.';
        }
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.currentUser!.reauthenticateWithCredential(credential);
        return credential;
      }
    } on FirebaseAuthException catch (e) {
      LoggingService.log(
        'Google re-auth error: ${e.code} - ${e.message}',
        tag: 'AUTH_ERROR',
      );
      throw _getAuthErrorMessage(e);
    } catch (e) {
      LoggingService.log(
        'Google re-auth unexpected error: $e',
        tag: 'AUTH_ERROR',
      );
      throw 'Failed to re-authenticate with Google. Please try again.';
    }
  }

  /// Re-authenticate with Apple for sensitive operations (e.g., account deletion)
  ///
  /// Returns [AuthCredential] that can be used with deleteAccount() or other
  /// sensitive operations that require re-authentication.
  ///
  /// Throws [String] error message on failure.
  Future<AuthCredential> reauthenticateWithApple() async {
    try {
      if (kIsWeb) {
        // Web: Use popup for re-authentication
        final appleProvider = AppleAuthProvider();
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        final userCredential = await _auth.currentUser!.reauthenticateWithPopup(
          appleProvider,
        );
        final credential = userCredential.credential;
        if (credential == null) {
          throw 'Re-authentication succeeded but no credential was returned.';
        }
        return credential;
      } else {
        // Mobile (iOS): Use native Sign in with Apple SDK
        final rawNonce = _generateNonce();
        final nonce = _sha256ofString(rawNonce);

        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );

        // Guard against null identityToken
        if (appleCredential.identityToken == null) {
          unawaited(
            LoggingService.logError(
              'APPLE_REAUTH_NO_IDENTITY_TOKEN',
              Exception('Apple re-auth returned null identityToken'),
            ),
          );
          throw 'Apple re-authentication failed. Please try again.';
        }

        final oauthCredential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
          accessToken: appleCredential.authorizationCode,
        );

        await _auth.currentUser!.reauthenticateWithCredential(oauthCredential);
        return oauthCredential;
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw 'Apple re-authentication was cancelled.';
      }
      LoggingService.log(
        'Apple re-auth native SDK error: ${e.code}',
        tag: 'AUTH_ERROR',
      );
      throw 'Failed to re-authenticate with Apple. Please try again.';
    } on FirebaseAuthException catch (e) {
      LoggingService.log(
        'Apple re-auth error: ${e.code} - ${e.message}',
        tag: 'AUTH_ERROR',
      );
      throw _getAuthErrorMessage(e);
    } catch (e) {
      LoggingService.log(
        'Apple re-auth unexpected error: $e',
        tag: 'AUTH_ERROR',
      );
      throw 'Failed to re-authenticate with Apple. Please try again.';
    }
  }
}
