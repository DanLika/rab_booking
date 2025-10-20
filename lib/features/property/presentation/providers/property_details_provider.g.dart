// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_details_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$propertyDetailsHash() => r'8a4f4617f185390645a6355fe978fd78f4f4bda6';

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

/// Property details provider (fetch by ID)
///
/// Copied from [propertyDetails].
@ProviderFor(propertyDetails)
const propertyDetailsProvider = PropertyDetailsFamily();

/// Property details provider (fetch by ID)
///
/// Copied from [propertyDetails].
class PropertyDetailsFamily extends Family<AsyncValue<PropertyModel?>> {
  /// Property details provider (fetch by ID)
  ///
  /// Copied from [propertyDetails].
  const PropertyDetailsFamily();

  /// Property details provider (fetch by ID)
  ///
  /// Copied from [propertyDetails].
  PropertyDetailsProvider call(String propertyId) {
    return PropertyDetailsProvider(propertyId);
  }

  @override
  PropertyDetailsProvider getProviderOverride(
    covariant PropertyDetailsProvider provider,
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
  String? get name => r'propertyDetailsProvider';
}

/// Property details provider (fetch by ID)
///
/// Copied from [propertyDetails].
class PropertyDetailsProvider
    extends AutoDisposeFutureProvider<PropertyModel?> {
  /// Property details provider (fetch by ID)
  ///
  /// Copied from [propertyDetails].
  PropertyDetailsProvider(String propertyId)
    : this._internal(
        (ref) => propertyDetails(ref as PropertyDetailsRef, propertyId),
        from: propertyDetailsProvider,
        name: r'propertyDetailsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$propertyDetailsHash,
        dependencies: PropertyDetailsFamily._dependencies,
        allTransitiveDependencies:
            PropertyDetailsFamily._allTransitiveDependencies,
        propertyId: propertyId,
      );

  PropertyDetailsProvider._internal(
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
    FutureOr<PropertyModel?> Function(PropertyDetailsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PropertyDetailsProvider._internal(
        (ref) => create(ref as PropertyDetailsRef),
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
    return _PropertyDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PropertyDetailsProvider && other.propertyId == propertyId;
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
mixin PropertyDetailsRef on AutoDisposeFutureProviderRef<PropertyModel?> {
  /// The parameter `propertyId` of this provider.
  String get propertyId;
}

class _PropertyDetailsProviderElement
    extends AutoDisposeFutureProviderElement<PropertyModel?>
    with PropertyDetailsRef {
  _PropertyDetailsProviderElement(super.provider);

  @override
  String get propertyId => (origin as PropertyDetailsProvider).propertyId;
}

String _$propertyUnitsHash() => r'4244cf0721971206d280d6b3c1b1bde9b85b0d59';

/// Units provider (fetch units for a property)
///
/// Copied from [propertyUnits].
@ProviderFor(propertyUnits)
const propertyUnitsProvider = PropertyUnitsFamily();

/// Units provider (fetch units for a property)
///
/// Copied from [propertyUnits].
class PropertyUnitsFamily extends Family<AsyncValue<List<PropertyUnit>>> {
  /// Units provider (fetch units for a property)
  ///
  /// Copied from [propertyUnits].
  const PropertyUnitsFamily();

  /// Units provider (fetch units for a property)
  ///
  /// Copied from [propertyUnits].
  PropertyUnitsProvider call(String propertyId) {
    return PropertyUnitsProvider(propertyId);
  }

  @override
  PropertyUnitsProvider getProviderOverride(
    covariant PropertyUnitsProvider provider,
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
  String? get name => r'propertyUnitsProvider';
}

/// Units provider (fetch units for a property)
///
/// Copied from [propertyUnits].
class PropertyUnitsProvider
    extends AutoDisposeFutureProvider<List<PropertyUnit>> {
  /// Units provider (fetch units for a property)
  ///
  /// Copied from [propertyUnits].
  PropertyUnitsProvider(String propertyId)
    : this._internal(
        (ref) => propertyUnits(ref as PropertyUnitsRef, propertyId),
        from: propertyUnitsProvider,
        name: r'propertyUnitsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$propertyUnitsHash,
        dependencies: PropertyUnitsFamily._dependencies,
        allTransitiveDependencies:
            PropertyUnitsFamily._allTransitiveDependencies,
        propertyId: propertyId,
      );

  PropertyUnitsProvider._internal(
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
    FutureOr<List<PropertyUnit>> Function(PropertyUnitsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PropertyUnitsProvider._internal(
        (ref) => create(ref as PropertyUnitsRef),
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
  AutoDisposeFutureProviderElement<List<PropertyUnit>> createElement() {
    return _PropertyUnitsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PropertyUnitsProvider && other.propertyId == propertyId;
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
mixin PropertyUnitsRef on AutoDisposeFutureProviderRef<List<PropertyUnit>> {
  /// The parameter `propertyId` of this provider.
  String get propertyId;
}

class _PropertyUnitsProviderElement
    extends AutoDisposeFutureProviderElement<List<PropertyUnit>>
    with PropertyUnitsRef {
  _PropertyUnitsProviderElement(super.provider);

  @override
  String get propertyId => (origin as PropertyUnitsProvider).propertyId;
}

String _$unitDetailsHash() => r'ed88db97123b11a31a1a02c00861615a85cf20af';

/// Single unit provider (fetch unit by ID)
///
/// Copied from [unitDetails].
@ProviderFor(unitDetails)
const unitDetailsProvider = UnitDetailsFamily();

/// Single unit provider (fetch unit by ID)
///
/// Copied from [unitDetails].
class UnitDetailsFamily extends Family<AsyncValue<PropertyUnit?>> {
  /// Single unit provider (fetch unit by ID)
  ///
  /// Copied from [unitDetails].
  const UnitDetailsFamily();

  /// Single unit provider (fetch unit by ID)
  ///
  /// Copied from [unitDetails].
  UnitDetailsProvider call(String unitId) {
    return UnitDetailsProvider(unitId);
  }

  @override
  UnitDetailsProvider getProviderOverride(
    covariant UnitDetailsProvider provider,
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
  String? get name => r'unitDetailsProvider';
}

/// Single unit provider (fetch unit by ID)
///
/// Copied from [unitDetails].
class UnitDetailsProvider extends AutoDisposeFutureProvider<PropertyUnit?> {
  /// Single unit provider (fetch unit by ID)
  ///
  /// Copied from [unitDetails].
  UnitDetailsProvider(String unitId)
    : this._internal(
        (ref) => unitDetails(ref as UnitDetailsRef, unitId),
        from: unitDetailsProvider,
        name: r'unitDetailsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$unitDetailsHash,
        dependencies: UnitDetailsFamily._dependencies,
        allTransitiveDependencies: UnitDetailsFamily._allTransitiveDependencies,
        unitId: unitId,
      );

  UnitDetailsProvider._internal(
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
    FutureOr<PropertyUnit?> Function(UnitDetailsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UnitDetailsProvider._internal(
        (ref) => create(ref as UnitDetailsRef),
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
  AutoDisposeFutureProviderElement<PropertyUnit?> createElement() {
    return _UnitDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnitDetailsProvider && other.unitId == unitId;
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
mixin UnitDetailsRef on AutoDisposeFutureProviderRef<PropertyUnit?> {
  /// The parameter `unitId` of this provider.
  String get unitId;
}

class _UnitDetailsProviderElement
    extends AutoDisposeFutureProviderElement<PropertyUnit?>
    with UnitDetailsRef {
  _UnitDetailsProviderElement(super.provider);

  @override
  String get unitId => (origin as UnitDetailsProvider).unitId;
}

String _$bookingCalculationHash() =>
    r'2b5e2b6107367c7f79280617187ed8d70f0168c1';

/// Booking calculation provider (calculates total price)
///
/// Copied from [bookingCalculation].
@ProviderFor(bookingCalculation)
const bookingCalculationProvider = BookingCalculationFamily();

/// Booking calculation provider (calculates total price)
///
/// Copied from [bookingCalculation].
class BookingCalculationFamily
    extends Family<AsyncValue<Map<String, dynamic>?>> {
  /// Booking calculation provider (calculates total price)
  ///
  /// Copied from [bookingCalculation].
  const BookingCalculationFamily();

  /// Booking calculation provider (calculates total price)
  ///
  /// Copied from [bookingCalculation].
  BookingCalculationProvider call(String unitId) {
    return BookingCalculationProvider(unitId);
  }

  @override
  BookingCalculationProvider getProviderOverride(
    covariant BookingCalculationProvider provider,
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
  String? get name => r'bookingCalculationProvider';
}

/// Booking calculation provider (calculates total price)
///
/// Copied from [bookingCalculation].
class BookingCalculationProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>?> {
  /// Booking calculation provider (calculates total price)
  ///
  /// Copied from [bookingCalculation].
  BookingCalculationProvider(String unitId)
    : this._internal(
        (ref) => bookingCalculation(ref as BookingCalculationRef, unitId),
        from: bookingCalculationProvider,
        name: r'bookingCalculationProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bookingCalculationHash,
        dependencies: BookingCalculationFamily._dependencies,
        allTransitiveDependencies:
            BookingCalculationFamily._allTransitiveDependencies,
        unitId: unitId,
      );

  BookingCalculationProvider._internal(
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
    FutureOr<Map<String, dynamic>?> Function(BookingCalculationRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookingCalculationProvider._internal(
        (ref) => create(ref as BookingCalculationRef),
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
  AutoDisposeFutureProviderElement<Map<String, dynamic>?> createElement() {
    return _BookingCalculationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingCalculationProvider && other.unitId == unitId;
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
mixin BookingCalculationRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>?> {
  /// The parameter `unitId` of this provider.
  String get unitId;
}

class _BookingCalculationProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>?>
    with BookingCalculationRef {
  _BookingCalculationProviderElement(super.provider);

  @override
  String get unitId => (origin as BookingCalculationProvider).unitId;
}

String _$blockedDatesHash() => r'cb87c61429824efe47ff9751a882b25013231323';

/// Blocked dates provider for a unit
///
/// Copied from [blockedDates].
@ProviderFor(blockedDates)
const blockedDatesProvider = BlockedDatesFamily();

/// Blocked dates provider for a unit
///
/// Copied from [blockedDates].
class BlockedDatesFamily extends Family<AsyncValue<List<DateTime>>> {
  /// Blocked dates provider for a unit
  ///
  /// Copied from [blockedDates].
  const BlockedDatesFamily();

  /// Blocked dates provider for a unit
  ///
  /// Copied from [blockedDates].
  BlockedDatesProvider call(String unitId) {
    return BlockedDatesProvider(unitId);
  }

  @override
  BlockedDatesProvider getProviderOverride(
    covariant BlockedDatesProvider provider,
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
  String? get name => r'blockedDatesProvider';
}

/// Blocked dates provider for a unit
///
/// Copied from [blockedDates].
class BlockedDatesProvider extends AutoDisposeFutureProvider<List<DateTime>> {
  /// Blocked dates provider for a unit
  ///
  /// Copied from [blockedDates].
  BlockedDatesProvider(String unitId)
    : this._internal(
        (ref) => blockedDates(ref as BlockedDatesRef, unitId),
        from: blockedDatesProvider,
        name: r'blockedDatesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$blockedDatesHash,
        dependencies: BlockedDatesFamily._dependencies,
        allTransitiveDependencies:
            BlockedDatesFamily._allTransitiveDependencies,
        unitId: unitId,
      );

  BlockedDatesProvider._internal(
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
    FutureOr<List<DateTime>> Function(BlockedDatesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BlockedDatesProvider._internal(
        (ref) => create(ref as BlockedDatesRef),
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
  AutoDisposeFutureProviderElement<List<DateTime>> createElement() {
    return _BlockedDatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BlockedDatesProvider && other.unitId == unitId;
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
mixin BlockedDatesRef on AutoDisposeFutureProviderRef<List<DateTime>> {
  /// The parameter `unitId` of this provider.
  String get unitId;
}

class _BlockedDatesProviderElement
    extends AutoDisposeFutureProviderElement<List<DateTime>>
    with BlockedDatesRef {
  _BlockedDatesProviderElement(super.provider);

  @override
  String get unitId => (origin as BlockedDatesProvider).unitId;
}

String _$unitAvailabilityHash() => r'fdbbc7d2284197d448554b77e841246bb9969dbf';

/// Unit availability provider
///
/// Copied from [unitAvailability].
@ProviderFor(unitAvailability)
const unitAvailabilityProvider = UnitAvailabilityFamily();

/// Unit availability provider
///
/// Copied from [unitAvailability].
class UnitAvailabilityFamily extends Family<AsyncValue<bool>> {
  /// Unit availability provider
  ///
  /// Copied from [unitAvailability].
  const UnitAvailabilityFamily();

  /// Unit availability provider
  ///
  /// Copied from [unitAvailability].
  UnitAvailabilityProvider call(String unitId) {
    return UnitAvailabilityProvider(unitId);
  }

  @override
  UnitAvailabilityProvider getProviderOverride(
    covariant UnitAvailabilityProvider provider,
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
  String? get name => r'unitAvailabilityProvider';
}

/// Unit availability provider
///
/// Copied from [unitAvailability].
class UnitAvailabilityProvider extends AutoDisposeFutureProvider<bool> {
  /// Unit availability provider
  ///
  /// Copied from [unitAvailability].
  UnitAvailabilityProvider(String unitId)
    : this._internal(
        (ref) => unitAvailability(ref as UnitAvailabilityRef, unitId),
        from: unitAvailabilityProvider,
        name: r'unitAvailabilityProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$unitAvailabilityHash,
        dependencies: UnitAvailabilityFamily._dependencies,
        allTransitiveDependencies:
            UnitAvailabilityFamily._allTransitiveDependencies,
        unitId: unitId,
      );

  UnitAvailabilityProvider._internal(
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
    FutureOr<bool> Function(UnitAvailabilityRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UnitAvailabilityProvider._internal(
        (ref) => create(ref as UnitAvailabilityRef),
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
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _UnitAvailabilityProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnitAvailabilityProvider && other.unitId == unitId;
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
mixin UnitAvailabilityRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `unitId` of this provider.
  String get unitId;
}

class _UnitAvailabilityProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with UnitAvailabilityRef {
  _UnitAvailabilityProviderElement(super.provider);

  @override
  String get unitId => (origin as UnitAvailabilityProvider).unitId;
}

String _$selectedDatesNotifierHash() =>
    r'7b36ca3090e5a81f7d664d74da54830e6fea8a78';

/// Selected dates provider for booking
///
/// Copied from [SelectedDatesNotifier].
@ProviderFor(SelectedDatesNotifier)
final selectedDatesNotifierProvider =
    AutoDisposeNotifierProvider<SelectedDatesNotifier, SelectedDates>.internal(
      SelectedDatesNotifier.new,
      name: r'selectedDatesNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedDatesNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedDatesNotifier = AutoDisposeNotifier<SelectedDates>;
String _$selectedGuestsNotifierHash() =>
    r'139202aa2317a92944ae59d500f65a54e400771c';

/// Selected guests provider
///
/// Copied from [SelectedGuestsNotifier].
@ProviderFor(SelectedGuestsNotifier)
final selectedGuestsNotifierProvider =
    AutoDisposeNotifierProvider<SelectedGuestsNotifier, int>.internal(
      SelectedGuestsNotifier.new,
      name: r'selectedGuestsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedGuestsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedGuestsNotifier = AutoDisposeNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
