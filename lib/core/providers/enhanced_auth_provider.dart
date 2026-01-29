import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants/auth_feature_flags.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/services/rate_limit_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/security_events_service.dart';
import '../../core/services/ip_geolocation_service.dart';
import '../../core/services/logging_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/fcm_service.dart';
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
  final bool requiresProfileCompletion;

  const EnhancedAuthState({
    this.firebaseUser,
    this.userModel,
    this.isLoading = true, // Start as loading to show splash immediately
    this.error,
    this.requiresEmailVerification = false,
    this.requiresOnboarding = false,
    this.requiresProfileCompletion = false,
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
    bool? requiresProfileCompletion,
  }) {
    return EnhancedAuthState(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      userModel: userModel ?? this.userModel,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      requiresEmailVerification:
          requiresEmailVerification ?? this.requiresEmailVerification,
      requiresOnboarding: requiresOnboarding ?? this.requiresOnboarding,
      requiresProfileCompletion:
          requiresProfileCompletion ?? this.requiresProfileCompletion,
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
  StreamSubscription<User?>? _authSubscription;
  String? _loadingUserId; // Prevents concurrent profile loads for same user
  Timer?
  _signOutGraceTimer; // Grace period before treating null user as sign-out
  EnhancedAuthNotifier(
    this._auth,
    this._firestore,
    this._rateLimit,
    this._security,
    this._geolocation,
  ) : super(const EnhancedAuthState()) {
    // Listen to auth state changes
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      LoggingService.log(
        'authStateChanges: user=${user?.uid}',
        tag: 'ENHANCED_AUTH',
      );
      if (user != null) {
        // Cancel any pending sign-out grace timer
        _signOutGraceTimer?.cancel();
        _signOutGraceTimer = null;
        _loadUserProfile(user);
      } else {
        // GRACE PERIOD: Don't immediately clear state when user becomes null.
        // This handles token refresh race conditions (e.g., after email change via
        // verifyBeforeUpdateEmail). The auth listener may briefly fire with null
        // during token refresh, then fire again with user once refresh completes.
        // Without this grace period, the router would redirect to login during
        // the brief null state, causing "dashboard for 3 seconds then login" bug.
        _signOutGraceTimer?.cancel();

        _signOutGraceTimer = Timer(const Duration(seconds: 2), () {
          // After grace period, if still no user, treat as real sign-out
          if (_auth.currentUser == null) {
            LoggingService.log(
              'User signed out (confirmed after grace period)',
              tag: 'ENHANCED_AUTH',
            );
            // Clear user context for Sentry/Crashlytics
            LoggingService.clearUser();
            // Set isLoading to false when no user (initial check complete)
            state = const EnhancedAuthState(isLoading: false);
          } else {
            LoggingService.log(
              'User recovered after grace period (token refresh)',
              tag: 'ENHANCED_AUTH',
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _signOutGraceTimer?.cancel();
    super.dispose();
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

    // Prevent concurrent loads for the same user
    if (_loadingUserId == firebaseUser.uid) {
      LoggingService.log(
        'User profile load already in progress for ${firebaseUser.uid}, skipping duplicate request',
        tag: 'ENHANCED_AUTH',
      );
      return;
    }

    _loadingUserId = firebaseUser.uid;
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
        // EXCEPTION: Social sign-in users (Google, Apple) have pre-verified emails
        final isSocialProvider =
            userModel.lastProvider == 'google.com' ||
            userModel.lastProvider == 'apple.com';
        final requiresVerification =
            AuthFeatureFlags.requireEmailVerification &&
            !firebaseUser.emailVerified &&
            !isSocialProvider;

        // Check onboarding status
        final requiresOnboarding = userModel.needsOnboarding;

        // Check profile completion status (for social sign-in users)
        final requiresProfileCompletion = !userModel.profileCompleted;

        // Set isLoading to false when user profile is loaded (initial check complete)
        state = EnhancedAuthState(
          firebaseUser: firebaseUser,
          userModel: userModel,
          isLoading: false,
          requiresEmailVerification: requiresVerification,
          requiresOnboarding: requiresOnboarding,
          requiresProfileCompletion: requiresProfileCompletion,
        );

        // Set user context for Sentry/Crashlytics error tracking
        LoggingService.setUser(firebaseUser.uid, email: userModel.email);

        // ANALYTICS: Set user ID for session tracking
        unawaited(AnalyticsService.instance.setUserId(firebaseUser.uid));
        unawaited(
          AnalyticsService.instance.setUserProperty(
            'role',
            userModel.role.name,
          ),
        );

        // Initialize FCM push notifications (non-blocking)
        // This saves the FCM token to Firestore for Cloud Functions to use
        unawaited(
          fcmService.initialize().catchError((e) {
            LoggingService.log(
              'FCM initialization failed (non-critical): $e',
              tag: 'FCM_INIT',
            );
          }),
        );

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

      // Calculate verification requirement even on error
      // This prevents the "Flash" bug where router redirects to dashboard
      // because requiresEmailVerification defaults to false
      final requiresVerification =
          AuthFeatureFlags.requireEmailVerification &&
          !firebaseUser.emailVerified;

      // Set isLoading to false even on error (initial check complete)
      state = EnhancedAuthState(
        firebaseUser: firebaseUser,
        isLoading: false,
        requiresEmailVerification: requiresVerification,
        error: 'Failed to load user profile: $e',
      );
    } finally {
      _loadingUserId = null;
    }
  }

  /// Create user profile in Firestore
  ///
  /// [providerId] - The authentication provider ID (e.g., 'google.com', 'apple.com', 'password')
  /// For social sign-in users, sets profileCompleted=false to trigger profile completion flow.
  Future<void> _createUserProfile(
    User firebaseUser, {
    String? providerId,
  }) async {
    // Determine if this is a social sign-in (Google, Apple)
    final isSocialSignIn =
        providerId == 'google.com' || providerId == 'apple.com';

    // Parse display name for first/last name
    // Note: Apple only provides name on FIRST sign-in, subsequent logins may have empty name
    String firstName = '';
    String lastName = '';

    if (firebaseUser.displayName != null &&
        firebaseUser.displayName!.isNotEmpty) {
      final nameParts = firebaseUser.displayName!.split(' ');
      firstName = nameParts.first;
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    }

    final userModel = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email!,
      firstName: firstName,
      lastName: lastName,
      role: UserRole.owner, // Default to owner (was guest before)
      emailVerified:
          firebaseUser.emailVerified ||
          isSocialSignIn, // Social sign-in emails are verified
      displayName: firebaseUser.displayName,
      phone: firebaseUser.phoneNumber,
      avatarUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
      // Social sign-in: profile needs completion (phone, address, etc.)
      profileCompleted: !isSocialSignIn,
      lastProvider: providerId,
    );

    // SECURITY FIX: Don't use toJson() - it includes protected fields
    // that are blocked by Firestore security rules on user creation.
    await _firestore.collection('users').doc(firebaseUser.uid).set({
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
      'createdAt': FieldValue.serverTimestamp(),
      'profileCompleted': userModel.profileCompleted,
      'lastProvider': userModel.lastProvider,
    });

    // Set isLoading to false when user profile is created (initial check complete)
    // For social sign-in, set requiresProfileCompletion flag
    // For email/password sign-in, check if email verification is required
    final requiresVerification =
        !isSocialSignIn &&
        AuthFeatureFlags.requireEmailVerification &&
        !firebaseUser.emailVerified;

    state = EnhancedAuthState(
      firebaseUser: firebaseUser,
      userModel: userModel,
      isLoading: false,
      requiresEmailVerification: requiresVerification,
      requiresProfileCompletion: isSocialSignIn,
    );

    // BUG FIX: Initialize FCM for newly created users (Google/Apple sign-in)
    // The authStateChanges listener calls _loadUserProfile() but the optimization
    // skips it because userModel is already set above.
    unawaited(
      fcmService.initialize().catchError((e) {
        LoggingService.log(
          'FCM initialization failed during profile creation (non-critical): $e',
          tag: 'FCM_INIT',
        );
      }),
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

      // 1. Cloud Rate Limit Future (wrapped to handle errors internally)
      final cloudRateLimitFuture = (() async {
        try {
          final functions = FirebaseFunctions.instanceFor(
            region: 'europe-west1',
          );
          final callable = functions.httpsCallable(
            'checkRegistrationRateLimit',
          );
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
      })();

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
        'createdAt': FieldValue.serverTimestamp(),
        'profileCompleted': userModel.profileCompleted,
        'newsletterOptIn': newsletterOptIn,
      });

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

  /// Sign out
  Future<void> signOut() async {
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
        // Note: Apple may not provide display name on subsequent logins (only on first sign-in)
        // Pass provider ID to set profileCompleted=false for profile completion flow
        await _createUserProfile(userCredential.user!, providerId: 'apple.com');
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
      // SENTRY: Enhanced logging for Apple Sign-In errors
      LoggingService.log(
        'APPLE_SIGNIN_FAILED: code=${e.code}',
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
    } catch (e) {
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
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      final UserCredential userCredential;
      if (kIsWeb) {
        // Web: Use popup for re-authentication
        userCredential = await _auth.currentUser!.reauthenticateWithPopup(
          appleProvider,
        );
      } else {
        // Native: Use signInWithProvider for re-authentication
        userCredential = await _auth.currentUser!.reauthenticateWithProvider(
          appleProvider,
        );
      }

      final credential = userCredential.credential;
      if (credential == null) {
        throw 'Re-authentication succeeded but no credential was returned.';
      }
      return credential;
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

  /// Update last login timestamp and optionally the provider
  Future<void> _updateLastLogin(String userId, {String? provider}) async {
    try {
      final updates = <String, dynamic>{
        'lastLoginAt': FieldValue.serverTimestamp(),
      };
      if (provider != null) {
        updates['last_provider'] = provider;
      }
      await _firestore.collection('users').doc(userId).update(updates);
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

  /// Complete profile (for social sign-in users)
  ///
  /// Called after user completes their profile on Edit Profile screen.
  /// Sets profileCompleted=true in Firestore and updates state.
  Future<void> completeProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).update({
      'profile_completed': true,
      'updated_at': FieldValue.serverTimestamp(),
    });

    if (state.userModel != null) {
      state = state.copyWith(
        userModel: state.userModel!.copyWith(profileCompleted: true),
        requiresProfileCompletion: false,
      );
    }

    LoggingService.log(
      'Profile completed for user: $userId',
      tag: 'ENHANCED_AUTH',
    );
  }

  /// Mark a feature as seen (Feature Discovery)
  ///
  /// Used by [FeatureHighlightWidget] to track which features the user has interacted with.
  /// Uses optimistic update for instant UI feedback, then persists to Firestore.
  Future<void> markFeatureAsSeen(String featureId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || state.userModel == null) return;

    // Check if already seen to avoid unnecessary writes
    if (state.userModel!.featureFlags[featureId] == true) return;

    try {
      // Optimistic update for instant UI feedback
      final updatedFlags = Map<String, bool>.from(
        state.userModel!.featureFlags,
      );
      updatedFlags[featureId] = true;

      state = state.copyWith(
        userModel: state.userModel!.copyWith(featureFlags: updatedFlags),
      );

      // Persist to Firestore (non-blocking)
      await _firestore.collection('users').doc(userId).update({
        'featureFlags.$featureId': true,
      });

      LoggingService.log(
        'Feature marked as seen: $featureId',
        tag: 'FEATURE_DISCOVERY',
      );
    } catch (e) {
      // Silent fail - feature flags are not critical
      // User will see the highlight again next time, which is acceptable
      LoggingService.log(
        'Failed to mark feature as seen: $e',
        tag: 'AUTH_WARNING',
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

      // Update userModel with new email so resend works correctly
      final updatedUserModel = state.userModel?.copyWith(
        email: newEmail,
        emailVerified: false,
      );

      // Reload state to reflect changes
      state = state.copyWith(
        userModel: updatedUserModel,
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
        // BUG FIX: Improved message that mentions Google/Apple Sign-In
        // Since fetchSignInMethodsForEmail is deprecated, we can't detect the provider,
        // so we mention both possibilities to help the user
        return 'This email is already registered. If you previously signed up with Google or Apple, please use that sign-in method instead.';
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
