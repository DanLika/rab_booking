// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_calendar_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Booking calendar notifier

@ProviderFor(BookingCalendarNotifier)
const bookingCalendarProvider = BookingCalendarNotifierFamily._();

/// Booking calendar notifier
final class BookingCalendarNotifierProvider
    extends $NotifierProvider<BookingCalendarNotifier, BookingCalendarState> {
  /// Booking calendar notifier
  const BookingCalendarNotifierProvider._({
    required BookingCalendarNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bookingCalendarProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookingCalendarNotifierHash();

  @override
  String toString() {
    return r'bookingCalendarProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BookingCalendarNotifier create() => BookingCalendarNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookingCalendarState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookingCalendarState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BookingCalendarNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookingCalendarNotifierHash() =>
    r'95cad76dce9d66053d814d3ad0041c7c06aef663';

/// Booking calendar notifier

final class BookingCalendarNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BookingCalendarNotifier,
          BookingCalendarState,
          BookingCalendarState,
          BookingCalendarState,
          String
        > {
  const BookingCalendarNotifierFamily._()
    : super(
        retry: null,
        name: r'bookingCalendarProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Booking calendar notifier

  BookingCalendarNotifierProvider call(String unitId) =>
      BookingCalendarNotifierProvider._(argument: unitId, from: this);

  @override
  String toString() => r'bookingCalendarProvider';
}

/// Booking calendar notifier

abstract class _$BookingCalendarNotifier
    extends $Notifier<BookingCalendarState> {
  late final _$args = ref.$arg as String;
  String get unitId => _$args;

  BookingCalendarState build(String unitId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<BookingCalendarState, BookingCalendarState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BookingCalendarState, BookingCalendarState>,
              BookingCalendarState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
