// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overbooking_detection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$overbookingConflictsHash() =>
    r'ba0046674d278ebac82981a115f2c640ba71d915';

/// Overbooking detection provider
/// Automatically detects conflicts between bookings in real-time
///
/// Copied from [overbookingConflicts].
@ProviderFor(overbookingConflicts)
final overbookingConflictsProvider =
    AutoDisposeStreamProvider<List<OverbookingConflict>>.internal(
      overbookingConflicts,
      name: r'overbookingConflictsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$overbookingConflictsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OverbookingConflictsRef =
    AutoDisposeStreamProviderRef<List<OverbookingConflict>>;
String _$overbookingConflictCountHash() =>
    r'ce5600c28b52f28e1903c26ebfdfd8e1bb1f19ea';

/// Helper provider to get conflict count
///
/// Copied from [overbookingConflictCount].
@ProviderFor(overbookingConflictCount)
final overbookingConflictCountProvider = AutoDisposeProvider<int>.internal(
  overbookingConflictCount,
  name: r'overbookingConflictCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$overbookingConflictCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OverbookingConflictCountRef = AutoDisposeProviderRef<int>;
String _$isBookingInConflictHash() =>
    r'51d0202c2645d24fdfc9926b9c17e62caad640b5';

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

/// Helper provider to check if a booking is in conflict
///
/// Copied from [isBookingInConflict].
@ProviderFor(isBookingInConflict)
const isBookingInConflictProvider = IsBookingInConflictFamily();

/// Helper provider to check if a booking is in conflict
///
/// Copied from [isBookingInConflict].
class IsBookingInConflictFamily extends Family<bool> {
  /// Helper provider to check if a booking is in conflict
  ///
  /// Copied from [isBookingInConflict].
  const IsBookingInConflictFamily();

  /// Helper provider to check if a booking is in conflict
  ///
  /// Copied from [isBookingInConflict].
  IsBookingInConflictProvider call(String bookingId) {
    return IsBookingInConflictProvider(bookingId);
  }

  @override
  IsBookingInConflictProvider getProviderOverride(
    covariant IsBookingInConflictProvider provider,
  ) {
    return call(provider.bookingId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'isBookingInConflictProvider';
}

/// Helper provider to check if a booking is in conflict
///
/// Copied from [isBookingInConflict].
class IsBookingInConflictProvider extends AutoDisposeProvider<bool> {
  /// Helper provider to check if a booking is in conflict
  ///
  /// Copied from [isBookingInConflict].
  IsBookingInConflictProvider(String bookingId)
    : this._internal(
        (ref) => isBookingInConflict(ref as IsBookingInConflictRef, bookingId),
        from: isBookingInConflictProvider,
        name: r'isBookingInConflictProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$isBookingInConflictHash,
        dependencies: IsBookingInConflictFamily._dependencies,
        allTransitiveDependencies:
            IsBookingInConflictFamily._allTransitiveDependencies,
        bookingId: bookingId,
      );

  IsBookingInConflictProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bookingId,
  }) : super.internal();

  final String bookingId;

  @override
  Override overrideWith(bool Function(IsBookingInConflictRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: IsBookingInConflictProvider._internal(
        (ref) => create(ref as IsBookingInConflictRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bookingId: bookingId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsBookingInConflictProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsBookingInConflictProvider && other.bookingId == bookingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsBookingInConflictRef on AutoDisposeProviderRef<bool> {
  /// The parameter `bookingId` of this provider.
  String get bookingId;
}

class _IsBookingInConflictProviderElement
    extends AutoDisposeProviderElement<bool>
    with IsBookingInConflictRef {
  _IsBookingInConflictProviderElement(super.provider);

  @override
  String get bookingId => (origin as IsBookingInConflictProvider).bookingId;
}

String _$conflictsForUnitHash() => r'e02d4af1397d22736b499e5d2c956e454c0b76b3';

/// Helper provider to get conflicts for a specific unit
///
/// Copied from [conflictsForUnit].
@ProviderFor(conflictsForUnit)
const conflictsForUnitProvider = ConflictsForUnitFamily();

/// Helper provider to get conflicts for a specific unit
///
/// Copied from [conflictsForUnit].
class ConflictsForUnitFamily extends Family<List<OverbookingConflict>> {
  /// Helper provider to get conflicts for a specific unit
  ///
  /// Copied from [conflictsForUnit].
  const ConflictsForUnitFamily();

  /// Helper provider to get conflicts for a specific unit
  ///
  /// Copied from [conflictsForUnit].
  ConflictsForUnitProvider call(String unitId) {
    return ConflictsForUnitProvider(unitId);
  }

  @override
  ConflictsForUnitProvider getProviderOverride(
    covariant ConflictsForUnitProvider provider,
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
  String? get name => r'conflictsForUnitProvider';
}

/// Helper provider to get conflicts for a specific unit
///
/// Copied from [conflictsForUnit].
class ConflictsForUnitProvider
    extends AutoDisposeProvider<List<OverbookingConflict>> {
  /// Helper provider to get conflicts for a specific unit
  ///
  /// Copied from [conflictsForUnit].
  ConflictsForUnitProvider(String unitId)
    : this._internal(
        (ref) => conflictsForUnit(ref as ConflictsForUnitRef, unitId),
        from: conflictsForUnitProvider,
        name: r'conflictsForUnitProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$conflictsForUnitHash,
        dependencies: ConflictsForUnitFamily._dependencies,
        allTransitiveDependencies:
            ConflictsForUnitFamily._allTransitiveDependencies,
        unitId: unitId,
      );

  ConflictsForUnitProvider._internal(
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
    List<OverbookingConflict> Function(ConflictsForUnitRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConflictsForUnitProvider._internal(
        (ref) => create(ref as ConflictsForUnitRef),
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
  AutoDisposeProviderElement<List<OverbookingConflict>> createElement() {
    return _ConflictsForUnitProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConflictsForUnitProvider && other.unitId == unitId;
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
mixin ConflictsForUnitRef on AutoDisposeProviderRef<List<OverbookingConflict>> {
  /// The parameter `unitId` of this provider.
  String get unitId;
}

class _ConflictsForUnitProviderElement
    extends AutoDisposeProviderElement<List<OverbookingConflict>>
    with ConflictsForUnitRef {
  _ConflictsForUnitProviderElement(super.provider);

  @override
  String get unitId => (origin as ConflictsForUnitProvider).unitId;
}

String _$overbookingAutoResolverHash() =>
    r'a8460f74ac30c203e821a9d247c15840b4801dd4';

/// Auto-resolution listener provider
/// Automatically rejects pending bookings when they conflict with confirmed bookings
///
/// Copied from [OverbookingAutoResolver].
@ProviderFor(OverbookingAutoResolver)
final overbookingAutoResolverProvider =
    AutoDisposeNotifierProvider<OverbookingAutoResolver, void>.internal(
      OverbookingAutoResolver.new,
      name: r'overbookingAutoResolverProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$overbookingAutoResolverHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OverbookingAutoResolver = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
