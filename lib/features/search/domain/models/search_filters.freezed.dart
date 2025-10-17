// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_filters.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SearchFilters {

// Location & dates (from search bar)
 String? get location; DateTime? get checkIn; DateTime? get checkOut; int get guests;// Price range
 double? get minPrice; double? get maxPrice;// Property type
 List<PropertyType> get propertyTypes;// Amenities
 List<String> get amenities;// Bedrooms & bathrooms
 int? get minBedrooms; int? get minBathrooms;// Sorting
 SortBy get sortBy;// Pagination
 int get page; int get pageSize;
/// Create a copy of SearchFilters
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchFiltersCopyWith<SearchFilters> get copyWith => _$SearchFiltersCopyWithImpl<SearchFilters>(this as SearchFilters, _$identity);

  /// Serializes this SearchFilters to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchFilters&&(identical(other.location, location) || other.location == location)&&(identical(other.checkIn, checkIn) || other.checkIn == checkIn)&&(identical(other.checkOut, checkOut) || other.checkOut == checkOut)&&(identical(other.guests, guests) || other.guests == guests)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&const DeepCollectionEquality().equals(other.propertyTypes, propertyTypes)&&const DeepCollectionEquality().equals(other.amenities, amenities)&&(identical(other.minBedrooms, minBedrooms) || other.minBedrooms == minBedrooms)&&(identical(other.minBathrooms, minBathrooms) || other.minBathrooms == minBathrooms)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,location,checkIn,checkOut,guests,minPrice,maxPrice,const DeepCollectionEquality().hash(propertyTypes),const DeepCollectionEquality().hash(amenities),minBedrooms,minBathrooms,sortBy,page,pageSize);

@override
String toString() {
  return 'SearchFilters(location: $location, checkIn: $checkIn, checkOut: $checkOut, guests: $guests, minPrice: $minPrice, maxPrice: $maxPrice, propertyTypes: $propertyTypes, amenities: $amenities, minBedrooms: $minBedrooms, minBathrooms: $minBathrooms, sortBy: $sortBy, page: $page, pageSize: $pageSize)';
}


}

/// @nodoc
abstract mixin class $SearchFiltersCopyWith<$Res>  {
  factory $SearchFiltersCopyWith(SearchFilters value, $Res Function(SearchFilters) _then) = _$SearchFiltersCopyWithImpl;
@useResult
$Res call({
 String? location, DateTime? checkIn, DateTime? checkOut, int guests, double? minPrice, double? maxPrice, List<PropertyType> propertyTypes, List<String> amenities, int? minBedrooms, int? minBathrooms, SortBy sortBy, int page, int pageSize
});




}
/// @nodoc
class _$SearchFiltersCopyWithImpl<$Res>
    implements $SearchFiltersCopyWith<$Res> {
  _$SearchFiltersCopyWithImpl(this._self, this._then);

  final SearchFilters _self;
  final $Res Function(SearchFilters) _then;

/// Create a copy of SearchFilters
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? location = freezed,Object? checkIn = freezed,Object? checkOut = freezed,Object? guests = null,Object? minPrice = freezed,Object? maxPrice = freezed,Object? propertyTypes = null,Object? amenities = null,Object? minBedrooms = freezed,Object? minBathrooms = freezed,Object? sortBy = null,Object? page = null,Object? pageSize = null,}) {
  return _then(_self.copyWith(
location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,checkIn: freezed == checkIn ? _self.checkIn : checkIn // ignore: cast_nullable_to_non_nullable
as DateTime?,checkOut: freezed == checkOut ? _self.checkOut : checkOut // ignore: cast_nullable_to_non_nullable
as DateTime?,guests: null == guests ? _self.guests : guests // ignore: cast_nullable_to_non_nullable
as int,minPrice: freezed == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as double?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as double?,propertyTypes: null == propertyTypes ? _self.propertyTypes : propertyTypes // ignore: cast_nullable_to_non_nullable
as List<PropertyType>,amenities: null == amenities ? _self.amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<String>,minBedrooms: freezed == minBedrooms ? _self.minBedrooms : minBedrooms // ignore: cast_nullable_to_non_nullable
as int?,minBathrooms: freezed == minBathrooms ? _self.minBathrooms : minBathrooms // ignore: cast_nullable_to_non_nullable
as int?,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as SortBy,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchFilters].
extension SearchFiltersPatterns on SearchFilters {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchFilters value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchFilters() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchFilters value)  $default,){
final _that = this;
switch (_that) {
case _SearchFilters():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchFilters value)?  $default,){
final _that = this;
switch (_that) {
case _SearchFilters() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? location,  DateTime? checkIn,  DateTime? checkOut,  int guests,  double? minPrice,  double? maxPrice,  List<PropertyType> propertyTypes,  List<String> amenities,  int? minBedrooms,  int? minBathrooms,  SortBy sortBy,  int page,  int pageSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchFilters() when $default != null:
return $default(_that.location,_that.checkIn,_that.checkOut,_that.guests,_that.minPrice,_that.maxPrice,_that.propertyTypes,_that.amenities,_that.minBedrooms,_that.minBathrooms,_that.sortBy,_that.page,_that.pageSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? location,  DateTime? checkIn,  DateTime? checkOut,  int guests,  double? minPrice,  double? maxPrice,  List<PropertyType> propertyTypes,  List<String> amenities,  int? minBedrooms,  int? minBathrooms,  SortBy sortBy,  int page,  int pageSize)  $default,) {final _that = this;
switch (_that) {
case _SearchFilters():
return $default(_that.location,_that.checkIn,_that.checkOut,_that.guests,_that.minPrice,_that.maxPrice,_that.propertyTypes,_that.amenities,_that.minBedrooms,_that.minBathrooms,_that.sortBy,_that.page,_that.pageSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? location,  DateTime? checkIn,  DateTime? checkOut,  int guests,  double? minPrice,  double? maxPrice,  List<PropertyType> propertyTypes,  List<String> amenities,  int? minBedrooms,  int? minBathrooms,  SortBy sortBy,  int page,  int pageSize)?  $default,) {final _that = this;
switch (_that) {
case _SearchFilters() when $default != null:
return $default(_that.location,_that.checkIn,_that.checkOut,_that.guests,_that.minPrice,_that.maxPrice,_that.propertyTypes,_that.amenities,_that.minBedrooms,_that.minBathrooms,_that.sortBy,_that.page,_that.pageSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchFilters extends SearchFilters {
  const _SearchFilters({this.location, this.checkIn, this.checkOut, this.guests = 2, this.minPrice, this.maxPrice, final  List<PropertyType> propertyTypes = const [], final  List<String> amenities = const [], this.minBedrooms, this.minBathrooms, this.sortBy = SortBy.recommended, this.page = 0, this.pageSize = 20}): _propertyTypes = propertyTypes,_amenities = amenities,super._();
  factory _SearchFilters.fromJson(Map<String, dynamic> json) => _$SearchFiltersFromJson(json);

// Location & dates (from search bar)
@override final  String? location;
@override final  DateTime? checkIn;
@override final  DateTime? checkOut;
@override@JsonKey() final  int guests;
// Price range
@override final  double? minPrice;
@override final  double? maxPrice;
// Property type
 final  List<PropertyType> _propertyTypes;
// Property type
@override@JsonKey() List<PropertyType> get propertyTypes {
  if (_propertyTypes is EqualUnmodifiableListView) return _propertyTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_propertyTypes);
}

// Amenities
 final  List<String> _amenities;
// Amenities
@override@JsonKey() List<String> get amenities {
  if (_amenities is EqualUnmodifiableListView) return _amenities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_amenities);
}

// Bedrooms & bathrooms
@override final  int? minBedrooms;
@override final  int? minBathrooms;
// Sorting
@override@JsonKey() final  SortBy sortBy;
// Pagination
@override@JsonKey() final  int page;
@override@JsonKey() final  int pageSize;

/// Create a copy of SearchFilters
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchFiltersCopyWith<_SearchFilters> get copyWith => __$SearchFiltersCopyWithImpl<_SearchFilters>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchFiltersToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchFilters&&(identical(other.location, location) || other.location == location)&&(identical(other.checkIn, checkIn) || other.checkIn == checkIn)&&(identical(other.checkOut, checkOut) || other.checkOut == checkOut)&&(identical(other.guests, guests) || other.guests == guests)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&const DeepCollectionEquality().equals(other._propertyTypes, _propertyTypes)&&const DeepCollectionEquality().equals(other._amenities, _amenities)&&(identical(other.minBedrooms, minBedrooms) || other.minBedrooms == minBedrooms)&&(identical(other.minBathrooms, minBathrooms) || other.minBathrooms == minBathrooms)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,location,checkIn,checkOut,guests,minPrice,maxPrice,const DeepCollectionEquality().hash(_propertyTypes),const DeepCollectionEquality().hash(_amenities),minBedrooms,minBathrooms,sortBy,page,pageSize);

@override
String toString() {
  return 'SearchFilters(location: $location, checkIn: $checkIn, checkOut: $checkOut, guests: $guests, minPrice: $minPrice, maxPrice: $maxPrice, propertyTypes: $propertyTypes, amenities: $amenities, minBedrooms: $minBedrooms, minBathrooms: $minBathrooms, sortBy: $sortBy, page: $page, pageSize: $pageSize)';
}


}

/// @nodoc
abstract mixin class _$SearchFiltersCopyWith<$Res> implements $SearchFiltersCopyWith<$Res> {
  factory _$SearchFiltersCopyWith(_SearchFilters value, $Res Function(_SearchFilters) _then) = __$SearchFiltersCopyWithImpl;
@override @useResult
$Res call({
 String? location, DateTime? checkIn, DateTime? checkOut, int guests, double? minPrice, double? maxPrice, List<PropertyType> propertyTypes, List<String> amenities, int? minBedrooms, int? minBathrooms, SortBy sortBy, int page, int pageSize
});




}
/// @nodoc
class __$SearchFiltersCopyWithImpl<$Res>
    implements _$SearchFiltersCopyWith<$Res> {
  __$SearchFiltersCopyWithImpl(this._self, this._then);

  final _SearchFilters _self;
  final $Res Function(_SearchFilters) _then;

/// Create a copy of SearchFilters
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? location = freezed,Object? checkIn = freezed,Object? checkOut = freezed,Object? guests = null,Object? minPrice = freezed,Object? maxPrice = freezed,Object? propertyTypes = null,Object? amenities = null,Object? minBedrooms = freezed,Object? minBathrooms = freezed,Object? sortBy = null,Object? page = null,Object? pageSize = null,}) {
  return _then(_SearchFilters(
location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,checkIn: freezed == checkIn ? _self.checkIn : checkIn // ignore: cast_nullable_to_non_nullable
as DateTime?,checkOut: freezed == checkOut ? _self.checkOut : checkOut // ignore: cast_nullable_to_non_nullable
as DateTime?,guests: null == guests ? _self.guests : guests // ignore: cast_nullable_to_non_nullable
as int,minPrice: freezed == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as double?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as double?,propertyTypes: null == propertyTypes ? _self._propertyTypes : propertyTypes // ignore: cast_nullable_to_non_nullable
as List<PropertyType>,amenities: null == amenities ? _self._amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<String>,minBedrooms: freezed == minBedrooms ? _self.minBedrooms : minBedrooms // ignore: cast_nullable_to_non_nullable
as int?,minBathrooms: freezed == minBathrooms ? _self.minBathrooms : minBathrooms // ignore: cast_nullable_to_non_nullable
as int?,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as SortBy,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
