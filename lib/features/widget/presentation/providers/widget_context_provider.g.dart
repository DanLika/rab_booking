// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_context_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$widgetContextHash() => r'ff29d169d0d08d0d8052f7ac51193012947d39c1';

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

/// Aggregated context provider for the booking widget.
///
/// Fetches property, unit, and widget settings in parallel with a single
/// provider subscription, reducing Firestore queries from 3 separate calls
/// to a single coordinated batch.
///
/// ## Caching Strategy
/// - Results are cached for 5 minutes using `keepAlive`
/// - Same params will return cached result instantly
/// - Different params will trigger new fetch
///
/// ## Usage
/// ```dart
/// final contextAsync = ref.watch(widgetContextProvider((
///   propertyId: 'abc123',
///   unitId: 'xyz789',
/// )));
///
/// contextAsync.when(
///   data: (ctx) => BookingWidget(context: ctx),
///   loading: () => LoadingIndicator(),
///   error: (e, st) => ErrorWidget(e),
/// );
/// ```
///
/// ## Query Optimization
/// Previously, the widget made 3-4 separate queries:
/// - widgetPropertyByIdProvider
/// - unitByIdProvider
/// - widgetSettingsOrDefaultProvider
/// - (booking_price_provider also fetched unit separately)
///
/// With this provider:
/// - All 3 queries run in parallel via Future.wait
/// - Unit data is cached and reused by booking_price_provider
/// - Result is cached for 5 minutes
///
/// Copied from [widgetContext].
@ProviderFor(widgetContext)
const widgetContextProvider = WidgetContextFamily();

/// Aggregated context provider for the booking widget.
///
/// Fetches property, unit, and widget settings in parallel with a single
/// provider subscription, reducing Firestore queries from 3 separate calls
/// to a single coordinated batch.
///
/// ## Caching Strategy
/// - Results are cached for 5 minutes using `keepAlive`
/// - Same params will return cached result instantly
/// - Different params will trigger new fetch
///
/// ## Usage
/// ```dart
/// final contextAsync = ref.watch(widgetContextProvider((
///   propertyId: 'abc123',
///   unitId: 'xyz789',
/// )));
///
/// contextAsync.when(
///   data: (ctx) => BookingWidget(context: ctx),
///   loading: () => LoadingIndicator(),
///   error: (e, st) => ErrorWidget(e),
/// );
/// ```
///
/// ## Query Optimization
/// Previously, the widget made 3-4 separate queries:
/// - widgetPropertyByIdProvider
/// - unitByIdProvider
/// - widgetSettingsOrDefaultProvider
/// - (booking_price_provider also fetched unit separately)
///
/// With this provider:
/// - All 3 queries run in parallel via Future.wait
/// - Unit data is cached and reused by booking_price_provider
/// - Result is cached for 5 minutes
///
/// Copied from [widgetContext].
class WidgetContextFamily extends Family<AsyncValue<WidgetContext>> {
  /// Aggregated context provider for the booking widget.
  ///
  /// Fetches property, unit, and widget settings in parallel with a single
  /// provider subscription, reducing Firestore queries from 3 separate calls
  /// to a single coordinated batch.
  ///
  /// ## Caching Strategy
  /// - Results are cached for 5 minutes using `keepAlive`
  /// - Same params will return cached result instantly
  /// - Different params will trigger new fetch
  ///
  /// ## Usage
  /// ```dart
  /// final contextAsync = ref.watch(widgetContextProvider((
  ///   propertyId: 'abc123',
  ///   unitId: 'xyz789',
  /// )));
  ///
  /// contextAsync.when(
  ///   data: (ctx) => BookingWidget(context: ctx),
  ///   loading: () => LoadingIndicator(),
  ///   error: (e, st) => ErrorWidget(e),
  /// );
  /// ```
  ///
  /// ## Query Optimization
  /// Previously, the widget made 3-4 separate queries:
  /// - widgetPropertyByIdProvider
  /// - unitByIdProvider
  /// - widgetSettingsOrDefaultProvider
  /// - (booking_price_provider also fetched unit separately)
  ///
  /// With this provider:
  /// - All 3 queries run in parallel via Future.wait
  /// - Unit data is cached and reused by booking_price_provider
  /// - Result is cached for 5 minutes
  ///
  /// Copied from [widgetContext].
  const WidgetContextFamily();

  /// Aggregated context provider for the booking widget.
  ///
  /// Fetches property, unit, and widget settings in parallel with a single
  /// provider subscription, reducing Firestore queries from 3 separate calls
  /// to a single coordinated batch.
  ///
  /// ## Caching Strategy
  /// - Results are cached for 5 minutes using `keepAlive`
  /// - Same params will return cached result instantly
  /// - Different params will trigger new fetch
  ///
  /// ## Usage
  /// ```dart
  /// final contextAsync = ref.watch(widgetContextProvider((
  ///   propertyId: 'abc123',
  ///   unitId: 'xyz789',
  /// )));
  ///
  /// contextAsync.when(
  ///   data: (ctx) => BookingWidget(context: ctx),
  ///   loading: () => LoadingIndicator(),
  ///   error: (e, st) => ErrorWidget(e),
  /// );
  /// ```
  ///
  /// ## Query Optimization
  /// Previously, the widget made 3-4 separate queries:
  /// - widgetPropertyByIdProvider
  /// - unitByIdProvider
  /// - widgetSettingsOrDefaultProvider
  /// - (booking_price_provider also fetched unit separately)
  ///
  /// With this provider:
  /// - All 3 queries run in parallel via Future.wait
  /// - Unit data is cached and reused by booking_price_provider
  /// - Result is cached for 5 minutes
  ///
  /// Copied from [widgetContext].
  WidgetContextProvider call(({String propertyId, String unitId}) params) {
    return WidgetContextProvider(params);
  }

  @override
  WidgetContextProvider getProviderOverride(
    covariant WidgetContextProvider provider,
  ) {
    return call(provider.params);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'widgetContextProvider';
}

/// Aggregated context provider for the booking widget.
///
/// Fetches property, unit, and widget settings in parallel with a single
/// provider subscription, reducing Firestore queries from 3 separate calls
/// to a single coordinated batch.
///
/// ## Caching Strategy
/// - Results are cached for 5 minutes using `keepAlive`
/// - Same params will return cached result instantly
/// - Different params will trigger new fetch
///
/// ## Usage
/// ```dart
/// final contextAsync = ref.watch(widgetContextProvider((
///   propertyId: 'abc123',
///   unitId: 'xyz789',
/// )));
///
/// contextAsync.when(
///   data: (ctx) => BookingWidget(context: ctx),
///   loading: () => LoadingIndicator(),
///   error: (e, st) => ErrorWidget(e),
/// );
/// ```
///
/// ## Query Optimization
/// Previously, the widget made 3-4 separate queries:
/// - widgetPropertyByIdProvider
/// - unitByIdProvider
/// - widgetSettingsOrDefaultProvider
/// - (booking_price_provider also fetched unit separately)
///
/// With this provider:
/// - All 3 queries run in parallel via Future.wait
/// - Unit data is cached and reused by booking_price_provider
/// - Result is cached for 5 minutes
///
/// Copied from [widgetContext].
class WidgetContextProvider extends FutureProvider<WidgetContext> {
  /// Aggregated context provider for the booking widget.
  ///
  /// Fetches property, unit, and widget settings in parallel with a single
  /// provider subscription, reducing Firestore queries from 3 separate calls
  /// to a single coordinated batch.
  ///
  /// ## Caching Strategy
  /// - Results are cached for 5 minutes using `keepAlive`
  /// - Same params will return cached result instantly
  /// - Different params will trigger new fetch
  ///
  /// ## Usage
  /// ```dart
  /// final contextAsync = ref.watch(widgetContextProvider((
  ///   propertyId: 'abc123',
  ///   unitId: 'xyz789',
  /// )));
  ///
  /// contextAsync.when(
  ///   data: (ctx) => BookingWidget(context: ctx),
  ///   loading: () => LoadingIndicator(),
  ///   error: (e, st) => ErrorWidget(e),
  /// );
  /// ```
  ///
  /// ## Query Optimization
  /// Previously, the widget made 3-4 separate queries:
  /// - widgetPropertyByIdProvider
  /// - unitByIdProvider
  /// - widgetSettingsOrDefaultProvider
  /// - (booking_price_provider also fetched unit separately)
  ///
  /// With this provider:
  /// - All 3 queries run in parallel via Future.wait
  /// - Unit data is cached and reused by booking_price_provider
  /// - Result is cached for 5 minutes
  ///
  /// Copied from [widgetContext].
  WidgetContextProvider(({String propertyId, String unitId}) params)
    : this._internal(
        (ref) => widgetContext(ref as WidgetContextRef, params),
        from: widgetContextProvider,
        name: r'widgetContextProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$widgetContextHash,
        dependencies: WidgetContextFamily._dependencies,
        allTransitiveDependencies:
            WidgetContextFamily._allTransitiveDependencies,
        params: params,
      );

  WidgetContextProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({String propertyId, String unitId}) params;

  @override
  Override overrideWith(
    FutureOr<WidgetContext> Function(WidgetContextRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WidgetContextProvider._internal(
        (ref) => create(ref as WidgetContextRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  FutureProviderElement<WidgetContext> createElement() {
    return _WidgetContextProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WidgetContextProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WidgetContextRef on FutureProviderRef<WidgetContext> {
  /// The parameter `params` of this provider.
  ({String propertyId, String unitId}) get params;
}

class _WidgetContextProviderElement extends FutureProviderElement<WidgetContext>
    with WidgetContextRef {
  _WidgetContextProviderElement(super.provider);

  @override
  ({String propertyId, String unitId}) get params =>
      (origin as WidgetContextProvider).params;
}

String _$widgetContextByUnitOnlyHash() =>
    r'4c7db7434b9b45e02de018fa2f099812549a4d1b';

/// Simplified provider that only needs unitId.
///
/// Fetches unit via collection group query, then resolves full context.
/// Use when propertyId is not available (e.g., some embed scenarios).
///
/// Note: This requires an extra query to get the unit first, so prefer
/// [widgetContextProvider] when propertyId is available.
///
/// Copied from [widgetContextByUnitOnly].
@ProviderFor(widgetContextByUnitOnly)
const widgetContextByUnitOnlyProvider = WidgetContextByUnitOnlyFamily();

/// Simplified provider that only needs unitId.
///
/// Fetches unit via collection group query, then resolves full context.
/// Use when propertyId is not available (e.g., some embed scenarios).
///
/// Note: This requires an extra query to get the unit first, so prefer
/// [widgetContextProvider] when propertyId is available.
///
/// Copied from [widgetContextByUnitOnly].
class WidgetContextByUnitOnlyFamily extends Family<AsyncValue<WidgetContext>> {
  /// Simplified provider that only needs unitId.
  ///
  /// Fetches unit via collection group query, then resolves full context.
  /// Use when propertyId is not available (e.g., some embed scenarios).
  ///
  /// Note: This requires an extra query to get the unit first, so prefer
  /// [widgetContextProvider] when propertyId is available.
  ///
  /// Copied from [widgetContextByUnitOnly].
  const WidgetContextByUnitOnlyFamily();

  /// Simplified provider that only needs unitId.
  ///
  /// Fetches unit via collection group query, then resolves full context.
  /// Use when propertyId is not available (e.g., some embed scenarios).
  ///
  /// Note: This requires an extra query to get the unit first, so prefer
  /// [widgetContextProvider] when propertyId is available.
  ///
  /// Copied from [widgetContextByUnitOnly].
  WidgetContextByUnitOnlyProvider call(String unitId) {
    return WidgetContextByUnitOnlyProvider(unitId);
  }

  @override
  WidgetContextByUnitOnlyProvider getProviderOverride(
    covariant WidgetContextByUnitOnlyProvider provider,
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
  String? get name => r'widgetContextByUnitOnlyProvider';
}

/// Simplified provider that only needs unitId.
///
/// Fetches unit via collection group query, then resolves full context.
/// Use when propertyId is not available (e.g., some embed scenarios).
///
/// Note: This requires an extra query to get the unit first, so prefer
/// [widgetContextProvider] when propertyId is available.
///
/// Copied from [widgetContextByUnitOnly].
class WidgetContextByUnitOnlyProvider
    extends AutoDisposeFutureProvider<WidgetContext> {
  /// Simplified provider that only needs unitId.
  ///
  /// Fetches unit via collection group query, then resolves full context.
  /// Use when propertyId is not available (e.g., some embed scenarios).
  ///
  /// Note: This requires an extra query to get the unit first, so prefer
  /// [widgetContextProvider] when propertyId is available.
  ///
  /// Copied from [widgetContextByUnitOnly].
  WidgetContextByUnitOnlyProvider(String unitId)
    : this._internal(
        (ref) =>
            widgetContextByUnitOnly(ref as WidgetContextByUnitOnlyRef, unitId),
        from: widgetContextByUnitOnlyProvider,
        name: r'widgetContextByUnitOnlyProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$widgetContextByUnitOnlyHash,
        dependencies: WidgetContextByUnitOnlyFamily._dependencies,
        allTransitiveDependencies:
            WidgetContextByUnitOnlyFamily._allTransitiveDependencies,
        unitId: unitId,
      );

  WidgetContextByUnitOnlyProvider._internal(
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
    FutureOr<WidgetContext> Function(WidgetContextByUnitOnlyRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WidgetContextByUnitOnlyProvider._internal(
        (ref) => create(ref as WidgetContextByUnitOnlyRef),
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
  AutoDisposeFutureProviderElement<WidgetContext> createElement() {
    return _WidgetContextByUnitOnlyProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WidgetContextByUnitOnlyProvider && other.unitId == unitId;
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
mixin WidgetContextByUnitOnlyRef
    on AutoDisposeFutureProviderRef<WidgetContext> {
  /// The parameter `unitId` of this provider.
  String get unitId;
}

class _WidgetContextByUnitOnlyProviderElement
    extends AutoDisposeFutureProviderElement<WidgetContext>
    with WidgetContextByUnitOnlyRef {
  _WidgetContextByUnitOnlyProviderElement(super.provider);

  @override
  String get unitId => (origin as WidgetContextByUnitOnlyProvider).unitId;
}

String _$cachedWidgetContextHash() =>
    r'cc3e7de39473e703134d0c79df6f31c9d682b7e4';

/// Quick access to cached unit from widget context.
///
/// Use this in booking_price_provider to avoid duplicate unit fetch.
/// Returns the cached context if available, otherwise fetches it.
///
/// Copied from [cachedWidgetContext].
@ProviderFor(cachedWidgetContext)
const cachedWidgetContextProvider = CachedWidgetContextFamily();

/// Quick access to cached unit from widget context.
///
/// Use this in booking_price_provider to avoid duplicate unit fetch.
/// Returns the cached context if available, otherwise fetches it.
///
/// Copied from [cachedWidgetContext].
class CachedWidgetContextFamily extends Family<AsyncValue<WidgetContext>> {
  /// Quick access to cached unit from widget context.
  ///
  /// Use this in booking_price_provider to avoid duplicate unit fetch.
  /// Returns the cached context if available, otherwise fetches it.
  ///
  /// Copied from [cachedWidgetContext].
  const CachedWidgetContextFamily();

  /// Quick access to cached unit from widget context.
  ///
  /// Use this in booking_price_provider to avoid duplicate unit fetch.
  /// Returns the cached context if available, otherwise fetches it.
  ///
  /// Copied from [cachedWidgetContext].
  CachedWidgetContextProvider call(
    ({String propertyId, String unitId}) params,
  ) {
    return CachedWidgetContextProvider(params);
  }

  @override
  CachedWidgetContextProvider getProviderOverride(
    covariant CachedWidgetContextProvider provider,
  ) {
    return call(provider.params);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'cachedWidgetContextProvider';
}

/// Quick access to cached unit from widget context.
///
/// Use this in booking_price_provider to avoid duplicate unit fetch.
/// Returns the cached context if available, otherwise fetches it.
///
/// Copied from [cachedWidgetContext].
class CachedWidgetContextProvider
    extends AutoDisposeFutureProvider<WidgetContext> {
  /// Quick access to cached unit from widget context.
  ///
  /// Use this in booking_price_provider to avoid duplicate unit fetch.
  /// Returns the cached context if available, otherwise fetches it.
  ///
  /// Copied from [cachedWidgetContext].
  CachedWidgetContextProvider(({String propertyId, String unitId}) params)
    : this._internal(
        (ref) => cachedWidgetContext(ref as CachedWidgetContextRef, params),
        from: cachedWidgetContextProvider,
        name: r'cachedWidgetContextProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$cachedWidgetContextHash,
        dependencies: CachedWidgetContextFamily._dependencies,
        allTransitiveDependencies:
            CachedWidgetContextFamily._allTransitiveDependencies,
        params: params,
      );

  CachedWidgetContextProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({String propertyId, String unitId}) params;

  @override
  Override overrideWith(
    FutureOr<WidgetContext> Function(CachedWidgetContextRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CachedWidgetContextProvider._internal(
        (ref) => create(ref as CachedWidgetContextRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<WidgetContext> createElement() {
    return _CachedWidgetContextProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CachedWidgetContextProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CachedWidgetContextRef on AutoDisposeFutureProviderRef<WidgetContext> {
  /// The parameter `params` of this provider.
  ({String propertyId, String unitId}) get params;
}

class _CachedWidgetContextProviderElement
    extends AutoDisposeFutureProviderElement<WidgetContext>
    with CachedWidgetContextRef {
  _CachedWidgetContextProviderElement(super.provider);

  @override
  ({String propertyId, String unitId}) get params =>
      (origin as CachedWidgetContextProvider).params;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
