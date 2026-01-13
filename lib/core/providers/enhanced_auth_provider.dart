import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/auth_feature_flags.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/services/rate_limit_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/security_events_service.dart';
import '../../core/services/ip_geolocation_service.dart';
import '../../core/services/logging_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/password_validator.dart';
import '../../shared/models/user_model.dart';
import '../../shared/providers/repository_providers.dart';
import '../constants/enums.dart';

/// Enhanced Auth state model with BedBooking security features
class EnhancedAuthState {
  final User? firebaseUser;
  final UserModel? userModel;
  final bool isLoading;
  final String? error;
  final bool requiresEmailVerification;
  final bool requiresOnboarding;

  const EnhancedAuthState({
    this.firebaseUser,
    this.userModel,
    this.isLoading = true, // Start as loading to show splash immediately
    this.error,
    this.requiresEmailVerification = false,
    this.requiresOnboarding = false,
  });

  bool get isAuthenticated => firebaseUser != null && userModel != null;
  bool get isAnonymous => firebaseUser?.isAnonymous ?? false;
  bool get isOwner => userModel?.isOwner ?? false;
  bool get isAdmin => userModel?.isAdmin ?? false;
  bool get isEmployee => userModel?.isEmployee ?? false;

  EnhancedAuthState copyWith({
    User? firebaseUser,
    UserModel? userModel,
    bool? isLoading,
    String? error,
    bool? requiresEmailVerification,
    bool? requiresOnboarding,
  }) {
    return EnhancedAuthState(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      userModel: userModel ?? this.userModel,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      requiresEmailVerification:
          requiresEmailVerification ?? this.requiresEmailVerification,
      requiresOnboarding: requiresOnboarding ?? this.requiresOnboarding,
    );
  }
}

/// Enhanced Auth Notifier with BedBooking security features
class EnhancedAuthNotifier extends StateNotifier<EnhancedAuthState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final RateLimitService _rateLimit;
  final SecurityEventsService _security;
  final IpGeolocationService _geolocation;

  EnhancedAuthNotifier(
    this._auth,
    this._firestore,
    this._rateLimit,
    this._security,
    this._geolocation,
  ) : super(const EnhancedAuthState()) {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      LoggingService.log(
        'authStateChanges: user=${user?.uid}',
        tag: 'ENHANCED_AUTH',
      );
      if (user != null) {
        _loadUserProfile(user);
      } else {
        LoggingService.log(
          'User signed out, clearing state',
          tag: 'ENHANCED_AUTH',
        );
        // Clear user context for Sentry/Crashlytics
        LoggingService.clearUser();
        // Set isLoading to false when no user (initial check complete)
        state = const EnhancedAuthState(isLoading: false);
      }
    });
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile(
    User firebaseUser, {
    bool forceRefresh = false,
  }) async {
    // OPTIMIZATION: Avoid redundant fetches if profile is already loaded
    // This prevents double-fetches during login (explicit call + listener)
    if (!forceRefresh &&
        state.userModel?.id == firebaseUser.uid &&
        !state.isLoading) {
      LoggingService.log(
        'User profile already loaded for ${firebaseUser.uid}, skipping fetch',
        tag: 'ENHANCED_AUTH',
      );
      return;
    }

    LoggingService.log(
      'Loading user profile for ${firebaseUser.uid}...',
      tag: 'ENHANCED_AUTH',
    );
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        LoggingService.log(
          'User profile found in Firestore',
          tag: 'ENHANCED_AUTH',
        );

        final data = doc.data()!;

        UserModel userModel;
        try {
          // Try parsing the user model
          userModel = UserModel.fromJson({...data, 'id': doc.id});
        } catch (parseError, stackTrace) {
          // Log detailed error information
          LoggingService.log(
            'Failed to parse UserModel. Error: $parseError',
            tag: 'ENHANCED_AUTH_ERROR',
          );
          LoggingService.log(
            'Stack trace: $stackTrace',
            tag: 'ENHANCED_AUTH_ERROR',
          );

          // Log all field types to help identify the problem
          LoggingService.log(
            'Firestore fields (${data.length}):',
            tag: 'ENHANCED_AUTH_ERROR',
          );
          data.forEach((key, value) {
            // SECURITY: Redact sensitive PII fields in logs
            final lowerKey = key.toLowerCase();
            final isSensitive =
                lowerKey.contains('email') ||
                lowerKey.contains('phone') ||
                lowerKey.contains('password') ||
                lowerKey.contains('token') ||
                lowerKey.contains('secret') ||
                lowerKey.contains('iban') ||
                lowerKey.contains('swift') ||
                lowerKey.contains('credit') ||
                // Exact matches for short words to avoid false positives
                lowerKey == 'vat' ||
                lowerKey == 'tax' ||
                lowerKey == 'vatid' ||
                lowerKey == 'taxid' ||
                lowerKey.endsWith('_vat') ||
                lowerKey.endsWith('_tax');

            final valStr = isSensitive
                ? '[REDACTED]'
                : (value.toString().length > 50
                      ? '${value.toString().substring(0, 50)}...'
                      : value);

            LoggingService.log(
              '  $key: ${value.runtimeType} = $valStr',
              tag: 'ENHANCED_AUTH_ERROR',
            );
          });

          // Create fallback UserModel instead of crashing
          try {
            userModel = UserModel(
              id: doc.id,
              email:
                  data['email'] as String? ??
                  firebaseUser.email ??
                  'unknown@email.com',
              firstName: data['first_name'] as String? ?? '',
              lastName: data['last_name'] as String? ?? '',
              role: UserRole.values.firstWhere(
                (r) => r.name == (data['role'] as String?),
                orElse: () => UserRole.owner,
              ),
              emailVerified: data['emailVerified'] as bool? ?? false,
              onboardingCompleted:
                  data['onboardingCompleted'] as bool? ?? false,
              displayName: data['displayName'] as String?,
              phone: data['phone'] as String?,
              avatarUrl: data['avatar_url'] as String?,
              createdAt: DateTime.now(), // Fallback
            );
          } catch (fallbackError) {
            rethrow;
          }
        }

        // Check email verification status (respects feature flag)
        // SECURITY FIX: Use ONLY Firebase Auth's emailVerified status
        // Do NOT trust Firestore userModel.emailVerified as it can be stale or manipulated
        final requiresVerification =
            AuthFeatureFlags.requireEmailVerification &&
            !firebaseUser.emailVerified;

        // Check onboarding status
        final requiresOnboarding = userModel.needsOnboarding;

        // Set isLoading to false when user profile is loaded (initial check complete)
        state = EnhancedAuthState(
          firebaseUser: firebaseUser,
          userModel: userModel,
          isLoading: false,
          requiresEmailVerification: requiresVerification,
          requiresOnboarding: requiresOnboarding,
        );

        // Set user context for Sentry/Crashlytics error tracking
        LoggingService.setUser(firebaseUser.uid, email: userModel.email);

        LoggingService.log(
          'State updated: isAuthenticated=${state.isAuthenticated}, requiresVerification=$requiresVerification, requiresOnboarding=$requiresOnboarding',
          tag: 'ENHANCED_AUTH',
        );

        // Update last login time (non-blocking to speed up auth)
        unawaited(_updateLastLogin(firebaseUser.uid));
      } else {
        LoggingService.log(
          'User profile NOT found, creating new profile...',
          tag: 'ENHANCED_AUTH',
        );
        // Create user profile if it doesn't exist
        await _createUserProfile(firebaseUser);
      }
    } catch (e) {
      unawaited(LoggingService.logError('ERROR loading user profile', e));
      // Set isLoading to false even on error (initial check complete)
      state = EnhancedAuthState(
        firebaseUser: firebaseUser,
        isLoading: false,
        error: 'Failed to load user profile: $e',
      );
    }
  }

  /// Create user profile in Firestore
  Future<void> _createUserProfile(User firebaseUser) async {
    final userModel = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email!,
      firstName: firebaseUser.displayName?.split(' ').first ?? '',
      lastName: firebaseUser.displayName?.split(' ').last ?? '',
      role: UserRole.owner, // Default to owner (was guest before)
      emailVerified: firebaseUser.emailVerified,
      onboardingCompleted: true, // Skip onboarding for OAuth users
      displayName: firebaseUser.displayName,
      phone: firebaseUser.phoneNumber,
      avatarUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set(userModel.toJson());
    // Set isLoading to false when user profile is created (initial check complete)
    state = EnhancedAuthState(
      firebaseUser: firebaseUser,
      userModel: userModel,
      isLoading: false,
    );
  }

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

      // SECURITY: IP-based rate limiting for login (Cloud Function)
      try {
        final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
        final callable = functions.httpsCallable('checkLoginRateLimit');
        await callable.call({'email': email});
      } on FirebaseFunctionsException catch (e) {
        if (e.code == 'resource-exhausted') {
          LoggingService.log(
            'IP-based rate limit exceeded for login',
            tag: 'ENHANCED_AUTH',
          );
          state = state.copyWith(isLoading: false, error: e.message);
          throw e.message ??
              'Too many login attempts. Please wait before trying again.';
        }
        // Continue with login if rate limit check fails (fail-open for availability)
        LoggingService.log(
          'IP rate limit check failed, continuing: ${e.message}',
          tag: 'AUTH_WARNING',
        );
      }

      // PERFORMANCE: Run rate limit check and persistence setup in PARALLEL
      // Both are independent operations, no need to wait sequentially
      final rateLimitFuture = _rateLimit.checkRateLimit(email);
      final persistenceFuture = kIsWeb
          ? _auth.setPersistence(
              rememberMe ? Persistence.LOCAL : Persistence.SESSION,
            )
          : Future<void>.value();

      // Wait for both to complete
      final results = await Future.wait([rateLimitFuture, persistenceFuture]);
      final rateLimit = results[0] as LoginAttempt?;

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
        'Calling Firebase signInWithEmailAndPassword...',
        tag: 'ENHANCED_AUTH',
      );
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
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

      // SECURITY: IP-based rate limiting for registration (Cloud Function)
      // Stricter limits for registration to prevent spam account creation
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
          state = state.copyWith(isLoading: false, error: e.message);
          throw e.message ??
              'Too many registration attempts. Please wait before trying again.';
        }
        // Continue with registration if rate limit check fails (fail-open for availability)
        LoggingService.log(
          'IP rate limit check failed, continuing: ${e.message}',
          tag: 'AUTH_WARNING',
        );
      }

      // Check email-based rate limit (Dart-side, Firestore-backed)
      final rateLimit = await _rateLimit.checkRateLimit(email);
      if (rateLimit != null && rateLimit.isLocked) {
        throw _rateLimit.getRateLimitMessage(rateLimit);
      }

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
      final userModel = UserModel(
        id: user.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: UserRole.owner, // Default to owner for registration
        phone: phone,
        avatarUrl: finalAvatarUrl,
        displayName: '$firstName $lastName',
        onboardingCompleted:
            true, // Skip onboarding - user will use Unit Hub instead
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set({
        ...userModel.toJson(),
        'newsletterOptIn': newsletterOptIn,
      });

      // Update display name in Firebase Auth
      await user.updateDisplayName('$firstName $lastName');

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
    } on FirebaseAuthException catch (e) {
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
      final errorMessage = e.toString();
      // CRITICAL: Always reset isLoading to prevent infinite loading state
      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw 'No user logged in';

    try {
      await user.sendEmailVerification();
      await _security.logEvent(
        userId: user.uid,
        type: SecurityEventType.emailVerification,
        metadata: {'action': 'resent'},
      );
    } catch (e) {
      throw 'Failed to send verification email: $e';
    }
  }

  /// Refresh email verification status
  Future<void> refreshEmailVerificationStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await user.reload();
    final refreshedUser = _auth.currentUser;

    if (refreshedUser != null && refreshedUser.emailVerified) {
      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'emailVerified': true,
      });

      // Log verification success
      await _security.logEmailVerification(user.uid);

      // Reload profile
      await _loadUserProfile(refreshedUser);
    }
  }

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
        final userModel = UserModel(
          id: user.uid,
          email: 'anonymous@demo.com',
          firstName: 'Demo',
          lastName: 'User',
          role: UserRole.owner,
          displayName: 'Demo User',
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toJson());
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

  /// Sign out
  Future<void> signOut() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _security.logLogout(userId);
    }

    // Clear user context for Sentry/Crashlytics error tracking
    LoggingService.clearUser();

    // NOTE: We do NOT clear secure storage (Remember Me email) on sign out.
    // The email should persist after logout so it's pre-filled on next login.
    // Credentials are only cleared when user:
    // 1. Unchecks "Remember Me" checkbox during login
    // 2. Deletes their account

    await _auth.signOut();
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
  /// [password] - Required for re-authentication before deletion (security measure)
  ///
  /// Throws [String] error message on failure.
  Future<void> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user is currently signed in';
    }

    // Re-authenticate user before deletion (security measure)
    try {
      if (user.email == null) {
        throw 'User email is missing';
      }
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e);
    }

    try {
      // Call Cloud Function to delete all user data
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('deleteUserAccount');
      await callable.call();

      LoggingService.log(
        'User account deleted successfully',
        tag: 'ENHANCED_AUTH',
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
      LoggingService.log(
        'Failed to delete account: ${e.message}',
        tag: 'ENHANCED_AUTH',
      );
      throw e.message ?? 'Failed to delete account';
    } catch (e) {
      LoggingService.log('Failed to delete account: $e', tag: 'ENHANCED_AUTH');
      throw 'Failed to delete account. Please try again or contact support.';
    }
  }

  /// Reset password using custom email template
  Future<void> resetPassword(String email) async {
    try {
      // Use Cloud Function for custom email template instead of default Firebase Auth email
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendPasswordResetEmail');

      await callable.call({'email': email});
    } on FirebaseFunctionsException catch (e) {
      // Handle Cloud Function errors
      throw e.message ?? 'Failed to send password reset email';
    } on FirebaseAuthException catch (e) {
      // Fallback to Firebase Auth if Cloud Function fails
      throw _getAuthErrorMessage(e);
    } catch (e) {
      throw 'Failed to send password reset email: $e';
    }
  }

  /// Sign in with Google (OAuth)
  /// NOTE: Requires Firebase configuration with Google Sign-In enabled
  /// Setup steps in Firebase Console:
  /// 1. Enable Google Sign-In in Authentication > Sign-in method
  /// 2. Add SHA-1 and SHA-256 certificates (for Android)
  /// 3. Download updated google-services.json / GoogleService-Info.plist
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);

    try {
      // Set persistence to LOCAL for Google sign in (web only)
      if (kIsWeb) {
        await _auth.setPersistence(Persistence.LOCAL);
      }

      // Create Google Auth Provider
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Add scopes if needed
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // Sign in with popup for web, native SDK for mobile
      final UserCredential userCredential = await _auth.signInWithProvider(
        googleProvider,
      );

      if (userCredential.user == null) {
        throw AuthException.noUserReturned('Google');
      }

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        // Create user profile in Firestore for new users
        await _createUserProfile(userCredential.user!);
      } else {
        // Update last login for existing users
        await _updateLastLogin(userCredential.user!.uid);
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

      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      LoggingService.log(
        'Google Sign-In error: ${e.code} - ${e.message}',
        tag: 'AUTH_ERROR',
      );
      final errorMessage = _getAuthErrorMessage(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message instead of FirebaseAuthException
    } catch (e) {
      LoggingService.log(
        'Google Sign-In unexpected error: $e',
        tag: 'AUTH_ERROR',
      );
      const errorMessage = 'Failed to sign in with Google. Please try again.';
      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message
    }
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
      // Set persistence to LOCAL for Apple sign in (web only)
      if (kIsWeb) {
        await _auth.setPersistence(Persistence.LOCAL);
      }

      // Create Apple Auth Provider
      final OAuthProvider appleProvider = OAuthProvider('apple.com');

      // Request email and full name scopes
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      // Sign in with popup for web, native SDK for mobile
      final UserCredential userCredential = await _auth.signInWithProvider(
        appleProvider,
      );

      if (userCredential.user == null) {
        throw AuthException.noUserReturned('Apple');
      }

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        // Create user profile in Firestore for new users
        // Note: Apple may not provide display name on subsequent logins
        await _createUserProfile(userCredential.user!);
      } else {
        // Update last login for existing users
        await _updateLastLogin(userCredential.user!.uid);
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

      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      LoggingService.log(
        'Apple Sign-In error: ${e.code} - ${e.message}',
        tag: 'AUTH_ERROR',
      );
      final errorMessage = _getAuthErrorMessage(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message instead of FirebaseAuthException
    } catch (e) {
      LoggingService.log(
        'Apple Sign-In unexpected error: $e',
        tag: 'AUTH_ERROR',
      );
      const errorMessage = 'Failed to sign in with Apple. Please try again.';
      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message
    }
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Ignore error
    }
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).update({
      'onboardingCompleted': true,
    });

    if (state.userModel != null) {
      state = state.copyWith(
        userModel: state.userModel!.copyWith(onboardingCompleted: true),
        requiresOnboarding: false,
      );
    }
  }

  /// Update user email (Phase 3 feature)
  /// Re-authenticates user with password, then updates email and sends verification
  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    LoggingService.log('Updating email to: $newEmail', tag: 'ENHANCED_AUTH');

    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('No user logged in', code: 'auth/no-user');
    }

    if (user.email == null) {
      throw AuthException('Current user has no email', code: 'auth/no-email');
    }

    try {
      // Re-authenticate user with current password
      LoggingService.log('Re-authenticating user...', tag: 'ENHANCED_AUTH');
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Verify email
      await user.verifyBeforeUpdateEmail(newEmail);

      // Update email in Firestore
      LoggingService.log(
        'Updating email in Firestore...',
        tag: 'ENHANCED_AUTH',
      );
      await _firestore.collection('users').doc(user.uid).update({
        'email': newEmail,
        'emailVerified': false, // Email now requires verification
        'updatedAt': FieldValue.serverTimestamp(),
      });

      LoggingService.log('Email updated successfully!', tag: 'ENHANCED_AUTH');

      // Reload state to reflect changes
      state = state.copyWith(
        requiresEmailVerification: AuthFeatureFlags.requireEmailVerification,
      );
    } on FirebaseAuthException catch (e) {
      unawaited(LoggingService.logError('Email update failed: ${e.code}', e));
      throw _getAuthErrorMessage(e);
    } catch (e) {
      unawaited(LoggingService.logError('Email update error', e));
      const errorMessage = 'Failed to update email. Please try again.';
      throw errorMessage; // Throw user-friendly message instead of raw exception
    }
  }

  /// Get user-friendly error message
  /// Note: These are English-only fallbacks. The login screen should use
  /// AppLocalizations for proper multi-language support.
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Try again or reset your password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password must be at least 8 characters with uppercase, lowercase, number, and special character';
      case 'operation-not-allowed':
        return 'Operation not allowed. Contact support';
      case 'user-disabled':
        return 'Your account has been disabled. Contact support';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      default:
        return e.message ?? 'An error occurred. Please try again';
    }
  }
}

/// Enhanced Auth Provider
///
/// ## keepAlive Decision: TRUE (implicit via StateNotifierProvider)
/// Auth state MUST persist throughout app lifecycle:
/// - Used by all authenticated routes and guards
/// - Maintains Firebase auth listener subscription
/// - Prevents re-authentication on every navigation
/// - Memory impact: Low (~1KB for auth state)
final enhancedAuthProvider =
    StateNotifierProvider<EnhancedAuthNotifier, EnhancedAuthState>((ref) {
      final auth = ref.watch(firebaseAuthProvider);
      final firestore = ref.watch(firestoreProvider);
      final rateLimit = RateLimitService();
      final security = SecurityEventsService();
      final geolocation = IpGeolocationService();

      return EnhancedAuthNotifier(
        auth,
        firestore,
        rateLimit,
        security,
        geolocation,
      );
    });
