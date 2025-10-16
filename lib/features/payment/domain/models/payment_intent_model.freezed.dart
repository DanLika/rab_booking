// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_intent_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PaymentIntentModel _$PaymentIntentModelFromJson(Map<String, dynamic> json) {
  return _PaymentIntentModel.fromJson(json);
}

/// @nodoc
mixin _$PaymentIntentModel {
  String get clientSecret => throw _privateConstructorUsedError;
  String get paymentIntentId => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String? get bookingId => throw _privateConstructorUsedError;

  /// Serializes this PaymentIntentModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PaymentIntentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentIntentModelCopyWith<PaymentIntentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentIntentModelCopyWith<$Res> {
  factory $PaymentIntentModelCopyWith(
    PaymentIntentModel value,
    $Res Function(PaymentIntentModel) then,
  ) = _$PaymentIntentModelCopyWithImpl<$Res, PaymentIntentModel>;
  @useResult
  $Res call({
    String clientSecret,
    String paymentIntentId,
    int amount,
    String currency,
    String? bookingId,
  });
}

/// @nodoc
class _$PaymentIntentModelCopyWithImpl<$Res, $Val extends PaymentIntentModel>
    implements $PaymentIntentModelCopyWith<$Res> {
  _$PaymentIntentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentIntentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? clientSecret = null,
    Object? paymentIntentId = null,
    Object? amount = null,
    Object? currency = null,
    Object? bookingId = freezed,
  }) {
    return _then(
      _value.copyWith(
            clientSecret:
                null == clientSecret
                    ? _value.clientSecret
                    : clientSecret // ignore: cast_nullable_to_non_nullable
                        as String,
            paymentIntentId:
                null == paymentIntentId
                    ? _value.paymentIntentId
                    : paymentIntentId // ignore: cast_nullable_to_non_nullable
                        as String,
            amount:
                null == amount
                    ? _value.amount
                    : amount // ignore: cast_nullable_to_non_nullable
                        as int,
            currency:
                null == currency
                    ? _value.currency
                    : currency // ignore: cast_nullable_to_non_nullable
                        as String,
            bookingId:
                freezed == bookingId
                    ? _value.bookingId
                    : bookingId // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaymentIntentModelImplCopyWith<$Res>
    implements $PaymentIntentModelCopyWith<$Res> {
  factory _$$PaymentIntentModelImplCopyWith(
    _$PaymentIntentModelImpl value,
    $Res Function(_$PaymentIntentModelImpl) then,
  ) = __$$PaymentIntentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String clientSecret,
    String paymentIntentId,
    int amount,
    String currency,
    String? bookingId,
  });
}

/// @nodoc
class __$$PaymentIntentModelImplCopyWithImpl<$Res>
    extends _$PaymentIntentModelCopyWithImpl<$Res, _$PaymentIntentModelImpl>
    implements _$$PaymentIntentModelImplCopyWith<$Res> {
  __$$PaymentIntentModelImplCopyWithImpl(
    _$PaymentIntentModelImpl _value,
    $Res Function(_$PaymentIntentModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PaymentIntentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? clientSecret = null,
    Object? paymentIntentId = null,
    Object? amount = null,
    Object? currency = null,
    Object? bookingId = freezed,
  }) {
    return _then(
      _$PaymentIntentModelImpl(
        clientSecret:
            null == clientSecret
                ? _value.clientSecret
                : clientSecret // ignore: cast_nullable_to_non_nullable
                    as String,
        paymentIntentId:
            null == paymentIntentId
                ? _value.paymentIntentId
                : paymentIntentId // ignore: cast_nullable_to_non_nullable
                    as String,
        amount:
            null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                    as int,
        currency:
            null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                    as String,
        bookingId:
            freezed == bookingId
                ? _value.bookingId
                : bookingId // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentIntentModelImpl implements _PaymentIntentModel {
  const _$PaymentIntentModelImpl({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.amount,
    this.currency = 'eur',
    this.bookingId,
  });

  factory _$PaymentIntentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentIntentModelImplFromJson(json);

  @override
  final String clientSecret;
  @override
  final String paymentIntentId;
  @override
  final int amount;
  @override
  @JsonKey()
  final String currency;
  @override
  final String? bookingId;

  @override
  String toString() {
    return 'PaymentIntentModel(clientSecret: $clientSecret, paymentIntentId: $paymentIntentId, amount: $amount, currency: $currency, bookingId: $bookingId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentIntentModelImpl &&
            (identical(other.clientSecret, clientSecret) ||
                other.clientSecret == clientSecret) &&
            (identical(other.paymentIntentId, paymentIntentId) ||
                other.paymentIntentId == paymentIntentId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.bookingId, bookingId) ||
                other.bookingId == bookingId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    clientSecret,
    paymentIntentId,
    amount,
    currency,
    bookingId,
  );

  /// Create a copy of PaymentIntentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentIntentModelImplCopyWith<_$PaymentIntentModelImpl> get copyWith =>
      __$$PaymentIntentModelImplCopyWithImpl<_$PaymentIntentModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentIntentModelImplToJson(this);
  }
}

abstract class _PaymentIntentModel implements PaymentIntentModel {
  const factory _PaymentIntentModel({
    required final String clientSecret,
    required final String paymentIntentId,
    required final int amount,
    final String currency,
    final String? bookingId,
  }) = _$PaymentIntentModelImpl;

  factory _PaymentIntentModel.fromJson(Map<String, dynamic> json) =
      _$PaymentIntentModelImpl.fromJson;

  @override
  String get clientSecret;
  @override
  String get paymentIntentId;
  @override
  int get amount;
  @override
  String get currency;
  @override
  String? get bookingId;

  /// Create a copy of PaymentIntentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentIntentModelImplCopyWith<_$PaymentIntentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
