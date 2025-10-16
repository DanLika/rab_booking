// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PaymentState {
  // Payment intent
  PaymentIntentModel? get paymentIntent =>
      throw _privateConstructorUsedError; // Payment record
  PaymentRecord? get paymentRecord =>
      throw _privateConstructorUsedError; // Processing state
  bool get isProcessing => throw _privateConstructorUsedError;
  bool get isSuccess => throw _privateConstructorUsedError;
  bool get isFailed => throw _privateConstructorUsedError; // Error handling
  String? get error =>
      throw _privateConstructorUsedError; // Stripe payment intent status
  String? get paymentStatus => throw _privateConstructorUsedError;

  /// Create a copy of PaymentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentStateCopyWith<PaymentState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentStateCopyWith<$Res> {
  factory $PaymentStateCopyWith(
    PaymentState value,
    $Res Function(PaymentState) then,
  ) = _$PaymentStateCopyWithImpl<$Res, PaymentState>;
  @useResult
  $Res call({
    PaymentIntentModel? paymentIntent,
    PaymentRecord? paymentRecord,
    bool isProcessing,
    bool isSuccess,
    bool isFailed,
    String? error,
    String? paymentStatus,
  });

  $PaymentIntentModelCopyWith<$Res>? get paymentIntent;
  $PaymentRecordCopyWith<$Res>? get paymentRecord;
}

/// @nodoc
class _$PaymentStateCopyWithImpl<$Res, $Val extends PaymentState>
    implements $PaymentStateCopyWith<$Res> {
  _$PaymentStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? paymentIntent = freezed,
    Object? paymentRecord = freezed,
    Object? isProcessing = null,
    Object? isSuccess = null,
    Object? isFailed = null,
    Object? error = freezed,
    Object? paymentStatus = freezed,
  }) {
    return _then(
      _value.copyWith(
            paymentIntent:
                freezed == paymentIntent
                    ? _value.paymentIntent
                    : paymentIntent // ignore: cast_nullable_to_non_nullable
                        as PaymentIntentModel?,
            paymentRecord:
                freezed == paymentRecord
                    ? _value.paymentRecord
                    : paymentRecord // ignore: cast_nullable_to_non_nullable
                        as PaymentRecord?,
            isProcessing:
                null == isProcessing
                    ? _value.isProcessing
                    : isProcessing // ignore: cast_nullable_to_non_nullable
                        as bool,
            isSuccess:
                null == isSuccess
                    ? _value.isSuccess
                    : isSuccess // ignore: cast_nullable_to_non_nullable
                        as bool,
            isFailed:
                null == isFailed
                    ? _value.isFailed
                    : isFailed // ignore: cast_nullable_to_non_nullable
                        as bool,
            error:
                freezed == error
                    ? _value.error
                    : error // ignore: cast_nullable_to_non_nullable
                        as String?,
            paymentStatus:
                freezed == paymentStatus
                    ? _value.paymentStatus
                    : paymentStatus // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of PaymentState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PaymentIntentModelCopyWith<$Res>? get paymentIntent {
    if (_value.paymentIntent == null) {
      return null;
    }

    return $PaymentIntentModelCopyWith<$Res>(_value.paymentIntent!, (value) {
      return _then(_value.copyWith(paymentIntent: value) as $Val);
    });
  }

  /// Create a copy of PaymentState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PaymentRecordCopyWith<$Res>? get paymentRecord {
    if (_value.paymentRecord == null) {
      return null;
    }

    return $PaymentRecordCopyWith<$Res>(_value.paymentRecord!, (value) {
      return _then(_value.copyWith(paymentRecord: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PaymentStateImplCopyWith<$Res>
    implements $PaymentStateCopyWith<$Res> {
  factory _$$PaymentStateImplCopyWith(
    _$PaymentStateImpl value,
    $Res Function(_$PaymentStateImpl) then,
  ) = __$$PaymentStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    PaymentIntentModel? paymentIntent,
    PaymentRecord? paymentRecord,
    bool isProcessing,
    bool isSuccess,
    bool isFailed,
    String? error,
    String? paymentStatus,
  });

  @override
  $PaymentIntentModelCopyWith<$Res>? get paymentIntent;
  @override
  $PaymentRecordCopyWith<$Res>? get paymentRecord;
}

/// @nodoc
class __$$PaymentStateImplCopyWithImpl<$Res>
    extends _$PaymentStateCopyWithImpl<$Res, _$PaymentStateImpl>
    implements _$$PaymentStateImplCopyWith<$Res> {
  __$$PaymentStateImplCopyWithImpl(
    _$PaymentStateImpl _value,
    $Res Function(_$PaymentStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PaymentState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? paymentIntent = freezed,
    Object? paymentRecord = freezed,
    Object? isProcessing = null,
    Object? isSuccess = null,
    Object? isFailed = null,
    Object? error = freezed,
    Object? paymentStatus = freezed,
  }) {
    return _then(
      _$PaymentStateImpl(
        paymentIntent:
            freezed == paymentIntent
                ? _value.paymentIntent
                : paymentIntent // ignore: cast_nullable_to_non_nullable
                    as PaymentIntentModel?,
        paymentRecord:
            freezed == paymentRecord
                ? _value.paymentRecord
                : paymentRecord // ignore: cast_nullable_to_non_nullable
                    as PaymentRecord?,
        isProcessing:
            null == isProcessing
                ? _value.isProcessing
                : isProcessing // ignore: cast_nullable_to_non_nullable
                    as bool,
        isSuccess:
            null == isSuccess
                ? _value.isSuccess
                : isSuccess // ignore: cast_nullable_to_non_nullable
                    as bool,
        isFailed:
            null == isFailed
                ? _value.isFailed
                : isFailed // ignore: cast_nullable_to_non_nullable
                    as bool,
        error:
            freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                    as String?,
        paymentStatus:
            freezed == paymentStatus
                ? _value.paymentStatus
                : paymentStatus // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc

class _$PaymentStateImpl implements _PaymentState {
  const _$PaymentStateImpl({
    this.paymentIntent,
    this.paymentRecord,
    this.isProcessing = false,
    this.isSuccess = false,
    this.isFailed = false,
    this.error,
    this.paymentStatus,
  });

  // Payment intent
  @override
  final PaymentIntentModel? paymentIntent;
  // Payment record
  @override
  final PaymentRecord? paymentRecord;
  // Processing state
  @override
  @JsonKey()
  final bool isProcessing;
  @override
  @JsonKey()
  final bool isSuccess;
  @override
  @JsonKey()
  final bool isFailed;
  // Error handling
  @override
  final String? error;
  // Stripe payment intent status
  @override
  final String? paymentStatus;

  @override
  String toString() {
    return 'PaymentState(paymentIntent: $paymentIntent, paymentRecord: $paymentRecord, isProcessing: $isProcessing, isSuccess: $isSuccess, isFailed: $isFailed, error: $error, paymentStatus: $paymentStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentStateImpl &&
            (identical(other.paymentIntent, paymentIntent) ||
                other.paymentIntent == paymentIntent) &&
            (identical(other.paymentRecord, paymentRecord) ||
                other.paymentRecord == paymentRecord) &&
            (identical(other.isProcessing, isProcessing) ||
                other.isProcessing == isProcessing) &&
            (identical(other.isSuccess, isSuccess) ||
                other.isSuccess == isSuccess) &&
            (identical(other.isFailed, isFailed) ||
                other.isFailed == isFailed) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    paymentIntent,
    paymentRecord,
    isProcessing,
    isSuccess,
    isFailed,
    error,
    paymentStatus,
  );

  /// Create a copy of PaymentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentStateImplCopyWith<_$PaymentStateImpl> get copyWith =>
      __$$PaymentStateImplCopyWithImpl<_$PaymentStateImpl>(this, _$identity);
}

abstract class _PaymentState implements PaymentState {
  const factory _PaymentState({
    final PaymentIntentModel? paymentIntent,
    final PaymentRecord? paymentRecord,
    final bool isProcessing,
    final bool isSuccess,
    final bool isFailed,
    final String? error,
    final String? paymentStatus,
  }) = _$PaymentStateImpl;

  // Payment intent
  @override
  PaymentIntentModel? get paymentIntent; // Payment record
  @override
  PaymentRecord? get paymentRecord; // Processing state
  @override
  bool get isProcessing;
  @override
  bool get isSuccess;
  @override
  bool get isFailed; // Error handling
  @override
  String? get error; // Stripe payment intent status
  @override
  String? get paymentStatus;

  /// Create a copy of PaymentState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentStateImplCopyWith<_$PaymentStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
