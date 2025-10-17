// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_details_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for property details repository

@ProviderFor(propertyDetailsRepository)
const propertyDetailsRepositoryProvider = PropertyDetailsRepositoryProvider._();

/// Provider for property details repository

final class PropertyDetailsRepositoryProvider
    extends
        $FunctionalProvider<
          PropertyDetailsRepository,
          PropertyDetailsRepository,
          PropertyDetailsRepository
        >
    with $Provider<PropertyDetailsRepository> {
  /// Provider for property details repository
  const PropertyDetailsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'propertyDetailsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$propertyDetailsRepositoryHash();

  @$internal
  @override
  $ProviderElement<PropertyDetailsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PropertyDetailsRepository create(Ref ref) {
    return propertyDetailsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PropertyDetailsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PropertyDetailsRepository>(value),
    );
  }
}

String _$propertyDetailsRepositoryHash() =>
    r'd986be8b4b352771b70937e26017824a2010dc3b';
