import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/user_model.dart';
import '../../shared/providers/repository_providers.dart';
import '../constants/enums.dart';

/// Auth state model
class AuthState {
  final User? firebaseUser;
  final UserModel? userModel;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.firebaseUser,
    this.userModel,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => firebaseUser != null && userModel != null;
  bool get isOwner => userModel?.isOwner ?? false;
  bool get isAdmin => userModel?.isAdmin ?? false;

  AuthState copyWith({
    User? firebaseUser,
    UserModel? userModel,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      userModel: userModel ?? this.userModel,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthNotifier(this._auth, this._firestore) : super(const AuthState()) {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      print('[AUTH] authStateChanges: user=${user?.uid}');
      if (user != null) {
        _loadUserProfile(user);
      } else {
        print('[AUTH] User signed out, clearing state');
        state = const AuthState();
      }
    });
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile(User firebaseUser) async {
    print('[AUTH] Loading user profile for ${firebaseUser.uid}...');
    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (doc.exists) {
        print('[AUTH] User profile found in Firestore');
        final userModel = UserModel.fromJson({...doc.data()!, 'id': doc.id});
        state = AuthState(firebaseUser: firebaseUser, userModel: userModel);
        print('[AUTH] State updated: isAuthenticated=${state.isAuthenticated}');
      } else {
        print('[AUTH] User profile NOT found, creating new profile...');
        // Create user profile if it doesn't exist
        await _createUserProfile(firebaseUser);
      }
    } catch (e) {
      print('[AUTH] ERROR loading user profile: $e');
      state = AuthState(
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
      role: UserRole.guest, // Default role
      phone: firebaseUser.phoneNumber,
      avatarUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(firebaseUser.uid).set(userModel.toJson());
    state = AuthState(firebaseUser: firebaseUser, userModel: userModel);
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    print('[AUTH] signInWithEmail called for $email');
    try {
      state = state.copyWith(isLoading: true, error: null);
      print('[AUTH] Calling Firebase signInWithEmailAndPassword...');
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      print('[AUTH] Firebase sign in successful!');
      // Auth state listener will handle the rest
    } on FirebaseAuthException catch (e) {
      print('[AUTH] Firebase sign in FAILED: ${e.code} - ${e.message}');
      state = state.copyWith(isLoading: false, error: _getAuthErrorMessage(e));
      rethrow;
    } catch (e) {
      print('[AUTH] Sign in ERROR: $e');
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
  }) async {
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
        role: UserRole.guest,
        phone: phone,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(credential.user!.uid).set(userModel.toJson());

      // Update display name
      await credential.user!.updateDisplayName('$firstName $lastName');

      state = AuthState(firebaseUser: credential.user, userModel: userModel);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _getAuthErrorMessage(e));
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    state = const AuthState();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e);
    }
  }

  /// Get user-friendly error message
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'An error occurred';
    }
  }
}

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return AuthNotifier(auth, firestore);
});

/// Current user provider (shorthand)
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).userModel;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
