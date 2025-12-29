// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subdomain_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subdomainServiceHash() => r'7c934866d7e77a36b4726ef7cf779c441f0fe534';

/// Provider for SubdomainService instance.
///
/// Copied from [subdomainService].
@ProviderFor(subdomainService)
final subdomainServiceProvider = AutoDisposeProvider<SubdomainService>.internal(
  subdomainService,
  name: r'subdomainServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subdomainServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SubdomainServiceRef = AutoDisposeProviderRef<SubdomainService>;
String _$currentSubdomainHash() => r'fc6cca87e9f4944b611bc3e99783c8e54a07d920';

/// Provider that returns just the current subdomain string (if any).
///
/// This is a synchronous provider that doesn't require Firestore lookup.
/// Useful when you just need to check if a subdomain is present.
///
/// Copied from [currentSubdomain].
@ProviderFor(currentSubdomain)
final currentSubdomainProvider = AutoDisposeProvider<String?>.internal(
  currentSubdomain,
  name: r'currentSubdomainProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentSubdomainHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentSubdomainRef = AutoDisposeProviderRef<String?>;
String _$subdomainContextHash() => r'ac77c48bb4f1b0fc7f2f34336beee2d537974dbe';

/// OPTIMIZED: Cached provider that resolves the current subdomain context from the URL.
///
/// This provider is marked with `keepAlive: true` to cache the result for
/// the entire session, eliminating duplicate Firestore queries when:
/// - Navigating between widget screens
/// - Switching views (year/month calendar)
/// - Accessing subdomain context multiple times
///
/// ## Query Savings
/// BEFORE: 1 Firestore query per page load (no caching)
/// AFTER: 1 Firestore query per session (cached with keepAlive)
///
/// ## Usage
/// ```dart
/// final contextAsync = ref.watch(subdomainContextProvider);
/// contextAsync.when(
///   data: (context) {
///     if (context == null) {
///       // No subdomain in URL - show default widget
///     } else if (!context.found) {
///       // Subdomain not found - show error screen
///     } else {
///       // Use context.property and context.branding
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
///
/// Copied from [subdomainContext].
@ProviderFor(subdomainContext)
final subdomainContextProvider = FutureProvider<SubdomainContext?>.internal(
  subdomainContext,
  name: r'subdomainContextProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subdomainContextHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SubdomainContextRef = FutureProviderRef<SubdomainContext?>;
String _$fullSlugContextHash() => r'8df52a19b4b7d12a92efd21af71746c0ccf319ca';

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

/// OPTIMIZED: Cached provider that resolves full context from subdomain + slug URL.
///
/// URL format: `https://jasko-rab.bookbed.io/apartman-6`
/// 1. Reuses cached property from [subdomainContextProvider] (no query)
/// 2. Resolves unit by slug (1 query, cached by family param)
///
/// ## Query Savings
/// BEFORE: 2 Firestore queries per navigation (property + unit)
/// AFTER: 0-1 Firestore queries (property cached, unit cached by slug)
///
/// ## Usage
/// ```dart
/// final contextAsync = ref.watch(fullSlugContextProvider('apartman-6'));
/// contextAsync.when(
///   data: (context) {
///     if (context == null) {
///       // No subdomain in URL - fallback to query params
///     } else if (!context.propertyFound) {
///       // Property not found for subdomain
///     } else if (!context.unitFound) {
///       // Unit not found for slug
///     } else {
///       // Use context.propertyId and context.unitId
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
///
/// Copied from [fullSlugContext].
@ProviderFor(fullSlugContext)
const fullSlugContextProvider = FullSlugContextFamily();

/// OPTIMIZED: Cached provider that resolves full context from subdomain + slug URL.
///
/// URL format: `https://jasko-rab.bookbed.io/apartman-6`
/// 1. Reuses cached property from [subdomainContextProvider] (no query)
/// 2. Resolves unit by slug (1 query, cached by family param)
///
/// ## Query Savings
/// BEFORE: 2 Firestore queries per navigation (property + unit)
/// AFTER: 0-1 Firestore queries (property cached, unit cached by slug)
///
/// ## Usage
/// ```dart
/// final contextAsync = ref.watch(fullSlugContextProvider('apartman-6'));
/// contextAsync.when(
///   data: (context) {
///     if (context == null) {
///       // No subdomain in URL - fallback to query params
///     } else if (!context.propertyFound) {
///       // Property not found for subdomain
///     } else if (!context.unitFound) {
///       // Unit not found for slug
///     } else {
///       // Use context.propertyId and context.unitId
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
///
/// Copied from [fullSlugContext].
class FullSlugContextFamily extends Family<AsyncValue<FullSlugContext?>> {
  /// OPTIMIZED: Cached provider that resolves full context from subdomain + slug URL.
  ///
  /// URL format: `https://jasko-rab.bookbed.io/apartman-6`
  /// 1. Reuses cached property from [subdomainContextProvider] (no query)
  /// 2. Resolves unit by slug (1 query, cached by family param)
  ///
  /// ## Query Savings
  /// BEFORE: 2 Firestore queries per navigation (property + unit)
  /// AFTER: 0-1 Firestore queries (property cached, unit cached by slug)
  ///
  /// ## Usage
  /// ```dart
  /// final contextAsync = ref.watch(fullSlugContextProvider('apartman-6'));
  /// contextAsync.when(
  ///   data: (context) {
  ///     if (context == null) {
  ///       // No subdomain in URL - fallback to query params
  ///     } else if (!context.propertyFound) {
  ///       // Property not found for subdomain
  ///     } else if (!context.unitFound) {
  ///       // Unit not found for slug
  ///     } else {
  ///       // Use context.propertyId and context.unitId
  ///     }
  ///   },
  ///   loading: () => CircularProgressIndicator(),
  ///   error: (e, _) => Text('Error: $e'),
  /// );
  /// ```
  ///
  /// Copied from [fullSlugContext].
  const FullSlugContextFamily();

  /// OPTIMIZED: Cached provider that resolves full context from subdomain + slug URL.
  ///
  /// URL format: `https://jasko-rab.bookbed.io/apartman-6`
  /// 1. Reuses cached property from [subdomainContextProvider] (no query)
  /// 2. Resolves unit by slug (1 query, cached by family param)
  ///
  /// ## Query Savings
  /// BEFORE: 2 Firestore queries per navigation (property + unit)
  /// AFTER: 0-1 Firestore queries (property cached, unit cached by slug)
  ///
  /// ## Usage
  /// ```dart
  /// final contextAsync = ref.watch(fullSlugContextProvider('apartman-6'));
  /// contextAsync.when(
  ///   data: (context) {
  ///     if (context == null) {
  ///       // No subdomain in URL - fallback to query params
  ///     } else if (!context.propertyFound) {
  ///       // Property not found for subdomain
  ///     } else if (!context.unitFound) {
  ///       // Unit not found for slug
  ///     } else {
  ///       // Use context.propertyId and context.unitId
  ///     }
  ///   },
  ///   loading: () => CircularProgressIndicator(),
  ///   error: (e, _) => Text('Error: $e'),
  /// );
  /// ```
  ///
  /// Copied from [fullSlugContext].
  FullSlugContextProvider call(String? urlSlug) {
    return FullSlugContextProvider(urlSlug);
  }

  @override
  FullSlugContextProvider getProviderOverride(
    covariant FullSlugContextProvider provider,
  ) {
    return call(provider.urlSlug);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fullSlugContextProvider';
}

/// OPTIMIZED: Cached provider that resolves full context from subdomain + slug URL.
///
/// URL format: `https://jasko-rab.bookbed.io/apartman-6`
/// 1. Reuses cached property from [subdomainContextProvider] (no query)
/// 2. Resolves unit by slug (1 query, cached by family param)
///
/// ## Query Savings
/// BEFORE: 2 Firestore queries per navigation (property + unit)
/// AFTER: 0-1 Firestore queries (property cached, unit cached by slug)
///
/// ## Usage
/// ```dart
/// final contextAsync = ref.watch(fullSlugContextProvider('apartman-6'));
/// contextAsync.when(
///   data: (context) {
///     if (context == null) {
///       // No subdomain in URL - fallback to query params
///     } else if (!context.propertyFound) {
///       // Property not found for subdomain
///     } else if (!context.unitFound) {
///       // Unit not found for slug
///     } else {
///       // Use context.propertyId and context.unitId
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
///
/// Copied from [fullSlugContext].
class FullSlugContextProvider extends FutureProvider<FullSlugContext?> {
  /// OPTIMIZED: Cached provider that resolves full context from subdomain + slug URL.
  ///
  /// URL format: `https://jasko-rab.bookbed.io/apartman-6`
  /// 1. Reuses cached property from [subdomainContextProvider] (no query)
  /// 2. Resolves unit by slug (1 query, cached by family param)
  ///
  /// ## Query Savings
  /// BEFORE: 2 Firestore queries per navigation (property + unit)
  /// AFTER: 0-1 Firestore queries (property cached, unit cached by slug)
  ///
  /// ## Usage
  /// ```dart
  /// final contextAsync = ref.watch(fullSlugContextProvider('apartman-6'));
  /// contextAsync.when(
  ///   data: (context) {
  ///     if (context == null) {
  ///       // No subdomain in URL - fallback to query params
  ///     } else if (!context.propertyFound) {
  ///       // Property not found for subdomain
  ///     } else if (!context.unitFound) {
  ///       // Unit not found for slug
  ///     } else {
  ///       // Use context.propertyId and context.unitId
  ///     }
  ///   },
  ///   loading: () => CircularProgressIndicator(),
  ///   error: (e, _) => Text('Error: $e'),
  /// );
  /// ```
  ///
  /// Copied from [fullSlugContext].
  FullSlugContextProvider(String? urlSlug)
    : this._internal(
        (ref) => fullSlugContext(ref as FullSlugContextRef, urlSlug),
        from: fullSlugContextProvider,
        name: r'fullSlugContextProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$fullSlugContextHash,
        dependencies: FullSlugContextFamily._dependencies,
        allTransitiveDependencies:
            FullSlugContextFamily._allTransitiveDependencies,
        urlSlug: urlSlug,
      );

  FullSlugContextProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.urlSlug,
  }) : super.internal();

  final String? urlSlug;

  @override
  Override overrideWith(
    FutureOr<FullSlugContext?> Function(FullSlugContextRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FullSlugContextProvider._internal(
        (ref) => create(ref as FullSlugContextRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        urlSlug: urlSlug,
      ),
    );
  }

  @override
  FutureProviderElement<FullSlugContext?> createElement() {
    return _FullSlugContextProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FullSlugContextProvider && other.urlSlug == urlSlug;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, urlSlug.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FullSlugContextRef on FutureProviderRef<FullSlugContext?> {
  /// The parameter `urlSlug` of this provider.
  String? get urlSlug;
}

class _FullSlugContextProviderElement
    extends FutureProviderElement<FullSlugContext?>
    with FullSlugContextRef {
  _FullSlugContextProviderElement(super.provider);

  @override
  String? get urlSlug => (origin as FullSlugContextProvider).urlSlug;
}

String _$optimizedSlugWidgetContextHash() =>
    r'2730b3467e1641190c2e4e271d2c6a9c16c76705';

/// PERFORMANCE OPTIMIZED: Complete widget context from slug URL in PARALLEL.
///
/// This provider eliminates duplicate Firestore queries by fetching ALL data
/// needed for the widget in a single parallel batch:
/// 1. Property (by subdomain) - 1 query
/// 2. Unit (by slug within property) - 1 query
/// 3. Settings - 1 query
///
/// BEFORE (sequential + duplicate):
/// - fullSlugContextProvider: property query → unit query (sequential)
/// - widgetContextProvider: property query + unit query + settings query (parallel but DUPLICATE)
/// Total: 5 queries, ~4-6 seconds
///
/// AFTER (parallel, no duplicates):
/// - This provider: property + unit + settings in parallel
/// Total: 3 queries, ~1-2 seconds
///
/// ## Usage
/// ```dart
/// final contextAsync = ref.watch(optimizedSlugWidgetContextProvider('apartman-6'));
/// contextAsync.when(
///   data: (result) {
///     if (result == null) // No subdomain - use query params
///     else if (result.error != null) // Show error
///     else // Use result.context!
///   },
///   loading: () => LoadingIndicator(),
///   error: (e, _) => ErrorWidget(e),
/// );
/// ```
///
/// Copied from [optimizedSlugWidgetContext].
@ProviderFor(optimizedSlugWidgetContext)
const optimizedSlugWidgetContextProvider = OptimizedSlugWidgetContextFamily();

/// PERFORMANCE OPTIMIZED: Complete widget context from slug URL in PARALLEL.
///
/// This provider eliminates duplicate Firestore queries by fetching ALL data
/// needed for the widget in a single parallel batch:
/// 1. Property (by subdomain) - 1 query
/// 2. Unit (by slug within property) - 1 query
/// 3. Settings - 1 query
///
/// BEFORE (sequential + duplicate):
/// - fullSlugContextProvider: property query → unit query (sequential)
/// - widgetContextProvider: property query + unit query + settings query (parallel but DUPLICATE)
/// Total: 5 queries, ~4-6 seconds
///
/// AFTER (parallel, no duplicates):
/// - This provider: property + unit + settings in parallel
/// Total: 3 queries, ~1-2 seconds
///
/// ## Usage
/// ```dart
/// final contextAsync = ref.watch(optimizedSlugWidgetContextProvider('apartman-6'));
/// contextAsync.when(
///   data: (result) {
///     if (result == null) // No subdomain - use query params
///     else if (result.error != null) // Show error
///     else // Use result.context!
///   },
///   loading: () => LoadingIndicator(),
///   error: (e, _) => ErrorWidget(e),
/// );
/// ```
///
/// Copied from [optimizedSlugWidgetContext].
class OptimizedSlugWidgetContextFamily
    extends Family<AsyncValue<OptimizedSlugResult?>> {
  /// PERFORMANCE OPTIMIZED: Complete widget context from slug URL in PARALLEL.
  ///
  /// This provider eliminates duplicate Firestore queries by fetching ALL data
  /// needed for the widget in a single parallel batch:
  /// 1. Property (by subdomain) - 1 query
  /// 2. Unit (by slug within property) - 1 query
  /// 3. Settings - 1 query
  ///
  /// BEFORE (sequential + duplicate):
  /// - fullSlugContextProvider: property query → unit query (sequential)
  /// - widgetContextProvider: property query + unit query + settings query (parallel but DUPLICATE)
  /// Total: 5 queries, ~4-6 seconds
  ///
  /// AFTER (parallel, no duplicates):
  /// - This provider: property + unit + settings in parallel
  /// Total: 3 queries, ~1-2 seconds
  ///
  /// ## Usage
  /// ```dart
  /// final contextAsync = ref.watch(optimizedSlugWidgetContextProvider('apartman-6'));
  /// contextAsync.when(
  ///   data: (result) {
  ///     if (result == null) // No subdomain - use query params
  ///     else if (result.error != null) // Show error
  ///     else // Use result.context!
  ///   },
  ///   loading: () => LoadingIndicator(),
  ///   error: (e, _) => ErrorWidget(e),
  /// );
  /// ```
  ///
  /// Copied from [optimizedSlugWidgetContext].
  const OptimizedSlugWidgetContextFamily();

  /// PERFORMANCE OPTIMIZED: Complete widget context from slug URL in PARALLEL.
  ///
  /// This provider eliminates duplicate Firestore queries by fetching ALL data
  /// needed for the widget in a single parallel batch:
  /// 1. Property (by subdomain) - 1 query
  /// 2. Unit (by slug within property) - 1 query
  /// 3. Settings - 1 query
  ///
  /// BEFORE (sequential + duplicate):
  /// - fullSlugContextProvider: property query → unit query (sequential)
  /// - widgetContextProvider: property query + unit query + settings query (parallel but DUPLICATE)
  /// Total: 5 queries, ~4-6 seconds
  ///
  /// AFTER (parallel, no duplicates):
  /// - This provider: property + unit + settings in parallel
  /// Total: 3 queries, ~1-2 seconds
  ///
  /// ## Usage
  /// ```dart
  /// final contextAsync = ref.watch(optimizedSlugWidgetContextProvider('apartman-6'));
  /// contextAsync.when(
  ///   data: (result) {
  ///     if (result == null) // No subdomain - use query params
  ///     else if (result.error != null) // Show error
  ///     else // Use result.context!
  ///   },
  ///   loading: () => LoadingIndicator(),
  ///   error: (e, _) => ErrorWidget(e),
  /// );
  /// ```
  ///
  /// Copied from [optimizedSlugWidgetContext].
  OptimizedSlugWidgetContextProvider call(String? urlSlug) {
    return OptimizedSlugWidgetContextProvider(urlSlug);
  }

  @override
  OptimizedSlugWidgetContextProvider getProviderOverride(
    covariant OptimizedSlugWidgetContextProvider provider,
  ) {
    return call(provider.urlSlug);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'optimizedSlugWidgetContextProvider';
}

/// PERFORMANCE OPTIMIZED: Complete widget context from slug URL in PARALLEL.
///
/// This provider eliminates duplicate Firestore queries by fetching ALL data
/// needed for the widget in a single parallel batch:
/// 1. Property (by subdomain) - 1 query
/// 2. Unit (by slug within property) - 1 query
/// 3. Settings - 1 query
///
/// BEFORE (sequential + duplicate):
/// - fullSlugContextProvider: property query → unit query (sequential)
/// - widgetContextProvider: property query + unit query + settings query (parallel but DUPLICATE)
/// Total: 5 queries, ~4-6 seconds
///
/// AFTER (parallel, no duplicates):
/// - This provider: property + unit + settings in parallel
/// Total: 3 queries, ~1-2 seconds
///
/// ## Usage
/// ```dart
/// final contextAsync = ref.watch(optimizedSlugWidgetContextProvider('apartman-6'));
/// contextAsync.when(
///   data: (result) {
///     if (result == null) // No subdomain - use query params
///     else if (result.error != null) // Show error
///     else // Use result.context!
///   },
///   loading: () => LoadingIndicator(),
///   error: (e, _) => ErrorWidget(e),
/// );
/// ```
///
/// Copied from [optimizedSlugWidgetContext].
class OptimizedSlugWidgetContextProvider
    extends FutureProvider<OptimizedSlugResult?> {
  /// PERFORMANCE OPTIMIZED: Complete widget context from slug URL in PARALLEL.
  ///
  /// This provider eliminates duplicate Firestore queries by fetching ALL data
  /// needed for the widget in a single parallel batch:
  /// 1. Property (by subdomain) - 1 query
  /// 2. Unit (by slug within property) - 1 query
  /// 3. Settings - 1 query
  ///
  /// BEFORE (sequential + duplicate):
  /// - fullSlugContextProvider: property query → unit query (sequential)
  /// - widgetContextProvider: property query + unit query + settings query (parallel but DUPLICATE)
  /// Total: 5 queries, ~4-6 seconds
  ///
  /// AFTER (parallel, no duplicates):
  /// - This provider: property + unit + settings in parallel
  /// Total: 3 queries, ~1-2 seconds
  ///
  /// ## Usage
  /// ```dart
  /// final contextAsync = ref.watch(optimizedSlugWidgetContextProvider('apartman-6'));
  /// contextAsync.when(
  ///   data: (result) {
  ///     if (result == null) // No subdomain - use query params
  ///     else if (result.error != null) // Show error
  ///     else // Use result.context!
  ///   },
  ///   loading: () => LoadingIndicator(),
  ///   error: (e, _) => ErrorWidget(e),
  /// );
  /// ```
  ///
  /// Copied from [optimizedSlugWidgetContext].
  OptimizedSlugWidgetContextProvider(String? urlSlug)
    : this._internal(
        (ref) => optimizedSlugWidgetContext(
          ref as OptimizedSlugWidgetContextRef,
          urlSlug,
        ),
        from: optimizedSlugWidgetContextProvider,
        name: r'optimizedSlugWidgetContextProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$optimizedSlugWidgetContextHash,
        dependencies: OptimizedSlugWidgetContextFamily._dependencies,
        allTransitiveDependencies:
            OptimizedSlugWidgetContextFamily._allTransitiveDependencies,
        urlSlug: urlSlug,
      );

  OptimizedSlugWidgetContextProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.urlSlug,
  }) : super.internal();

  final String? urlSlug;

  @override
  Override overrideWith(
    FutureOr<OptimizedSlugResult?> Function(
      OptimizedSlugWidgetContextRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: OptimizedSlugWidgetContextProvider._internal(
        (ref) => create(ref as OptimizedSlugWidgetContextRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        urlSlug: urlSlug,
      ),
    );
  }

  @override
  FutureProviderElement<OptimizedSlugResult?> createElement() {
    return _OptimizedSlugWidgetContextProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OptimizedSlugWidgetContextProvider &&
        other.urlSlug == urlSlug;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, urlSlug.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin OptimizedSlugWidgetContextRef on FutureProviderRef<OptimizedSlugResult?> {
  /// The parameter `urlSlug` of this provider.
  String? get urlSlug;
}

class _OptimizedSlugWidgetContextProviderElement
    extends FutureProviderElement<OptimizedSlugResult?>
    with OptimizedSlugWidgetContextRef {
  _OptimizedSlugWidgetContextProviderElement(super.provider);

  @override
  String? get urlSlug => (origin as OptimizedSlugWidgetContextProvider).urlSlug;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
