// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_flow_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookingFlowState {

// Current step: review, payment, success
 BookingStep get currentStep;// Selected property and unit
 PropertyModel? get property; PropertyUnit? get selectedUnit;// Booking details
 DateTime? get checkInDate; DateTime? get checkOutDate; int get numberOfGuests;// Guest details
 String? get guestFirstName; String? get guestLastName; String? get guestEmail; String? get guestPhone; String? get specialRequests;// Price calculation
 double get basePrice; double get serviceFee; double get cleaningFee; double get totalPrice; double get advanceAmount;// Booking ID (created after review)
 String? get bookingId;// Loading and error states
 bool get isLoading; String? get error;
/// Create a copy of BookingFlowState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingFlowStateCopyWith<BookingFlowState> get copyWith => _$BookingFlowStateCopyWithImpl<BookingFlowState>(this as BookingFlowState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingFlowState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.property, property) || other.property == property)&&(identical(other.selectedUnit, selectedUnit) || other.selectedUnit == selectedUnit)&&(identical(other.checkInDate, checkInDate) || other.checkInDate == checkInDate)&&(identical(other.checkOutDate, checkOutDate) || other.checkOutDate == checkOutDate)&&(identical(other.numberOfGuests, numberOfGuests) || other.numberOfGuests == numberOfGuests)&&(identical(other.guestFirstName, guestFirstName) || other.guestFirstName == guestFirstName)&&(identical(other.guestLastName, guestLastName) || other.guestLastName == guestLastName)&&(identical(other.guestEmail, guestEmail) || other.guestEmail == guestEmail)&&(identical(other.guestPhone, guestPhone) || other.guestPhone == guestPhone)&&(identical(other.specialRequests, specialRequests) || other.specialRequests == specialRequests)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.serviceFee, serviceFee) || other.serviceFee == serviceFee)&&(identical(other.cleaningFee, cleaningFee) || other.cleaningFee == cleaningFee)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice)&&(identical(other.advanceAmount, advanceAmount) || other.advanceAmount == advanceAmount)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hashAll([runtimeType,currentStep,property,selectedUnit,checkInDate,checkOutDate,numberOfGuests,guestFirstName,guestLastName,guestEmail,guestPhone,specialRequests,basePrice,serviceFee,cleaningFee,totalPrice,advanceAmount,bookingId,isLoading,error]);

@override
String toString() {
  return 'BookingFlowState(currentStep: $currentStep, property: $property, selectedUnit: $selectedUnit, checkInDate: $checkInDate, checkOutDate: $checkOutDate, numberOfGuests: $numberOfGuests, guestFirstName: $guestFirstName, guestLastName: $guestLastName, guestEmail: $guestEmail, guestPhone: $guestPhone, specialRequests: $specialRequests, basePrice: $basePrice, serviceFee: $serviceFee, cleaningFee: $cleaningFee, totalPrice: $totalPrice, advanceAmount: $advanceAmount, bookingId: $bookingId, isLoading: $isLoading, error: $error)';
}


}

/// @nodoc
abstract mixin class $BookingFlowStateCopyWith<$Res>  {
  factory $BookingFlowStateCopyWith(BookingFlowState value, $Res Function(BookingFlowState) _then) = _$BookingFlowStateCopyWithImpl;
@useResult
$Res call({
 BookingStep currentStep, PropertyModel? property, PropertyUnit? selectedUnit, DateTime? checkInDate, DateTime? checkOutDate, int numberOfGuests, String? guestFirstName, String? guestLastName, String? guestEmail, String? guestPhone, String? specialRequests, double basePrice, double serviceFee, double cleaningFee, double totalPrice, double advanceAmount, String? bookingId, bool isLoading, String? error
});


$PropertyModelCopyWith<$Res>? get property;$PropertyUnitCopyWith<$Res>? get selectedUnit;

}
/// @nodoc
class _$BookingFlowStateCopyWithImpl<$Res>
    implements $BookingFlowStateCopyWith<$Res> {
  _$BookingFlowStateCopyWithImpl(this._self, this._then);

  final BookingFlowState _self;
  final $Res Function(BookingFlowState) _then;

/// Create a copy of BookingFlowState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentStep = null,Object? property = freezed,Object? selectedUnit = freezed,Object? checkInDate = freezed,Object? checkOutDate = freezed,Object? numberOfGuests = null,Object? guestFirstName = freezed,Object? guestLastName = freezed,Object? guestEmail = freezed,Object? guestPhone = freezed,Object? specialRequests = freezed,Object? basePrice = null,Object? serviceFee = null,Object? cleaningFee = null,Object? totalPrice = null,Object? advanceAmount = null,Object? bookingId = freezed,Object? isLoading = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as BookingStep,property: freezed == property ? _self.property : property // ignore: cast_nullable_to_non_nullable
as PropertyModel?,selectedUnit: freezed == selectedUnit ? _self.selectedUnit : selectedUnit // ignore: cast_nullable_to_non_nullable
as PropertyUnit?,checkInDate: freezed == checkInDate ? _self.checkInDate : checkInDate // ignore: cast_nullable_to_non_nullable
as DateTime?,checkOutDate: freezed == checkOutDate ? _self.checkOutDate : checkOutDate // ignore: cast_nullable_to_non_nullable
as DateTime?,numberOfGuests: null == numberOfGuests ? _self.numberOfGuests : numberOfGuests // ignore: cast_nullable_to_non_nullable
as int,guestFirstName: freezed == guestFirstName ? _self.guestFirstName : guestFirstName // ignore: cast_nullable_to_non_nullable
as String?,guestLastName: freezed == guestLastName ? _self.guestLastName : guestLastName // ignore: cast_nullable_to_non_nullable
as String?,guestEmail: freezed == guestEmail ? _self.guestEmail : guestEmail // ignore: cast_nullable_to_non_nullable
as String?,guestPhone: freezed == guestPhone ? _self.guestPhone : guestPhone // ignore: cast_nullable_to_non_nullable
as String?,specialRequests: freezed == specialRequests ? _self.specialRequests : specialRequests // ignore: cast_nullable_to_non_nullable
as String?,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as double,serviceFee: null == serviceFee ? _self.serviceFee : serviceFee // ignore: cast_nullable_to_non_nullable
as double,cleaningFee: null == cleaningFee ? _self.cleaningFee : cleaningFee // ignore: cast_nullable_to_non_nullable
as double,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as double,advanceAmount: null == advanceAmount ? _self.advanceAmount : advanceAmount // ignore: cast_nullable_to_non_nullable
as double,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of BookingFlowState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PropertyModelCopyWith<$Res>? get property {
    if (_self.property == null) {
    return null;
  }

  return $PropertyModelCopyWith<$Res>(_self.property!, (value) {
    return _then(_self.copyWith(property: value));
  });
}/// Create a copy of BookingFlowState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PropertyUnitCopyWith<$Res>? get selectedUnit {
    if (_self.selectedUnit == null) {
    return null;
  }

  return $PropertyUnitCopyWith<$Res>(_self.selectedUnit!, (value) {
    return _then(_self.copyWith(selectedUnit: value));
  });
}
}


/// Adds pattern-matching-related methods to [BookingFlowState].
extension BookingFlowStatePatterns on BookingFlowState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingFlowState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingFlowState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingFlowState value)  $default,){
final _that = this;
switch (_that) {
case _BookingFlowState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingFlowState value)?  $default,){
final _that = this;
switch (_that) {
case _BookingFlowState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BookingStep currentStep,  PropertyModel? property,  PropertyUnit? selectedUnit,  DateTime? checkInDate,  DateTime? checkOutDate,  int numberOfGuests,  String? guestFirstName,  String? guestLastName,  String? guestEmail,  String? guestPhone,  String? specialRequests,  double basePrice,  double serviceFee,  double cleaningFee,  double totalPrice,  double advanceAmount,  String? bookingId,  bool isLoading,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingFlowState() when $default != null:
return $default(_that.currentStep,_that.property,_that.selectedUnit,_that.checkInDate,_that.checkOutDate,_that.numberOfGuests,_that.guestFirstName,_that.guestLastName,_that.guestEmail,_that.guestPhone,_that.specialRequests,_that.basePrice,_that.serviceFee,_that.cleaningFee,_that.totalPrice,_that.advanceAmount,_that.bookingId,_that.isLoading,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BookingStep currentStep,  PropertyModel? property,  PropertyUnit? selectedUnit,  DateTime? checkInDate,  DateTime? checkOutDate,  int numberOfGuests,  String? guestFirstName,  String? guestLastName,  String? guestEmail,  String? guestPhone,  String? specialRequests,  double basePrice,  double serviceFee,  double cleaningFee,  double totalPrice,  double advanceAmount,  String? bookingId,  bool isLoading,  String? error)  $default,) {final _that = this;
switch (_that) {
case _BookingFlowState():
return $default(_that.currentStep,_that.property,_that.selectedUnit,_that.checkInDate,_that.checkOutDate,_that.numberOfGuests,_that.guestFirstName,_that.guestLastName,_that.guestEmail,_that.guestPhone,_that.specialRequests,_that.basePrice,_that.serviceFee,_that.cleaningFee,_that.totalPrice,_that.advanceAmount,_that.bookingId,_that.isLoading,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BookingStep currentStep,  PropertyModel? property,  PropertyUnit? selectedUnit,  DateTime? checkInDate,  DateTime? checkOutDate,  int numberOfGuests,  String? guestFirstName,  String? guestLastName,  String? guestEmail,  String? guestPhone,  String? specialRequests,  double basePrice,  double serviceFee,  double cleaningFee,  double totalPrice,  double advanceAmount,  String? bookingId,  bool isLoading,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _BookingFlowState() when $default != null:
return $default(_that.currentStep,_that.property,_that.selectedUnit,_that.checkInDate,_that.checkOutDate,_that.numberOfGuests,_that.guestFirstName,_that.guestLastName,_that.guestEmail,_that.guestPhone,_that.specialRequests,_that.basePrice,_that.serviceFee,_that.cleaningFee,_that.totalPrice,_that.advanceAmount,_that.bookingId,_that.isLoading,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _BookingFlowState implements BookingFlowState {
  const _BookingFlowState({this.currentStep = BookingStep.review, this.property, this.selectedUnit, this.checkInDate, this.checkOutDate, this.numberOfGuests = 2, this.guestFirstName, this.guestLastName, this.guestEmail, this.guestPhone, this.specialRequests, this.basePrice = 0.0, this.serviceFee = 0.0, this.cleaningFee = 0.0, this.totalPrice = 0.0, this.advanceAmount = 0.0, this.bookingId, this.isLoading = false, this.error});
  

// Current step: review, payment, success
@override@JsonKey() final  BookingStep currentStep;
// Selected property and unit
@override final  PropertyModel? property;
@override final  PropertyUnit? selectedUnit;
// Booking details
@override final  DateTime? checkInDate;
@override final  DateTime? checkOutDate;
@override@JsonKey() final  int numberOfGuests;
// Guest details
@override final  String? guestFirstName;
@override final  String? guestLastName;
@override final  String? guestEmail;
@override final  String? guestPhone;
@override final  String? specialRequests;
// Price calculation
@override@JsonKey() final  double basePrice;
@override@JsonKey() final  double serviceFee;
@override@JsonKey() final  double cleaningFee;
@override@JsonKey() final  double totalPrice;
@override@JsonKey() final  double advanceAmount;
// Booking ID (created after review)
@override final  String? bookingId;
// Loading and error states
@override@JsonKey() final  bool isLoading;
@override final  String? error;

/// Create a copy of BookingFlowState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingFlowStateCopyWith<_BookingFlowState> get copyWith => __$BookingFlowStateCopyWithImpl<_BookingFlowState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingFlowState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.property, property) || other.property == property)&&(identical(other.selectedUnit, selectedUnit) || other.selectedUnit == selectedUnit)&&(identical(other.checkInDate, checkInDate) || other.checkInDate == checkInDate)&&(identical(other.checkOutDate, checkOutDate) || other.checkOutDate == checkOutDate)&&(identical(other.numberOfGuests, numberOfGuests) || other.numberOfGuests == numberOfGuests)&&(identical(other.guestFirstName, guestFirstName) || other.guestFirstName == guestFirstName)&&(identical(other.guestLastName, guestLastName) || other.guestLastName == guestLastName)&&(identical(other.guestEmail, guestEmail) || other.guestEmail == guestEmail)&&(identical(other.guestPhone, guestPhone) || other.guestPhone == guestPhone)&&(identical(other.specialRequests, specialRequests) || other.specialRequests == specialRequests)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.serviceFee, serviceFee) || other.serviceFee == serviceFee)&&(identical(other.cleaningFee, cleaningFee) || other.cleaningFee == cleaningFee)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice)&&(identical(other.advanceAmount, advanceAmount) || other.advanceAmount == advanceAmount)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hashAll([runtimeType,currentStep,property,selectedUnit,checkInDate,checkOutDate,numberOfGuests,guestFirstName,guestLastName,guestEmail,guestPhone,specialRequests,basePrice,serviceFee,cleaningFee,totalPrice,advanceAmount,bookingId,isLoading,error]);

@override
String toString() {
  return 'BookingFlowState(currentStep: $currentStep, property: $property, selectedUnit: $selectedUnit, checkInDate: $checkInDate, checkOutDate: $checkOutDate, numberOfGuests: $numberOfGuests, guestFirstName: $guestFirstName, guestLastName: $guestLastName, guestEmail: $guestEmail, guestPhone: $guestPhone, specialRequests: $specialRequests, basePrice: $basePrice, serviceFee: $serviceFee, cleaningFee: $cleaningFee, totalPrice: $totalPrice, advanceAmount: $advanceAmount, bookingId: $bookingId, isLoading: $isLoading, error: $error)';
}


}

/// @nodoc
abstract mixin class _$BookingFlowStateCopyWith<$Res> implements $BookingFlowStateCopyWith<$Res> {
  factory _$BookingFlowStateCopyWith(_BookingFlowState value, $Res Function(_BookingFlowState) _then) = __$BookingFlowStateCopyWithImpl;
@override @useResult
$Res call({
 BookingStep currentStep, PropertyModel? property, PropertyUnit? selectedUnit, DateTime? checkInDate, DateTime? checkOutDate, int numberOfGuests, String? guestFirstName, String? guestLastName, String? guestEmail, String? guestPhone, String? specialRequests, double basePrice, double serviceFee, double cleaningFee, double totalPrice, double advanceAmount, String? bookingId, bool isLoading, String? error
});


@override $PropertyModelCopyWith<$Res>? get property;@override $PropertyUnitCopyWith<$Res>? get selectedUnit;

}
/// @nodoc
class __$BookingFlowStateCopyWithImpl<$Res>
    implements _$BookingFlowStateCopyWith<$Res> {
  __$BookingFlowStateCopyWithImpl(this._self, this._then);

  final _BookingFlowState _self;
  final $Res Function(_BookingFlowState) _then;

/// Create a copy of BookingFlowState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentStep = null,Object? property = freezed,Object? selectedUnit = freezed,Object? checkInDate = freezed,Object? checkOutDate = freezed,Object? numberOfGuests = null,Object? guestFirstName = freezed,Object? guestLastName = freezed,Object? guestEmail = freezed,Object? guestPhone = freezed,Object? specialRequests = freezed,Object? basePrice = null,Object? serviceFee = null,Object? cleaningFee = null,Object? totalPrice = null,Object? advanceAmount = null,Object? bookingId = freezed,Object? isLoading = null,Object? error = freezed,}) {
  return _then(_BookingFlowState(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as BookingStep,property: freezed == property ? _self.property : property // ignore: cast_nullable_to_non_nullable
as PropertyModel?,selectedUnit: freezed == selectedUnit ? _self.selectedUnit : selectedUnit // ignore: cast_nullable_to_non_nullable
as PropertyUnit?,checkInDate: freezed == checkInDate ? _self.checkInDate : checkInDate // ignore: cast_nullable_to_non_nullable
as DateTime?,checkOutDate: freezed == checkOutDate ? _self.checkOutDate : checkOutDate // ignore: cast_nullable_to_non_nullable
as DateTime?,numberOfGuests: null == numberOfGuests ? _self.numberOfGuests : numberOfGuests // ignore: cast_nullable_to_non_nullable
as int,guestFirstName: freezed == guestFirstName ? _self.guestFirstName : guestFirstName // ignore: cast_nullable_to_non_nullable
as String?,guestLastName: freezed == guestLastName ? _self.guestLastName : guestLastName // ignore: cast_nullable_to_non_nullable
as String?,guestEmail: freezed == guestEmail ? _self.guestEmail : guestEmail // ignore: cast_nullable_to_non_nullable
as String?,guestPhone: freezed == guestPhone ? _self.guestPhone : guestPhone // ignore: cast_nullable_to_non_nullable
as String?,specialRequests: freezed == specialRequests ? _self.specialRequests : specialRequests // ignore: cast_nullable_to_non_nullable
as String?,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as double,serviceFee: null == serviceFee ? _self.serviceFee : serviceFee // ignore: cast_nullable_to_non_nullable
as double,cleaningFee: null == cleaningFee ? _self.cleaningFee : cleaningFee // ignore: cast_nullable_to_non_nullable
as double,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as double,advanceAmount: null == advanceAmount ? _self.advanceAmount : advanceAmount // ignore: cast_nullable_to_non_nullable
as double,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BookingFlowState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PropertyModelCopyWith<$Res>? get property {
    if (_self.property == null) {
    return null;
  }

  return $PropertyModelCopyWith<$Res>(_self.property!, (value) {
    return _then(_self.copyWith(property: value));
  });
}/// Create a copy of BookingFlowState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PropertyUnitCopyWith<$Res>? get selectedUnit {
    if (_self.selectedUnit == null) {
    return null;
  }

  return $PropertyUnitCopyWith<$Res>(_self.selectedUnit!, (value) {
    return _then(_self.copyWith(selectedUnit: value));
  });
}
}

// dart format on
