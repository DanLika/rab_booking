// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realtime_booking_calendar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bookingCalendarRepositoryHash() =>
    r'cb685581c181824fc3a0fc772451b8180965a53e';

/// Repository provider (V2 with price support)
/// Returns interface type for better testability and flexibility
///
/// Copied from [bookingCalendarRepository].
@ProviderFor(bookingCalendarRepository)
final bookingCalendarRepositoryProvider =
    AutoDisposeProvider<IBookingCalendarRepository>.internal(
      bookingCalendarRepository,
      name: r'bookingCalendarRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$bookingCalendarRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BookingCalendarRepositoryRef =
    AutoDisposeProviderRef<IBookingCalendarRepository>;
String _$realtimeYearCalendarHash() =>
    r'59420e4357dbfc0cedeabe615f12286acc77438a';

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

/// Realtime calendar data provider for year view.
/// Returns Map with String keys (yyyy-MM-dd format) to CalendarDateInfo.
///
/// OPTIMIZED:
/// - Uses debounce to reduce rapid UI updates when multiple
///   booking changes occur in quick succession.
/// - keepAlive: true prevents re-subscription when switching between
///   Year and Month views (stream persists during session).
/// - Accepts minNights parameter to eliminate redundant widgetSettings fetch.
///
/// Query savings: ~60% reduction when switching views frequently.
/// Stream reduction: 4 → 3 streams (25% reduction per provider).
///
/// Copied from [realtimeYearCalendar].
@ProviderFor(realtimeYearCalendar)
const realtimeYearCalendarProvider = RealtimeYearCalendarFamily();

/// Realtime calendar data provider for year view.
/// Returns Map with String keys (yyyy-MM-dd format) to CalendarDateInfo.
///
/// OPTIMIZED:
/// - Uses debounce to reduce rapid UI updates when multiple
///   booking changes occur in quick succession.
/// - keepAlive: true prevents re-subscription when switching between
///   Year and Month views (stream persists during session).
/// - Accepts minNights parameter to eliminate redundant widgetSettings fetch.
///
/// Query savings: ~60% reduction when switching views frequently.
/// Stream reduction: 4 → 3 streams (25% reduction per provider).
///
/// Copied from [realtimeYearCalendar].
class RealtimeYearCalendarFamily
    extends Family<AsyncValue<Map<String, CalendarDateInfo>>> {
  /// Realtime calendar data provider for year view.
  /// Returns Map with String keys (yyyy-MM-dd format) to CalendarDateInfo.
  ///
  /// OPTIMIZED:
  /// - Uses debounce to reduce rapid UI updates when multiple
  ///   booking changes occur in quick succession.
  /// - keepAlive: true prevents re-subscription when switching between
  ///   Year and Month views (stream persists during session).
  /// - Accepts minNights parameter to eliminate redundant widgetSettings fetch.
  ///
  /// Query savings: ~60% reduction when switching views frequently.
  /// Stream reduction: 4 → 3 streams (25% reduction per provider).
  ///
  /// Copied from [realtimeYearCalendar].
  const RealtimeYearCalendarFamily();

  /// Realtime calendar data provider for year view.
  /// Returns Map with String keys (yyyy-MM-dd format) to CalendarDateInfo.
  ///
  /// OPTIMIZED:
  /// - Uses debounce to reduce rapid UI updates when multiple
  ///   booking changes occur in quick succession.
  /// - keepAlive: true prevents re-subscription when switching between
  ///   Year and Month views (stream persists during session).
  /// - Accepts minNights parameter to eliminate redundant widgetSettings fetch.
  ///
  /// Query savings: ~60% reduction when switching views frequently.
  /// Stream reduction: 4 → 3 streams (25% reduction per provider).
  ///
  /// Copied from [realtimeYearCalendar].
  RealtimeYearCalendarProvider call(
    String propertyId,
    String unitId,
    int year,
    int minNights,
  ) {
    return RealtimeYearCalendarProvider(propertyId, unitId, year, minNights);
  }

  @override
  RealtimeYearCalendarProvider getProviderOverride(
    covariant RealtimeYearCalendarProvider provider,
  ) {
    return call(
      provider.propertyId,
      provider.unitId,
      provider.year,
      provider.minNights,
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
  String? get name => r'realtimeYearCalendarProvider';
}

/// Realtime calendar data provider for year view.
/// Returns Map with String keys (yyyy-MM-dd format) to CalendarDateInfo.
///
/// OPTIMIZED:
/// - Uses debounce to reduce rapid UI updates when multiple
///   booking changes occur in quick succession.
/// - keepAlive: true prevents re-subscription when switching between
///   Year and Month views (stream persists during session).
/// - Accepts minNights parameter to eliminate redundant widgetSettings fetch.
///
/// Query savings: ~60% reduction when switching views frequently.
/// Stream reduction: 4 → 3 streams (25% reduction per provider).
///
/// Copied from [realtimeYearCalendar].
class RealtimeYearCalendarProvider
    extends StreamProvider<Map<String, CalendarDateInfo>> {
  /// Realtime calendar data provider for year view.
  /// Returns Map with String keys (yyyy-MM-dd format) to CalendarDateInfo.
  ///
  /// OPTIMIZED:
  /// - Uses debounce to reduce rapid UI updates when multiple
  ///   booking changes occur in quick succession.
  /// - keepAlive: true prevents re-subscription when switching between
  ///   Year and Month views (stream persists during session).
  /// - Accepts minNights parameter to eliminate redundant widgetSettings fetch.
  ///
  /// Query savings: ~60% reduction when switching views frequently.
  /// Stream reduction: 4 → 3 streams (25% reduction per provider).
  ///
  /// Copied from [realtimeYearCalendar].
  RealtimeYearCalendarProvider(
    String propertyId,
    String unitId,
    int year,
    int minNights,
  ) : this._internal(
        (ref) => realtimeYearCalendar(
          ref as RealtimeYearCalendarRef,
          propertyId,
          unitId,
          year,
          minNights,
        ),
        from: realtimeYearCalendarProvider,
        name: r'realtimeYearCalendarProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$realtimeYearCalendarHash,
        dependencies: RealtimeYearCalendarFamily._dependencies,
        allTransitiveDependencies:
            RealtimeYearCalendarFamily._allTransitiveDependencies,
        propertyId: propertyId,
        unitId: unitId,
        year: year,
        minNights: minNights,
      );

  RealtimeYearCalendarProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.propertyId,
    required this.unitId,
    required this.year,
    required this.minNights,
  }) : super.internal();

  final String propertyId;
  final String unitId;
  final int year;
  final int minNights;

  @override
  Override overrideWith(
    Stream<Map<String, CalendarDateInfo>> Function(
      RealtimeYearCalendarRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RealtimeYearCalendarProvider._internal(
        (ref) => create(ref as RealtimeYearCalendarRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        propertyId: propertyId,
        unitId: unitId,
        year: year,
        minNights: minNights,
      ),
    );
  }

  @override
  StreamProviderElement<Map<String, CalendarDateInfo>> createElement() {
    return _RealtimeYearCalendarProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RealtimeYearCalendarProvider &&
        other.propertyId == propertyId &&
        other.unitId == unitId &&
        other.year == year &&
        other.minNights == minNights;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, propertyId.hashCode);
    hash = _SystemHash.combine(hash, unitId.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);
    hash = _SystemHash.combine(hash, minNights.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RealtimeYearCalendarRef
    on StreamProviderRef<Map<String, CalendarDateInfo>> {
  /// The parameter `propertyId` of this provider.
  String get propertyId;

  /// The parameter `unitId` of this provider.
  String get unitId;

  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `minNights` of this provider.
  int get minNights;
}

class _RealtimeYearCalendarProviderElement
    extends StreamProviderElement<Map<String, CalendarDateInfo>>
    with RealtimeYearCalendarRef {
  _RealtimeYearCalendarProviderElement(super.provider);

  @override
  String get propertyId => (origin as RealtimeYearCalendarProvider).propertyId;
  @override
  String get unitId => (origin as RealtimeYearCalendarProvider).unitId;
  @override
  int get year => (origin as RealtimeYearCalendarProvider).year;
  @override
  int get minNights => (origin as RealtimeYearCalendarProvider).minNights;
}

String _$realtimeMonthCalendarHash() =>
    r'25809a7e4df1c5972d6fdc5c3c56e1eee1deea20';

/// Realtime calendar data provider for month view.
/// Returns Map with String keys (yyyy-MM-dd format) to CalendarDateInfo.
///
/// OPTIMIZED:
/// - Uses debounce to reduce rapid UI updates when multiple
///   booking changes occur in quick succession.
/// - keepAlive: true prevents re-subscription when switching between
///   Year and Month views (stream persists during session).
/// - Accepts minNights parameter to eliminate redundant widgetSettings fetch.
///
/// Query savings: ~60% reduction when switching views frequently.
/// Stream reduction: 4 → 3 streams (25% reduction per provider).
///
/// Copied from [realtimeMonthCalendar].
@ProviderFor(realtimeMonthCalendar)
const realtimeMonthCalendarProvider = RealtimeMonthCalendarFamily();

/// Realtime calendar data provider for month view.
/// Returns Map with String keys (yyyy-MM-dd format) to CalendarDateInfo.
///
/// OPTIMIZED:
/// - Uses debounce to reduce rapid UI updates when multiple
///   booking changes occur in quick succession.
/// - keepAlive: true prevents re-subscription when switching between
///   Year and Month views (stream persists during session).
/// - Accepts minNights parameter to eliminate redundant widgetSettings fetch.
///
/// Query savings: ~60% reduction when switching views frequently.
/// Stream reduction: 4 → 3 streams (25% reduction per provider).
///
/// Copied from [realtimeMonthCalendar].
class RealtimeMonthCalendarFamily
    extends Family<AsyncValue<Map<String, CalendarDateInfo>>> {
  /// Realtime calendar data provider for month view.
  /// Returns Map with String keys (yyyy-MM-dd format) to CalendarDateInfo.
  ///
  /// OPTIMIZED:
  /// - Uses debounce to reduce rapid UI updates when multiple
  ///   booking changes occur in quick succession.
  /// - keepAlive: true prevents re-subscription when switching between
  ///   Year and Month views (stream persists during session).
  /// - Accepts minNights parameter to eliminate redundant widgetSettings fetch.
  ///
  /// Query savings: ~60% reduction when switching views frequently.
  /// Stream reduction: 4 → 3 streams (25% reduction per provider).
  ///
  /// Copied from [realtimeMonthCalendar].
  const RealtimeMonthCalendarFamily();

  /// Realtime calendar data provider for month view.
  /// Returns Map with String keys (yyyy-MM-dd format) to CalendarDateInfo.
  ///
  /// OPTIMIZED:
  /// - Uses debounce to reduce rapid UI updates when multiple
  ///   booking changes occur in quick succession.
  /// - keepAlive: true prevents re-subscription when switching between
  ///   Year and Month views (stream persists during session).
  /// - Accepts minNights parameter to eliminate redundant widgetSettings fetch.
  ///
  /// Query savings: ~60% reduction when switching views frequently.
  /// Stream reduction: 4 → 3 streams (25% reduction per provider).
  ///
  /// Copied from [realtimeMonthCalendar].
  RealtimeMonthCalendarProvider call(
    String propertyId,
    String unitId,
    int year,
    int month,
    int minNights,
  ) {
    return RealtimeMonthCalendarProvider(
      propertyId,
      unitId,
      year,
      month,
      minNights,
    );
  }

  @override
  RealtimeMonthCalendarProvider getProviderOverride(
    covariant RealtimeMonthCalendarProvider provider,
  ) {
    return call(
      provider.propertyId,
      provider.unitId,
      provider.year,
      provider.month,
      provider.minNights,
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
  String? get name => r'realtimeMonthCalendarProvider';
}

/// Realtime calendar data provider for month view.
/// Returns Map with String keys (yyyy-MM-dd format) to CalendarDateInfo.
///
/// OPTIMIZED:
/// - Uses debounce to reduce rapid UI updates when multiple
///   booking changes occur in quick succession.
/// - keepAlive: true prevents re-subscription when switching between
///   Year and Month views (stream persists during session).
/// - Accepts minNights parameter to eliminate redundant widgetSettings fetch.
///
/// Query savings: ~60% reduction when switching views frequently.
/// Stream reduction: 4 → 3 streams (25% reduction per provider).
///
/// Copied from [realtimeMonthCalendar].
class RealtimeMonthCalendarProvider
    extends StreamProvider<Map<String, CalendarDateInfo>> {
  /// Realtime calendar data provider for month view.
  /// Returns Map with String keys (yyyy-MM-dd format) to CalendarDateInfo.
  ///
  /// OPTIMIZED:
  /// - Uses debounce to reduce rapid UI updates when multiple
  ///   booking changes occur in quick succession.
  /// - keepAlive: true prevents re-subscription when switching between
  ///   Year and Month views (stream persists during session).
  /// - Accepts minNights parameter to eliminate redundant widgetSettings fetch.
  ///
  /// Query savings: ~60% reduction when switching views frequently.
  /// Stream reduction: 4 → 3 streams (25% reduction per provider).
  ///
  /// Copied from [realtimeMonthCalendar].
  RealtimeMonthCalendarProvider(
    String propertyId,
    String unitId,
    int year,
    int month,
    int minNights,
  ) : this._internal(
        (ref) => realtimeMonthCalendar(
          ref as RealtimeMonthCalendarRef,
          propertyId,
          unitId,
          year,
          month,
          minNights,
        ),
        from: realtimeMonthCalendarProvider,
        name: r'realtimeMonthCalendarProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$realtimeMonthCalendarHash,
        dependencies: RealtimeMonthCalendarFamily._dependencies,
        allTransitiveDependencies:
            RealtimeMonthCalendarFamily._allTransitiveDependencies,
        propertyId: propertyId,
        unitId: unitId,
        year: year,
        month: month,
        minNights: minNights,
      );

  RealtimeMonthCalendarProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.propertyId,
    required this.unitId,
    required this.year,
    required this.month,
    required this.minNights,
  }) : super.internal();

  final String propertyId;
  final String unitId;
  final int year;
  final int month;
  final int minNights;

  @override
  Override overrideWith(
    Stream<Map<String, CalendarDateInfo>> Function(
      RealtimeMonthCalendarRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RealtimeMonthCalendarProvider._internal(
        (ref) => create(ref as RealtimeMonthCalendarRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        propertyId: propertyId,
        unitId: unitId,
        year: year,
        month: month,
        minNights: minNights,
      ),
    );
  }

  @override
  StreamProviderElement<Map<String, CalendarDateInfo>> createElement() {
    return _RealtimeMonthCalendarProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RealtimeMonthCalendarProvider &&
        other.propertyId == propertyId &&
        other.unitId == unitId &&
        other.year == year &&
        other.month == month &&
        other.minNights == minNights;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, propertyId.hashCode);
    hash = _SystemHash.combine(hash, unitId.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);
    hash = _SystemHash.combine(hash, minNights.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RealtimeMonthCalendarRef
    on StreamProviderRef<Map<String, CalendarDateInfo>> {
  /// The parameter `propertyId` of this provider.
  String get propertyId;

  /// The parameter `unitId` of this provider.
  String get unitId;

  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `month` of this provider.
  int get month;

  /// The parameter `minNights` of this provider.
  int get minNights;
}

class _RealtimeMonthCalendarProviderElement
    extends StreamProviderElement<Map<String, CalendarDateInfo>>
    with RealtimeMonthCalendarRef {
  _RealtimeMonthCalendarProviderElement(super.provider);

  @override
  String get propertyId => (origin as RealtimeMonthCalendarProvider).propertyId;
  @override
  String get unitId => (origin as RealtimeMonthCalendarProvider).unitId;
  @override
  int get year => (origin as RealtimeMonthCalendarProvider).year;
  @override
  int get month => (origin as RealtimeMonthCalendarProvider).month;
  @override
  int get minNights => (origin as RealtimeMonthCalendarProvider).minNights;
}

String _$checkDateAvailabilityHash() =>
    r'a73670ef1c130baf0066b2baf71324ebb0dca2ea';

/// Check date availability
///
/// Copied from [checkDateAvailability].
@ProviderFor(checkDateAvailability)
const checkDateAvailabilityProvider = CheckDateAvailabilityFamily();

/// Check date availability
///
/// Copied from [checkDateAvailability].
class CheckDateAvailabilityFamily extends Family<AsyncValue<bool>> {
  /// Check date availability
  ///
  /// Copied from [checkDateAvailability].
  const CheckDateAvailabilityFamily();

  /// Check date availability
  ///
  /// Copied from [checkDateAvailability].
  CheckDateAvailabilityProvider call({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    return CheckDateAvailabilityProvider(
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
    );
  }

  @override
  CheckDateAvailabilityProvider getProviderOverride(
    covariant CheckDateAvailabilityProvider provider,
  ) {
    return call(
      unitId: provider.unitId,
      checkIn: provider.checkIn,
      checkOut: provider.checkOut,
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
  String? get name => r'checkDateAvailabilityProvider';
}

/// Check date availability
///
/// Copied from [checkDateAvailability].
class CheckDateAvailabilityProvider extends AutoDisposeFutureProvider<bool> {
  /// Check date availability
  ///
  /// Copied from [checkDateAvailability].
  CheckDateAvailabilityProvider({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) : this._internal(
         (ref) => checkDateAvailability(
           ref as CheckDateAvailabilityRef,
           unitId: unitId,
           checkIn: checkIn,
           checkOut: checkOut,
         ),
         from: checkDateAvailabilityProvider,
         name: r'checkDateAvailabilityProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$checkDateAvailabilityHash,
         dependencies: CheckDateAvailabilityFamily._dependencies,
         allTransitiveDependencies:
             CheckDateAvailabilityFamily._allTransitiveDependencies,
         unitId: unitId,
         checkIn: checkIn,
         checkOut: checkOut,
       );

  CheckDateAvailabilityProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.unitId,
    required this.checkIn,
    required this.checkOut,
  }) : super.internal();

  final String unitId;
  final DateTime checkIn;
  final DateTime checkOut;

  @override
  Override overrideWith(
    FutureOr<bool> Function(CheckDateAvailabilityRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CheckDateAvailabilityProvider._internal(
        (ref) => create(ref as CheckDateAvailabilityRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        unitId: unitId,
        checkIn: checkIn,
        checkOut: checkOut,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _CheckDateAvailabilityProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CheckDateAvailabilityProvider &&
        other.unitId == unitId &&
        other.checkIn == checkIn &&
        other.checkOut == checkOut;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, unitId.hashCode);
    hash = _SystemHash.combine(hash, checkIn.hashCode);
    hash = _SystemHash.combine(hash, checkOut.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CheckDateAvailabilityRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `unitId` of this provider.
  String get unitId;

  /// The parameter `checkIn` of this provider.
  DateTime get checkIn;

  /// The parameter `checkOut` of this provider.
  DateTime get checkOut;
}

class _CheckDateAvailabilityProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with CheckDateAvailabilityRef {
  _CheckDateAvailabilityProviderElement(super.provider);

  @override
  String get unitId => (origin as CheckDateAvailabilityProvider).unitId;
  @override
  DateTime get checkIn => (origin as CheckDateAvailabilityProvider).checkIn;
  @override
  DateTime get checkOut => (origin as CheckDateAvailabilityProvider).checkOut;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
