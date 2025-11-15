// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BookingModel _$BookingModelFromJson(Map<String, dynamic> json) {
  return _BookingModel.fromJson(json);
}

/// @nodoc
mixin _$BookingModel {
  /// Booking ID (UUID)
  String get id => throw _privateConstructorUsedError;

  /// Unit being booked
  @JsonKey(name: 'unit_id')
  String get unitId => throw _privateConstructorUsedError;

  /// Guest user ID (nullable for anonymous widget bookings)
  @JsonKey(name: 'user_id')
  String? get userId => throw _privateConstructorUsedError;

  /// Guest ID (for anonymous widget bookings)
  @JsonKey(name: 'guest_id')
  String? get guestId => throw _privateConstructorUsedError;

  /// Owner ID (denormalized)
  @JsonKey(name: 'owner_id')
  String? get ownerId => throw _privateConstructorUsedError;

  /// Guest name (for widget bookings without auth)
  @JsonKey(name: 'guest_name')
  String? get guestName => throw _privateConstructorUsedError;

  /// Guest email (for widget bookings without auth)
  @JsonKey(name: 'guest_email')
  String? get guestEmail => throw _privateConstructorUsedError;

  /// Guest phone (for widget bookings without auth)
  @JsonKey(name: 'guest_phone')
  String? get guestPhone => throw _privateConstructorUsedError;

  /// Check-in date
  @TimestampConverter()
  @JsonKey(name: 'check_in')
  DateTime get checkIn => throw _privateConstructorUsedError;

  /// Check-in time
  @JsonKey(name: 'check_in_time')
  String? get checkInTime => throw _privateConstructorUsedError;

  /// Check-out time
  @JsonKey(name: 'check_out_time')
  String? get checkOutTime => throw _privateConstructorUsedError;

  /// Check-out date
  @TimestampConverter()
  @JsonKey(name: 'check_out')
  DateTime get checkOut => throw _privateConstructorUsedError;

  /// Booking status
  BookingStatus get status => throw _privateConstructorUsedError;

  /// Total price in EUR
  @JsonKey(name: 'total_price')
  double get totalPrice => throw _privateConstructorUsedError;

  /// Amount paid (advance payment - 20%)
  @JsonKey(name: 'paid_amount')
  double get paidAmount => throw _privateConstructorUsedError;

  /// Advance payment amount (20% of total)
  @JsonKey(name: 'advance_amount')
  double? get advanceAmount => throw _privateConstructorUsedError;

  /// Payment method (bank_transfer, stripe, cash, other)
  @JsonKey(name: 'payment_method')
  String? get paymentMethod => throw _privateConstructorUsedError;

  /// Payment status (pending, paid, refunded)
  @JsonKey(name: 'payment_status')
  String? get paymentStatus => throw _privateConstructorUsedError;

  /// Booking source (widget, admin, direct, api)
  String? get source => throw _privateConstructorUsedError;

  /// Number of guests
  @JsonKey(name: 'guest_count')
  int get guestCount => throw _privateConstructorUsedError;

  /// Special requests or notes
  String? get notes => throw _privateConstructorUsedError;

  /// Tax/Legal disclaimer acceptance (for compliance audit trail)
  @JsonKey(name: 'tax_legal_accepted')
  bool? get taxLegalAccepted => throw _privateConstructorUsedError;

  /// Stripe payment intent ID
  @JsonKey(name: 'payment_intent_id')
  String? get paymentIntentId => throw _privateConstructorUsedError;

  /// Booking creation timestamp
  @TimestampConverter()
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Last update timestamp
  @NullableTimestampConverter()
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Cancellation reason (if cancelled)
  @JsonKey(name: 'cancellation_reason')
  String? get cancellationReason => throw _privateConstructorUsedError;

  /// Cancelled at timestamp
  @NullableTimestampConverter()
  @JsonKey(name: 'cancelled_at')
  DateTime? get cancelledAt => throw _privateConstructorUsedError;

  /// User ID who cancelled the booking
  @JsonKey(name: 'cancelled_by')
  String? get cancelledBy => throw _privateConstructorUsedError;

  /// Serializes this BookingModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BookingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookingModelCopyWith<BookingModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookingModelCopyWith<$Res> {
  factory $BookingModelCopyWith(
    BookingModel value,
    $Res Function(BookingModel) then,
  ) = _$BookingModelCopyWithImpl<$Res, BookingModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'unit_id') String unitId,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'guest_id') String? guestId,
    @JsonKey(name: 'owner_id') String? ownerId,
    @JsonKey(name: 'guest_name') String? guestName,
    @JsonKey(name: 'guest_email') String? guestEmail,
    @JsonKey(name: 'guest_phone') String? guestPhone,
    @TimestampConverter() @JsonKey(name: 'check_in') DateTime checkIn,
    @JsonKey(name: 'check_in_time') String? checkInTime,
    @JsonKey(name: 'check_out_time') String? checkOutTime,
    @TimestampConverter() @JsonKey(name: 'check_out') DateTime checkOut,
    BookingStatus status,
    @JsonKey(name: 'total_price') double totalPrice,
    @JsonKey(name: 'paid_amount') double paidAmount,
    @JsonKey(name: 'advance_amount') double? advanceAmount,
    @JsonKey(name: 'payment_method') String? paymentMethod,
    @JsonKey(name: 'payment_status') String? paymentStatus,
    String? source,
    @JsonKey(name: 'guest_count') int guestCount,
    String? notes,
    @JsonKey(name: 'tax_legal_accepted') bool? taxLegalAccepted,
    @JsonKey(name: 'payment_intent_id') String? paymentIntentId,
    @TimestampConverter() @JsonKey(name: 'created_at') DateTime createdAt,
    @NullableTimestampConverter()
    @JsonKey(name: 'updated_at')
    DateTime? updatedAt,
    @JsonKey(name: 'cancellation_reason') String? cancellationReason,
    @NullableTimestampConverter()
    @JsonKey(name: 'cancelled_at')
    DateTime? cancelledAt,
    @JsonKey(name: 'cancelled_by') String? cancelledBy,
  });
}

/// @nodoc
class _$BookingModelCopyWithImpl<$Res, $Val extends BookingModel>
    implements $BookingModelCopyWith<$Res> {
  _$BookingModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? unitId = null,
    Object? userId = freezed,
    Object? guestId = freezed,
    Object? ownerId = freezed,
    Object? guestName = freezed,
    Object? guestEmail = freezed,
    Object? guestPhone = freezed,
    Object? checkIn = null,
    Object? checkInTime = freezed,
    Object? checkOutTime = freezed,
    Object? checkOut = null,
    Object? status = null,
    Object? totalPrice = null,
    Object? paidAmount = null,
    Object? advanceAmount = freezed,
    Object? paymentMethod = freezed,
    Object? paymentStatus = freezed,
    Object? source = freezed,
    Object? guestCount = null,
    Object? notes = freezed,
    Object? taxLegalAccepted = freezed,
    Object? paymentIntentId = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? cancellationReason = freezed,
    Object? cancelledAt = freezed,
    Object? cancelledBy = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            unitId: null == unitId
                ? _value.unitId
                : unitId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: freezed == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String?,
            guestId: freezed == guestId
                ? _value.guestId
                : guestId // ignore: cast_nullable_to_non_nullable
                      as String?,
            ownerId: freezed == ownerId
                ? _value.ownerId
                : ownerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            guestName: freezed == guestName
                ? _value.guestName
                : guestName // ignore: cast_nullable_to_non_nullable
                      as String?,
            guestEmail: freezed == guestEmail
                ? _value.guestEmail
                : guestEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            guestPhone: freezed == guestPhone
                ? _value.guestPhone
                : guestPhone // ignore: cast_nullable_to_non_nullable
                      as String?,
            checkIn: null == checkIn
                ? _value.checkIn
                : checkIn // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            checkInTime: freezed == checkInTime
                ? _value.checkInTime
                : checkInTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            checkOutTime: freezed == checkOutTime
                ? _value.checkOutTime
                : checkOutTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            checkOut: null == checkOut
                ? _value.checkOut
                : checkOut // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as BookingStatus,
            totalPrice: null == totalPrice
                ? _value.totalPrice
                : totalPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            paidAmount: null == paidAmount
                ? _value.paidAmount
                : paidAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            advanceAmount: freezed == advanceAmount
                ? _value.advanceAmount
                : advanceAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
            paymentMethod: freezed == paymentMethod
                ? _value.paymentMethod
                : paymentMethod // ignore: cast_nullable_to_non_nullable
                      as String?,
            paymentStatus: freezed == paymentStatus
                ? _value.paymentStatus
                : paymentStatus // ignore: cast_nullable_to_non_nullable
                      as String?,
            source: freezed == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String?,
            guestCount: null == guestCount
                ? _value.guestCount
                : guestCount // ignore: cast_nullable_to_non_nullable
                      as int,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            taxLegalAccepted: freezed == taxLegalAccepted
                ? _value.taxLegalAccepted
                : taxLegalAccepted // ignore: cast_nullable_to_non_nullable
                      as bool?,
            paymentIntentId: freezed == paymentIntentId
                ? _value.paymentIntentId
                : paymentIntentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            cancellationReason: freezed == cancellationReason
                ? _value.cancellationReason
                : cancellationReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            cancelledAt: freezed == cancelledAt
                ? _value.cancelledAt
                : cancelledAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            cancelledBy: freezed == cancelledBy
                ? _value.cancelledBy
                : cancelledBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookingModelImplCopyWith<$Res>
    implements $BookingModelCopyWith<$Res> {
  factory _$$BookingModelImplCopyWith(
    _$BookingModelImpl value,
    $Res Function(_$BookingModelImpl) then,
  ) = __$$BookingModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'unit_id') String unitId,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'guest_id') String? guestId,
    @JsonKey(name: 'owner_id') String? ownerId,
    @JsonKey(name: 'guest_name') String? guestName,
    @JsonKey(name: 'guest_email') String? guestEmail,
    @JsonKey(name: 'guest_phone') String? guestPhone,
    @TimestampConverter() @JsonKey(name: 'check_in') DateTime checkIn,
    @JsonKey(name: 'check_in_time') String? checkInTime,
    @JsonKey(name: 'check_out_time') String? checkOutTime,
    @TimestampConverter() @JsonKey(name: 'check_out') DateTime checkOut,
    BookingStatus status,
    @JsonKey(name: 'total_price') double totalPrice,
    @JsonKey(name: 'paid_amount') double paidAmount,
    @JsonKey(name: 'advance_amount') double? advanceAmount,
    @JsonKey(name: 'payment_method') String? paymentMethod,
    @JsonKey(name: 'payment_status') String? paymentStatus,
    String? source,
    @JsonKey(name: 'guest_count') int guestCount,
    String? notes,
    @JsonKey(name: 'tax_legal_accepted') bool? taxLegalAccepted,
    @JsonKey(name: 'payment_intent_id') String? paymentIntentId,
    @TimestampConverter() @JsonKey(name: 'created_at') DateTime createdAt,
    @NullableTimestampConverter()
    @JsonKey(name: 'updated_at')
    DateTime? updatedAt,
    @JsonKey(name: 'cancellation_reason') String? cancellationReason,
    @NullableTimestampConverter()
    @JsonKey(name: 'cancelled_at')
    DateTime? cancelledAt,
    @JsonKey(name: 'cancelled_by') String? cancelledBy,
  });
}

/// @nodoc
class __$$BookingModelImplCopyWithImpl<$Res>
    extends _$BookingModelCopyWithImpl<$Res, _$BookingModelImpl>
    implements _$$BookingModelImplCopyWith<$Res> {
  __$$BookingModelImplCopyWithImpl(
    _$BookingModelImpl _value,
    $Res Function(_$BookingModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BookingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? unitId = null,
    Object? userId = freezed,
    Object? guestId = freezed,
    Object? ownerId = freezed,
    Object? guestName = freezed,
    Object? guestEmail = freezed,
    Object? guestPhone = freezed,
    Object? checkIn = null,
    Object? checkInTime = freezed,
    Object? checkOutTime = freezed,
    Object? checkOut = null,
    Object? status = null,
    Object? totalPrice = null,
    Object? paidAmount = null,
    Object? advanceAmount = freezed,
    Object? paymentMethod = freezed,
    Object? paymentStatus = freezed,
    Object? source = freezed,
    Object? guestCount = null,
    Object? notes = freezed,
    Object? taxLegalAccepted = freezed,
    Object? paymentIntentId = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? cancellationReason = freezed,
    Object? cancelledAt = freezed,
    Object? cancelledBy = freezed,
  }) {
    return _then(
      _$BookingModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        unitId: null == unitId
            ? _value.unitId
            : unitId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: freezed == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String?,
        guestId: freezed == guestId
            ? _value.guestId
            : guestId // ignore: cast_nullable_to_non_nullable
                  as String?,
        ownerId: freezed == ownerId
            ? _value.ownerId
            : ownerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        guestName: freezed == guestName
            ? _value.guestName
            : guestName // ignore: cast_nullable_to_non_nullable
                  as String?,
        guestEmail: freezed == guestEmail
            ? _value.guestEmail
            : guestEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        guestPhone: freezed == guestPhone
            ? _value.guestPhone
            : guestPhone // ignore: cast_nullable_to_non_nullable
                  as String?,
        checkIn: null == checkIn
            ? _value.checkIn
            : checkIn // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        checkInTime: freezed == checkInTime
            ? _value.checkInTime
            : checkInTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        checkOutTime: freezed == checkOutTime
            ? _value.checkOutTime
            : checkOutTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        checkOut: null == checkOut
            ? _value.checkOut
            : checkOut // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as BookingStatus,
        totalPrice: null == totalPrice
            ? _value.totalPrice
            : totalPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        paidAmount: null == paidAmount
            ? _value.paidAmount
            : paidAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        advanceAmount: freezed == advanceAmount
            ? _value.advanceAmount
            : advanceAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
        paymentMethod: freezed == paymentMethod
            ? _value.paymentMethod
            : paymentMethod // ignore: cast_nullable_to_non_nullable
                  as String?,
        paymentStatus: freezed == paymentStatus
            ? _value.paymentStatus
            : paymentStatus // ignore: cast_nullable_to_non_nullable
                  as String?,
        source: freezed == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String?,
        guestCount: null == guestCount
            ? _value.guestCount
            : guestCount // ignore: cast_nullable_to_non_nullable
                  as int,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        taxLegalAccepted: freezed == taxLegalAccepted
            ? _value.taxLegalAccepted
            : taxLegalAccepted // ignore: cast_nullable_to_non_nullable
                  as bool?,
        paymentIntentId: freezed == paymentIntentId
            ? _value.paymentIntentId
            : paymentIntentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        cancellationReason: freezed == cancellationReason
            ? _value.cancellationReason
            : cancellationReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        cancelledAt: freezed == cancelledAt
            ? _value.cancelledAt
            : cancelledAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        cancelledBy: freezed == cancelledBy
            ? _value.cancelledBy
            : cancelledBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BookingModelImpl extends _BookingModel {
  const _$BookingModelImpl({
    required this.id,
    @JsonKey(name: 'unit_id') required this.unitId,
    @JsonKey(name: 'user_id') this.userId,
    @JsonKey(name: 'guest_id') this.guestId,
    @JsonKey(name: 'owner_id') this.ownerId,
    @JsonKey(name: 'guest_name') this.guestName,
    @JsonKey(name: 'guest_email') this.guestEmail,
    @JsonKey(name: 'guest_phone') this.guestPhone,
    @TimestampConverter() @JsonKey(name: 'check_in') required this.checkIn,
    @JsonKey(name: 'check_in_time') this.checkInTime,
    @JsonKey(name: 'check_out_time') this.checkOutTime,
    @TimestampConverter() @JsonKey(name: 'check_out') required this.checkOut,
    required this.status,
    @JsonKey(name: 'total_price') this.totalPrice = 0.0,
    @JsonKey(name: 'paid_amount') this.paidAmount = 0.0,
    @JsonKey(name: 'advance_amount') this.advanceAmount,
    @JsonKey(name: 'payment_method') this.paymentMethod,
    @JsonKey(name: 'payment_status') this.paymentStatus,
    this.source,
    @JsonKey(name: 'guest_count') this.guestCount = 1,
    this.notes,
    @JsonKey(name: 'tax_legal_accepted') this.taxLegalAccepted,
    @JsonKey(name: 'payment_intent_id') this.paymentIntentId,
    @TimestampConverter() @JsonKey(name: 'created_at') required this.createdAt,
    @NullableTimestampConverter() @JsonKey(name: 'updated_at') this.updatedAt,
    @JsonKey(name: 'cancellation_reason') this.cancellationReason,
    @NullableTimestampConverter()
    @JsonKey(name: 'cancelled_at')
    this.cancelledAt,
    @JsonKey(name: 'cancelled_by') this.cancelledBy,
  }) : super._();

  factory _$BookingModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookingModelImplFromJson(json);

  /// Booking ID (UUID)
  @override
  final String id;

  /// Unit being booked
  @override
  @JsonKey(name: 'unit_id')
  final String unitId;

  /// Guest user ID (nullable for anonymous widget bookings)
  @override
  @JsonKey(name: 'user_id')
  final String? userId;

  /// Guest ID (for anonymous widget bookings)
  @override
  @JsonKey(name: 'guest_id')
  final String? guestId;

  /// Owner ID (denormalized)
  @override
  @JsonKey(name: 'owner_id')
  final String? ownerId;

  /// Guest name (for widget bookings without auth)
  @override
  @JsonKey(name: 'guest_name')
  final String? guestName;

  /// Guest email (for widget bookings without auth)
  @override
  @JsonKey(name: 'guest_email')
  final String? guestEmail;

  /// Guest phone (for widget bookings without auth)
  @override
  @JsonKey(name: 'guest_phone')
  final String? guestPhone;

  /// Check-in date
  @override
  @TimestampConverter()
  @JsonKey(name: 'check_in')
  final DateTime checkIn;

  /// Check-in time
  @override
  @JsonKey(name: 'check_in_time')
  final String? checkInTime;

  /// Check-out time
  @override
  @JsonKey(name: 'check_out_time')
  final String? checkOutTime;

  /// Check-out date
  @override
  @TimestampConverter()
  @JsonKey(name: 'check_out')
  final DateTime checkOut;

  /// Booking status
  @override
  final BookingStatus status;

  /// Total price in EUR
  @override
  @JsonKey(name: 'total_price')
  final double totalPrice;

  /// Amount paid (advance payment - 20%)
  @override
  @JsonKey(name: 'paid_amount')
  final double paidAmount;

  /// Advance payment amount (20% of total)
  @override
  @JsonKey(name: 'advance_amount')
  final double? advanceAmount;

  /// Payment method (bank_transfer, stripe, cash, other)
  @override
  @JsonKey(name: 'payment_method')
  final String? paymentMethod;

  /// Payment status (pending, paid, refunded)
  @override
  @JsonKey(name: 'payment_status')
  final String? paymentStatus;

  /// Booking source (widget, admin, direct, api)
  @override
  final String? source;

  /// Number of guests
  @override
  @JsonKey(name: 'guest_count')
  final int guestCount;

  /// Special requests or notes
  @override
  final String? notes;

  /// Tax/Legal disclaimer acceptance (for compliance audit trail)
  @override
  @JsonKey(name: 'tax_legal_accepted')
  final bool? taxLegalAccepted;

  /// Stripe payment intent ID
  @override
  @JsonKey(name: 'payment_intent_id')
  final String? paymentIntentId;

  /// Booking creation timestamp
  @override
  @TimestampConverter()
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Last update timestamp
  @override
  @NullableTimestampConverter()
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Cancellation reason (if cancelled)
  @override
  @JsonKey(name: 'cancellation_reason')
  final String? cancellationReason;

  /// Cancelled at timestamp
  @override
  @NullableTimestampConverter()
  @JsonKey(name: 'cancelled_at')
  final DateTime? cancelledAt;

  /// User ID who cancelled the booking
  @override
  @JsonKey(name: 'cancelled_by')
  final String? cancelledBy;

  @override
  String toString() {
    return 'BookingModel(id: $id, unitId: $unitId, userId: $userId, guestId: $guestId, ownerId: $ownerId, guestName: $guestName, guestEmail: $guestEmail, guestPhone: $guestPhone, checkIn: $checkIn, checkInTime: $checkInTime, checkOutTime: $checkOutTime, checkOut: $checkOut, status: $status, totalPrice: $totalPrice, paidAmount: $paidAmount, advanceAmount: $advanceAmount, paymentMethod: $paymentMethod, paymentStatus: $paymentStatus, source: $source, guestCount: $guestCount, notes: $notes, taxLegalAccepted: $taxLegalAccepted, paymentIntentId: $paymentIntentId, createdAt: $createdAt, updatedAt: $updatedAt, cancellationReason: $cancellationReason, cancelledAt: $cancelledAt, cancelledBy: $cancelledBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookingModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.unitId, unitId) || other.unitId == unitId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.guestId, guestId) || other.guestId == guestId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.guestName, guestName) ||
                other.guestName == guestName) &&
            (identical(other.guestEmail, guestEmail) ||
                other.guestEmail == guestEmail) &&
            (identical(other.guestPhone, guestPhone) ||
                other.guestPhone == guestPhone) &&
            (identical(other.checkIn, checkIn) || other.checkIn == checkIn) &&
            (identical(other.checkInTime, checkInTime) ||
                other.checkInTime == checkInTime) &&
            (identical(other.checkOutTime, checkOutTime) ||
                other.checkOutTime == checkOutTime) &&
            (identical(other.checkOut, checkOut) ||
                other.checkOut == checkOut) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.totalPrice, totalPrice) ||
                other.totalPrice == totalPrice) &&
            (identical(other.paidAmount, paidAmount) ||
                other.paidAmount == paidAmount) &&
            (identical(other.advanceAmount, advanceAmount) ||
                other.advanceAmount == advanceAmount) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.guestCount, guestCount) ||
                other.guestCount == guestCount) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.taxLegalAccepted, taxLegalAccepted) ||
                other.taxLegalAccepted == taxLegalAccepted) &&
            (identical(other.paymentIntentId, paymentIntentId) ||
                other.paymentIntentId == paymentIntentId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.cancellationReason, cancellationReason) ||
                other.cancellationReason == cancellationReason) &&
            (identical(other.cancelledAt, cancelledAt) ||
                other.cancelledAt == cancelledAt) &&
            (identical(other.cancelledBy, cancelledBy) ||
                other.cancelledBy == cancelledBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    unitId,
    userId,
    guestId,
    ownerId,
    guestName,
    guestEmail,
    guestPhone,
    checkIn,
    checkInTime,
    checkOutTime,
    checkOut,
    status,
    totalPrice,
    paidAmount,
    advanceAmount,
    paymentMethod,
    paymentStatus,
    source,
    guestCount,
    notes,
    taxLegalAccepted,
    paymentIntentId,
    createdAt,
    updatedAt,
    cancellationReason,
    cancelledAt,
    cancelledBy,
  ]);

  /// Create a copy of BookingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookingModelImplCopyWith<_$BookingModelImpl> get copyWith =>
      __$$BookingModelImplCopyWithImpl<_$BookingModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BookingModelImplToJson(this);
  }
}

abstract class _BookingModel extends BookingModel {
  const factory _BookingModel({
    required final String id,
    @JsonKey(name: 'unit_id') required final String unitId,
    @JsonKey(name: 'user_id') final String? userId,
    @JsonKey(name: 'guest_id') final String? guestId,
    @JsonKey(name: 'owner_id') final String? ownerId,
    @JsonKey(name: 'guest_name') final String? guestName,
    @JsonKey(name: 'guest_email') final String? guestEmail,
    @JsonKey(name: 'guest_phone') final String? guestPhone,
    @TimestampConverter()
    @JsonKey(name: 'check_in')
    required final DateTime checkIn,
    @JsonKey(name: 'check_in_time') final String? checkInTime,
    @JsonKey(name: 'check_out_time') final String? checkOutTime,
    @TimestampConverter()
    @JsonKey(name: 'check_out')
    required final DateTime checkOut,
    required final BookingStatus status,
    @JsonKey(name: 'total_price') final double totalPrice,
    @JsonKey(name: 'paid_amount') final double paidAmount,
    @JsonKey(name: 'advance_amount') final double? advanceAmount,
    @JsonKey(name: 'payment_method') final String? paymentMethod,
    @JsonKey(name: 'payment_status') final String? paymentStatus,
    final String? source,
    @JsonKey(name: 'guest_count') final int guestCount,
    final String? notes,
    @JsonKey(name: 'tax_legal_accepted') final bool? taxLegalAccepted,
    @JsonKey(name: 'payment_intent_id') final String? paymentIntentId,
    @TimestampConverter()
    @JsonKey(name: 'created_at')
    required final DateTime createdAt,
    @NullableTimestampConverter()
    @JsonKey(name: 'updated_at')
    final DateTime? updatedAt,
    @JsonKey(name: 'cancellation_reason') final String? cancellationReason,
    @NullableTimestampConverter()
    @JsonKey(name: 'cancelled_at')
    final DateTime? cancelledAt,
    @JsonKey(name: 'cancelled_by') final String? cancelledBy,
  }) = _$BookingModelImpl;
  const _BookingModel._() : super._();

  factory _BookingModel.fromJson(Map<String, dynamic> json) =
      _$BookingModelImpl.fromJson;

  /// Booking ID (UUID)
  @override
  String get id;

  /// Unit being booked
  @override
  @JsonKey(name: 'unit_id')
  String get unitId;

  /// Guest user ID (nullable for anonymous widget bookings)
  @override
  @JsonKey(name: 'user_id')
  String? get userId;

  /// Guest ID (for anonymous widget bookings)
  @override
  @JsonKey(name: 'guest_id')
  String? get guestId;

  /// Owner ID (denormalized)
  @override
  @JsonKey(name: 'owner_id')
  String? get ownerId;

  /// Guest name (for widget bookings without auth)
  @override
  @JsonKey(name: 'guest_name')
  String? get guestName;

  /// Guest email (for widget bookings without auth)
  @override
  @JsonKey(name: 'guest_email')
  String? get guestEmail;

  /// Guest phone (for widget bookings without auth)
  @override
  @JsonKey(name: 'guest_phone')
  String? get guestPhone;

  /// Check-in date
  @override
  @TimestampConverter()
  @JsonKey(name: 'check_in')
  DateTime get checkIn;

  /// Check-in time
  @override
  @JsonKey(name: 'check_in_time')
  String? get checkInTime;

  /// Check-out time
  @override
  @JsonKey(name: 'check_out_time')
  String? get checkOutTime;

  /// Check-out date
  @override
  @TimestampConverter()
  @JsonKey(name: 'check_out')
  DateTime get checkOut;

  /// Booking status
  @override
  BookingStatus get status;

  /// Total price in EUR
  @override
  @JsonKey(name: 'total_price')
  double get totalPrice;

  /// Amount paid (advance payment - 20%)
  @override
  @JsonKey(name: 'paid_amount')
  double get paidAmount;

  /// Advance payment amount (20% of total)
  @override
  @JsonKey(name: 'advance_amount')
  double? get advanceAmount;

  /// Payment method (bank_transfer, stripe, cash, other)
  @override
  @JsonKey(name: 'payment_method')
  String? get paymentMethod;

  /// Payment status (pending, paid, refunded)
  @override
  @JsonKey(name: 'payment_status')
  String? get paymentStatus;

  /// Booking source (widget, admin, direct, api)
  @override
  String? get source;

  /// Number of guests
  @override
  @JsonKey(name: 'guest_count')
  int get guestCount;

  /// Special requests or notes
  @override
  String? get notes;

  /// Tax/Legal disclaimer acceptance (for compliance audit trail)
  @override
  @JsonKey(name: 'tax_legal_accepted')
  bool? get taxLegalAccepted;

  /// Stripe payment intent ID
  @override
  @JsonKey(name: 'payment_intent_id')
  String? get paymentIntentId;

  /// Booking creation timestamp
  @override
  @TimestampConverter()
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Last update timestamp
  @override
  @NullableTimestampConverter()
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Cancellation reason (if cancelled)
  @override
  @JsonKey(name: 'cancellation_reason')
  String? get cancellationReason;

  /// Cancelled at timestamp
  @override
  @NullableTimestampConverter()
  @JsonKey(name: 'cancelled_at')
  DateTime? get cancelledAt;

  /// User ID who cancelled the booking
  @override
  @JsonKey(name: 'cancelled_by')
  String? get cancelledBy;

  /// Create a copy of BookingModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookingModelImplCopyWith<_$BookingModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
