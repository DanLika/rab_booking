// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PaymentState {

// Payment intent
 PaymentIntentModel? get paymentIntent;// Payment record
 PaymentRecord? get paymentRecord;// Processing state
 bool get isProcessing; bool get isSuccess; bool get isFailed;// Error handling
 String? get error;// Stripe payment intent status
 String? get paymentStatus;
/// Create a copy of PaymentState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentStateCopyWith<PaymentState> get copyWith => _$PaymentStateCopyWithImpl<PaymentState>(this as PaymentState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentState&&(identical(other.paymentIntent, paymentIntent) || other.paymentIntent == paymentIntent)&&(identical(other.paymentRecord, paymentRecord) || other.paymentRecord == paymentRecord)&&(identical(other.isProcessing, isProcessing) || other.isProcessing == isProcessing)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.isFailed, isFailed) || other.isFailed == isFailed)&&(identical(other.error, error) || other.error == error)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus));
}


@override
int get hashCode => Object.hash(runtimeType,paymentIntent,paymentRecord,isProcessing,isSuccess,isFailed,error,paymentStatus);

@override
String toString() {
  return 'PaymentState(paymentIntent: $paymentIntent, paymentRecord: $paymentRecord, isProcessing: $isProcessing, isSuccess: $isSuccess, isFailed: $isFailed, error: $error, paymentStatus: $paymentStatus)';
}


}

/// @nodoc
abstract mixin class $PaymentStateCopyWith<$Res>  {
  factory $PaymentStateCopyWith(PaymentState value, $Res Function(PaymentState) _then) = _$PaymentStateCopyWithImpl;
@useResult
$Res call({
 PaymentIntentModel? paymentIntent, PaymentRecord? paymentRecord, bool isProcessing, bool isSuccess, bool isFailed, String? error, String? paymentStatus
});


$PaymentIntentModelCopyWith<$Res>? get paymentIntent;$PaymentRecordCopyWith<$Res>? get paymentRecord;

}
/// @nodoc
class _$PaymentStateCopyWithImpl<$Res>
    implements $PaymentStateCopyWith<$Res> {
  _$PaymentStateCopyWithImpl(this._self, this._then);

  final PaymentState _self;
  final $Res Function(PaymentState) _then;

/// Create a copy of PaymentState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? paymentIntent = freezed,Object? paymentRecord = freezed,Object? isProcessing = null,Object? isSuccess = null,Object? isFailed = null,Object? error = freezed,Object? paymentStatus = freezed,}) {
  return _then(_self.copyWith(
paymentIntent: freezed == paymentIntent ? _self.paymentIntent : paymentIntent // ignore: cast_nullable_to_non_nullable
as PaymentIntentModel?,paymentRecord: freezed == paymentRecord ? _self.paymentRecord : paymentRecord // ignore: cast_nullable_to_non_nullable
as PaymentRecord?,isProcessing: null == isProcessing ? _self.isProcessing : isProcessing // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,isFailed: null == isFailed ? _self.isFailed : isFailed // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,paymentStatus: freezed == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PaymentState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentIntentModelCopyWith<$Res>? get paymentIntent {
    if (_self.paymentIntent == null) {
    return null;
  }

  return $PaymentIntentModelCopyWith<$Res>(_self.paymentIntent!, (value) {
    return _then(_self.copyWith(paymentIntent: value));
  });
}/// Create a copy of PaymentState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentRecordCopyWith<$Res>? get paymentRecord {
    if (_self.paymentRecord == null) {
    return null;
  }

  return $PaymentRecordCopyWith<$Res>(_self.paymentRecord!, (value) {
    return _then(_self.copyWith(paymentRecord: value));
  });
}
}


/// Adds pattern-matching-related methods to [PaymentState].
extension PaymentStatePatterns on PaymentState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentState value)  $default,){
final _that = this;
switch (_that) {
case _PaymentState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentState value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PaymentIntentModel? paymentIntent,  PaymentRecord? paymentRecord,  bool isProcessing,  bool isSuccess,  bool isFailed,  String? error,  String? paymentStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentState() when $default != null:
return $default(_that.paymentIntent,_that.paymentRecord,_that.isProcessing,_that.isSuccess,_that.isFailed,_that.error,_that.paymentStatus);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PaymentIntentModel? paymentIntent,  PaymentRecord? paymentRecord,  bool isProcessing,  bool isSuccess,  bool isFailed,  String? error,  String? paymentStatus)  $default,) {final _that = this;
switch (_that) {
case _PaymentState():
return $default(_that.paymentIntent,_that.paymentRecord,_that.isProcessing,_that.isSuccess,_that.isFailed,_that.error,_that.paymentStatus);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PaymentIntentModel? paymentIntent,  PaymentRecord? paymentRecord,  bool isProcessing,  bool isSuccess,  bool isFailed,  String? error,  String? paymentStatus)?  $default,) {final _that = this;
switch (_that) {
case _PaymentState() when $default != null:
return $default(_that.paymentIntent,_that.paymentRecord,_that.isProcessing,_that.isSuccess,_that.isFailed,_that.error,_that.paymentStatus);case _:
  return null;

}
}

}

/// @nodoc


class _PaymentState implements PaymentState {
  const _PaymentState({this.paymentIntent, this.paymentRecord, this.isProcessing = false, this.isSuccess = false, this.isFailed = false, this.error, this.paymentStatus});
  

// Payment intent
@override final  PaymentIntentModel? paymentIntent;
// Payment record
@override final  PaymentRecord? paymentRecord;
// Processing state
@override@JsonKey() final  bool isProcessing;
@override@JsonKey() final  bool isSuccess;
@override@JsonKey() final  bool isFailed;
// Error handling
@override final  String? error;
// Stripe payment intent status
@override final  String? paymentStatus;

/// Create a copy of PaymentState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentStateCopyWith<_PaymentState> get copyWith => __$PaymentStateCopyWithImpl<_PaymentState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentState&&(identical(other.paymentIntent, paymentIntent) || other.paymentIntent == paymentIntent)&&(identical(other.paymentRecord, paymentRecord) || other.paymentRecord == paymentRecord)&&(identical(other.isProcessing, isProcessing) || other.isProcessing == isProcessing)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.isFailed, isFailed) || other.isFailed == isFailed)&&(identical(other.error, error) || other.error == error)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus));
}


@override
int get hashCode => Object.hash(runtimeType,paymentIntent,paymentRecord,isProcessing,isSuccess,isFailed,error,paymentStatus);

@override
String toString() {
  return 'PaymentState(paymentIntent: $paymentIntent, paymentRecord: $paymentRecord, isProcessing: $isProcessing, isSuccess: $isSuccess, isFailed: $isFailed, error: $error, paymentStatus: $paymentStatus)';
}


}

/// @nodoc
abstract mixin class _$PaymentStateCopyWith<$Res> implements $PaymentStateCopyWith<$Res> {
  factory _$PaymentStateCopyWith(_PaymentState value, $Res Function(_PaymentState) _then) = __$PaymentStateCopyWithImpl;
@override @useResult
$Res call({
 PaymentIntentModel? paymentIntent, PaymentRecord? paymentRecord, bool isProcessing, bool isSuccess, bool isFailed, String? error, String? paymentStatus
});


@override $PaymentIntentModelCopyWith<$Res>? get paymentIntent;@override $PaymentRecordCopyWith<$Res>? get paymentRecord;

}
/// @nodoc
class __$PaymentStateCopyWithImpl<$Res>
    implements _$PaymentStateCopyWith<$Res> {
  __$PaymentStateCopyWithImpl(this._self, this._then);

  final _PaymentState _self;
  final $Res Function(_PaymentState) _then;

/// Create a copy of PaymentState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? paymentIntent = freezed,Object? paymentRecord = freezed,Object? isProcessing = null,Object? isSuccess = null,Object? isFailed = null,Object? error = freezed,Object? paymentStatus = freezed,}) {
  return _then(_PaymentState(
paymentIntent: freezed == paymentIntent ? _self.paymentIntent : paymentIntent // ignore: cast_nullable_to_non_nullable
as PaymentIntentModel?,paymentRecord: freezed == paymentRecord ? _self.paymentRecord : paymentRecord // ignore: cast_nullable_to_non_nullable
as PaymentRecord?,isProcessing: null == isProcessing ? _self.isProcessing : isProcessing // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,isFailed: null == isFailed ? _self.isFailed : isFailed // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,paymentStatus: freezed == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PaymentState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentIntentModelCopyWith<$Res>? get paymentIntent {
    if (_self.paymentIntent == null) {
    return null;
  }

  return $PaymentIntentModelCopyWith<$Res>(_self.paymentIntent!, (value) {
    return _then(_self.copyWith(paymentIntent: value));
  });
}/// Create a copy of PaymentState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentRecordCopyWith<$Res>? get paymentRecord {
    if (_self.paymentRecord == null) {
    return null;
  }

  return $PaymentRecordCopyWith<$Res>(_self.paymentRecord!, (value) {
    return _then(_self.copyWith(paymentRecord: value));
  });
}
}

// dart format on
