// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_properties_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ownerPropertiesHash() => r'a1def606c82c9fd153d738dd2e2b30ba787f3921';

/// Owner properties provider (REAL-TIME STREAM)
/// Automatically syncs across browser tabs
///
/// Copied from [ownerProperties].
@ProviderFor(ownerProperties)
final ownerPropertiesProvider =
    AutoDisposeStreamProvider<List<PropertyModel>>.internal(
      ownerProperties,
      name: r'ownerPropertiesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$ownerPropertiesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OwnerPropertiesRef = AutoDisposeStreamProviderRef<List<PropertyModel>>;
String _$ownerPropertiesCountHash() =>
    r'58c713cc7460e83f5c76d6a5518aa67d64c23e5b';

/// Owner properties count
///
/// Copied from [ownerPropertiesCount].
@ProviderFor(ownerPropertiesCount)
final ownerPropertiesCountProvider = AutoDisposeFutureProvider<int>.internal(
  ownerPropertiesCount,
  name: r'ownerPropertiesCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ownerPropertiesCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OwnerPropertiesCountRef = AutoDisposeFutureProviderRef<int>;
String _$propertyByIdHash() => r'bdb8a872a1ee7890255facff3d78514bde32ad07';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Get property by ID
///
/// Copied from [propertyById].
@ProviderFor(propertyById)
const propertyByIdProvider = PropertyByIdFamily();

/// Get property by ID
///
/// Copied from [propertyById].
class PropertyByIdFamily extends Family<AsyncValue<PropertyModel?>> {
  /// Get property by ID
  ///
  /// Copied from [propertyById].
  const PropertyByIdFamily();

  /// Get property by ID
  ///
  /// Copied from [propertyById].
  PropertyByIdProvider call(String propertyId) {
    return PropertyByIdProvider(propertyId);
  }

  @override
  PropertyByIdProvider getProviderOverride(
    covariant PropertyByIdProvider provider,
  ) {
    return call(provider.propertyId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'propertyByIdProvider';
}

/// Get property by ID
///
/// Copied from [propertyById].
class PropertyByIdProvider extends AutoDisposeFutureProvider<PropertyModel?> {
  /// Get property by ID
  ///
  /// Copied from [propertyById].
  PropertyByIdProvider(String propertyId)
    : this._internal(
        (ref) => propertyById(ref as PropertyByIdRef, propertyId),
        from: propertyByIdProvider,
        name: r'propertyByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$propertyByIdHash,
        dependencies: PropertyByIdFamily._dependencies,
        allTransitiveDependencies:
            PropertyByIdFamily._allTransitiveDependencies,
        propertyId: propertyId,
      );

  PropertyByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.propertyId,
  }) : super.internal();

  final String propertyId;

  @override
  Override overrideWith(
    FutureOr<PropertyModel?> Function(PropertyByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PropertyByIdProvider._internal(
        (ref) => create(ref as PropertyByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        propertyId: propertyId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PropertyModel?> createElement() {
    return _PropertyByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PropertyByIdProvider && other.propertyId == propertyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, propertyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PropertyByIdRef on AutoDisposeFutureProviderRef<PropertyModel?> {
  /// The parameter `propertyId` of this provider.
  String get propertyId;
}

class _PropertyByIdProviderElement
    extends AutoDisposeFutureProviderElement<PropertyModel?>
    with PropertyByIdRef {
  _PropertyByIdProviderElement(super.provider);

  @override
  String get propertyId => (origin as PropertyByIdProvider).propertyId;
}

String _$unitByIdHash() => r'571a49070d2dd088c71deae5ffdcd7617be99cda';

/// Get unit by ID (requires propertyId since units are in subcollection)
///
/// Copied from [unitById].
@ProviderFor(unitById)
const unitByIdProvider = UnitByIdFamily();

/// Get unit by ID (requires propertyId since units are in subcollection)
///
/// Copied from [unitById].
class UnitByIdFamily extends Family<AsyncValue<UnitModel?>> {
  /// Get unit by ID (requires propertyId since units are in subcollection)
  ///
  /// Copied from [unitById].
  const UnitByIdFamily();

  /// Get unit by ID (requires propertyId since units are in subcollection)
  ///
  /// Copied from [unitById].
  UnitByIdProvider call(String propertyId, String unitId) {
    return UnitByIdProvider(propertyId, unitId);
  }

  @override
  UnitByIdProvider getProviderOverride(covariant UnitByIdProvider provider) {
    return call(provider.propertyId, provider.unitId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'unitByIdProvider';
}

/// Get unit by ID (requires propertyId since units are in subcollection)
///
/// Copied from [unitById].
class UnitByIdProvider extends AutoDisposeFutureProvider<UnitModel?> {
  /// Get unit by ID (requires propertyId since units are in subcollection)
  ///
  /// Copied from [unitById].
  UnitByIdProvider(String propertyId, String unitId)
    : this._internal(
        (ref) => unitById(ref as UnitByIdRef, propertyId, unitId),
        from: unitByIdProvider,
        name: r'unitByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$unitByIdHash,
        dependencies: UnitByIdFamily._dependencies,
        allTransitiveDependencies: UnitByIdFamily._allTransitiveDependencies,
        propertyId: propertyId,
        unitId: unitId,
      );

  UnitByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.propertyId,
    required this.unitId,
  }) : super.internal();

  final String propertyId;
  final String unitId;

  @override
  Override overrideWith(
    FutureOr<UnitModel?> Function(UnitByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UnitByIdProvider._internal(
        (ref) => create(ref as UnitByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        propertyId: propertyId,
        unitId: unitId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<UnitModel?> createElement() {
    return _UnitByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnitByIdProvider &&
        other.propertyId == propertyId &&
        other.unitId == unitId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, propertyId.hashCode);
    hash = _SystemHash.combine(hash, unitId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UnitByIdRef on AutoDisposeFutureProviderRef<UnitModel?> {
  /// The parameter `propertyId` of this provider.
  String get propertyId;

  /// The parameter `unitId` of this provider.
  String get unitId;
}

class _UnitByIdProviderElement
    extends AutoDisposeFutureProviderElement<UnitModel?>
    with UnitByIdRef {
  _UnitByIdProviderElement(super.provider);

  @override
  String get propertyId => (origin as UnitByIdProvider).propertyId;
  @override
  String get unitId => (origin as UnitByIdProvider).unitId;
}

String _$unitByIdAcrossPropertiesHash() =>
    r'6f8b330a6f04827e1b1a2b53ee746105bd4a3364';

/// Get unit by ID across all properties (uses collection group query)
/// Useful for routes that only have unitId
///
/// Copied from [unitByIdAcrossProperties].
@ProviderFor(unitByIdAcrossProperties)
const unitByIdAcrossPropertiesProvider = UnitByIdAcrossPropertiesFamily();

/// Get unit by ID across all properties (uses collection group query)
/// Useful for routes that only have unitId
///
/// Copied from [unitByIdAcrossProperties].
class UnitByIdAcrossPropertiesFamily extends Family<AsyncValue<UnitModel?>> {
  /// Get unit by ID across all properties (uses collection group query)
  /// Useful for routes that only have unitId
  ///
  /// Copied from [unitByIdAcrossProperties].
  const UnitByIdAcrossPropertiesFamily();

  /// Get unit by ID across all properties (uses collection group query)
  /// Useful for routes that only have unitId
  ///
  /// Copied from [unitByIdAcrossProperties].
  UnitByIdAcrossPropertiesProvider call(String unitId) {
    return UnitByIdAcrossPropertiesProvider(unitId);
  }

  @override
  UnitByIdAcrossPropertiesProvider getProviderOverride(
    covariant UnitByIdAcrossPropertiesProvider provider,
  ) {
    return call(provider.unitId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'unitByIdAcrossPropertiesProvider';
}

/// Get unit by ID across all properties (uses collection group query)
/// Useful for routes that only have unitId
///
/// Copied from [unitByIdAcrossProperties].
class UnitByIdAcrossPropertiesProvider
    extends AutoDisposeFutureProvider<UnitModel?> {
  /// Get unit by ID across all properties (uses collection group query)
  /// Useful for routes that only have unitId
  ///
  /// Copied from [unitByIdAcrossProperties].
  UnitByIdAcrossPropertiesProvider(String unitId)
    : this._internal(
        (ref) => unitByIdAcrossProperties(
          ref as UnitByIdAcrossPropertiesRef,
          unitId,
        ),
        from: unitByIdAcrossPropertiesProvider,
        name: r'unitByIdAcrossPropertiesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$unitByIdAcrossPropertiesHash,
        dependencies: UnitByIdAcrossPropertiesFamily._dependencies,
        allTransitiveDependencies:
            UnitByIdAcrossPropertiesFamily._allTransitiveDependencies,
        unitId: unitId,
      );

  UnitByIdAcrossPropertiesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.unitId,
  }) : super.internal();

  final String unitId;

  @override
  Override overrideWith(
    FutureOr<UnitModel?> Function(UnitByIdAcrossPropertiesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UnitByIdAcrossPropertiesProvider._internal(
        (ref) => create(ref as UnitByIdAcrossPropertiesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        unitId: unitId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<UnitModel?> createElement() {
    return _UnitByIdAcrossPropertiesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnitByIdAcrossPropertiesProvider && other.unitId == unitId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, unitId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UnitByIdAcrossPropertiesRef on AutoDisposeFutureProviderRef<UnitModel?> {
  /// The parameter `unitId` of this provider.
  String get unitId;
}

class _UnitByIdAcrossPropertiesProviderElement
    extends AutoDisposeFutureProviderElement<UnitModel?>
    with UnitByIdAcrossPropertiesRef {
  _UnitByIdAcrossPropertiesProviderElement(super.provider);

  @override
  String get unitId => (origin as UnitByIdAcrossPropertiesProvider).unitId;
}

String _$ownerUnitsHash() => r'dff66ec55177aed69293b705500f46fd4401fa37';

/// Get all units for owner (across all properties) - REAL-TIME STREAM
/// Used for calendar views that display all units
/// Automatically syncs across browser tabs
///
/// Copied from [ownerUnits].
@ProviderFor(ownerUnits)
final ownerUnitsProvider = AutoDisposeStreamProvider<List<UnitModel>>.internal(
  ownerUnits,
  name: r'ownerUnitsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ownerUnitsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OwnerUnitsRef = AutoDisposeStreamProviderRef<List<UnitModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
