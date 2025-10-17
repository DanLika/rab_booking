// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_intent_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaymentIntentModel {

 String get clientSecret; String get paymentIntentId; int get amount; String get currency; String? get bookingId;
/// Create a copy of PaymentIntentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentIntentModelCopyWith<PaymentIntentModel> get copyWith => _$PaymentIntentModelCopyWithImpl<PaymentIntentModel>(this as PaymentIntentModel, _$identity);

  /// Serializes this PaymentIntentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentIntentModel&&(identical(other.clientSecret, clientSecret) || other.clientSecret == clientSecret)&&(identical(other.paymentIntentId, paymentIntentId) || other.paymentIntentId == paymentIntentId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientSecret,paymentIntentId,amount,currency,bookingId);

@override
String toString() {
  return 'PaymentIntentModel(clientSecret: $clientSecret, paymentIntentId: $paymentIntentId, amount: $amount, currency: $currency, bookingId: $bookingId)';
}


}

/// @nodoc
abstract mixin class $PaymentIntentModelCopyWith<$Res>  {
  factory $PaymentIntentModelCopyWith(PaymentIntentModel value, $Res Function(PaymentIntentModel) _then) = _$PaymentIntentModelCopyWithImpl;
@useResult
$Res call({
 String clientSecret, String paymentIntentId, int amount, String currency, String? bookingId
});




}
/// @nodoc
class _$PaymentIntentModelCopyWithImpl<$Res>
    implements $PaymentIntentModelCopyWith<$Res> {
  _$PaymentIntentModelCopyWithImpl(this._self, this._then);

  final PaymentIntentModel _self;
  final $Res Function(PaymentIntentModel) _then;

/// Create a copy of PaymentIntentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientSecret = null,Object? paymentIntentId = null,Object? amount = null,Object? currency = null,Object? bookingId = freezed,}) {
  return _then(_self.copyWith(
clientSecret: null == clientSecret ? _self.clientSecret : clientSecret // ignore: cast_nullable_to_non_nullable
as String,paymentIntentId: null == paymentIntentId ? _self.paymentIntentId : paymentIntentId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentIntentModel].
extension PaymentIntentModelPatterns on PaymentIntentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentIntentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentIntentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentIntentModel value)  $default,){
final _that = this;
switch (_that) {
case _PaymentIntentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentIntentModel value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentIntentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientSecret,  String paymentIntentId,  int amount,  String currency,  String? bookingId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentIntentModel() when $default != null:
return $default(_that.clientSecret,_that.paymentIntentId,_that.amount,_that.currency,_that.bookingId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientSecret,  String paymentIntentId,  int amount,  String currency,  String? bookingId)  $default,) {final _that = this;
switch (_that) {
case _PaymentIntentModel():
return $default(_that.clientSecret,_that.paymentIntentId,_that.amount,_that.currency,_that.bookingId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientSecret,  String paymentIntentId,  int amount,  String currency,  String? bookingId)?  $default,) {final _that = this;
switch (_that) {
case _PaymentIntentModel() when $default != null:
return $default(_that.clientSecret,_that.paymentIntentId,_that.amount,_that.currency,_that.bookingId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentIntentModel implements PaymentIntentModel {
  const _PaymentIntentModel({required this.clientSecret, required this.paymentIntentId, required this.amount, this.currency = 'eur', this.bookingId});
  factory _PaymentIntentModel.fromJson(Map<String, dynamic> json) => _$PaymentIntentModelFromJson(json);

@override final  String clientSecret;
@override final  String paymentIntentId;
@override final  int amount;
@override@JsonKey() final  String currency;
@override final  String? bookingId;

/// Create a copy of PaymentIntentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentIntentModelCopyWith<_PaymentIntentModel> get copyWith => __$PaymentIntentModelCopyWithImpl<_PaymentIntentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentIntentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentIntentModel&&(identical(other.clientSecret, clientSecret) || other.clientSecret == clientSecret)&&(identical(other.paymentIntentId, paymentIntentId) || other.paymentIntentId == paymentIntentId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientSecret,paymentIntentId,amount,currency,bookingId);

@override
String toString() {
  return 'PaymentIntentModel(clientSecret: $clientSecret, paymentIntentId: $paymentIntentId, amount: $amount, currency: $currency, bookingId: $bookingId)';
}


}

/// @nodoc
abstract mixin class _$PaymentIntentModelCopyWith<$Res> implements $PaymentIntentModelCopyWith<$Res> {
  factory _$PaymentIntentModelCopyWith(_PaymentIntentModel value, $Res Function(_PaymentIntentModel) _then) = __$PaymentIntentModelCopyWithImpl;
@override @useResult
$Res call({
 String clientSecret, String paymentIntentId, int amount, String currency, String? bookingId
});




}
/// @nodoc
class __$PaymentIntentModelCopyWithImpl<$Res>
    implements _$PaymentIntentModelCopyWith<$Res> {
  __$PaymentIntentModelCopyWithImpl(this._self, this._then);

  final _PaymentIntentModel _self;
  final $Res Function(_PaymentIntentModel) _then;

/// Create a copy of PaymentIntentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientSecret = null,Object? paymentIntentId = null,Object? amount = null,Object? currency = null,Object? bookingId = freezed,}) {
  return _then(_PaymentIntentModel(
clientSecret: null == clientSecret ? _self.clientSecret : clientSecret // ignore: cast_nullable_to_non_nullable
as String,paymentIntentId: null == paymentIntentId ? _self.paymentIntentId : paymentIntentId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
