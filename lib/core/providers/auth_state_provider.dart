import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_state_provider.g.dart';

/// User role enum
enum UserRole {
  guest,
  owner,
  admin;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.guest;
    }
  }
}

/// Auth state model
@immutable
class AuthState {
  final User? user;
  final UserRole? role;
  final bool isLoading;

  const AuthState({
    this.user,
    this.role,
    this.isLoading = false,
  });

  bool get isAuthenticated => user != null;

  bool get isGuest => role == UserRole.guest;
  bool get isOwner => role == UserRole.owner;
  bool get isAdmin => role == UserRole.admin;

  AuthState copyWith({
    User? user,
    UserRole? role,
    bool? isLoading,
  }) {
    return AuthState(
      user: user ?? this.user,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Auth state notifier provider
@riverpod
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  AuthState build() {
    // Listen to auth state changes
    _listenToAuthChanges();

    // Return initial state
    final currentUser = Supabase.instance.client.auth.currentUser;
    return AuthState(
      user: currentUser,
      role: currentUser != null ? _getUserRole(currentUser) : null,
      isLoading: false,
    );
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;

      if (user != null) {
        // Fetch user role from database
        final role = await _fetchUserRoleFromDatabase(user.id);
        state = AuthState(user: user, role: role, isLoading: false);
      } else {
        state = const AuthState(user: null, role: null, isLoading: false);
      }
    });
  }

  UserRole _getUserRole(User user) {
    // Try to get role from user metadata first
    final roleString = user.userMetadata?['role'] as String?;
    return UserRole.fromString(roleString);
  }

  Future<UserRole> _fetchUserRoleFromDatabase(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      return UserRole.fromString(response['role'] as String?);
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return UserRole.guest; // Default to guest on error
    }
  }

  /// Check if user has required role
  bool hasRole(UserRole requiredRole) {
    final currentRole = state.role;
    if (currentRole == null) return false;

    // Admin has access to everything
    if (currentRole == UserRole.admin) return true;

    // Owner has access to owner and guest routes
    if (currentRole == UserRole.owner && requiredRole == UserRole.guest) {
      return true;
    }

    // Exact role match
    return currentRole == requiredRole;
  }

  /// Manually refresh auth state
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final role = await _fetchUserRoleFromDatabase(user.id);
      state = AuthState(user: user, role: role, isLoading: false);
    } else {
      state = const AuthState(user: null, role: null, isLoading: false);
    }
  }
}

/// Convenience providers

/// Check if user is authenticated
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  return ref.watch(authStateNotifierProvider).isAuthenticated;
}

/// Get current user
@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authStateNotifierProvider).user;
}

/// Get current user role
@riverpod
UserRole? currentUserRole(CurrentUserRoleRef ref) {
  return ref.watch(authStateNotifierProvider).role;
}

/// Check if user is owner or admin
@riverpod
bool isOwnerOrAdmin(IsOwnerOrAdminRef ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role == UserRole.owner || role == UserRole.admin;
}
