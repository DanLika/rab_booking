// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookingModel {

/// Booking ID (UUID)
 String get id;/// Unit being booked
 String get unitId;/// Guest user ID
 String get guestId;/// Check-in date
 DateTime get checkIn;/// Check-out date
 DateTime get checkOut;/// Booking status
 BookingStatus get status;/// Total price in EUR
 double get totalPrice;/// Amount paid (advance payment - 20%)
 double get paidAmount;/// Number of guests
 int get guestCount;/// Special requests or notes
 String? get notes;/// Stripe payment intent ID
 String? get paymentIntentId;/// Booking creation timestamp
 DateTime get createdAt;/// Last update timestamp
 DateTime? get updatedAt;/// Cancellation reason (if cancelled)
 String? get cancellationReason;/// Cancelled at timestamp
 DateTime? get cancelledAt;
/// Create a copy of BookingModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingModelCopyWith<BookingModel> get copyWith => _$BookingModelCopyWithImpl<BookingModel>(this as BookingModel, _$identity);

  /// Serializes this BookingModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingModel&&(identical(other.id, id) || other.id == id)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.guestId, guestId) || other.guestId == guestId)&&(identical(other.checkIn, checkIn) || other.checkIn == checkIn)&&(identical(other.checkOut, checkOut) || other.checkOut == checkOut)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.guestCount, guestCount) || other.guestCount == guestCount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.paymentIntentId, paymentIntentId) || other.paymentIntentId == paymentIntentId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,unitId,guestId,checkIn,checkOut,status,totalPrice,paidAmount,guestCount,notes,paymentIntentId,createdAt,updatedAt,cancellationReason,cancelledAt);

@override
String toString() {
  return 'BookingModel(id: $id, unitId: $unitId, guestId: $guestId, checkIn: $checkIn, checkOut: $checkOut, status: $status, totalPrice: $totalPrice, paidAmount: $paidAmount, guestCount: $guestCount, notes: $notes, paymentIntentId: $paymentIntentId, createdAt: $createdAt, updatedAt: $updatedAt, cancellationReason: $cancellationReason, cancelledAt: $cancelledAt)';
}


}

/// @nodoc
abstract mixin class $BookingModelCopyWith<$Res>  {
  factory $BookingModelCopyWith(BookingModel value, $Res Function(BookingModel) _then) = _$BookingModelCopyWithImpl;
@useResult
$Res call({
 String id, String unitId, String guestId, DateTime checkIn, DateTime checkOut, BookingStatus status, double totalPrice, double paidAmount, int guestCount, String? notes, String? paymentIntentId, DateTime createdAt, DateTime? updatedAt, String? cancellationReason, DateTime? cancelledAt
});




}
/// @nodoc
class _$BookingModelCopyWithImpl<$Res>
    implements $BookingModelCopyWith<$Res> {
  _$BookingModelCopyWithImpl(this._self, this._then);

  final BookingModel _self;
  final $Res Function(BookingModel) _then;

/// Create a copy of BookingModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? unitId = null,Object? guestId = null,Object? checkIn = null,Object? checkOut = null,Object? status = null,Object? totalPrice = null,Object? paidAmount = null,Object? guestCount = null,Object? notes = freezed,Object? paymentIntentId = freezed,Object? createdAt = null,Object? updatedAt = freezed,Object? cancellationReason = freezed,Object? cancelledAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,guestId: null == guestId ? _self.guestId : guestId // ignore: cast_nullable_to_non_nullable
as String,checkIn: null == checkIn ? _self.checkIn : checkIn // ignore: cast_nullable_to_non_nullable
as DateTime,checkOut: null == checkOut ? _self.checkOut : checkOut // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingStatus,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as double,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double,guestCount: null == guestCount ? _self.guestCount : guestCount // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,paymentIntentId: freezed == paymentIntentId ? _self.paymentIntentId : paymentIntentId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingModel].
extension BookingModelPatterns on BookingModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String unitId,  String guestId,  DateTime checkIn,  DateTime checkOut,  BookingStatus status,  double totalPrice,  double paidAmount,  int guestCount,  String? notes,  String? paymentIntentId,  DateTime createdAt,  DateTime? updatedAt,  String? cancellationReason,  DateTime? cancelledAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingModel() when $default != null:
return $default(_that.id,_that.unitId,_that.guestId,_that.checkIn,_that.checkOut,_that.status,_that.totalPrice,_that.paidAmount,_that.guestCount,_that.notes,_that.paymentIntentId,_that.createdAt,_that.updatedAt,_that.cancellationReason,_that.cancelledAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String unitId,  String guestId,  DateTime checkIn,  DateTime checkOut,  BookingStatus status,  double totalPrice,  double paidAmount,  int guestCount,  String? notes,  String? paymentIntentId,  DateTime createdAt,  DateTime? updatedAt,  String? cancellationReason,  DateTime? cancelledAt)  $default,) {final _that = this;
switch (_that) {
case _BookingModel():
return $default(_that.id,_that.unitId,_that.guestId,_that.checkIn,_that.checkOut,_that.status,_that.totalPrice,_that.paidAmount,_that.guestCount,_that.notes,_that.paymentIntentId,_that.createdAt,_that.updatedAt,_that.cancellationReason,_that.cancelledAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String unitId,  String guestId,  DateTime checkIn,  DateTime checkOut,  BookingStatus status,  double totalPrice,  double paidAmount,  int guestCount,  String? notes,  String? paymentIntentId,  DateTime createdAt,  DateTime? updatedAt,  String? cancellationReason,  DateTime? cancelledAt)?  $default,) {final _that = this;
switch (_that) {
case _BookingModel() when $default != null:
return $default(_that.id,_that.unitId,_that.guestId,_that.checkIn,_that.checkOut,_that.status,_that.totalPrice,_that.paidAmount,_that.guestCount,_that.notes,_that.paymentIntentId,_that.createdAt,_that.updatedAt,_that.cancellationReason,_that.cancelledAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingModel extends BookingModel {
  const _BookingModel({required this.id, required this.unitId, required this.guestId, required this.checkIn, required this.checkOut, required this.status, required this.totalPrice, required this.paidAmount, required this.guestCount, this.notes, this.paymentIntentId, required this.createdAt, this.updatedAt, this.cancellationReason, this.cancelledAt}): super._();
  factory _BookingModel.fromJson(Map<String, dynamic> json) => _$BookingModelFromJson(json);

/// Booking ID (UUID)
@override final  String id;
/// Unit being booked
@override final  String unitId;
/// Guest user ID
@override final  String guestId;
/// Check-in date
@override final  DateTime checkIn;
/// Check-out date
@override final  DateTime checkOut;
/// Booking status
@override final  BookingStatus status;
/// Total price in EUR
@override final  double totalPrice;
/// Amount paid (advance payment - 20%)
@override final  double paidAmount;
/// Number of guests
@override final  int guestCount;
/// Special requests or notes
@override final  String? notes;
/// Stripe payment intent ID
@override final  String? paymentIntentId;
/// Booking creation timestamp
@override final  DateTime createdAt;
/// Last update timestamp
@override final  DateTime? updatedAt;
/// Cancellation reason (if cancelled)
@override final  String? cancellationReason;
/// Cancelled at timestamp
@override final  DateTime? cancelledAt;

/// Create a copy of BookingModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingModelCopyWith<_BookingModel> get copyWith => __$BookingModelCopyWithImpl<_BookingModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingModel&&(identical(other.id, id) || other.id == id)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.guestId, guestId) || other.guestId == guestId)&&(identical(other.checkIn, checkIn) || other.checkIn == checkIn)&&(identical(other.checkOut, checkOut) || other.checkOut == checkOut)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.guestCount, guestCount) || other.guestCount == guestCount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.paymentIntentId, paymentIntentId) || other.paymentIntentId == paymentIntentId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,unitId,guestId,checkIn,checkOut,status,totalPrice,paidAmount,guestCount,notes,paymentIntentId,createdAt,updatedAt,cancellationReason,cancelledAt);

@override
String toString() {
  return 'BookingModel(id: $id, unitId: $unitId, guestId: $guestId, checkIn: $checkIn, checkOut: $checkOut, status: $status, totalPrice: $totalPrice, paidAmount: $paidAmount, guestCount: $guestCount, notes: $notes, paymentIntentId: $paymentIntentId, createdAt: $createdAt, updatedAt: $updatedAt, cancellationReason: $cancellationReason, cancelledAt: $cancelledAt)';
}


}

/// @nodoc
abstract mixin class _$BookingModelCopyWith<$Res> implements $BookingModelCopyWith<$Res> {
  factory _$BookingModelCopyWith(_BookingModel value, $Res Function(_BookingModel) _then) = __$BookingModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String unitId, String guestId, DateTime checkIn, DateTime checkOut, BookingStatus status, double totalPrice, double paidAmount, int guestCount, String? notes, String? paymentIntentId, DateTime createdAt, DateTime? updatedAt, String? cancellationReason, DateTime? cancelledAt
});




}
/// @nodoc
class __$BookingModelCopyWithImpl<$Res>
    implements _$BookingModelCopyWith<$Res> {
  __$BookingModelCopyWithImpl(this._self, this._then);

  final _BookingModel _self;
  final $Res Function(_BookingModel) _then;

/// Create a copy of BookingModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? unitId = null,Object? guestId = null,Object? checkIn = null,Object? checkOut = null,Object? status = null,Object? totalPrice = null,Object? paidAmount = null,Object? guestCount = null,Object? notes = freezed,Object? paymentIntentId = freezed,Object? createdAt = null,Object? updatedAt = freezed,Object? cancellationReason = freezed,Object? cancelledAt = freezed,}) {
  return _then(_BookingModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,guestId: null == guestId ? _self.guestId : guestId // ignore: cast_nullable_to_non_nullable
as String,checkIn: null == checkIn ? _self.checkIn : checkIn // ignore: cast_nullable_to_non_nullable
as DateTime,checkOut: null == checkOut ? _self.checkOut : checkOut // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingStatus,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as double,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double,guestCount: null == guestCount ? _self.guestCount : guestCount // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,paymentIntentId: freezed == paymentIntentId ? _self.paymentIntentId : paymentIntentId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
