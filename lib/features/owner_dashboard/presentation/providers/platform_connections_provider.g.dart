// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_connections_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$platformConnectionsHash() =>
    r'0e0937152b428b2f37499b4f375b331a447968ff';

/// Stream provider for all platform connections for the current owner
///
/// Copied from [platformConnections].
@ProviderFor(platformConnections)
final platformConnectionsProvider =
    AutoDisposeStreamProvider<List<PlatformConnection>>.internal(
      platformConnections,
      name: r'platformConnectionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$platformConnectionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlatformConnectionsRef =
    AutoDisposeStreamProviderRef<List<PlatformConnection>>;
String _$platformConnectionsForUnitHash() =>
    r'c279024f0eb1754aae988befdd87936ac3e7746b';

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

/// Provider for platform connections for a specific unit
///
/// Copied from [platformConnectionsForUnit].
@ProviderFor(platformConnectionsForUnit)
const platformConnectionsForUnitProvider = PlatformConnectionsForUnitFamily();

/// Provider for platform connections for a specific unit
///
/// Copied from [platformConnectionsForUnit].
class PlatformConnectionsForUnitFamily
    extends Family<AsyncValue<List<PlatformConnection>>> {
  /// Provider for platform connections for a specific unit
  ///
  /// Copied from [platformConnectionsForUnit].
  const PlatformConnectionsForUnitFamily();

  /// Provider for platform connections for a specific unit
  ///
  /// Copied from [platformConnectionsForUnit].
  PlatformConnectionsForUnitProvider call(String unitId) {
    return PlatformConnectionsForUnitProvider(unitId);
  }

  @override
  PlatformConnectionsForUnitProvider getProviderOverride(
    covariant PlatformConnectionsForUnitProvider provider,
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
  String? get name => r'platformConnectionsForUnitProvider';
}

/// Provider for platform connections for a specific unit
///
/// Copied from [platformConnectionsForUnit].
class PlatformConnectionsForUnitProvider
    extends AutoDisposeStreamProvider<List<PlatformConnection>> {
  /// Provider for platform connections for a specific unit
  ///
  /// Copied from [platformConnectionsForUnit].
  PlatformConnectionsForUnitProvider(String unitId)
    : this._internal(
        (ref) => platformConnectionsForUnit(
          ref as PlatformConnectionsForUnitRef,
          unitId,
        ),
        from: platformConnectionsForUnitProvider,
        name: r'platformConnectionsForUnitProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$platformConnectionsForUnitHash,
        dependencies: PlatformConnectionsForUnitFamily._dependencies,
        allTransitiveDependencies:
            PlatformConnectionsForUnitFamily._allTransitiveDependencies,
        unitId: unitId,
      );

  PlatformConnectionsForUnitProvider._internal(
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
    Stream<List<PlatformConnection>> Function(
      PlatformConnectionsForUnitRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PlatformConnectionsForUnitProvider._internal(
        (ref) => create(ref as PlatformConnectionsForUnitRef),
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
  AutoDisposeStreamProviderElement<List<PlatformConnection>> createElement() {
    return _PlatformConnectionsForUnitProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PlatformConnectionsForUnitProvider &&
        other.unitId == unitId;
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
mixin PlatformConnectionsForUnitRef
    on AutoDisposeStreamProviderRef<List<PlatformConnection>> {
  /// The parameter `unitId` of this provider.
  String get unitId;
}

class _PlatformConnectionsForUnitProviderElement
    extends AutoDisposeStreamProviderElement<List<PlatformConnection>>
    with PlatformConnectionsForUnitRef {
  _PlatformConnectionsForUnitProviderElement(super.provider);

  @override
  String get unitId => (origin as PlatformConnectionsForUnitProvider).unitId;
}

String _$connectBookingComHash() => r'636022176bf981d801abc73c42f11517aa0a3574';

/// Initiate Booking.com OAuth flow
///
/// Copied from [connectBookingCom].
@ProviderFor(connectBookingCom)
const connectBookingComProvider = ConnectBookingComFamily();

/// Initiate Booking.com OAuth flow
///
/// Copied from [connectBookingCom].
class ConnectBookingComFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// Initiate Booking.com OAuth flow
  ///
  /// Copied from [connectBookingCom].
  const ConnectBookingComFamily();

  /// Initiate Booking.com OAuth flow
  ///
  /// Copied from [connectBookingCom].
  ConnectBookingComProvider call({
    required String unitId,
    required String hotelId,
    required String roomTypeId,
  }) {
    return ConnectBookingComProvider(
      unitId: unitId,
      hotelId: hotelId,
      roomTypeId: roomTypeId,
    );
  }

  @override
  ConnectBookingComProvider getProviderOverride(
    covariant ConnectBookingComProvider provider,
  ) {
    return call(
      unitId: provider.unitId,
      hotelId: provider.hotelId,
      roomTypeId: provider.roomTypeId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'connectBookingComProvider';
}

/// Initiate Booking.com OAuth flow
///
/// Copied from [connectBookingCom].
class ConnectBookingComProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// Initiate Booking.com OAuth flow
  ///
  /// Copied from [connectBookingCom].
  ConnectBookingComProvider({
    required String unitId,
    required String hotelId,
    required String roomTypeId,
  }) : this._internal(
         (ref) => connectBookingCom(
           ref as ConnectBookingComRef,
           unitId: unitId,
           hotelId: hotelId,
           roomTypeId: roomTypeId,
         ),
         from: connectBookingComProvider,
         name: r'connectBookingComProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$connectBookingComHash,
         dependencies: ConnectBookingComFamily._dependencies,
         allTransitiveDependencies:
             ConnectBookingComFamily._allTransitiveDependencies,
         unitId: unitId,
         hotelId: hotelId,
         roomTypeId: roomTypeId,
       );

  ConnectBookingComProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.unitId,
    required this.hotelId,
    required this.roomTypeId,
  }) : super.internal();

  final String unitId;
  final String hotelId;
  final String roomTypeId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(ConnectBookingComRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConnectBookingComProvider._internal(
        (ref) => create(ref as ConnectBookingComRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        unitId: unitId,
        hotelId: hotelId,
        roomTypeId: roomTypeId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _ConnectBookingComProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConnectBookingComProvider &&
        other.unitId == unitId &&
        other.hotelId == hotelId &&
        other.roomTypeId == roomTypeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, unitId.hashCode);
    hash = _SystemHash.combine(hash, hotelId.hashCode);
    hash = _SystemHash.combine(hash, roomTypeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ConnectBookingComRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `unitId` of this provider.
  String get unitId;

  /// The parameter `hotelId` of this provider.
  String get hotelId;

  /// The parameter `roomTypeId` of this provider.
  String get roomTypeId;
}

class _ConnectBookingComProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with ConnectBookingComRef {
  _ConnectBookingComProviderElement(super.provider);

  @override
  String get unitId => (origin as ConnectBookingComProvider).unitId;
  @override
  String get hotelId => (origin as ConnectBookingComProvider).hotelId;
  @override
  String get roomTypeId => (origin as ConnectBookingComProvider).roomTypeId;
}

String _$connectAirbnbHash() => r'a337cee945436c98c1945db7837dc2023b912bc2';

/// Initiate Airbnb OAuth flow
///
/// Copied from [connectAirbnb].
@ProviderFor(connectAirbnb)
const connectAirbnbProvider = ConnectAirbnbFamily();

/// Initiate Airbnb OAuth flow
///
/// Copied from [connectAirbnb].
class ConnectAirbnbFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// Initiate Airbnb OAuth flow
  ///
  /// Copied from [connectAirbnb].
  const ConnectAirbnbFamily();

  /// Initiate Airbnb OAuth flow
  ///
  /// Copied from [connectAirbnb].
  ConnectAirbnbProvider call({
    required String unitId,
    required String listingId,
  }) {
    return ConnectAirbnbProvider(unitId: unitId, listingId: listingId);
  }

  @override
  ConnectAirbnbProvider getProviderOverride(
    covariant ConnectAirbnbProvider provider,
  ) {
    return call(unitId: provider.unitId, listingId: provider.listingId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'connectAirbnbProvider';
}

/// Initiate Airbnb OAuth flow
///
/// Copied from [connectAirbnb].
class ConnectAirbnbProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// Initiate Airbnb OAuth flow
  ///
  /// Copied from [connectAirbnb].
  ConnectAirbnbProvider({required String unitId, required String listingId})
    : this._internal(
        (ref) => connectAirbnb(
          ref as ConnectAirbnbRef,
          unitId: unitId,
          listingId: listingId,
        ),
        from: connectAirbnbProvider,
        name: r'connectAirbnbProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$connectAirbnbHash,
        dependencies: ConnectAirbnbFamily._dependencies,
        allTransitiveDependencies:
            ConnectAirbnbFamily._allTransitiveDependencies,
        unitId: unitId,
        listingId: listingId,
      );

  ConnectAirbnbProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.unitId,
    required this.listingId,
  }) : super.internal();

  final String unitId;
  final String listingId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(ConnectAirbnbRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConnectAirbnbProvider._internal(
        (ref) => create(ref as ConnectAirbnbRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        unitId: unitId,
        listingId: listingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _ConnectAirbnbProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConnectAirbnbProvider &&
        other.unitId == unitId &&
        other.listingId == listingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, unitId.hashCode);
    hash = _SystemHash.combine(hash, listingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ConnectAirbnbRef on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `unitId` of this provider.
  String get unitId;

  /// The parameter `listingId` of this provider.
  String get listingId;
}

class _ConnectAirbnbProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with ConnectAirbnbRef {
  _ConnectAirbnbProviderElement(super.provider);

  @override
  String get unitId => (origin as ConnectAirbnbProvider).unitId;
  @override
  String get listingId => (origin as ConnectAirbnbProvider).listingId;
}

String _$removePlatformConnectionHash() =>
    r'c681a960f1407500d4c1834a61d251bf7c67891f';

/// Remove platform connection
///
/// Copied from [removePlatformConnection].
@ProviderFor(removePlatformConnection)
const removePlatformConnectionProvider = RemovePlatformConnectionFamily();

/// Remove platform connection
///
/// Copied from [removePlatformConnection].
class RemovePlatformConnectionFamily extends Family<AsyncValue<void>> {
  /// Remove platform connection
  ///
  /// Copied from [removePlatformConnection].
  const RemovePlatformConnectionFamily();

  /// Remove platform connection
  ///
  /// Copied from [removePlatformConnection].
  RemovePlatformConnectionProvider call(String connectionId) {
    return RemovePlatformConnectionProvider(connectionId);
  }

  @override
  RemovePlatformConnectionProvider getProviderOverride(
    covariant RemovePlatformConnectionProvider provider,
  ) {
    return call(provider.connectionId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'removePlatformConnectionProvider';
}

/// Remove platform connection
///
/// Copied from [removePlatformConnection].
class RemovePlatformConnectionProvider extends AutoDisposeFutureProvider<void> {
  /// Remove platform connection
  ///
  /// Copied from [removePlatformConnection].
  RemovePlatformConnectionProvider(String connectionId)
    : this._internal(
        (ref) => removePlatformConnection(
          ref as RemovePlatformConnectionRef,
          connectionId,
        ),
        from: removePlatformConnectionProvider,
        name: r'removePlatformConnectionProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$removePlatformConnectionHash,
        dependencies: RemovePlatformConnectionFamily._dependencies,
        allTransitiveDependencies:
            RemovePlatformConnectionFamily._allTransitiveDependencies,
        connectionId: connectionId,
      );

  RemovePlatformConnectionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.connectionId,
  }) : super.internal();

  final String connectionId;

  @override
  Override overrideWith(
    FutureOr<void> Function(RemovePlatformConnectionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RemovePlatformConnectionProvider._internal(
        (ref) => create(ref as RemovePlatformConnectionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        connectionId: connectionId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _RemovePlatformConnectionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RemovePlatformConnectionProvider &&
        other.connectionId == connectionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, connectionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RemovePlatformConnectionRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `connectionId` of this provider.
  String get connectionId;
}

class _RemovePlatformConnectionProviderElement
    extends AutoDisposeFutureProviderElement<void>
    with RemovePlatformConnectionRef {
  _RemovePlatformConnectionProviderElement(super.provider);

  @override
  String get connectionId =>
      (origin as RemovePlatformConnectionProvider).connectionId;
}

String _$testPlatformConnectionHash() =>
    r'8fb2750808aaa0d2cf5c7afc998e052a55ac28a1';

/// Test platform connection
///
/// PLACEHOLDER: Returns true (always passes) until platform APIs are integrated.
/// Future implementation would:
/// 1. Fetch iCal feed from platform URL
/// 2. Validate feed format (ICS/iCalendar)
/// 3. Check for recent events/bookings
/// Priority: Low - iCal sync already validates on import
///
/// Copied from [testPlatformConnection].
@ProviderFor(testPlatformConnection)
const testPlatformConnectionProvider = TestPlatformConnectionFamily();

/// Test platform connection
///
/// PLACEHOLDER: Returns true (always passes) until platform APIs are integrated.
/// Future implementation would:
/// 1. Fetch iCal feed from platform URL
/// 2. Validate feed format (ICS/iCalendar)
/// 3. Check for recent events/bookings
/// Priority: Low - iCal sync already validates on import
///
/// Copied from [testPlatformConnection].
class TestPlatformConnectionFamily extends Family<AsyncValue<bool>> {
  /// Test platform connection
  ///
  /// PLACEHOLDER: Returns true (always passes) until platform APIs are integrated.
  /// Future implementation would:
  /// 1. Fetch iCal feed from platform URL
  /// 2. Validate feed format (ICS/iCalendar)
  /// 3. Check for recent events/bookings
  /// Priority: Low - iCal sync already validates on import
  ///
  /// Copied from [testPlatformConnection].
  const TestPlatformConnectionFamily();

  /// Test platform connection
  ///
  /// PLACEHOLDER: Returns true (always passes) until platform APIs are integrated.
  /// Future implementation would:
  /// 1. Fetch iCal feed from platform URL
  /// 2. Validate feed format (ICS/iCalendar)
  /// 3. Check for recent events/bookings
  /// Priority: Low - iCal sync already validates on import
  ///
  /// Copied from [testPlatformConnection].
  TestPlatformConnectionProvider call(String connectionId) {
    return TestPlatformConnectionProvider(connectionId);
  }

  @override
  TestPlatformConnectionProvider getProviderOverride(
    covariant TestPlatformConnectionProvider provider,
  ) {
    return call(provider.connectionId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'testPlatformConnectionProvider';
}

/// Test platform connection
///
/// PLACEHOLDER: Returns true (always passes) until platform APIs are integrated.
/// Future implementation would:
/// 1. Fetch iCal feed from platform URL
/// 2. Validate feed format (ICS/iCalendar)
/// 3. Check for recent events/bookings
/// Priority: Low - iCal sync already validates on import
///
/// Copied from [testPlatformConnection].
class TestPlatformConnectionProvider extends AutoDisposeFutureProvider<bool> {
  /// Test platform connection
  ///
  /// PLACEHOLDER: Returns true (always passes) until platform APIs are integrated.
  /// Future implementation would:
  /// 1. Fetch iCal feed from platform URL
  /// 2. Validate feed format (ICS/iCalendar)
  /// 3. Check for recent events/bookings
  /// Priority: Low - iCal sync already validates on import
  ///
  /// Copied from [testPlatformConnection].
  TestPlatformConnectionProvider(String connectionId)
    : this._internal(
        (ref) => testPlatformConnection(
          ref as TestPlatformConnectionRef,
          connectionId,
        ),
        from: testPlatformConnectionProvider,
        name: r'testPlatformConnectionProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$testPlatformConnectionHash,
        dependencies: TestPlatformConnectionFamily._dependencies,
        allTransitiveDependencies:
            TestPlatformConnectionFamily._allTransitiveDependencies,
        connectionId: connectionId,
      );

  TestPlatformConnectionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.connectionId,
  }) : super.internal();

  final String connectionId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(TestPlatformConnectionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TestPlatformConnectionProvider._internal(
        (ref) => create(ref as TestPlatformConnectionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        connectionId: connectionId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _TestPlatformConnectionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TestPlatformConnectionProvider &&
        other.connectionId == connectionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, connectionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TestPlatformConnectionRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `connectionId` of this provider.
  String get connectionId;
}

class _TestPlatformConnectionProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with TestPlatformConnectionRef {
  _TestPlatformConnectionProviderElement(super.provider);

  @override
  String get connectionId =>
      (origin as TestPlatformConnectionProvider).connectionId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
