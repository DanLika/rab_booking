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

  /// Guest user ID
  @JsonKey(name: 'guest_id')
  String get guestId => throw _privateConstructorUsedError;

  /// Check-in date
  @JsonKey(name: 'check_in')
  DateTime get checkIn => throw _privateConstructorUsedError;

  /// Check-out date
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

  /// Number of guests
  @JsonKey(name: 'guest_count')
  int get guestCount => throw _privateConstructorUsedError;

  /// Special requests or notes
  String? get notes => throw _privateConstructorUsedError;

  /// Stripe payment intent ID
  @JsonKey(name: 'payment_intent_id')
  String? get paymentIntentId => throw _privateConstructorUsedError;

  /// Booking creation timestamp
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Last update timestamp
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Cancellation reason (if cancelled)
  @JsonKey(name: 'cancellation_reason')
  String? get cancellationReason => throw _privateConstructorUsedError;

  /// Cancelled at timestamp
  @JsonKey(name: 'cancelled_at')
  DateTime? get cancelledAt => throw _privateConstructorUsedError;

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
    @JsonKey(name: 'guest_id') String guestId,
    @JsonKey(name: 'check_in') DateTime checkIn,
    @JsonKey(name: 'check_out') DateTime checkOut,
    BookingStatus status,
    @JsonKey(name: 'total_price') double totalPrice,
    @JsonKey(name: 'paid_amount') double paidAmount,
    @JsonKey(name: 'guest_count') int guestCount,
    String? notes,
    @JsonKey(name: 'payment_intent_id') String? paymentIntentId,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'cancellation_reason') String? cancellationReason,
    @JsonKey(name: 'cancelled_at') DateTime? cancelledAt,
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
    Object? guestId = null,
    Object? checkIn = null,
    Object? checkOut = null,
    Object? status = null,
    Object? totalPrice = null,
    Object? paidAmount = null,
    Object? guestCount = null,
    Object? notes = freezed,
    Object? paymentIntentId = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? cancellationReason = freezed,
    Object? cancelledAt = freezed,
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
            guestId: null == guestId
                ? _value.guestId
                : guestId // ignore: cast_nullable_to_non_nullable
                      as String,
            checkIn: null == checkIn
                ? _value.checkIn
                : checkIn // ignore: cast_nullable_to_non_nullable
                      as DateTime,
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
            guestCount: null == guestCount
                ? _value.guestCount
                : guestCount // ignore: cast_nullable_to_non_nullable
                      as int,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
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
    @JsonKey(name: 'guest_id') String guestId,
    @JsonKey(name: 'check_in') DateTime checkIn,
    @JsonKey(name: 'check_out') DateTime checkOut,
    BookingStatus status,
    @JsonKey(name: 'total_price') double totalPrice,
    @JsonKey(name: 'paid_amount') double paidAmount,
    @JsonKey(name: 'guest_count') int guestCount,
    String? notes,
    @JsonKey(name: 'payment_intent_id') String? paymentIntentId,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'cancellation_reason') String? cancellationReason,
    @JsonKey(name: 'cancelled_at') DateTime? cancelledAt,
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
    Object? guestId = null,
    Object? checkIn = null,
    Object? checkOut = null,
    Object? status = null,
    Object? totalPrice = null,
    Object? paidAmount = null,
    Object? guestCount = null,
    Object? notes = freezed,
    Object? paymentIntentId = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? cancellationReason = freezed,
    Object? cancelledAt = freezed,
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
        guestId: null == guestId
            ? _value.guestId
            : guestId // ignore: cast_nullable_to_non_nullable
                  as String,
        checkIn: null == checkIn
            ? _value.checkIn
            : checkIn // ignore: cast_nullable_to_non_nullable
                  as DateTime,
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
        guestCount: null == guestCount
            ? _value.guestCount
            : guestCount // ignore: cast_nullable_to_non_nullable
                  as int,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
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
    @JsonKey(name: 'guest_id') required this.guestId,
    @JsonKey(name: 'check_in') required this.checkIn,
    @JsonKey(name: 'check_out') required this.checkOut,
    required this.status,
    @JsonKey(name: 'total_price') required this.totalPrice,
    @JsonKey(name: 'paid_amount') required this.paidAmount,
    @JsonKey(name: 'guest_count') required this.guestCount,
    this.notes,
    @JsonKey(name: 'payment_intent_id') this.paymentIntentId,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
    @JsonKey(name: 'cancellation_reason') this.cancellationReason,
    @JsonKey(name: 'cancelled_at') this.cancelledAt,
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

  /// Guest user ID
  @override
  @JsonKey(name: 'guest_id')
  final String guestId;

  /// Check-in date
  @override
  @JsonKey(name: 'check_in')
  final DateTime checkIn;

  /// Check-out date
  @override
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

  /// Number of guests
  @override
  @JsonKey(name: 'guest_count')
  final int guestCount;

  /// Special requests or notes
  @override
  final String? notes;

  /// Stripe payment intent ID
  @override
  @JsonKey(name: 'payment_intent_id')
  final String? paymentIntentId;

  /// Booking creation timestamp
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Last update timestamp
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Cancellation reason (if cancelled)
  @override
  @JsonKey(name: 'cancellation_reason')
  final String? cancellationReason;

  /// Cancelled at timestamp
  @override
  @JsonKey(name: 'cancelled_at')
  final DateTime? cancelledAt;

  @override
  String toString() {
    return 'BookingModel(id: $id, unitId: $unitId, guestId: $guestId, checkIn: $checkIn, checkOut: $checkOut, status: $status, totalPrice: $totalPrice, paidAmount: $paidAmount, guestCount: $guestCount, notes: $notes, paymentIntentId: $paymentIntentId, createdAt: $createdAt, updatedAt: $updatedAt, cancellationReason: $cancellationReason, cancelledAt: $cancelledAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookingModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.unitId, unitId) || other.unitId == unitId) &&
            (identical(other.guestId, guestId) || other.guestId == guestId) &&
            (identical(other.checkIn, checkIn) || other.checkIn == checkIn) &&
            (identical(other.checkOut, checkOut) ||
                other.checkOut == checkOut) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.totalPrice, totalPrice) ||
                other.totalPrice == totalPrice) &&
            (identical(other.paidAmount, paidAmount) ||
                other.paidAmount == paidAmount) &&
            (identical(other.guestCount, guestCount) ||
                other.guestCount == guestCount) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.paymentIntentId, paymentIntentId) ||
                other.paymentIntentId == paymentIntentId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.cancellationReason, cancellationReason) ||
                other.cancellationReason == cancellationReason) &&
            (identical(other.cancelledAt, cancelledAt) ||
                other.cancelledAt == cancelledAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    unitId,
    guestId,
    checkIn,
    checkOut,
    status,
    totalPrice,
    paidAmount,
    guestCount,
    notes,
    paymentIntentId,
    createdAt,
    updatedAt,
    cancellationReason,
    cancelledAt,
  );

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
    @JsonKey(name: 'guest_id') required final String guestId,
    @JsonKey(name: 'check_in') required final DateTime checkIn,
    @JsonKey(name: 'check_out') required final DateTime checkOut,
    required final BookingStatus status,
    @JsonKey(name: 'total_price') required final double totalPrice,
    @JsonKey(name: 'paid_amount') required final double paidAmount,
    @JsonKey(name: 'guest_count') required final int guestCount,
    final String? notes,
    @JsonKey(name: 'payment_intent_id') final String? paymentIntentId,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
    @JsonKey(name: 'cancellation_reason') final String? cancellationReason,
    @JsonKey(name: 'cancelled_at') final DateTime? cancelledAt,
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

  /// Guest user ID
  @override
  @JsonKey(name: 'guest_id')
  String get guestId;

  /// Check-in date
  @override
  @JsonKey(name: 'check_in')
  DateTime get checkIn;

  /// Check-out date
  @override
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

  /// Number of guests
  @override
  @JsonKey(name: 'guest_count')
  int get guestCount;

  /// Special requests or notes
  @override
  String? get notes;

  /// Stripe payment intent ID
  @override
  @JsonKey(name: 'payment_intent_id')
  String? get paymentIntentId;

  /// Booking creation timestamp
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Last update timestamp
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Cancellation reason (if cancelled)
  @override
  @JsonKey(name: 'cancellation_reason')
  String? get cancellationReason;

  /// Cancelled at timestamp
  @override
  @JsonKey(name: 'cancelled_at')
  DateTime? get cancelledAt;

  /// Create a copy of BookingModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookingModelImplCopyWith<_$BookingModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
