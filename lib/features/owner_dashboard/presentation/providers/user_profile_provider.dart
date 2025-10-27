import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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
@riverpod
Stream<UserProfile?> userProfile(Ref ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(userProfileRepositoryProvider);
  return repository.watchUserProfile(userId);
}

/// Watch company details
@riverpod
Stream<CompanyDetails?> companyDetails(Ref ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(userProfileRepositoryProvider);
  return repository.watchCompanyDetails(userId);
}

/// Watch complete user data (profile + company)
@riverpod
Stream<UserData?> userData(Ref ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
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
  final userId = FirebaseAuth.instance.currentUser?.uid;
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
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(userProfileRepositoryProvider);
      await repository.updateUserProfile(profile);
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Update company details
  Future<void> updateCompany(String userId, CompanyDetails company) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(userProfileRepositoryProvider);
      await repository.updateCompanyDetails(userId, company);
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(userProfileRepositoryProvider);
      await repository.updateNotificationPreferences(preferences);
    });

    if (state.hasError) {
      throw state.error!;
    }
  }
}
