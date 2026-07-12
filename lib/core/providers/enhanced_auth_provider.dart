import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
import '../../core/utils/web_storage_wipe.dart';
import '../../shared/models/user_model.dart';
import '../../shared/providers/repository_providers.dart';
import '../constants/enums.dart';

part 'enhanced_auth_email.dart';
part 'enhanced_auth_profile_ops.dart';
part 'enhanced_auth_session.dart';
part 'enhanced_auth_social.dart';

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
/// Shared state, Firebase listeners and profile-lifecycle internals for
/// [EnhancedAuthNotifier] and its concern mixins. Split into `part` files
/// on 2026-07-12 — every method moved VERBATIM (only the constructor name
/// changed to the base and a forwarding constructor was added below).
abstract class _EnhancedAuthNotifierBase
    extends StateNotifier<EnhancedAuthState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final RateLimitService _rateLimit;
  final SecurityEventsService _security;
  final IpGeolocationService _geolocation;
  StreamSubscription<User?>? _authSubscription;
  String? _loadingUserId; // Prevents concurrent profile loads for same user
  Completer<void>?
  _profileLoadCompleter; // Allows callers to await in-progress load
  Timer?
  _signOutGraceTimer; // Grace period before treating null user as sign-out
  _EnhancedAuthNotifierBase(
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

    // If loading is in progress for the same user, wait for it to complete
    // instead of silently returning. This fixes the race condition where
    // signInWithEmail() returns before the profile is loaded (the auth listener
    // starts loading, the explicit call skips, and the login screen navigates
    // to dashboard with null userModel).
    if (_loadingUserId == firebaseUser.uid) {
      LoggingService.log(
        'User profile load already in progress for ${firebaseUser.uid}, waiting for completion...',
        tag: 'ENHANCED_AUTH',
      );
      await _profileLoadCompleter?.future;
      return;
    }

    _loadingUserId = firebaseUser.uid;
    _profileLoadCompleter = Completer<void>();
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

        // Check Apple credential state (iOS only, non-blocking)
        // Signs out if user revoked Apple access in Settings
        if (!kIsWeb && userModel.lastProvider == 'apple.com') {
          _checkAppleCredentialState(firebaseUser);
        }
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
      if (_profileLoadCompleter != null &&
          !_profileLoadCompleter!.isCompleted) {
        _profileLoadCompleter!.complete();
      }
      _profileLoadCompleter = null;
    }
  }

  /// Check if Apple credentials are still valid (iOS only).
  /// If user revoked Apple Sign-In access (Settings → Apple ID → Sign-In),
  /// sign them out gracefully. Fire-and-forget — does not block app launch.
  void _checkAppleCredentialState(User firebaseUser) {
    final appleProviderData = firebaseUser.providerData
        .where((info) => info.providerId == 'apple.com')
        .firstOrNull;

    if (appleProviderData == null) return;

    final appleUserId = appleProviderData.uid;
    if (appleUserId == null || appleUserId.isEmpty) return;

    SignInWithApple.getCredentialState(appleUserId)
        .then((credentialState) {
          if (credentialState == CredentialState.revoked ||
              credentialState == CredentialState.notFound) {
            LoggingService.log(
              'Apple credential state: $credentialState — signing out',
              tag: 'AUTH_APPLE',
            );
            signOut();
          }
        })
        .catchError((e) {
          // SignInWithAppleNotSupportedException on non-Apple platforms
          // or network errors — silently ignore
          LoggingService.log(
            'Apple credential state check failed (non-critical): $e',
            tag: 'AUTH_APPLE',
          );
        });
  }

  /// Create user profile in Firestore
  ///
  /// [providerId] - The authentication provider ID (e.g., 'google.com', 'apple.com', 'password')
  Future<void> _createUserProfile(
    User firebaseUser, {
    String? providerId,
    String? firstName,
    String? lastName,
  }) async {
    // Determine if this is a social sign-in (Google, Apple)
    final isSocialSignIn =
        providerId == 'google.com' || providerId == 'apple.com';

    // Parse display name for first/last name
    // Note: Apple only provides name on FIRST sign-in, subsequent logins may have empty name
    String finalFirstName = firstName ?? '';
    String finalLastName = lastName ?? '';

    // If explicit names not provided, try parsing from displayName
    if (finalFirstName.isEmpty && finalLastName.isEmpty) {
      if (firebaseUser.displayName != null &&
          firebaseUser.displayName!.isNotEmpty) {
        final nameParts = firebaseUser.displayName!.split(' ');
        finalFirstName = nameParts.first;
        finalLastName = nameParts.length > 1
            ? nameParts.sublist(1).join(' ')
            : '';
      }
    }

    final userModel = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      firstName: finalFirstName,
      lastName: finalLastName,
      role: UserRole.owner, // Default to owner (was guest before)
      emailVerified:
          firebaseUser.emailVerified ||
          isSocialSignIn, // Social sign-in emails are verified
      displayName:
          firebaseUser.displayName ??
          (finalFirstName.isNotEmpty
              ? '$finalFirstName $finalLastName'.trim()
              : null),
      phone: firebaseUser.phoneNumber,
      avatarUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
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

    // Pre-populate profile sub-doc so Edit Profile shows Apple/Google data
    // (Apple Guideline 4.0: don't ask for info already provided by Sign in with Apple)
    if (isSocialSignIn) {
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .collection('data')
          .doc('profile')
          .set({
            'displayName': firebaseUser.displayName ?? '',
            'emailContact': firebaseUser.email ?? '',
            'phoneE164': firebaseUser.phoneNumber ?? '',
            'address': {
              'country': '',
              'city': '',
              'street': '',
              'postalCode': '',
            },
            'social': {'website': '', 'facebook': ''},
            'propertyType': '',
            'logoUrl': firebaseUser.photoURL ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
          });
    }

    // Set isLoading to false when user profile is created (initial check complete)
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

  /// Implemented by [_SessionMixin]; declared here so base-class internals
  /// (Apple credential revocation watcher) can invoke it.
  Future<void> signOut({bool clearSavedEmail = false});
}

class EnhancedAuthNotifier extends _EnhancedAuthNotifierBase
    with _EmailAuthMixin, _SessionMixin, _SocialAuthMixin, _ProfileOpsMixin {
  EnhancedAuthNotifier(
    super.auth,
    super.firestore,
    super.rateLimit,
    super.security,
    super.geolocation,
  );
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
