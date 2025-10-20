import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/logging_service.dart';

part 'auth_repository.g.dart';

/// Auth repository for Supabase authentication
class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign up with email, password, and metadata
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
        },
      );

      // Create user profile using database function
      // This function runs as SECURITY DEFINER so it can insert into public.users
      if (response.user != null) {
        try {
          await _supabase.rpc('create_user_profile', params: {
            'user_id': response.user!.id,
            'user_email': email,
            'first_name': firstName,
            'last_name': lastName,
            'user_role': role,
          });
          LoggingService.logInfo('User profile created successfully for ${response.user!.id}');
        } catch (e) {
          // Log error but don't fail registration - user is still authenticated
          LoggingService.logError('Failed to create user profile: $e');
          // Profile creation failure is not critical - user can still login
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with Google OAuth
  Future<bool> signInWithGoogle() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'rabbooking://login-callback',
      );

      // Note: Profile creation for OAuth users happens via the callback
      // The auth state change listener should handle profile creation if needed

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'rabbooking://reset-password',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update user password (for reset password flow)
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Resend email verification
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Get current session
  Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }

  /// Stream of auth state changes
  Stream<AuthState> onAuthStateChange() {
    return _supabase.auth.onAuthStateChange;
  }

  /// Get user role from database
  Future<String?> getUserRole(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      return response['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Get user profile from database
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isNotEmpty) {
        updates['updated_at'] = DateTime.now().toIso8601String();

        await _supabase
            .from('users')
            .update(updates)
            .eq('id', userId);
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for auth repository
@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(Supabase.instance.client);
}
