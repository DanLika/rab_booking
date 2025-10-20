// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_flow_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BookingFlowState {
  // Current step: review, payment, success
  BookingStep get currentStep =>
      throw _privateConstructorUsedError; // Selected property and unit
  PropertyModel? get property => throw _privateConstructorUsedError;
  PropertyUnit? get selectedUnit =>
      throw _privateConstructorUsedError; // Booking details
  DateTime? get checkInDate => throw _privateConstructorUsedError;
  DateTime? get checkOutDate => throw _privateConstructorUsedError;
  int get numberOfGuests => throw _privateConstructorUsedError; // Guest details
  String? get guestFirstName => throw _privateConstructorUsedError;
  String? get guestLastName => throw _privateConstructorUsedError;
  String? get guestEmail => throw _privateConstructorUsedError;
  String? get guestPhone => throw _privateConstructorUsedError;
  String? get specialRequests =>
      throw _privateConstructorUsedError; // Price calculation
  double get basePrice => throw _privateConstructorUsedError;
  double get serviceFee => throw _privateConstructorUsedError;
  double get cleaningFee => throw _privateConstructorUsedError;
  double get totalPrice => throw _privateConstructorUsedError;
  double get advanceAmount =>
      throw _privateConstructorUsedError; // Booking ID (created after review)
  String? get bookingId =>
      throw _privateConstructorUsedError; // Loading and error states
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of BookingFlowState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookingFlowStateCopyWith<BookingFlowState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookingFlowStateCopyWith<$Res> {
  factory $BookingFlowStateCopyWith(
    BookingFlowState value,
    $Res Function(BookingFlowState) then,
  ) = _$BookingFlowStateCopyWithImpl<$Res, BookingFlowState>;
  @useResult
  $Res call({
    BookingStep currentStep,
    PropertyModel? property,
    PropertyUnit? selectedUnit,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int numberOfGuests,
    String? guestFirstName,
    String? guestLastName,
    String? guestEmail,
    String? guestPhone,
    String? specialRequests,
    double basePrice,
    double serviceFee,
    double cleaningFee,
    double totalPrice,
    double advanceAmount,
    String? bookingId,
    bool isLoading,
    String? error,
  });

  $PropertyModelCopyWith<$Res>? get property;
  $PropertyUnitCopyWith<$Res>? get selectedUnit;
}

/// @nodoc
class _$BookingFlowStateCopyWithImpl<$Res, $Val extends BookingFlowState>
    implements $BookingFlowStateCopyWith<$Res> {
  _$BookingFlowStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookingFlowState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentStep = null,
    Object? property = freezed,
    Object? selectedUnit = freezed,
    Object? checkInDate = freezed,
    Object? checkOutDate = freezed,
    Object? numberOfGuests = null,
    Object? guestFirstName = freezed,
    Object? guestLastName = freezed,
    Object? guestEmail = freezed,
    Object? guestPhone = freezed,
    Object? specialRequests = freezed,
    Object? basePrice = null,
    Object? serviceFee = null,
    Object? cleaningFee = null,
    Object? totalPrice = null,
    Object? advanceAmount = null,
    Object? bookingId = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            currentStep: null == currentStep
                ? _value.currentStep
                : currentStep // ignore: cast_nullable_to_non_nullable
                      as BookingStep,
            property: freezed == property
                ? _value.property
                : property // ignore: cast_nullable_to_non_nullable
                      as PropertyModel?,
            selectedUnit: freezed == selectedUnit
                ? _value.selectedUnit
                : selectedUnit // ignore: cast_nullable_to_non_nullable
                      as PropertyUnit?,
            checkInDate: freezed == checkInDate
                ? _value.checkInDate
                : checkInDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            checkOutDate: freezed == checkOutDate
                ? _value.checkOutDate
                : checkOutDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            numberOfGuests: null == numberOfGuests
                ? _value.numberOfGuests
                : numberOfGuests // ignore: cast_nullable_to_non_nullable
                      as int,
            guestFirstName: freezed == guestFirstName
                ? _value.guestFirstName
                : guestFirstName // ignore: cast_nullable_to_non_nullable
                      as String?,
            guestLastName: freezed == guestLastName
                ? _value.guestLastName
                : guestLastName // ignore: cast_nullable_to_non_nullable
                      as String?,
            guestEmail: freezed == guestEmail
                ? _value.guestEmail
                : guestEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            guestPhone: freezed == guestPhone
                ? _value.guestPhone
                : guestPhone // ignore: cast_nullable_to_non_nullable
                      as String?,
            specialRequests: freezed == specialRequests
                ? _value.specialRequests
                : specialRequests // ignore: cast_nullable_to_non_nullable
                      as String?,
            basePrice: null == basePrice
                ? _value.basePrice
                : basePrice // ignore: cast_nullable_to_non_nullable
                      as double,
            serviceFee: null == serviceFee
                ? _value.serviceFee
                : serviceFee // ignore: cast_nullable_to_non_nullable
                      as double,
            cleaningFee: null == cleaningFee
                ? _value.cleaningFee
                : cleaningFee // ignore: cast_nullable_to_non_nullable
                      as double,
            totalPrice: null == totalPrice
                ? _value.totalPrice
                : totalPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            advanceAmount: null == advanceAmount
                ? _value.advanceAmount
                : advanceAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            bookingId: freezed == bookingId
                ? _value.bookingId
                : bookingId // ignore: cast_nullable_to_non_nullable
                      as String?,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of BookingFlowState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PropertyModelCopyWith<$Res>? get property {
    if (_value.property == null) {
      return null;
    }

    return $PropertyModelCopyWith<$Res>(_value.property!, (value) {
      return _then(_value.copyWith(property: value) as $Val);
    });
  }

  /// Create a copy of BookingFlowState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PropertyUnitCopyWith<$Res>? get selectedUnit {
    if (_value.selectedUnit == null) {
      return null;
    }

    return $PropertyUnitCopyWith<$Res>(_value.selectedUnit!, (value) {
      return _then(_value.copyWith(selectedUnit: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BookingFlowStateImplCopyWith<$Res>
    implements $BookingFlowStateCopyWith<$Res> {
  factory _$$BookingFlowStateImplCopyWith(
    _$BookingFlowStateImpl value,
    $Res Function(_$BookingFlowStateImpl) then,
  ) = __$$BookingFlowStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    BookingStep currentStep,
    PropertyModel? property,
    PropertyUnit? selectedUnit,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int numberOfGuests,
    String? guestFirstName,
    String? guestLastName,
    String? guestEmail,
    String? guestPhone,
    String? specialRequests,
    double basePrice,
    double serviceFee,
    double cleaningFee,
    double totalPrice,
    double advanceAmount,
    String? bookingId,
    bool isLoading,
    String? error,
  });

  @override
  $PropertyModelCopyWith<$Res>? get property;
  @override
  $PropertyUnitCopyWith<$Res>? get selectedUnit;
}

/// @nodoc
class __$$BookingFlowStateImplCopyWithImpl<$Res>
    extends _$BookingFlowStateCopyWithImpl<$Res, _$BookingFlowStateImpl>
    implements _$$BookingFlowStateImplCopyWith<$Res> {
  __$$BookingFlowStateImplCopyWithImpl(
    _$BookingFlowStateImpl _value,
    $Res Function(_$BookingFlowStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BookingFlowState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentStep = null,
    Object? property = freezed,
    Object? selectedUnit = freezed,
    Object? checkInDate = freezed,
    Object? checkOutDate = freezed,
    Object? numberOfGuests = null,
    Object? guestFirstName = freezed,
    Object? guestLastName = freezed,
    Object? guestEmail = freezed,
    Object? guestPhone = freezed,
    Object? specialRequests = freezed,
    Object? basePrice = null,
    Object? serviceFee = null,
    Object? cleaningFee = null,
    Object? totalPrice = null,
    Object? advanceAmount = null,
    Object? bookingId = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _$BookingFlowStateImpl(
        currentStep: null == currentStep
            ? _value.currentStep
            : currentStep // ignore: cast_nullable_to_non_nullable
                  as BookingStep,
        property: freezed == property
            ? _value.property
            : property // ignore: cast_nullable_to_non_nullable
                  as PropertyModel?,
        selectedUnit: freezed == selectedUnit
            ? _value.selectedUnit
            : selectedUnit // ignore: cast_nullable_to_non_nullable
                  as PropertyUnit?,
        checkInDate: freezed == checkInDate
            ? _value.checkInDate
            : checkInDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        checkOutDate: freezed == checkOutDate
            ? _value.checkOutDate
            : checkOutDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        numberOfGuests: null == numberOfGuests
            ? _value.numberOfGuests
            : numberOfGuests // ignore: cast_nullable_to_non_nullable
                  as int,
        guestFirstName: freezed == guestFirstName
            ? _value.guestFirstName
            : guestFirstName // ignore: cast_nullable_to_non_nullable
                  as String?,
        guestLastName: freezed == guestLastName
            ? _value.guestLastName
            : guestLastName // ignore: cast_nullable_to_non_nullable
                  as String?,
        guestEmail: freezed == guestEmail
            ? _value.guestEmail
            : guestEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        guestPhone: freezed == guestPhone
            ? _value.guestPhone
            : guestPhone // ignore: cast_nullable_to_non_nullable
                  as String?,
        specialRequests: freezed == specialRequests
            ? _value.specialRequests
            : specialRequests // ignore: cast_nullable_to_non_nullable
                  as String?,
        basePrice: null == basePrice
            ? _value.basePrice
            : basePrice // ignore: cast_nullable_to_non_nullable
                  as double,
        serviceFee: null == serviceFee
            ? _value.serviceFee
            : serviceFee // ignore: cast_nullable_to_non_nullable
                  as double,
        cleaningFee: null == cleaningFee
            ? _value.cleaningFee
            : cleaningFee // ignore: cast_nullable_to_non_nullable
                  as double,
        totalPrice: null == totalPrice
            ? _value.totalPrice
            : totalPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        advanceAmount: null == advanceAmount
            ? _value.advanceAmount
            : advanceAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        bookingId: freezed == bookingId
            ? _value.bookingId
            : bookingId // ignore: cast_nullable_to_non_nullable
                  as String?,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$BookingFlowStateImpl implements _BookingFlowState {
  const _$BookingFlowStateImpl({
    this.currentStep = BookingStep.review,
    this.property,
    this.selectedUnit,
    this.checkInDate,
    this.checkOutDate,
    this.numberOfGuests = 2,
    this.guestFirstName,
    this.guestLastName,
    this.guestEmail,
    this.guestPhone,
    this.specialRequests,
    this.basePrice = 0.0,
    this.serviceFee = 0.0,
    this.cleaningFee = 0.0,
    this.totalPrice = 0.0,
    this.advanceAmount = 0.0,
    this.bookingId,
    this.isLoading = false,
    this.error,
  });

  // Current step: review, payment, success
  @override
  @JsonKey()
  final BookingStep currentStep;
  // Selected property and unit
  @override
  final PropertyModel? property;
  @override
  final PropertyUnit? selectedUnit;
  // Booking details
  @override
  final DateTime? checkInDate;
  @override
  final DateTime? checkOutDate;
  @override
  @JsonKey()
  final int numberOfGuests;
  // Guest details
  @override
  final String? guestFirstName;
  @override
  final String? guestLastName;
  @override
  final String? guestEmail;
  @override
  final String? guestPhone;
  @override
  final String? specialRequests;
  // Price calculation
  @override
  @JsonKey()
  final double basePrice;
  @override
  @JsonKey()
  final double serviceFee;
  @override
  @JsonKey()
  final double cleaningFee;
  @override
  @JsonKey()
  final double totalPrice;
  @override
  @JsonKey()
  final double advanceAmount;
  // Booking ID (created after review)
  @override
  final String? bookingId;
  // Loading and error states
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'BookingFlowState(currentStep: $currentStep, property: $property, selectedUnit: $selectedUnit, checkInDate: $checkInDate, checkOutDate: $checkOutDate, numberOfGuests: $numberOfGuests, guestFirstName: $guestFirstName, guestLastName: $guestLastName, guestEmail: $guestEmail, guestPhone: $guestPhone, specialRequests: $specialRequests, basePrice: $basePrice, serviceFee: $serviceFee, cleaningFee: $cleaningFee, totalPrice: $totalPrice, advanceAmount: $advanceAmount, bookingId: $bookingId, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookingFlowStateImpl &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            (identical(other.property, property) ||
                other.property == property) &&
            (identical(other.selectedUnit, selectedUnit) ||
                other.selectedUnit == selectedUnit) &&
            (identical(other.checkInDate, checkInDate) ||
                other.checkInDate == checkInDate) &&
            (identical(other.checkOutDate, checkOutDate) ||
                other.checkOutDate == checkOutDate) &&
            (identical(other.numberOfGuests, numberOfGuests) ||
                other.numberOfGuests == numberOfGuests) &&
            (identical(other.guestFirstName, guestFirstName) ||
                other.guestFirstName == guestFirstName) &&
            (identical(other.guestLastName, guestLastName) ||
                other.guestLastName == guestLastName) &&
            (identical(other.guestEmail, guestEmail) ||
                other.guestEmail == guestEmail) &&
            (identical(other.guestPhone, guestPhone) ||
                other.guestPhone == guestPhone) &&
            (identical(other.specialRequests, specialRequests) ||
                other.specialRequests == specialRequests) &&
            (identical(other.basePrice, basePrice) ||
                other.basePrice == basePrice) &&
            (identical(other.serviceFee, serviceFee) ||
                other.serviceFee == serviceFee) &&
            (identical(other.cleaningFee, cleaningFee) ||
                other.cleaningFee == cleaningFee) &&
            (identical(other.totalPrice, totalPrice) ||
                other.totalPrice == totalPrice) &&
            (identical(other.advanceAmount, advanceAmount) ||
                other.advanceAmount == advanceAmount) &&
            (identical(other.bookingId, bookingId) ||
                other.bookingId == bookingId) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    currentStep,
    property,
    selectedUnit,
    checkInDate,
    checkOutDate,
    numberOfGuests,
    guestFirstName,
    guestLastName,
    guestEmail,
    guestPhone,
    specialRequests,
    basePrice,
    serviceFee,
    cleaningFee,
    totalPrice,
    advanceAmount,
    bookingId,
    isLoading,
    error,
  ]);

  /// Create a copy of BookingFlowState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookingFlowStateImplCopyWith<_$BookingFlowStateImpl> get copyWith =>
      __$$BookingFlowStateImplCopyWithImpl<_$BookingFlowStateImpl>(
        this,
        _$identity,
      );
}

abstract class _BookingFlowState implements BookingFlowState {
  const factory _BookingFlowState({
    final BookingStep currentStep,
    final PropertyModel? property,
    final PropertyUnit? selectedUnit,
    final DateTime? checkInDate,
    final DateTime? checkOutDate,
    final int numberOfGuests,
    final String? guestFirstName,
    final String? guestLastName,
    final String? guestEmail,
    final String? guestPhone,
    final String? specialRequests,
    final double basePrice,
    final double serviceFee,
    final double cleaningFee,
    final double totalPrice,
    final double advanceAmount,
    final String? bookingId,
    final bool isLoading,
    final String? error,
  }) = _$BookingFlowStateImpl;

  // Current step: review, payment, success
  @override
  BookingStep get currentStep; // Selected property and unit
  @override
  PropertyModel? get property;
  @override
  PropertyUnit? get selectedUnit; // Booking details
  @override
  DateTime? get checkInDate;
  @override
  DateTime? get checkOutDate;
  @override
  int get numberOfGuests; // Guest details
  @override
  String? get guestFirstName;
  @override
  String? get guestLastName;
  @override
  String? get guestEmail;
  @override
  String? get guestPhone;
  @override
  String? get specialRequests; // Price calculation
  @override
  double get basePrice;
  @override
  double get serviceFee;
  @override
  double get cleaningFee;
  @override
  double get totalPrice;
  @override
  double get advanceAmount; // Booking ID (created after review)
  @override
  String? get bookingId; // Loading and error states
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of BookingFlowState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookingFlowStateImplCopyWith<_$BookingFlowStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
