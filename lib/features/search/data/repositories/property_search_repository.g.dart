// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_search_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for property search repository

@ProviderFor(propertySearchRepository)
const propertySearchRepositoryProvider = PropertySearchRepositoryProvider._();

/// Provider for property search repository

final class PropertySearchRepositoryProvider
    extends
        $FunctionalProvider<
          PropertySearchRepository,
          PropertySearchRepository,
          PropertySearchRepository
        >
    with $Provider<PropertySearchRepository> {
  /// Provider for property search repository
  const PropertySearchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'propertySearchRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$propertySearchRepositoryHash();

  @$internal
  @override
  $ProviderElement<PropertySearchRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PropertySearchRepository create(Ref ref) {
    return propertySearchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PropertySearchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PropertySearchRepository>(value),
    );
  }
}

String _$propertySearchRepositoryHash() =>
    r'cda388b504e53763da90cdef9a831d77e9b42851';
