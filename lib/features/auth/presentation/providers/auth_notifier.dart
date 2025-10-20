import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gotrue/gotrue.dart' as gotrue;
import '../../data/auth_repository.dart';
import '../../../../core/services/logging_service.dart';

part 'auth_notifier.g.dart';

/// Auth state model
class AuthState {
  final User? user;
  final String? role;
  final Map<String, dynamic>? profile;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.role,
    this.profile,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
  bool get isGuest => role == 'guest';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';

  AuthState copyWith({
    User? user,
    String? role,
    Map<String, dynamic>? profile,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      role: role ?? this.role,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Auth notifier
@riverpod
class AuthNotifier extends _$AuthNotifier {
  StreamSubscription<gotrue.AuthState>? _authSubscription;

  @override
  AuthState build() {
    // Listen to auth state changes
    _listenToAuthChanges();

    // Get current user
    final repository = ref.read(authRepositoryProvider);
    final currentUser = repository.getCurrentUser();

    if (currentUser != null) {
      // Fetch user profile and role
      _fetchUserProfile(currentUser.id);

      return AuthState(user: currentUser);
    }

    return const AuthState();
  }

  /// Listen to Supabase auth state changes
  void _listenToAuthChanges() {
    final repository = ref.read(authRepositoryProvider);

    _authSubscription = repository.onAuthStateChange().listen((gotrue.AuthState authState) {
      final user = authState.session?.user;

      if (user != null) {
        state = state.copyWith(user: user);
        _fetchUserProfile(user.id);
      } else {
        state = const AuthState();
      }
    });

    ref.onDispose(() {
      _authSubscription?.cancel();
    });
  }

  /// Fetch user profile and role from database
  Future<void> _fetchUserProfile(String userId) async {
    final repository = ref.read(authRepositoryProvider);

    try {
      final profile = await repository.getUserProfile(userId);

      if (profile != null) {
        state = state.copyWith(
          role: profile['role'] as String?,
          profile: profile,
        );
      }
    } catch (e) {
      // Profile fetch failed, but user is still authenticated
      LoggingService.logError('Failed to fetch user profile', e);
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.signInWithEmail(
        email: email,
        password: password,
      );

      if (response.user != null) {
        state = state.copyWith(user: response.user, isLoading: false);
        await _fetchUserProfile(response.user!.id);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Login failed. Please try again.',
        );
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getAuthErrorMessage(e),
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.signUpWithEmail(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );

      if (response.user != null) {
        state = state.copyWith(
          user: response.user,
          role: role,
          isLoading: false,
        );
        await _fetchUserProfile(response.user!.id);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Registration failed. Please try again.',
        );
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getAuthErrorMessage(e),
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
      rethrow;
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithGoogle();

      // Auth state will be updated via stream listener
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getAuthErrorMessage(e),
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Google sign-in failed. Please try again.',
      );
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signOut();

      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        error: 'Sign out failed. Please try again.',
      );
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.sendPasswordResetEmail(email);

      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getAuthErrorMessage(e),
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send reset email. Please try again.',
      );
      rethrow;
    }
  }

  /// Update user password (for reset password flow)
  Future<void> updatePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.updatePassword(newPassword);

      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getAuthErrorMessage(e),
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update password. Please try again.',
      );
      rethrow;
    }
  }

  /// Resend email verification
  Future<void> resendVerificationEmail(String email) async {
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.resendVerificationEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user-friendly error message from AuthException
  String _getAuthErrorMessage(AuthException exception) {
    switch (exception.message) {
      case 'Invalid login credentials':
        return 'Invalid email or password. Please try again.';
      case 'Email not confirmed':
        return 'Please confirm your email address before logging in.';
      case 'User already registered':
        return 'An account with this email already exists.';
      case 'Password should be at least 6 characters':
        return 'Password must be at least 6 characters long.';
      default:
        return exception.message;
    }
  }
}
