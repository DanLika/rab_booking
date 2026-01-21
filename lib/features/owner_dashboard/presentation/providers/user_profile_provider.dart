import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../shared/models/notification_preferences_model.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../../../../shared/repositories/user_profile_repository.dart';

part 'user_profile_provider.g.dart';

// ========== REPOSITORY PROVIDER ==========

@riverpod
UserProfileRepository userProfileRepository(Ref ref) {
  return UserProfileRepository();
}

// ========== USER PROFILE PROVIDERS ==========

/// Watch user profile data
///
/// ## AutoDispose Decision: TRUE (default @riverpod behavior)
/// AutoDispose is correct because:
/// - Profile data should refresh on re-entry
/// - Cleans up Firestore listener when not in use
/// - Memory freed when navigating away from profile screens
@riverpod
Stream<UserProfile?> watchUserProfile(Ref ref) {
  // Consistency: Use enhancedAuthProvider for auth state
  final authState = ref.watch(enhancedAuthProvider);
  final userId = authState.userModel?.id;
  if (userId == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(userProfileRepositoryProvider);
  return repository.watchUserProfile(userId);
}

/// Watch company details
@riverpod
Stream<CompanyDetails?> companyDetails(Ref ref) {
  final authState = ref.watch(enhancedAuthProvider);
  final userId = authState.userModel?.id;
  if (userId == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(userProfileRepositoryProvider);
  return repository.watchCompanyDetails(userId);
}

/// Watch complete user data (profile + company)
@riverpod
Stream<UserData?> userData(Ref ref) {
  final authState = ref.watch(enhancedAuthProvider);
  final userId = authState.userModel?.id;
  if (userId == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(userProfileRepositoryProvider);
  return repository.watchUserData(userId);
}

// ========== NOTIFICATION PREFERENCES PROVIDER ==========

/// Watch notification preferences
@riverpod
Stream<NotificationPreferences?> notificationPreferences(Ref ref) {
  final authState = ref.watch(enhancedAuthProvider);
  final userId = authState.userModel?.id;
  if (userId == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(userProfileRepositoryProvider);
  return repository.watchNotificationPreferences(userId);
}

// ========== PROFILE UPDATE NOTIFIER ==========

/// Notifier for updating user profile
@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  @override
  FutureOr<void> build() {}

  /// Update user profile
  Future<void> updateProfile(UserProfile profile) async {
    final repository = ref.read(userProfileRepositoryProvider);
    await repository.updateUserProfile(profile);
  }

  /// Update company details
  Future<void> updateCompany(String userId, CompanyDetails company) async {
    final repository = ref.read(userProfileRepositoryProvider);
    await repository.updateCompanyDetails(userId, company);
  }

  /// Update both profile and company in one call
  /// Note: Simplified to avoid AsyncValue.guard() race condition that
  /// caused "Future already completed" errors
  Future<void> updateProfileAndCompany(
    UserProfile profile,
    CompanyDetails company,
  ) async {
    final repository = ref.read(userProfileRepositoryProvider);
    await repository.updateUserProfile(profile);
    await repository.updateCompanyDetails(profile.userId, company);
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    final repository = ref.read(userProfileRepositoryProvider);
    await repository.updateNotificationPreferences(preferences);
  }
}
