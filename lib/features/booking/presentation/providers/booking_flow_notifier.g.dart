// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_flow_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Booking flow notifier

@ProviderFor(BookingFlowNotifier)
const bookingFlowProvider = BookingFlowNotifierProvider._();

/// Booking flow notifier
final class BookingFlowNotifierProvider
    extends $NotifierProvider<BookingFlowNotifier, BookingFlowState> {
  /// Booking flow notifier
  const BookingFlowNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingFlowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingFlowNotifierHash();

  @$internal
  @override
  BookingFlowNotifier create() => BookingFlowNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookingFlowState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookingFlowState>(value),
    );
  }
}

String _$bookingFlowNotifierHash() =>
    r'7e83aae7b3a64d4fba4eb4256d4792a0166f881a';

/// Booking flow notifier

abstract class _$BookingFlowNotifier extends $Notifier<BookingFlowState> {
  BookingFlowState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<BookingFlowState, BookingFlowState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BookingFlowState, BookingFlowState>,
              BookingFlowState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
