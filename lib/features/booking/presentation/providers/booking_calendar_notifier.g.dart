// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_calendar_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bookingCalendarNotifierHash() =>
    r'95cad76dce9d66053d814d3ad0041c7c06aef663';

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

abstract class _$BookingCalendarNotifier
    extends BuildlessAutoDisposeNotifier<BookingCalendarState> {
  late final String unitId;

  BookingCalendarState build(String unitId);
}

/// Booking calendar notifier
///
/// Copied from [BookingCalendarNotifier].
@ProviderFor(BookingCalendarNotifier)
const bookingCalendarNotifierProvider = BookingCalendarNotifierFamily();

/// Booking calendar notifier
///
/// Copied from [BookingCalendarNotifier].
class BookingCalendarNotifierFamily extends Family<BookingCalendarState> {
  /// Booking calendar notifier
  ///
  /// Copied from [BookingCalendarNotifier].
  const BookingCalendarNotifierFamily();

  /// Booking calendar notifier
  ///
  /// Copied from [BookingCalendarNotifier].
  BookingCalendarNotifierProvider call(String unitId) {
    return BookingCalendarNotifierProvider(unitId);
  }

  @override
  BookingCalendarNotifierProvider getProviderOverride(
    covariant BookingCalendarNotifierProvider provider,
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
  String? get name => r'bookingCalendarNotifierProvider';
}

/// Booking calendar notifier
///
/// Copied from [BookingCalendarNotifier].
class BookingCalendarNotifierProvider
    extends
        AutoDisposeNotifierProviderImpl<
          BookingCalendarNotifier,
          BookingCalendarState
        > {
  /// Booking calendar notifier
  ///
  /// Copied from [BookingCalendarNotifier].
  BookingCalendarNotifierProvider(String unitId)
    : this._internal(
        () => BookingCalendarNotifier()..unitId = unitId,
        from: bookingCalendarNotifierProvider,
        name: r'bookingCalendarNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bookingCalendarNotifierHash,
        dependencies: BookingCalendarNotifierFamily._dependencies,
        allTransitiveDependencies:
            BookingCalendarNotifierFamily._allTransitiveDependencies,
        unitId: unitId,
      );

  BookingCalendarNotifierProvider._internal(
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
  BookingCalendarState runNotifierBuild(
    covariant BookingCalendarNotifier notifier,
  ) {
    return notifier.build(unitId);
  }

  @override
  Override overrideWith(BookingCalendarNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: BookingCalendarNotifierProvider._internal(
        () => create()..unitId = unitId,
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
  AutoDisposeNotifierProviderElement<
    BookingCalendarNotifier,
    BookingCalendarState
  >
  createElement() {
    return _BookingCalendarNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingCalendarNotifierProvider && other.unitId == unitId;
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
mixin BookingCalendarNotifierRef
    on AutoDisposeNotifierProviderRef<BookingCalendarState> {
  /// The parameter `unitId` of this provider.
  String get unitId;
}

class _BookingCalendarNotifierProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          BookingCalendarNotifier,
          BookingCalendarState
        >
    with BookingCalendarNotifierRef {
  _BookingCalendarNotifierProviderElement(super.provider);

  @override
  String get unitId => (origin as BookingCalendarNotifierProvider).unitId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
