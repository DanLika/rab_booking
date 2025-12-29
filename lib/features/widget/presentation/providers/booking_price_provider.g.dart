// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_price_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bookingPriceHash() => r'c663a165d07c139646091b48da4f0696b7efcd85';

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

/// Provider for calculating booking price
///
/// OPTIMIZED: Now accepts optional [propertyId] to reuse cached unit data
/// from [widgetContextProvider], eliminating duplicate Firestore queries.
///
/// Copied from [bookingPrice].
@ProviderFor(bookingPrice)
const bookingPriceProvider = BookingPriceFamily();

/// Provider for calculating booking price
///
/// OPTIMIZED: Now accepts optional [propertyId] to reuse cached unit data
/// from [widgetContextProvider], eliminating duplicate Firestore queries.
///
/// Copied from [bookingPrice].
class BookingPriceFamily extends Family<AsyncValue<BookingPriceCalculation?>> {
  /// Provider for calculating booking price
  ///
  /// OPTIMIZED: Now accepts optional [propertyId] to reuse cached unit data
  /// from [widgetContextProvider], eliminating duplicate Firestore queries.
  ///
  /// Copied from [bookingPrice].
  const BookingPriceFamily();

  /// Provider for calculating booking price
  ///
  /// OPTIMIZED: Now accepts optional [propertyId] to reuse cached unit data
  /// from [widgetContextProvider], eliminating duplicate Firestore queries.
  ///
  /// Copied from [bookingPrice].
  BookingPriceProvider call({
    required String unitId,
    required DateTime? checkIn,
    required DateTime? checkOut,
    String? propertyId,
    int depositPercentage = 20,
  }) {
    return BookingPriceProvider(
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
      propertyId: propertyId,
      depositPercentage: depositPercentage,
    );
  }

  @override
  BookingPriceProvider getProviderOverride(
    covariant BookingPriceProvider provider,
  ) {
    return call(
      unitId: provider.unitId,
      checkIn: provider.checkIn,
      checkOut: provider.checkOut,
      propertyId: provider.propertyId,
      depositPercentage: provider.depositPercentage,
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
  String? get name => r'bookingPriceProvider';
}

/// Provider for calculating booking price
///
/// OPTIMIZED: Now accepts optional [propertyId] to reuse cached unit data
/// from [widgetContextProvider], eliminating duplicate Firestore queries.
///
/// Copied from [bookingPrice].
class BookingPriceProvider
    extends AutoDisposeFutureProvider<BookingPriceCalculation?> {
  /// Provider for calculating booking price
  ///
  /// OPTIMIZED: Now accepts optional [propertyId] to reuse cached unit data
  /// from [widgetContextProvider], eliminating duplicate Firestore queries.
  ///
  /// Copied from [bookingPrice].
  BookingPriceProvider({
    required String unitId,
    required DateTime? checkIn,
    required DateTime? checkOut,
    String? propertyId,
    int depositPercentage = 20,
  }) : this._internal(
         (ref) => bookingPrice(
           ref as BookingPriceRef,
           unitId: unitId,
           checkIn: checkIn,
           checkOut: checkOut,
           propertyId: propertyId,
           depositPercentage: depositPercentage,
         ),
         from: bookingPriceProvider,
         name: r'bookingPriceProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$bookingPriceHash,
         dependencies: BookingPriceFamily._dependencies,
         allTransitiveDependencies:
             BookingPriceFamily._allTransitiveDependencies,
         unitId: unitId,
         checkIn: checkIn,
         checkOut: checkOut,
         propertyId: propertyId,
         depositPercentage: depositPercentage,
       );

  BookingPriceProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.unitId,
    required this.checkIn,
    required this.checkOut,
    required this.propertyId,
    required this.depositPercentage,
  }) : super.internal();

  final String unitId;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? propertyId;
  final int depositPercentage;

  @override
  Override overrideWith(
    FutureOr<BookingPriceCalculation?> Function(BookingPriceRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookingPriceProvider._internal(
        (ref) => create(ref as BookingPriceRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        unitId: unitId,
        checkIn: checkIn,
        checkOut: checkOut,
        propertyId: propertyId,
        depositPercentage: depositPercentage,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<BookingPriceCalculation?> createElement() {
    return _BookingPriceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingPriceProvider &&
        other.unitId == unitId &&
        other.checkIn == checkIn &&
        other.checkOut == checkOut &&
        other.propertyId == propertyId &&
        other.depositPercentage == depositPercentage;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, unitId.hashCode);
    hash = _SystemHash.combine(hash, checkIn.hashCode);
    hash = _SystemHash.combine(hash, checkOut.hashCode);
    hash = _SystemHash.combine(hash, propertyId.hashCode);
    hash = _SystemHash.combine(hash, depositPercentage.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BookingPriceRef
    on AutoDisposeFutureProviderRef<BookingPriceCalculation?> {
  /// The parameter `unitId` of this provider.
  String get unitId;

  /// The parameter `checkIn` of this provider.
  DateTime? get checkIn;

  /// The parameter `checkOut` of this provider.
  DateTime? get checkOut;

  /// The parameter `propertyId` of this provider.
  String? get propertyId;

  /// The parameter `depositPercentage` of this provider.
  int get depositPercentage;
}

class _BookingPriceProviderElement
    extends AutoDisposeFutureProviderElement<BookingPriceCalculation?>
    with BookingPriceRef {
  _BookingPriceProviderElement(super.provider);

  @override
  String get unitId => (origin as BookingPriceProvider).unitId;
  @override
  DateTime? get checkIn => (origin as BookingPriceProvider).checkIn;
  @override
  DateTime? get checkOut => (origin as BookingPriceProvider).checkOut;
  @override
  String? get propertyId => (origin as BookingPriceProvider).propertyId;
  @override
  int get depositPercentage =>
      (origin as BookingPriceProvider).depositPercentage;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
