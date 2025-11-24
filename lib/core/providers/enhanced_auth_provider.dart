import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/rate_limit_service.dart';
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
    this.isLoading = false,
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
        state = const EnhancedAuthState();
      }
    });
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile(User firebaseUser) async {
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

        // Print ALL field types to console for debugging
        print('=== FIRESTORE USER DATA DEBUG ===');
        print('Total fields: ${data.length}');
        data.forEach((key, value) {
          print(
            'Field: $key | Type: ${value.runtimeType} | Value: ${value.toString().length > 100 ? '${value.toString().substring(0, 100)}...' : value}',
          );
        });
        print('=== END DEBUG ===');

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
            LoggingService.log(
              '  $key: ${value.runtimeType} = ${value.toString().length > 50 ? '${value.toString().substring(0, 50)}...' : value}',
              tag: 'ENHANCED_AUTH_ERROR',
            );
          });

          // Create fallback UserModel instead of crashing
          print('=== CREATING FALLBACK USER MODEL ===');
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
            print(
              'Fallback UserModel created successfully for ${userModel.email}',
            );
          } catch (fallbackError) {
            print('Fallback also failed: $fallbackError');
            rethrow;
          }
        }

        // Check email verification status
        final requiresVerification =
            !firebaseUser.emailVerified && !userModel.emailVerified;

        // Check onboarding status
        final requiresOnboarding = userModel.needsOnboarding;

        state = EnhancedAuthState(
          firebaseUser: firebaseUser,
          userModel: userModel,
          requiresEmailVerification: requiresVerification,
          requiresOnboarding: requiresOnboarding,
        );

        LoggingService.log(
          'State updated: isAuthenticated=${state.isAuthenticated}, requiresVerification=$requiresVerification, requiresOnboarding=$requiresOnboarding',
          tag: 'ENHANCED_AUTH',
        );

        // Update last login time
        await _updateLastLogin(firebaseUser.uid);
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
      state = EnhancedAuthState(
        firebaseUser: firebaseUser,
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
      role: UserRole.guest,
      emailVerified: firebaseUser.emailVerified,
      displayName: firebaseUser.displayName,
      phone: firebaseUser.phoneNumber,
      avatarUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set(userModel.toJson());
    state = EnhancedAuthState(firebaseUser: firebaseUser, userModel: userModel);
  }

  /// Sign in with email and password (with rate limiting)
  Future<void> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    LoggingService.log(
      'signInWithEmail called for $email, rememberMe=$rememberMe',
      tag: 'ENHANCED_AUTH',
    );
    try {
      state = state.copyWith(isLoading: true);

      // Check rate limit
      final rateLimit = await _rateLimit.checkRateLimit(email);
      if (rateLimit != null && rateLimit.isLocked) {
        LoggingService.log(
          'Rate limit exceeded for $email',
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
      LoggingService.log(
        'Explicitly loading user profile...',
        tag: 'ENHANCED_AUTH',
      );
      await _loadUserProfile(credential.user!);

      // Reset rate limit on success
      await _rateLimit.resetAttempts(email);

      // Get geolocation (with timeout to avoid blocking login)
      String? location;
      try {
        final geoResult = await _geolocation.getCurrentLocation().timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );
        location = geoResult?.locationString;
      } catch (e) {
        // Ignore geolocation errors, don't block login
        location = null;
      }

      // Log security event with location
      await _security.logLogin(credential.user!, location: location);

      // Set persistence based on rememberMe
      if (!rememberMe) {
        await _auth.setPersistence(Persistence.SESSION);
      }

      // Auth state listener will handle the rest
      LoggingService.log(
        'Sign in completed, auth state listener will load profile',
        tag: 'ENHANCED_AUTH',
      );
    } on FirebaseAuthException catch (e) {
      unawaited(
        LoggingService.logError(
          'Firebase sign in FAILED: ${e.code} - ${e.message}',
          e,
        ),
      );
      // Record failed attempt
      await _rateLimit.recordFailedAttempt(email);

      // Get updated rate limit info
      final updatedLimit = await _rateLimit.checkRateLimit(email);
      final errorMessage = updatedLimit != null && updatedLimit.isLocked
          ? _rateLimit.getRateLimitMessage(updatedLimit)
          : _getAuthErrorMessage(e);

      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message instead of FirebaseAuthException
    } catch (e) {
      unawaited(LoggingService.logError('Sign in ERROR', e));
      final errorMessage = e.toString();
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

      // Check rate limit
      final rateLimit = await _rateLimit.checkRateLimit(email);
      if (rateLimit != null && rateLimit.isLocked) {
        throw _rateLimit.getRateLimitMessage(rateLimit);
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Upload profile image if provided
      String? finalAvatarUrl = avatarUrl;
      if (profileImageBytes != null && profileImageName != null) {
        try {
          final storageService = StorageService();
          finalAvatarUrl = await storageService.uploadProfileImage(
            userId: credential.user!.uid,
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
        id: credential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: UserRole.owner, // Default to owner for registration
        phone: phone,
        avatarUrl: finalAvatarUrl,
        displayName: '$firstName $lastName',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(credential.user!.uid).set({
        ...userModel.toJson(),
        'newsletterOptIn': newsletterOptIn,
      });

      // Update display name in Firebase Auth
      await credential.user!.updateDisplayName('$firstName $lastName');

      // Reset rate limit on success
      await _rateLimit.resetAttempts(email);

      // Send email verification
      await credential.user!.sendEmailVerification();

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

      // Log registration with location
      await _security.logEvent(
        userId: credential.user!.uid,
        type: SecurityEventType.registration,
        location: location,
        metadata: {'email': email, 'accountType': AccountType.trial.name},
      );

      // Log email verification sent
      await _security.logEvent(
        userId: credential.user!.uid,
        type: SecurityEventType.emailVerification,
        location: location,
        metadata: {'action': 'sent'},
      );

      state = EnhancedAuthState(
        firebaseUser: credential.user,
        userModel: userModel,
        requiresEmailVerification: true,
        requiresOnboarding: true,
      );
    } on FirebaseAuthException catch (e) {
      // Record failed attempt
      await _rateLimit.recordFailedAttempt(email);

      // Get updated rate limit info
      final updatedLimit = await _rateLimit.checkRateLimit(email);
      final errorMessage = updatedLimit != null && updatedLimit.isLocked
          ? _rateLimit.getRateLimitMessage(updatedLimit)
          : _getAuthErrorMessage(e);

      state = state.copyWith(isLoading: false, error: errorMessage);
      throw errorMessage; // Throw user-friendly message instead of FirebaseAuthException
    } catch (e) {
      final errorMessage = e.toString();
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
      final UserCredential userCredential = await _auth.signInAnonymously();

      if (userCredential.user == null) {
        throw Exception('Anonymous Sign-In failed: No user returned');
      }

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        // Create anonymous user profile
        final userModel = UserModel(
          id: userCredential.user!.uid,
          email: 'anonymous@demo.com',
          firstName: 'Demo',
          lastName: 'User',
          role: UserRole.owner,
          displayName: 'Demo User',
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toJson());
      } else {
        // Update last login for existing users
        await _updateLastLogin(userCredential.user!.uid);
      }

      // Log security event
      await _security.logEvent(
        userId: userCredential.user!.uid,
        type: SecurityEventType.login,
        metadata: {'provider': 'anonymous', 'isNewUser': isNewUser},
      );

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

    await _auth.signOut();
    state = const EnhancedAuthState();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e);
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
        throw Exception('Google Sign-In failed: No user returned');
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

      // Log security event
      await _security.logEvent(
        userId: userCredential.user!.uid,
        type: SecurityEventType.login,
        metadata: {'provider': 'google', 'isNewUser': isNewUser},
      );

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
        throw Exception('Apple Sign-In failed: No user returned');
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

      // Log security event
      await _security.logEvent(
        userId: userCredential.user!.uid,
        type: SecurityEventType.login,
        metadata: {'provider': 'apple', 'isNewUser': isNewUser},
      );

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
      throw Exception('No user logged in');
    }

    if (user.email == null) {
      throw Exception('Current user has no email');
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
      state = state.copyWith(requiresEmailVerification: true);
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
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Try again or reset your password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password must be at least 8 characters with uppercase, lowercase, number, and special character.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Contact support.';
      case 'user-disabled':
        return 'Your account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}

/// Enhanced Auth Provider
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

/// Current user provider (shorthand)
final enhancedCurrentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(enhancedAuthProvider).userModel;
});

/// Is authenticated provider
final enhancedIsAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(enhancedAuthProvider).isAuthenticated;
});
