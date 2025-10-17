// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_details_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Property details provider (fetch by ID)

@ProviderFor(propertyDetails)
const propertyDetailsProvider = PropertyDetailsFamily._();

/// Property details provider (fetch by ID)

final class PropertyDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PropertyModel?>,
          PropertyModel?,
          FutureOr<PropertyModel?>
        >
    with $FutureModifier<PropertyModel?>, $FutureProvider<PropertyModel?> {
  /// Property details provider (fetch by ID)
  const PropertyDetailsProvider._({
    required PropertyDetailsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'propertyDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$propertyDetailsHash();

  @override
  String toString() {
    return r'propertyDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PropertyModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PropertyModel?> create(Ref ref) {
    final argument = this.argument as String;
    return propertyDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PropertyDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$propertyDetailsHash() => r'28140f03ecf2c5ec840f01802191c32a2efce94f';

/// Property details provider (fetch by ID)

final class PropertyDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PropertyModel?>, String> {
  const PropertyDetailsFamily._()
    : super(
        retry: null,
        name: r'propertyDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Property details provider (fetch by ID)

  PropertyDetailsProvider call(String propertyId) =>
      PropertyDetailsProvider._(argument: propertyId, from: this);

  @override
  String toString() => r'propertyDetailsProvider';
}

/// Units provider (fetch units for a property)

@ProviderFor(propertyUnits)
const propertyUnitsProvider = PropertyUnitsFamily._();

/// Units provider (fetch units for a property)

final class PropertyUnitsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PropertyUnit>>,
          List<PropertyUnit>,
          FutureOr<List<PropertyUnit>>
        >
    with
        $FutureModifier<List<PropertyUnit>>,
        $FutureProvider<List<PropertyUnit>> {
  /// Units provider (fetch units for a property)
  const PropertyUnitsProvider._({
    required PropertyUnitsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'propertyUnitsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$propertyUnitsHash();

  @override
  String toString() {
    return r'propertyUnitsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PropertyUnit>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PropertyUnit>> create(Ref ref) {
    final argument = this.argument as String;
    return propertyUnits(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PropertyUnitsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$propertyUnitsHash() => r'2a52f0525b6f1604c0cae58b9d42933fae1a424e';

/// Units provider (fetch units for a property)

final class PropertyUnitsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PropertyUnit>>, String> {
  const PropertyUnitsFamily._()
    : super(
        retry: null,
        name: r'propertyUnitsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Units provider (fetch units for a property)

  PropertyUnitsProvider call(String propertyId) =>
      PropertyUnitsProvider._(argument: propertyId, from: this);

  @override
  String toString() => r'propertyUnitsProvider';
}

/// Selected dates provider for booking

@ProviderFor(SelectedDatesNotifier)
const selectedDatesProvider = SelectedDatesNotifierProvider._();

/// Selected dates provider for booking
final class SelectedDatesNotifierProvider
    extends $NotifierProvider<SelectedDatesNotifier, SelectedDates> {
  /// Selected dates provider for booking
  const SelectedDatesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedDatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedDatesNotifierHash();

  @$internal
  @override
  SelectedDatesNotifier create() => SelectedDatesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SelectedDates value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SelectedDates>(value),
    );
  }
}

String _$selectedDatesNotifierHash() =>
    r'7b36ca3090e5a81f7d664d74da54830e6fea8a78';

/// Selected dates provider for booking

abstract class _$SelectedDatesNotifier extends $Notifier<SelectedDates> {
  SelectedDates build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SelectedDates, SelectedDates>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SelectedDates, SelectedDates>,
              SelectedDates,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Selected guests provider

@ProviderFor(SelectedGuestsNotifier)
const selectedGuestsProvider = SelectedGuestsNotifierProvider._();

/// Selected guests provider
final class SelectedGuestsNotifierProvider
    extends $NotifierProvider<SelectedGuestsNotifier, int> {
  /// Selected guests provider
  const SelectedGuestsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedGuestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedGuestsNotifierHash();

  @$internal
  @override
  SelectedGuestsNotifier create() => SelectedGuestsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$selectedGuestsNotifierHash() =>
    r'139202aa2317a92944ae59d500f65a54e400771c';

/// Selected guests provider

abstract class _$SelectedGuestsNotifier extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Booking calculation provider (calculates total price)

@ProviderFor(bookingCalculation)
const bookingCalculationProvider = BookingCalculationFamily._();

/// Booking calculation provider (calculates total price)

final class BookingCalculationProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          FutureOr<Map<String, dynamic>?>
        >
    with
        $FutureModifier<Map<String, dynamic>?>,
        $FutureProvider<Map<String, dynamic>?> {
  /// Booking calculation provider (calculates total price)
  const BookingCalculationProvider._({
    required BookingCalculationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bookingCalculationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookingCalculationHash();

  @override
  String toString() {
    return r'bookingCalculationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>?> create(Ref ref) {
    final argument = this.argument as String;
    return bookingCalculation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingCalculationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookingCalculationHash() =>
    r'fcbd3e1bf79e07e93986738c25db0ddc02a1d132';

/// Booking calculation provider (calculates total price)

final class BookingCalculationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, dynamic>?>, String> {
  const BookingCalculationFamily._()
    : super(
        retry: null,
        name: r'bookingCalculationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Booking calculation provider (calculates total price)

  BookingCalculationProvider call(String unitId) =>
      BookingCalculationProvider._(argument: unitId, from: this);

  @override
  String toString() => r'bookingCalculationProvider';
}

/// Blocked dates provider for a unit

@ProviderFor(blockedDates)
const blockedDatesProvider = BlockedDatesFamily._();

/// Blocked dates provider for a unit

final class BlockedDatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DateTime>>,
          List<DateTime>,
          FutureOr<List<DateTime>>
        >
    with $FutureModifier<List<DateTime>>, $FutureProvider<List<DateTime>> {
  /// Blocked dates provider for a unit
  const BlockedDatesProvider._({
    required BlockedDatesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'blockedDatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$blockedDatesHash();

  @override
  String toString() {
    return r'blockedDatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<DateTime>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DateTime>> create(Ref ref) {
    final argument = this.argument as String;
    return blockedDates(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BlockedDatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$blockedDatesHash() => r'eeba213f3d0e629b6a54718cb2acde9316c089ec';

/// Blocked dates provider for a unit

final class BlockedDatesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<DateTime>>, String> {
  const BlockedDatesFamily._()
    : super(
        retry: null,
        name: r'blockedDatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Blocked dates provider for a unit

  BlockedDatesProvider call(String unitId) =>
      BlockedDatesProvider._(argument: unitId, from: this);

  @override
  String toString() => r'blockedDatesProvider';
}

/// Unit availability provider

@ProviderFor(unitAvailability)
const unitAvailabilityProvider = UnitAvailabilityFamily._();

/// Unit availability provider

final class UnitAvailabilityProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Unit availability provider
  const UnitAvailabilityProvider._({
    required UnitAvailabilityFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'unitAvailabilityProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$unitAvailabilityHash();

  @override
  String toString() {
    return r'unitAvailabilityProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return unitAvailability(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UnitAvailabilityProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$unitAvailabilityHash() => r'5c0765b0be51a916265c30967bf36ae32131749f';

/// Unit availability provider

final class UnitAvailabilityFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  const UnitAvailabilityFamily._()
    : super(
        retry: null,
        name: r'unitAvailabilityProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Unit availability provider

  UnitAvailabilityProvider call(String unitId) =>
      UnitAvailabilityProvider._(argument: unitId, from: this);

  @override
  String toString() => r'unitAvailabilityProvider';
}
