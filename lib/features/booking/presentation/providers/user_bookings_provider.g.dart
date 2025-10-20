// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_bookings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$upcomingBookingsHash() => r'bc7966dd0d25ed53bca1c5717d96a84364563ae4';

/// See also [upcomingBookings].
@ProviderFor(upcomingBookings)
final upcomingBookingsProvider =
    AutoDisposeFutureProvider<List<UserBooking>>.internal(
      upcomingBookings,
      name: r'upcomingBookingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$upcomingBookingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UpcomingBookingsRef = AutoDisposeFutureProviderRef<List<UserBooking>>;
String _$pastBookingsHash() => r'702fc2346d16d694335c68e1f876c62d308ec751';

/// See also [pastBookings].
@ProviderFor(pastBookings)
final pastBookingsProvider =
    AutoDisposeFutureProvider<List<UserBooking>>.internal(
      pastBookings,
      name: r'pastBookingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pastBookingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PastBookingsRef = AutoDisposeFutureProviderRef<List<UserBooking>>;
String _$cancelledBookingsHash() => r'bc7a31648a132e797f0ae4df4e588d2b8f8705b8';

/// See also [cancelledBookings].
@ProviderFor(cancelledBookings)
final cancelledBookingsProvider =
    AutoDisposeFutureProvider<List<UserBooking>>.internal(
      cancelledBookings,
      name: r'cancelledBookingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cancelledBookingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CancelledBookingsRef = AutoDisposeFutureProviderRef<List<UserBooking>>;
String _$bookingDetailsHash() => r'20417c3d0e7f33f1ce58095d5d65e95e7e70bee7';

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

/// See also [bookingDetails].
@ProviderFor(bookingDetails)
const bookingDetailsProvider = BookingDetailsFamily();

/// See also [bookingDetails].
class BookingDetailsFamily extends Family<AsyncValue<UserBooking>> {
  /// See also [bookingDetails].
  const BookingDetailsFamily();

  /// See also [bookingDetails].
  BookingDetailsProvider call(String bookingId) {
    return BookingDetailsProvider(bookingId);
  }

  @override
  BookingDetailsProvider getProviderOverride(
    covariant BookingDetailsProvider provider,
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
  String? get name => r'bookingDetailsProvider';
}

/// See also [bookingDetails].
class BookingDetailsProvider extends AutoDisposeFutureProvider<UserBooking> {
  /// See also [bookingDetails].
  BookingDetailsProvider(String bookingId)
    : this._internal(
        (ref) => bookingDetails(ref as BookingDetailsRef, bookingId),
        from: bookingDetailsProvider,
        name: r'bookingDetailsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bookingDetailsHash,
        dependencies: BookingDetailsFamily._dependencies,
        allTransitiveDependencies:
            BookingDetailsFamily._allTransitiveDependencies,
        bookingId: bookingId,
      );

  BookingDetailsProvider._internal(
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
  Override overrideWith(
    FutureOr<UserBooking> Function(BookingDetailsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookingDetailsProvider._internal(
        (ref) => create(ref as BookingDetailsRef),
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
  AutoDisposeFutureProviderElement<UserBooking> createElement() {
    return _BookingDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingDetailsProvider && other.bookingId == bookingId;
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
mixin BookingDetailsRef on AutoDisposeFutureProviderRef<UserBooking> {
  /// The parameter `bookingId` of this provider.
  String get bookingId;
}

class _BookingDetailsProviderElement
    extends AutoDisposeFutureProviderElement<UserBooking>
    with BookingDetailsRef {
  _BookingDetailsProviderElement(super.provider);

  @override
  String get bookingId => (origin as BookingDetailsProvider).bookingId;
}

String _$userBookingsHash() => r'444058c64cab435e879a0afbc31fc5b73016ebf5';

/// See also [UserBookings].
@ProviderFor(UserBookings)
final userBookingsProvider =
    AutoDisposeAsyncNotifierProvider<UserBookings, List<UserBooking>>.internal(
      UserBookings.new,
      name: r'userBookingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userBookingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UserBookings = AutoDisposeAsyncNotifier<List<UserBooking>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
