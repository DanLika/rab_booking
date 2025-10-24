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
  // Current step: 6-step wizard
  BookingStep get currentStep =>
      throw _privateConstructorUsedError; // Selected property and unit
  PropertyModel? get property => throw _privateConstructorUsedError;
  PropertyUnit? get selectedUnit =>
      throw _privateConstructorUsedError; // Booking details
  DateTime? get checkInDate => throw _privateConstructorUsedError;
  DateTime? get checkOutDate => throw _privateConstructorUsedError;
  int get numberOfGuests =>
      throw _privateConstructorUsedError; // Changed default to 1
  // Guest details
  String? get guestFirstName => throw _privateConstructorUsedError;
  String? get guestLastName => throw _privateConstructorUsedError;
  String? get guestEmail => throw _privateConstructorUsedError;
  String? get guestPhone => throw _privateConstructorUsedError;
  String? get specialRequests =>
      throw _privateConstructorUsedError; // Price calculation (with tax - FlutterFlow style)
  double get basePrice =>
      throw _privateConstructorUsedError; // price per night * nights * guests
  double get serviceFee => throw _privateConstructorUsedError;
  double get cleaningFee => throw _privateConstructorUsedError;
  double get taxRate =>
      throw _privateConstructorUsedError; // 8.25% like FlutterFlow
  double get taxAmount =>
      throw _privateConstructorUsedError; // calculated from basePrice
  double get totalPrice =>
      throw _privateConstructorUsedError; // basePrice + serviceFee + cleaningFee + taxAmount
  // Advance payment (20% default)
  double get advancePaymentPercentage => throw _privateConstructorUsedError;
  double get advancePaymentAmount => throw _privateConstructorUsedError;
  bool get isFullPaymentSelected =>
      throw _privateConstructorUsedError; // Stripe Customer & Payment Methods
  String? get stripeCustomerId => throw _privateConstructorUsedError;
  String? get savedPaymentMethodId => throw _privateConstructorUsedError;
  bool get savePaymentMethod =>
      throw _privateConstructorUsedError; // Refund policy
  RefundPolicy? get currentRefundPolicy => throw _privateConstructorUsedError;
  bool get canCancelBooking => throw _privateConstructorUsedError;
  double get cancellationFee => throw _privateConstructorUsedError; // E-Receipt
  String? get receiptPdfUrl => throw _privateConstructorUsedError;
  bool get receiptEmailSent =>
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
    double taxRate,
    double taxAmount,
    double totalPrice,
    double advancePaymentPercentage,
    double advancePaymentAmount,
    bool isFullPaymentSelected,
    String? stripeCustomerId,
    String? savedPaymentMethodId,
    bool savePaymentMethod,
    RefundPolicy? currentRefundPolicy,
    bool canCancelBooking,
    double cancellationFee,
    String? receiptPdfUrl,
    bool receiptEmailSent,
    String? bookingId,
    bool isLoading,
    String? error,
  });

  $PropertyModelCopyWith<$Res>? get property;
  $PropertyUnitCopyWith<$Res>? get selectedUnit;
  $RefundPolicyCopyWith<$Res>? get currentRefundPolicy;
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
    Object? taxRate = null,
    Object? taxAmount = null,
    Object? totalPrice = null,
    Object? advancePaymentPercentage = null,
    Object? advancePaymentAmount = null,
    Object? isFullPaymentSelected = null,
    Object? stripeCustomerId = freezed,
    Object? savedPaymentMethodId = freezed,
    Object? savePaymentMethod = null,
    Object? currentRefundPolicy = freezed,
    Object? canCancelBooking = null,
    Object? cancellationFee = null,
    Object? receiptPdfUrl = freezed,
    Object? receiptEmailSent = null,
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
            taxRate: null == taxRate
                ? _value.taxRate
                : taxRate // ignore: cast_nullable_to_non_nullable
                      as double,
            taxAmount: null == taxAmount
                ? _value.taxAmount
                : taxAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            totalPrice: null == totalPrice
                ? _value.totalPrice
                : totalPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            advancePaymentPercentage: null == advancePaymentPercentage
                ? _value.advancePaymentPercentage
                : advancePaymentPercentage // ignore: cast_nullable_to_non_nullable
                      as double,
            advancePaymentAmount: null == advancePaymentAmount
                ? _value.advancePaymentAmount
                : advancePaymentAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            isFullPaymentSelected: null == isFullPaymentSelected
                ? _value.isFullPaymentSelected
                : isFullPaymentSelected // ignore: cast_nullable_to_non_nullable
                      as bool,
            stripeCustomerId: freezed == stripeCustomerId
                ? _value.stripeCustomerId
                : stripeCustomerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            savedPaymentMethodId: freezed == savedPaymentMethodId
                ? _value.savedPaymentMethodId
                : savedPaymentMethodId // ignore: cast_nullable_to_non_nullable
                      as String?,
            savePaymentMethod: null == savePaymentMethod
                ? _value.savePaymentMethod
                : savePaymentMethod // ignore: cast_nullable_to_non_nullable
                      as bool,
            currentRefundPolicy: freezed == currentRefundPolicy
                ? _value.currentRefundPolicy
                : currentRefundPolicy // ignore: cast_nullable_to_non_nullable
                      as RefundPolicy?,
            canCancelBooking: null == canCancelBooking
                ? _value.canCancelBooking
                : canCancelBooking // ignore: cast_nullable_to_non_nullable
                      as bool,
            cancellationFee: null == cancellationFee
                ? _value.cancellationFee
                : cancellationFee // ignore: cast_nullable_to_non_nullable
                      as double,
            receiptPdfUrl: freezed == receiptPdfUrl
                ? _value.receiptPdfUrl
                : receiptPdfUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            receiptEmailSent: null == receiptEmailSent
                ? _value.receiptEmailSent
                : receiptEmailSent // ignore: cast_nullable_to_non_nullable
                      as bool,
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

  /// Create a copy of BookingFlowState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RefundPolicyCopyWith<$Res>? get currentRefundPolicy {
    if (_value.currentRefundPolicy == null) {
      return null;
    }

    return $RefundPolicyCopyWith<$Res>(_value.currentRefundPolicy!, (value) {
      return _then(_value.copyWith(currentRefundPolicy: value) as $Val);
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
    double taxRate,
    double taxAmount,
    double totalPrice,
    double advancePaymentPercentage,
    double advancePaymentAmount,
    bool isFullPaymentSelected,
    String? stripeCustomerId,
    String? savedPaymentMethodId,
    bool savePaymentMethod,
    RefundPolicy? currentRefundPolicy,
    bool canCancelBooking,
    double cancellationFee,
    String? receiptPdfUrl,
    bool receiptEmailSent,
    String? bookingId,
    bool isLoading,
    String? error,
  });

  @override
  $PropertyModelCopyWith<$Res>? get property;
  @override
  $PropertyUnitCopyWith<$Res>? get selectedUnit;
  @override
  $RefundPolicyCopyWith<$Res>? get currentRefundPolicy;
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
    Object? taxRate = null,
    Object? taxAmount = null,
    Object? totalPrice = null,
    Object? advancePaymentPercentage = null,
    Object? advancePaymentAmount = null,
    Object? isFullPaymentSelected = null,
    Object? stripeCustomerId = freezed,
    Object? savedPaymentMethodId = freezed,
    Object? savePaymentMethod = null,
    Object? currentRefundPolicy = freezed,
    Object? canCancelBooking = null,
    Object? cancellationFee = null,
    Object? receiptPdfUrl = freezed,
    Object? receiptEmailSent = null,
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
        taxRate: null == taxRate
            ? _value.taxRate
            : taxRate // ignore: cast_nullable_to_non_nullable
                  as double,
        taxAmount: null == taxAmount
            ? _value.taxAmount
            : taxAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        totalPrice: null == totalPrice
            ? _value.totalPrice
            : totalPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        advancePaymentPercentage: null == advancePaymentPercentage
            ? _value.advancePaymentPercentage
            : advancePaymentPercentage // ignore: cast_nullable_to_non_nullable
                  as double,
        advancePaymentAmount: null == advancePaymentAmount
            ? _value.advancePaymentAmount
            : advancePaymentAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        isFullPaymentSelected: null == isFullPaymentSelected
            ? _value.isFullPaymentSelected
            : isFullPaymentSelected // ignore: cast_nullable_to_non_nullable
                  as bool,
        stripeCustomerId: freezed == stripeCustomerId
            ? _value.stripeCustomerId
            : stripeCustomerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        savedPaymentMethodId: freezed == savedPaymentMethodId
            ? _value.savedPaymentMethodId
            : savedPaymentMethodId // ignore: cast_nullable_to_non_nullable
                  as String?,
        savePaymentMethod: null == savePaymentMethod
            ? _value.savePaymentMethod
            : savePaymentMethod // ignore: cast_nullable_to_non_nullable
                  as bool,
        currentRefundPolicy: freezed == currentRefundPolicy
            ? _value.currentRefundPolicy
            : currentRefundPolicy // ignore: cast_nullable_to_non_nullable
                  as RefundPolicy?,
        canCancelBooking: null == canCancelBooking
            ? _value.canCancelBooking
            : canCancelBooking // ignore: cast_nullable_to_non_nullable
                  as bool,
        cancellationFee: null == cancellationFee
            ? _value.cancellationFee
            : cancellationFee // ignore: cast_nullable_to_non_nullable
                  as double,
        receiptPdfUrl: freezed == receiptPdfUrl
            ? _value.receiptPdfUrl
            : receiptPdfUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        receiptEmailSent: null == receiptEmailSent
            ? _value.receiptEmailSent
            : receiptEmailSent // ignore: cast_nullable_to_non_nullable
                  as bool,
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
    this.currentStep = BookingStep.guestDetails,
    this.property,
    this.selectedUnit,
    this.checkInDate,
    this.checkOutDate,
    this.numberOfGuests = 1,
    this.guestFirstName,
    this.guestLastName,
    this.guestEmail,
    this.guestPhone,
    this.specialRequests,
    this.basePrice = 0.0,
    this.serviceFee = 0.0,
    this.cleaningFee = 0.0,
    this.taxRate = 0.0825,
    this.taxAmount = 0.0,
    this.totalPrice = 0.0,
    this.advancePaymentPercentage = 0.20,
    this.advancePaymentAmount = 0.0,
    this.isFullPaymentSelected = false,
    this.stripeCustomerId,
    this.savedPaymentMethodId,
    this.savePaymentMethod = false,
    this.currentRefundPolicy,
    this.canCancelBooking = true,
    this.cancellationFee = 0.0,
    this.receiptPdfUrl,
    this.receiptEmailSent = false,
    this.bookingId,
    this.isLoading = false,
    this.error,
  });

  // Current step: 6-step wizard
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
  // Changed default to 1
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
  // Price calculation (with tax - FlutterFlow style)
  @override
  @JsonKey()
  final double basePrice;
  // price per night * nights * guests
  @override
  @JsonKey()
  final double serviceFee;
  @override
  @JsonKey()
  final double cleaningFee;
  @override
  @JsonKey()
  final double taxRate;
  // 8.25% like FlutterFlow
  @override
  @JsonKey()
  final double taxAmount;
  // calculated from basePrice
  @override
  @JsonKey()
  final double totalPrice;
  // basePrice + serviceFee + cleaningFee + taxAmount
  // Advance payment (20% default)
  @override
  @JsonKey()
  final double advancePaymentPercentage;
  @override
  @JsonKey()
  final double advancePaymentAmount;
  @override
  @JsonKey()
  final bool isFullPaymentSelected;
  // Stripe Customer & Payment Methods
  @override
  final String? stripeCustomerId;
  @override
  final String? savedPaymentMethodId;
  @override
  @JsonKey()
  final bool savePaymentMethod;
  // Refund policy
  @override
  final RefundPolicy? currentRefundPolicy;
  @override
  @JsonKey()
  final bool canCancelBooking;
  @override
  @JsonKey()
  final double cancellationFee;
  // E-Receipt
  @override
  final String? receiptPdfUrl;
  @override
  @JsonKey()
  final bool receiptEmailSent;
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
    return 'BookingFlowState(currentStep: $currentStep, property: $property, selectedUnit: $selectedUnit, checkInDate: $checkInDate, checkOutDate: $checkOutDate, numberOfGuests: $numberOfGuests, guestFirstName: $guestFirstName, guestLastName: $guestLastName, guestEmail: $guestEmail, guestPhone: $guestPhone, specialRequests: $specialRequests, basePrice: $basePrice, serviceFee: $serviceFee, cleaningFee: $cleaningFee, taxRate: $taxRate, taxAmount: $taxAmount, totalPrice: $totalPrice, advancePaymentPercentage: $advancePaymentPercentage, advancePaymentAmount: $advancePaymentAmount, isFullPaymentSelected: $isFullPaymentSelected, stripeCustomerId: $stripeCustomerId, savedPaymentMethodId: $savedPaymentMethodId, savePaymentMethod: $savePaymentMethod, currentRefundPolicy: $currentRefundPolicy, canCancelBooking: $canCancelBooking, cancellationFee: $cancellationFee, receiptPdfUrl: $receiptPdfUrl, receiptEmailSent: $receiptEmailSent, bookingId: $bookingId, isLoading: $isLoading, error: $error)';
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
            (identical(other.taxRate, taxRate) || other.taxRate == taxRate) &&
            (identical(other.taxAmount, taxAmount) ||
                other.taxAmount == taxAmount) &&
            (identical(other.totalPrice, totalPrice) ||
                other.totalPrice == totalPrice) &&
            (identical(
                  other.advancePaymentPercentage,
                  advancePaymentPercentage,
                ) ||
                other.advancePaymentPercentage == advancePaymentPercentage) &&
            (identical(other.advancePaymentAmount, advancePaymentAmount) ||
                other.advancePaymentAmount == advancePaymentAmount) &&
            (identical(other.isFullPaymentSelected, isFullPaymentSelected) ||
                other.isFullPaymentSelected == isFullPaymentSelected) &&
            (identical(other.stripeCustomerId, stripeCustomerId) ||
                other.stripeCustomerId == stripeCustomerId) &&
            (identical(other.savedPaymentMethodId, savedPaymentMethodId) ||
                other.savedPaymentMethodId == savedPaymentMethodId) &&
            (identical(other.savePaymentMethod, savePaymentMethod) ||
                other.savePaymentMethod == savePaymentMethod) &&
            (identical(other.currentRefundPolicy, currentRefundPolicy) ||
                other.currentRefundPolicy == currentRefundPolicy) &&
            (identical(other.canCancelBooking, canCancelBooking) ||
                other.canCancelBooking == canCancelBooking) &&
            (identical(other.cancellationFee, cancellationFee) ||
                other.cancellationFee == cancellationFee) &&
            (identical(other.receiptPdfUrl, receiptPdfUrl) ||
                other.receiptPdfUrl == receiptPdfUrl) &&
            (identical(other.receiptEmailSent, receiptEmailSent) ||
                other.receiptEmailSent == receiptEmailSent) &&
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
    taxRate,
    taxAmount,
    totalPrice,
    advancePaymentPercentage,
    advancePaymentAmount,
    isFullPaymentSelected,
    stripeCustomerId,
    savedPaymentMethodId,
    savePaymentMethod,
    currentRefundPolicy,
    canCancelBooking,
    cancellationFee,
    receiptPdfUrl,
    receiptEmailSent,
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
    final double taxRate,
    final double taxAmount,
    final double totalPrice,
    final double advancePaymentPercentage,
    final double advancePaymentAmount,
    final bool isFullPaymentSelected,
    final String? stripeCustomerId,
    final String? savedPaymentMethodId,
    final bool savePaymentMethod,
    final RefundPolicy? currentRefundPolicy,
    final bool canCancelBooking,
    final double cancellationFee,
    final String? receiptPdfUrl,
    final bool receiptEmailSent,
    final String? bookingId,
    final bool isLoading,
    final String? error,
  }) = _$BookingFlowStateImpl;

  // Current step: 6-step wizard
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
  int get numberOfGuests; // Changed default to 1
  // Guest details
  @override
  String? get guestFirstName;
  @override
  String? get guestLastName;
  @override
  String? get guestEmail;
  @override
  String? get guestPhone;
  @override
  String? get specialRequests; // Price calculation (with tax - FlutterFlow style)
  @override
  double get basePrice; // price per night * nights * guests
  @override
  double get serviceFee;
  @override
  double get cleaningFee;
  @override
  double get taxRate; // 8.25% like FlutterFlow
  @override
  double get taxAmount; // calculated from basePrice
  @override
  double get totalPrice; // basePrice + serviceFee + cleaningFee + taxAmount
  // Advance payment (20% default)
  @override
  double get advancePaymentPercentage;
  @override
  double get advancePaymentAmount;
  @override
  bool get isFullPaymentSelected; // Stripe Customer & Payment Methods
  @override
  String? get stripeCustomerId;
  @override
  String? get savedPaymentMethodId;
  @override
  bool get savePaymentMethod; // Refund policy
  @override
  RefundPolicy? get currentRefundPolicy;
  @override
  bool get canCancelBooking;
  @override
  double get cancellationFee; // E-Receipt
  @override
  String? get receiptPdfUrl;
  @override
  bool get receiptEmailSent; // Booking ID (created after review)
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
