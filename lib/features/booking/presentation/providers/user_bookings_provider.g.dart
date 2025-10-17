// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_bookings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserBookings)
const userBookingsProvider = UserBookingsProvider._();

final class UserBookingsProvider
    extends $AsyncNotifierProvider<UserBookings, List<UserBooking>> {
  const UserBookingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userBookingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userBookingsHash();

  @$internal
  @override
  UserBookings create() => UserBookings();
}

String _$userBookingsHash() => r'444058c64cab435e879a0afbc31fc5b73016ebf5';

abstract class _$UserBookings extends $AsyncNotifier<List<UserBooking>> {
  FutureOr<List<UserBooking>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<UserBooking>>, List<UserBooking>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<UserBooking>>, List<UserBooking>>,
              AsyncValue<List<UserBooking>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(upcomingBookings)
const upcomingBookingsProvider = UpcomingBookingsProvider._();

final class UpcomingBookingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserBooking>>,
          List<UserBooking>,
          FutureOr<List<UserBooking>>
        >
    with
        $FutureModifier<List<UserBooking>>,
        $FutureProvider<List<UserBooking>> {
  const UpcomingBookingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'upcomingBookingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$upcomingBookingsHash();

  @$internal
  @override
  $FutureProviderElement<List<UserBooking>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserBooking>> create(Ref ref) {
    return upcomingBookings(ref);
  }
}

String _$upcomingBookingsHash() => r'31c1475851e5bc4627a10b6eb172221f2bf1da61';

@ProviderFor(pastBookings)
const pastBookingsProvider = PastBookingsProvider._();

final class PastBookingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserBooking>>,
          List<UserBooking>,
          FutureOr<List<UserBooking>>
        >
    with
        $FutureModifier<List<UserBooking>>,
        $FutureProvider<List<UserBooking>> {
  const PastBookingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pastBookingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pastBookingsHash();

  @$internal
  @override
  $FutureProviderElement<List<UserBooking>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserBooking>> create(Ref ref) {
    return pastBookings(ref);
  }
}

String _$pastBookingsHash() => r'2537c6449e6a753240e9e19fdad7633a8f833c40';

@ProviderFor(cancelledBookings)
const cancelledBookingsProvider = CancelledBookingsProvider._();

final class CancelledBookingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserBooking>>,
          List<UserBooking>,
          FutureOr<List<UserBooking>>
        >
    with
        $FutureModifier<List<UserBooking>>,
        $FutureProvider<List<UserBooking>> {
  const CancelledBookingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cancelledBookingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cancelledBookingsHash();

  @$internal
  @override
  $FutureProviderElement<List<UserBooking>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserBooking>> create(Ref ref) {
    return cancelledBookings(ref);
  }
}

String _$cancelledBookingsHash() => r'ffd3133f34b4a35f143f2ed8f4c8616c955165ae';

@ProviderFor(bookingDetails)
const bookingDetailsProvider = BookingDetailsFamily._();

final class BookingDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserBooking>,
          UserBooking,
          FutureOr<UserBooking>
        >
    with $FutureModifier<UserBooking>, $FutureProvider<UserBooking> {
  const BookingDetailsProvider._({
    required BookingDetailsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bookingDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookingDetailsHash();

  @override
  String toString() {
    return r'bookingDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<UserBooking> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserBooking> create(Ref ref) {
    final argument = this.argument as String;
    return bookingDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookingDetailsHash() => r'116cc74f2435a1b21f8bcfb76c04073a318cacf4';

final class BookingDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<UserBooking>, String> {
  const BookingDetailsFamily._()
    : super(
        retry: null,
        name: r'bookingDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BookingDetailsProvider call(String bookingId) =>
      BookingDetailsProvider._(argument: bookingId, from: this);

  @override
  String toString() => r'bookingDetailsProvider';
}
