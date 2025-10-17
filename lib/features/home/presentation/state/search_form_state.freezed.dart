// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchFormState implements DiagnosticableTreeMixin {

 String get location; DateTime? get checkInDate; DateTime? get checkOutDate; int get adults; int get children; int get infants;
/// Create a copy of SearchFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchFormStateCopyWith<SearchFormState> get copyWith => _$SearchFormStateCopyWithImpl<SearchFormState>(this as SearchFormState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchFormState'))
    ..add(DiagnosticsProperty('location', location))..add(DiagnosticsProperty('checkInDate', checkInDate))..add(DiagnosticsProperty('checkOutDate', checkOutDate))..add(DiagnosticsProperty('adults', adults))..add(DiagnosticsProperty('children', children))..add(DiagnosticsProperty('infants', infants));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchFormState&&(identical(other.location, location) || other.location == location)&&(identical(other.checkInDate, checkInDate) || other.checkInDate == checkInDate)&&(identical(other.checkOutDate, checkOutDate) || other.checkOutDate == checkOutDate)&&(identical(other.adults, adults) || other.adults == adults)&&(identical(other.children, children) || other.children == children)&&(identical(other.infants, infants) || other.infants == infants));
}


@override
int get hashCode => Object.hash(runtimeType,location,checkInDate,checkOutDate,adults,children,infants);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchFormState(location: $location, checkInDate: $checkInDate, checkOutDate: $checkOutDate, adults: $adults, children: $children, infants: $infants)';
}


}

/// @nodoc
abstract mixin class $SearchFormStateCopyWith<$Res>  {
  factory $SearchFormStateCopyWith(SearchFormState value, $Res Function(SearchFormState) _then) = _$SearchFormStateCopyWithImpl;
@useResult
$Res call({
 String location, DateTime? checkInDate, DateTime? checkOutDate, int adults, int children, int infants
});




}
/// @nodoc
class _$SearchFormStateCopyWithImpl<$Res>
    implements $SearchFormStateCopyWith<$Res> {
  _$SearchFormStateCopyWithImpl(this._self, this._then);

  final SearchFormState _self;
  final $Res Function(SearchFormState) _then;

/// Create a copy of SearchFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? location = null,Object? checkInDate = freezed,Object? checkOutDate = freezed,Object? adults = null,Object? children = null,Object? infants = null,}) {
  return _then(_self.copyWith(
location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,checkInDate: freezed == checkInDate ? _self.checkInDate : checkInDate // ignore: cast_nullable_to_non_nullable
as DateTime?,checkOutDate: freezed == checkOutDate ? _self.checkOutDate : checkOutDate // ignore: cast_nullable_to_non_nullable
as DateTime?,adults: null == adults ? _self.adults : adults // ignore: cast_nullable_to_non_nullable
as int,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as int,infants: null == infants ? _self.infants : infants // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchFormState].
extension SearchFormStatePatterns on SearchFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchFormState value)  $default,){
final _that = this;
switch (_that) {
case _SearchFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchFormState value)?  $default,){
final _that = this;
switch (_that) {
case _SearchFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String location,  DateTime? checkInDate,  DateTime? checkOutDate,  int adults,  int children,  int infants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchFormState() when $default != null:
return $default(_that.location,_that.checkInDate,_that.checkOutDate,_that.adults,_that.children,_that.infants);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String location,  DateTime? checkInDate,  DateTime? checkOutDate,  int adults,  int children,  int infants)  $default,) {final _that = this;
switch (_that) {
case _SearchFormState():
return $default(_that.location,_that.checkInDate,_that.checkOutDate,_that.adults,_that.children,_that.infants);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String location,  DateTime? checkInDate,  DateTime? checkOutDate,  int adults,  int children,  int infants)?  $default,) {final _that = this;
switch (_that) {
case _SearchFormState() when $default != null:
return $default(_that.location,_that.checkInDate,_that.checkOutDate,_that.adults,_that.children,_that.infants);case _:
  return null;

}
}

}

/// @nodoc


class _SearchFormState extends SearchFormState with DiagnosticableTreeMixin {
  const _SearchFormState({this.location = 'Otok Rab', this.checkInDate, this.checkOutDate, this.adults = 2, this.children = 0, this.infants = 0}): super._();
  

@override@JsonKey() final  String location;
@override final  DateTime? checkInDate;
@override final  DateTime? checkOutDate;
@override@JsonKey() final  int adults;
@override@JsonKey() final  int children;
@override@JsonKey() final  int infants;

/// Create a copy of SearchFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchFormStateCopyWith<_SearchFormState> get copyWith => __$SearchFormStateCopyWithImpl<_SearchFormState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SearchFormState'))
    ..add(DiagnosticsProperty('location', location))..add(DiagnosticsProperty('checkInDate', checkInDate))..add(DiagnosticsProperty('checkOutDate', checkOutDate))..add(DiagnosticsProperty('adults', adults))..add(DiagnosticsProperty('children', children))..add(DiagnosticsProperty('infants', infants));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchFormState&&(identical(other.location, location) || other.location == location)&&(identical(other.checkInDate, checkInDate) || other.checkInDate == checkInDate)&&(identical(other.checkOutDate, checkOutDate) || other.checkOutDate == checkOutDate)&&(identical(other.adults, adults) || other.adults == adults)&&(identical(other.children, children) || other.children == children)&&(identical(other.infants, infants) || other.infants == infants));
}


@override
int get hashCode => Object.hash(runtimeType,location,checkInDate,checkOutDate,adults,children,infants);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SearchFormState(location: $location, checkInDate: $checkInDate, checkOutDate: $checkOutDate, adults: $adults, children: $children, infants: $infants)';
}


}

/// @nodoc
abstract mixin class _$SearchFormStateCopyWith<$Res> implements $SearchFormStateCopyWith<$Res> {
  factory _$SearchFormStateCopyWith(_SearchFormState value, $Res Function(_SearchFormState) _then) = __$SearchFormStateCopyWithImpl;
@override @useResult
$Res call({
 String location, DateTime? checkInDate, DateTime? checkOutDate, int adults, int children, int infants
});




}
/// @nodoc
class __$SearchFormStateCopyWithImpl<$Res>
    implements _$SearchFormStateCopyWith<$Res> {
  __$SearchFormStateCopyWithImpl(this._self, this._then);

  final _SearchFormState _self;
  final $Res Function(_SearchFormState) _then;

/// Create a copy of SearchFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? location = null,Object? checkInDate = freezed,Object? checkOutDate = freezed,Object? adults = null,Object? children = null,Object? infants = null,}) {
  return _then(_SearchFormState(
location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,checkInDate: freezed == checkInDate ? _self.checkInDate : checkInDate // ignore: cast_nullable_to_non_nullable
as DateTime?,checkOutDate: freezed == checkOutDate ? _self.checkOutDate : checkOutDate // ignore: cast_nullable_to_non_nullable
as DateTime?,adults: null == adults ? _self.adults : adults // ignore: cast_nullable_to_non_nullable
as int,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as int,infants: null == infants ? _self.infants : infants // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
