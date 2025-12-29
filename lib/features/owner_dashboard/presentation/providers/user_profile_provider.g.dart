// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userProfileRepositoryHash() =>
    r'bb68e91a75cc17e098ffc4469b3471fdaca068e7';

/// See also [userProfileRepository].
@ProviderFor(userProfileRepository)
final userProfileRepositoryProvider =
    AutoDisposeProvider<UserProfileRepository>.internal(
      userProfileRepository,
      name: r'userProfileRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userProfileRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserProfileRepositoryRef =
    AutoDisposeProviderRef<UserProfileRepository>;
String _$watchUserProfileHash() => r'429d56fd375771154f418ce4e32ec716b743ab3c';

/// Watch user profile data
///
/// ## AutoDispose Decision: TRUE (default @riverpod behavior)
/// AutoDispose is correct because:
/// - Profile data should refresh on re-entry
/// - Cleans up Firestore listener when not in use
/// - Memory freed when navigating away from profile screens
///
/// Copied from [watchUserProfile].
@ProviderFor(watchUserProfile)
final watchUserProfileProvider =
    AutoDisposeStreamProvider<UserProfile?>.internal(
      watchUserProfile,
      name: r'watchUserProfileProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$watchUserProfileHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WatchUserProfileRef = AutoDisposeStreamProviderRef<UserProfile?>;
String _$companyDetailsHash() => r'11b9176843ace41246eda8dd527a33030faaf11a';

/// Watch company details
///
/// Copied from [companyDetails].
@ProviderFor(companyDetails)
final companyDetailsProvider =
    AutoDisposeStreamProvider<CompanyDetails?>.internal(
      companyDetails,
      name: r'companyDetailsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$companyDetailsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CompanyDetailsRef = AutoDisposeStreamProviderRef<CompanyDetails?>;
String _$userDataHash() => r'a3bae6fb87afcd8194d107bfd8409d595f24c9a3';

/// Watch complete user data (profile + company)
///
/// Copied from [userData].
@ProviderFor(userData)
final userDataProvider = AutoDisposeStreamProvider<UserData?>.internal(
  userData,
  name: r'userDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserDataRef = AutoDisposeStreamProviderRef<UserData?>;
String _$notificationPreferencesHash() =>
    r'71be01f2a40a62d4d5e7c5131343de0f1787b433';

/// Watch notification preferences
///
/// Copied from [notificationPreferences].
@ProviderFor(notificationPreferences)
final notificationPreferencesProvider =
    AutoDisposeStreamProvider<NotificationPreferences?>.internal(
      notificationPreferences,
      name: r'notificationPreferencesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationPreferencesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationPreferencesRef =
    AutoDisposeStreamProviderRef<NotificationPreferences?>;
String _$userProfileNotifierHash() =>
    r'1a9604a7611f652ef6305225528ac8829425f7c9';

/// Notifier for updating user profile
///
/// Copied from [UserProfileNotifier].
@ProviderFor(UserProfileNotifier)
final userProfileNotifierProvider =
    AutoDisposeAsyncNotifierProvider<UserProfileNotifier, void>.internal(
      UserProfileNotifier.new,
      name: r'userProfileNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userProfileNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UserProfileNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
