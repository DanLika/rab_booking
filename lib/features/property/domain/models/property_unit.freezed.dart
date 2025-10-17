// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'property_unit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PropertyUnit {

 String get id; String get propertyId; String get name; String? get description; double get pricePerNight; int get maxGuests; int get bedrooms; int get bathrooms; double get area; List<String> get amenities; List<String> get images; String? get coverImage; int get quantity; int get minStayNights; bool get isAvailable; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of PropertyUnit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PropertyUnitCopyWith<PropertyUnit> get copyWith => _$PropertyUnitCopyWithImpl<PropertyUnit>(this as PropertyUnit, _$identity);

  /// Serializes this PropertyUnit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PropertyUnit&&(identical(other.id, id) || other.id == id)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.pricePerNight, pricePerNight) || other.pricePerNight == pricePerNight)&&(identical(other.maxGuests, maxGuests) || other.maxGuests == maxGuests)&&(identical(other.bedrooms, bedrooms) || other.bedrooms == bedrooms)&&(identical(other.bathrooms, bathrooms) || other.bathrooms == bathrooms)&&(identical(other.area, area) || other.area == area)&&const DeepCollectionEquality().equals(other.amenities, amenities)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.coverImage, coverImage) || other.coverImage == coverImage)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.minStayNights, minStayNights) || other.minStayNights == minStayNights)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,propertyId,name,description,pricePerNight,maxGuests,bedrooms,bathrooms,area,const DeepCollectionEquality().hash(amenities),const DeepCollectionEquality().hash(images),coverImage,quantity,minStayNights,isAvailable,createdAt,updatedAt);

@override
String toString() {
  return 'PropertyUnit(id: $id, propertyId: $propertyId, name: $name, description: $description, pricePerNight: $pricePerNight, maxGuests: $maxGuests, bedrooms: $bedrooms, bathrooms: $bathrooms, area: $area, amenities: $amenities, images: $images, coverImage: $coverImage, quantity: $quantity, minStayNights: $minStayNights, isAvailable: $isAvailable, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PropertyUnitCopyWith<$Res>  {
  factory $PropertyUnitCopyWith(PropertyUnit value, $Res Function(PropertyUnit) _then) = _$PropertyUnitCopyWithImpl;
@useResult
$Res call({
 String id, String propertyId, String name, String? description, double pricePerNight, int maxGuests, int bedrooms, int bathrooms, double area, List<String> amenities, List<String> images, String? coverImage, int quantity, int minStayNights, bool isAvailable, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$PropertyUnitCopyWithImpl<$Res>
    implements $PropertyUnitCopyWith<$Res> {
  _$PropertyUnitCopyWithImpl(this._self, this._then);

  final PropertyUnit _self;
  final $Res Function(PropertyUnit) _then;

/// Create a copy of PropertyUnit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? propertyId = null,Object? name = null,Object? description = freezed,Object? pricePerNight = null,Object? maxGuests = null,Object? bedrooms = null,Object? bathrooms = null,Object? area = null,Object? amenities = null,Object? images = null,Object? coverImage = freezed,Object? quantity = null,Object? minStayNights = null,Object? isAvailable = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,pricePerNight: null == pricePerNight ? _self.pricePerNight : pricePerNight // ignore: cast_nullable_to_non_nullable
as double,maxGuests: null == maxGuests ? _self.maxGuests : maxGuests // ignore: cast_nullable_to_non_nullable
as int,bedrooms: null == bedrooms ? _self.bedrooms : bedrooms // ignore: cast_nullable_to_non_nullable
as int,bathrooms: null == bathrooms ? _self.bathrooms : bathrooms // ignore: cast_nullable_to_non_nullable
as int,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as double,amenities: null == amenities ? _self.amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<String>,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<String>,coverImage: freezed == coverImage ? _self.coverImage : coverImage // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,minStayNights: null == minStayNights ? _self.minStayNights : minStayNights // ignore: cast_nullable_to_non_nullable
as int,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PropertyUnit].
extension PropertyUnitPatterns on PropertyUnit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PropertyUnit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PropertyUnit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PropertyUnit value)  $default,){
final _that = this;
switch (_that) {
case _PropertyUnit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PropertyUnit value)?  $default,){
final _that = this;
switch (_that) {
case _PropertyUnit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String propertyId,  String name,  String? description,  double pricePerNight,  int maxGuests,  int bedrooms,  int bathrooms,  double area,  List<String> amenities,  List<String> images,  String? coverImage,  int quantity,  int minStayNights,  bool isAvailable,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PropertyUnit() when $default != null:
return $default(_that.id,_that.propertyId,_that.name,_that.description,_that.pricePerNight,_that.maxGuests,_that.bedrooms,_that.bathrooms,_that.area,_that.amenities,_that.images,_that.coverImage,_that.quantity,_that.minStayNights,_that.isAvailable,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String propertyId,  String name,  String? description,  double pricePerNight,  int maxGuests,  int bedrooms,  int bathrooms,  double area,  List<String> amenities,  List<String> images,  String? coverImage,  int quantity,  int minStayNights,  bool isAvailable,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PropertyUnit():
return $default(_that.id,_that.propertyId,_that.name,_that.description,_that.pricePerNight,_that.maxGuests,_that.bedrooms,_that.bathrooms,_that.area,_that.amenities,_that.images,_that.coverImage,_that.quantity,_that.minStayNights,_that.isAvailable,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String propertyId,  String name,  String? description,  double pricePerNight,  int maxGuests,  int bedrooms,  int bathrooms,  double area,  List<String> amenities,  List<String> images,  String? coverImage,  int quantity,  int minStayNights,  bool isAvailable,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PropertyUnit() when $default != null:
return $default(_that.id,_that.propertyId,_that.name,_that.description,_that.pricePerNight,_that.maxGuests,_that.bedrooms,_that.bathrooms,_that.area,_that.amenities,_that.images,_that.coverImage,_that.quantity,_that.minStayNights,_that.isAvailable,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PropertyUnit implements PropertyUnit {
  const _PropertyUnit({required this.id, required this.propertyId, required this.name, this.description, required this.pricePerNight, required this.maxGuests, required this.bedrooms, required this.bathrooms, required this.area, final  List<String> amenities = const [], final  List<String> images = const [], this.coverImage, this.quantity = 1, this.minStayNights = 1, this.isAvailable = true, this.createdAt, this.updatedAt}): _amenities = amenities,_images = images;
  factory _PropertyUnit.fromJson(Map<String, dynamic> json) => _$PropertyUnitFromJson(json);

@override final  String id;
@override final  String propertyId;
@override final  String name;
@override final  String? description;
@override final  double pricePerNight;
@override final  int maxGuests;
@override final  int bedrooms;
@override final  int bathrooms;
@override final  double area;
 final  List<String> _amenities;
@override@JsonKey() List<String> get amenities {
  if (_amenities is EqualUnmodifiableListView) return _amenities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_amenities);
}

 final  List<String> _images;
@override@JsonKey() List<String> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

@override final  String? coverImage;
@override@JsonKey() final  int quantity;
@override@JsonKey() final  int minStayNights;
@override@JsonKey() final  bool isAvailable;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of PropertyUnit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PropertyUnitCopyWith<_PropertyUnit> get copyWith => __$PropertyUnitCopyWithImpl<_PropertyUnit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PropertyUnitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PropertyUnit&&(identical(other.id, id) || other.id == id)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.pricePerNight, pricePerNight) || other.pricePerNight == pricePerNight)&&(identical(other.maxGuests, maxGuests) || other.maxGuests == maxGuests)&&(identical(other.bedrooms, bedrooms) || other.bedrooms == bedrooms)&&(identical(other.bathrooms, bathrooms) || other.bathrooms == bathrooms)&&(identical(other.area, area) || other.area == area)&&const DeepCollectionEquality().equals(other._amenities, _amenities)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.coverImage, coverImage) || other.coverImage == coverImage)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.minStayNights, minStayNights) || other.minStayNights == minStayNights)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,propertyId,name,description,pricePerNight,maxGuests,bedrooms,bathrooms,area,const DeepCollectionEquality().hash(_amenities),const DeepCollectionEquality().hash(_images),coverImage,quantity,minStayNights,isAvailable,createdAt,updatedAt);

@override
String toString() {
  return 'PropertyUnit(id: $id, propertyId: $propertyId, name: $name, description: $description, pricePerNight: $pricePerNight, maxGuests: $maxGuests, bedrooms: $bedrooms, bathrooms: $bathrooms, area: $area, amenities: $amenities, images: $images, coverImage: $coverImage, quantity: $quantity, minStayNights: $minStayNights, isAvailable: $isAvailable, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PropertyUnitCopyWith<$Res> implements $PropertyUnitCopyWith<$Res> {
  factory _$PropertyUnitCopyWith(_PropertyUnit value, $Res Function(_PropertyUnit) _then) = __$PropertyUnitCopyWithImpl;
@override @useResult
$Res call({
 String id, String propertyId, String name, String? description, double pricePerNight, int maxGuests, int bedrooms, int bathrooms, double area, List<String> amenities, List<String> images, String? coverImage, int quantity, int minStayNights, bool isAvailable, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$PropertyUnitCopyWithImpl<$Res>
    implements _$PropertyUnitCopyWith<$Res> {
  __$PropertyUnitCopyWithImpl(this._self, this._then);

  final _PropertyUnit _self;
  final $Res Function(_PropertyUnit) _then;

/// Create a copy of PropertyUnit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? propertyId = null,Object? name = null,Object? description = freezed,Object? pricePerNight = null,Object? maxGuests = null,Object? bedrooms = null,Object? bathrooms = null,Object? area = null,Object? amenities = null,Object? images = null,Object? coverImage = freezed,Object? quantity = null,Object? minStayNights = null,Object? isAvailable = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_PropertyUnit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,pricePerNight: null == pricePerNight ? _self.pricePerNight : pricePerNight // ignore: cast_nullable_to_non_nullable
as double,maxGuests: null == maxGuests ? _self.maxGuests : maxGuests // ignore: cast_nullable_to_non_nullable
as int,bedrooms: null == bedrooms ? _self.bedrooms : bedrooms // ignore: cast_nullable_to_non_nullable
as int,bathrooms: null == bathrooms ? _self.bathrooms : bathrooms // ignore: cast_nullable_to_non_nullable
as int,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as double,amenities: null == amenities ? _self._amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<String>,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<String>,coverImage: freezed == coverImage ? _self.coverImage : coverImage // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,minStayNights: null == minStayNights ? _self.minStayNights : minStayNights // ignore: cast_nullable_to_non_nullable
as int,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
