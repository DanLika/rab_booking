// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PaymentRecord _$PaymentRecordFromJson(Map<String, dynamic> json) {
  return _PaymentRecord.fromJson(json);
}

/// @nodoc
mixin _$PaymentRecord {
  String get id => throw _privateConstructorUsedError;
  String get bookingId => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // pending, completed, failed, refunded
  String get stripePaymentId => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String? get stripeChargeId => throw _privateConstructorUsedError;
  String? get receiptUrl => throw _privateConstructorUsedError;
  String? get failureMessage => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this PaymentRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PaymentRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentRecordCopyWith<PaymentRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentRecordCopyWith<$Res> {
  factory $PaymentRecordCopyWith(
    PaymentRecord value,
    $Res Function(PaymentRecord) then,
  ) = _$PaymentRecordCopyWithImpl<$Res, PaymentRecord>;
  @useResult
  $Res call({
    String id,
    String bookingId,
    int amount,
    String status,
    String stripePaymentId,
    String currency,
    String? stripeChargeId,
    String? receiptUrl,
    String? failureMessage,
    DateTime createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$PaymentRecordCopyWithImpl<$Res, $Val extends PaymentRecord>
    implements $PaymentRecordCopyWith<$Res> {
  _$PaymentRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? bookingId = null,
    Object? amount = null,
    Object? status = null,
    Object? stripePaymentId = null,
    Object? currency = null,
    Object? stripeChargeId = freezed,
    Object? receiptUrl = freezed,
    Object? failureMessage = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            bookingId:
                null == bookingId
                    ? _value.bookingId
                    : bookingId // ignore: cast_nullable_to_non_nullable
                        as String,
            amount:
                null == amount
                    ? _value.amount
                    : amount // ignore: cast_nullable_to_non_nullable
                        as int,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            stripePaymentId:
                null == stripePaymentId
                    ? _value.stripePaymentId
                    : stripePaymentId // ignore: cast_nullable_to_non_nullable
                        as String,
            currency:
                null == currency
                    ? _value.currency
                    : currency // ignore: cast_nullable_to_non_nullable
                        as String,
            stripeChargeId:
                freezed == stripeChargeId
                    ? _value.stripeChargeId
                    : stripeChargeId // ignore: cast_nullable_to_non_nullable
                        as String?,
            receiptUrl:
                freezed == receiptUrl
                    ? _value.receiptUrl
                    : receiptUrl // ignore: cast_nullable_to_non_nullable
                        as String?,
            failureMessage:
                freezed == failureMessage
                    ? _value.failureMessage
                    : failureMessage // ignore: cast_nullable_to_non_nullable
                        as String?,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            updatedAt:
                freezed == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaymentRecordImplCopyWith<$Res>
    implements $PaymentRecordCopyWith<$Res> {
  factory _$$PaymentRecordImplCopyWith(
    _$PaymentRecordImpl value,
    $Res Function(_$PaymentRecordImpl) then,
  ) = __$$PaymentRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String bookingId,
    int amount,
    String status,
    String stripePaymentId,
    String currency,
    String? stripeChargeId,
    String? receiptUrl,
    String? failureMessage,
    DateTime createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$PaymentRecordImplCopyWithImpl<$Res>
    extends _$PaymentRecordCopyWithImpl<$Res, _$PaymentRecordImpl>
    implements _$$PaymentRecordImplCopyWith<$Res> {
  __$$PaymentRecordImplCopyWithImpl(
    _$PaymentRecordImpl _value,
    $Res Function(_$PaymentRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PaymentRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? bookingId = null,
    Object? amount = null,
    Object? status = null,
    Object? stripePaymentId = null,
    Object? currency = null,
    Object? stripeChargeId = freezed,
    Object? receiptUrl = freezed,
    Object? failureMessage = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$PaymentRecordImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        bookingId:
            null == bookingId
                ? _value.bookingId
                : bookingId // ignore: cast_nullable_to_non_nullable
                    as String,
        amount:
            null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                    as int,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        stripePaymentId:
            null == stripePaymentId
                ? _value.stripePaymentId
                : stripePaymentId // ignore: cast_nullable_to_non_nullable
                    as String,
        currency:
            null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                    as String,
        stripeChargeId:
            freezed == stripeChargeId
                ? _value.stripeChargeId
                : stripeChargeId // ignore: cast_nullable_to_non_nullable
                    as String?,
        receiptUrl:
            freezed == receiptUrl
                ? _value.receiptUrl
                : receiptUrl // ignore: cast_nullable_to_non_nullable
                    as String?,
        failureMessage:
            freezed == failureMessage
                ? _value.failureMessage
                : failureMessage // ignore: cast_nullable_to_non_nullable
                    as String?,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        updatedAt:
            freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentRecordImpl implements _PaymentRecord {
  const _$PaymentRecordImpl({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.stripePaymentId,
    this.currency = 'eur',
    this.stripeChargeId,
    this.receiptUrl,
    this.failureMessage,
    required this.createdAt,
    this.updatedAt,
  });

  factory _$PaymentRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentRecordImplFromJson(json);

  @override
  final String id;
  @override
  final String bookingId;
  @override
  final int amount;
  @override
  final String status;
  // pending, completed, failed, refunded
  @override
  final String stripePaymentId;
  @override
  @JsonKey()
  final String currency;
  @override
  final String? stripeChargeId;
  @override
  final String? receiptUrl;
  @override
  final String? failureMessage;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'PaymentRecord(id: $id, bookingId: $bookingId, amount: $amount, status: $status, stripePaymentId: $stripePaymentId, currency: $currency, stripeChargeId: $stripeChargeId, receiptUrl: $receiptUrl, failureMessage: $failureMessage, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookingId, bookingId) ||
                other.bookingId == bookingId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.stripePaymentId, stripePaymentId) ||
                other.stripePaymentId == stripePaymentId) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.stripeChargeId, stripeChargeId) ||
                other.stripeChargeId == stripeChargeId) &&
            (identical(other.receiptUrl, receiptUrl) ||
                other.receiptUrl == receiptUrl) &&
            (identical(other.failureMessage, failureMessage) ||
                other.failureMessage == failureMessage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    bookingId,
    amount,
    status,
    stripePaymentId,
    currency,
    stripeChargeId,
    receiptUrl,
    failureMessage,
    createdAt,
    updatedAt,
  );

  /// Create a copy of PaymentRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentRecordImplCopyWith<_$PaymentRecordImpl> get copyWith =>
      __$$PaymentRecordImplCopyWithImpl<_$PaymentRecordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentRecordImplToJson(this);
  }
}

abstract class _PaymentRecord implements PaymentRecord {
  const factory _PaymentRecord({
    required final String id,
    required final String bookingId,
    required final int amount,
    required final String status,
    required final String stripePaymentId,
    final String currency,
    final String? stripeChargeId,
    final String? receiptUrl,
    final String? failureMessage,
    required final DateTime createdAt,
    final DateTime? updatedAt,
  }) = _$PaymentRecordImpl;

  factory _PaymentRecord.fromJson(Map<String, dynamic> json) =
      _$PaymentRecordImpl.fromJson;

  @override
  String get id;
  @override
  String get bookingId;
  @override
  int get amount;
  @override
  String get status; // pending, completed, failed, refunded
  @override
  String get stripePaymentId;
  @override
  String get currency;
  @override
  String? get stripeChargeId;
  @override
  String? get receiptUrl;
  @override
  String? get failureMessage;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of PaymentRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentRecordImplCopyWith<_$PaymentRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
