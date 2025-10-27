import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/rate_limit_service.dart';
import '../../core/services/security_events_service.dart';
import '../../core/services/ip_geolocation_service.dart';
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
      requiresEmailVerification: requiresEmailVerification ?? this.requiresEmailVerification,
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
      print('[ENHANCED_AUTH] authStateChanges: user=${user?.uid}');
      if (user != null) {
        _loadUserProfile(user);
      } else {
        print('[ENHANCED_AUTH] User signed out, clearing state');
        state = const EnhancedAuthState();
      }
    });
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile(User firebaseUser) async {
    print('[ENHANCED_AUTH] Loading user profile for ${firebaseUser.uid}...');
    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (doc.exists && doc.data() != null) {
        print('[ENHANCED_AUTH] User profile found in Firestore');
        final userModel = UserModel.fromJson({...doc.data()!, 'id': doc.id});

        // Check email verification status
        final requiresVerification = !firebaseUser.emailVerified && !userModel.emailVerified;

        // Check onboarding status
        final requiresOnboarding = userModel.needsOnboarding;

        state = EnhancedAuthState(
          firebaseUser: firebaseUser,
          userModel: userModel,
          requiresEmailVerification: requiresVerification,
          requiresOnboarding: requiresOnboarding,
        );

        print('[ENHANCED_AUTH] State updated: isAuthenticated=${state.isAuthenticated}, requiresVerification=$requiresVerification, requiresOnboarding=$requiresOnboarding');

        // Update last login time
        await _updateLastLogin(firebaseUser.uid);
      } else {
        print('[ENHANCED_AUTH] User profile NOT found, creating new profile...');
        // Create user profile if it doesn't exist
        await _createUserProfile(firebaseUser);
      }
    } catch (e) {
      print('[ENHANCED_AUTH] ERROR loading user profile: $e');
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
      accountType: AccountType.trial,
      emailVerified: firebaseUser.emailVerified,
      displayName: firebaseUser.displayName,
      phone: firebaseUser.phoneNumber,
      avatarUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(firebaseUser.uid).set(userModel.toJson());
    state = EnhancedAuthState(firebaseUser: firebaseUser, userModel: userModel);
  }

  /// Sign in with email and password (with rate limiting)
  Future<void> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    print('[ENHANCED_AUTH] signInWithEmail called for $email, rememberMe=$rememberMe');
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Check rate limit
      final rateLimit = await _rateLimit.checkRateLimit(email);
      if (rateLimit != null && rateLimit.isLocked) {
        print('[ENHANCED_AUTH] Rate limit exceeded for $email');
        throw _rateLimit.getRateLimitMessage(rateLimit);
      }

      // Attempt sign in
      print('[ENHANCED_AUTH] Calling Firebase signInWithEmailAndPassword...');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('[ENHANCED_AUTH] Firebase sign in successful for ${credential.user?.uid}');

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
      print('[ENHANCED_AUTH] Sign in completed, auth state listener will load profile');
    } on FirebaseAuthException catch (e) {
      print('[ENHANCED_AUTH] Firebase sign in FAILED: ${e.code} - ${e.message}');
      // Record failed attempt
      await _rateLimit.recordFailedAttempt(email);

      // Get updated rate limit info
      final updatedLimit = await _rateLimit.checkRateLimit(email);
      final errorMessage = updatedLimit != null && updatedLimit.isLocked
          ? _rateLimit.getRateLimitMessage(updatedLimit)
          : _getAuthErrorMessage(e);

      state = state.copyWith(isLoading: false, error: errorMessage);
      rethrow;
    } catch (e) {
      print('[ENHANCED_AUTH] Sign in ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Register with email and password
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    bool acceptedTerms = false,
    bool acceptedPrivacy = false,
    bool newsletterOptIn = false,
  }) async {
    if (!acceptedTerms || !acceptedPrivacy) {
      throw 'You must accept the Terms & Conditions and Privacy Policy';
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile
      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: UserRole.owner, // Default to owner for registration
        accountType: AccountType.trial,
        emailVerified: false,
        phone: phone,
        displayName: '$firstName $lastName',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(credential.user!.uid).set({
        ...userModel.toJson(),
        'newsletterOptIn': newsletterOptIn,
      });

      // Update display name in Firebase Auth
      await credential.user!.updateDisplayName('$firstName $lastName');

      // Send email verification
      await credential.user!.sendEmailVerification();

      // Get geolocation
      final geoResult = await _geolocation.getCurrentLocation();
      final location = geoResult?.locationString;

      // Log registration with location
      await _security.logEvent(
        userId: credential.user!.uid,
        type: SecurityEventType.registration,
        location: location,
        metadata: {
          'email': email,
          'accountType': AccountType.trial.name,
        },
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
      state = state.copyWith(isLoading: false, error: _getAuthErrorMessage(e));
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
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
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}

/// Enhanced Auth Provider
final enhancedAuthProvider = StateNotifierProvider<EnhancedAuthNotifier, EnhancedAuthState>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final rateLimit = RateLimitService();
  final security = SecurityEventsService();
  final geolocation = IpGeolocationService();

  return EnhancedAuthNotifier(auth, firestore, rateLimit, security, geolocation);
});

/// Current user provider (shorthand)
final enhancedCurrentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(enhancedAuthProvider).userModel;
});

/// Is authenticated provider
final enhancedIsAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(enhancedAuthProvider).isAuthenticated;
});
