// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_properties_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owner properties provider

@ProviderFor(ownerProperties)
const ownerPropertiesProvider = OwnerPropertiesProvider._();

/// Owner properties provider

final class OwnerPropertiesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PropertyModel>>,
          List<PropertyModel>,
          FutureOr<List<PropertyModel>>
        >
    with
        $FutureModifier<List<PropertyModel>>,
        $FutureProvider<List<PropertyModel>> {
  /// Owner properties provider
  const OwnerPropertiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ownerPropertiesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ownerPropertiesHash();

  @$internal
  @override
  $FutureProviderElement<List<PropertyModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PropertyModel>> create(Ref ref) {
    return ownerProperties(ref);
  }
}

String _$ownerPropertiesHash() => r'c8f6ea03a2d5f00960d2341fb8db88d0bc2dc0e8';

/// Owner properties count

@ProviderFor(ownerPropertiesCount)
const ownerPropertiesCountProvider = OwnerPropertiesCountProvider._();

/// Owner properties count

final class OwnerPropertiesCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Owner properties count
  const OwnerPropertiesCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ownerPropertiesCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ownerPropertiesCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return ownerPropertiesCount(ref);
  }
}

String _$ownerPropertiesCountHash() =>
    r'66db8343e1d8e87cf1009aa591da631c45e7e582';
