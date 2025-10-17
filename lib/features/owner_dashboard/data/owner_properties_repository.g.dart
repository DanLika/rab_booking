// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_properties_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for owner properties repository

@ProviderFor(ownerPropertiesRepository)
const ownerPropertiesRepositoryProvider = OwnerPropertiesRepositoryProvider._();

/// Provider for owner properties repository

final class OwnerPropertiesRepositoryProvider
    extends
        $FunctionalProvider<
          OwnerPropertiesRepository,
          OwnerPropertiesRepository,
          OwnerPropertiesRepository
        >
    with $Provider<OwnerPropertiesRepository> {
  /// Provider for owner properties repository
  const OwnerPropertiesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ownerPropertiesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ownerPropertiesRepositoryHash();

  @$internal
  @override
  $ProviderElement<OwnerPropertiesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OwnerPropertiesRepository create(Ref ref) {
    return ownerPropertiesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OwnerPropertiesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OwnerPropertiesRepository>(value),
    );
  }
}

String _$ownerPropertiesRepositoryHash() =>
    r'72c300ab7a5596e318abf3fd2b9317a8d20e76f9';
