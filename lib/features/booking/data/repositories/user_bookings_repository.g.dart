// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_bookings_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userBookingsRepository)
const userBookingsRepositoryProvider = UserBookingsRepositoryProvider._();

final class UserBookingsRepositoryProvider
    extends
        $FunctionalProvider<
          UserBookingsRepository,
          UserBookingsRepository,
          UserBookingsRepository
        >
    with $Provider<UserBookingsRepository> {
  const UserBookingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userBookingsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userBookingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserBookingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserBookingsRepository create(Ref ref) {
    return userBookingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserBookingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserBookingsRepository>(value),
    );
  }
}

String _$userBookingsRepositoryHash() =>
    r'2fc6f077201133ae4fe98e578af7ef5fdbc07567';
