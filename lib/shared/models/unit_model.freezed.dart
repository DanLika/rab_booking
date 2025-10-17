// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unit_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UnitModel {

/// Unit ID (UUID)
 String get id;/// Parent property ID
 String get propertyId;/// Unit name/title (e.g., "Apartment A1", "Studio 2")
 String get name;/// Unit description
 String? get description;/// Price per night in EUR
 double get pricePerNight;/// Maximum number of guests
 int get maxGuests;/// Number of bedrooms
 int get bedrooms;/// Number of bathrooms
 int get bathrooms;/// Floor area in square meters
 double? get areaSqm;/// List of unit-specific image URLs
 List<String> get images;/// Is unit available for booking
 bool get isAvailable;/// Minimum stay in nights
 int get minStayNights;/// Unit creation timestamp
 DateTime get createdAt;/// Last update timestamp
 DateTime? get updatedAt;
/// Create a copy of UnitModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitModelCopyWith<UnitModel> get copyWith => _$UnitModelCopyWithImpl<UnitModel>(this as UnitModel, _$identity);

  /// Serializes this UnitModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitModel&&(identical(other.id, id) || other.id == id)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.pricePerNight, pricePerNight) || other.pricePerNight == pricePerNight)&&(identical(other.maxGuests, maxGuests) || other.maxGuests == maxGuests)&&(identical(other.bedrooms, bedrooms) || other.bedrooms == bedrooms)&&(identical(other.bathrooms, bathrooms) || other.bathrooms == bathrooms)&&(identical(other.areaSqm, areaSqm) || other.areaSqm == areaSqm)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.minStayNights, minStayNights) || other.minStayNights == minStayNights)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,propertyId,name,description,pricePerNight,maxGuests,bedrooms,bathrooms,areaSqm,const DeepCollectionEquality().hash(images),isAvailable,minStayNights,createdAt,updatedAt);

@override
String toString() {
  return 'UnitModel(id: $id, propertyId: $propertyId, name: $name, description: $description, pricePerNight: $pricePerNight, maxGuests: $maxGuests, bedrooms: $bedrooms, bathrooms: $bathrooms, areaSqm: $areaSqm, images: $images, isAvailable: $isAvailable, minStayNights: $minStayNights, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $UnitModelCopyWith<$Res>  {
  factory $UnitModelCopyWith(UnitModel value, $Res Function(UnitModel) _then) = _$UnitModelCopyWithImpl;
@useResult
$Res call({
 String id, String propertyId, String name, String? description, double pricePerNight, int maxGuests, int bedrooms, int bathrooms, double? areaSqm, List<String> images, bool isAvailable, int minStayNights, DateTime createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$UnitModelCopyWithImpl<$Res>
    implements $UnitModelCopyWith<$Res> {
  _$UnitModelCopyWithImpl(this._self, this._then);

  final UnitModel _self;
  final $Res Function(UnitModel) _then;

/// Create a copy of UnitModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? propertyId = null,Object? name = null,Object? description = freezed,Object? pricePerNight = null,Object? maxGuests = null,Object? bedrooms = null,Object? bathrooms = null,Object? areaSqm = freezed,Object? images = null,Object? isAvailable = null,Object? minStayNights = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,pricePerNight: null == pricePerNight ? _self.pricePerNight : pricePerNight // ignore: cast_nullable_to_non_nullable
as double,maxGuests: null == maxGuests ? _self.maxGuests : maxGuests // ignore: cast_nullable_to_non_nullable
as int,bedrooms: null == bedrooms ? _self.bedrooms : bedrooms // ignore: cast_nullable_to_non_nullable
as int,bathrooms: null == bathrooms ? _self.bathrooms : bathrooms // ignore: cast_nullable_to_non_nullable
as int,areaSqm: freezed == areaSqm ? _self.areaSqm : areaSqm // ignore: cast_nullable_to_non_nullable
as double?,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<String>,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,minStayNights: null == minStayNights ? _self.minStayNights : minStayNights // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UnitModel].
extension UnitModelPatterns on UnitModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnitModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnitModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnitModel value)  $default,){
final _that = this;
switch (_that) {
case _UnitModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnitModel value)?  $default,){
final _that = this;
switch (_that) {
case _UnitModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String propertyId,  String name,  String? description,  double pricePerNight,  int maxGuests,  int bedrooms,  int bathrooms,  double? areaSqm,  List<String> images,  bool isAvailable,  int minStayNights,  DateTime createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnitModel() when $default != null:
return $default(_that.id,_that.propertyId,_that.name,_that.description,_that.pricePerNight,_that.maxGuests,_that.bedrooms,_that.bathrooms,_that.areaSqm,_that.images,_that.isAvailable,_that.minStayNights,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String propertyId,  String name,  String? description,  double pricePerNight,  int maxGuests,  int bedrooms,  int bathrooms,  double? areaSqm,  List<String> images,  bool isAvailable,  int minStayNights,  DateTime createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _UnitModel():
return $default(_that.id,_that.propertyId,_that.name,_that.description,_that.pricePerNight,_that.maxGuests,_that.bedrooms,_that.bathrooms,_that.areaSqm,_that.images,_that.isAvailable,_that.minStayNights,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String propertyId,  String name,  String? description,  double pricePerNight,  int maxGuests,  int bedrooms,  int bathrooms,  double? areaSqm,  List<String> images,  bool isAvailable,  int minStayNights,  DateTime createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _UnitModel() when $default != null:
return $default(_that.id,_that.propertyId,_that.name,_that.description,_that.pricePerNight,_that.maxGuests,_that.bedrooms,_that.bathrooms,_that.areaSqm,_that.images,_that.isAvailable,_that.minStayNights,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnitModel extends UnitModel {
  const _UnitModel({required this.id, required this.propertyId, required this.name, this.description, required this.pricePerNight, required this.maxGuests, this.bedrooms = 1, this.bathrooms = 1, this.areaSqm, final  List<String> images = const [], this.isAvailable = true, this.minStayNights = 1, required this.createdAt, this.updatedAt}): _images = images,super._();
  factory _UnitModel.fromJson(Map<String, dynamic> json) => _$UnitModelFromJson(json);

/// Unit ID (UUID)
@override final  String id;
/// Parent property ID
@override final  String propertyId;
/// Unit name/title (e.g., "Apartment A1", "Studio 2")
@override final  String name;
/// Unit description
@override final  String? description;
/// Price per night in EUR
@override final  double pricePerNight;
/// Maximum number of guests
@override final  int maxGuests;
/// Number of bedrooms
@override@JsonKey() final  int bedrooms;
/// Number of bathrooms
@override@JsonKey() final  int bathrooms;
/// Floor area in square meters
@override final  double? areaSqm;
/// List of unit-specific image URLs
 final  List<String> _images;
/// List of unit-specific image URLs
@override@JsonKey() List<String> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

/// Is unit available for booking
@override@JsonKey() final  bool isAvailable;
/// Minimum stay in nights
@override@JsonKey() final  int minStayNights;
/// Unit creation timestamp
@override final  DateTime createdAt;
/// Last update timestamp
@override final  DateTime? updatedAt;

/// Create a copy of UnitModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnitModelCopyWith<_UnitModel> get copyWith => __$UnitModelCopyWithImpl<_UnitModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnitModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnitModel&&(identical(other.id, id) || other.id == id)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.pricePerNight, pricePerNight) || other.pricePerNight == pricePerNight)&&(identical(other.maxGuests, maxGuests) || other.maxGuests == maxGuests)&&(identical(other.bedrooms, bedrooms) || other.bedrooms == bedrooms)&&(identical(other.bathrooms, bathrooms) || other.bathrooms == bathrooms)&&(identical(other.areaSqm, areaSqm) || other.areaSqm == areaSqm)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.minStayNights, minStayNights) || other.minStayNights == minStayNights)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,propertyId,name,description,pricePerNight,maxGuests,bedrooms,bathrooms,areaSqm,const DeepCollectionEquality().hash(_images),isAvailable,minStayNights,createdAt,updatedAt);

@override
String toString() {
  return 'UnitModel(id: $id, propertyId: $propertyId, name: $name, description: $description, pricePerNight: $pricePerNight, maxGuests: $maxGuests, bedrooms: $bedrooms, bathrooms: $bathrooms, areaSqm: $areaSqm, images: $images, isAvailable: $isAvailable, minStayNights: $minStayNights, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$UnitModelCopyWith<$Res> implements $UnitModelCopyWith<$Res> {
  factory _$UnitModelCopyWith(_UnitModel value, $Res Function(_UnitModel) _then) = __$UnitModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String propertyId, String name, String? description, double pricePerNight, int maxGuests, int bedrooms, int bathrooms, double? areaSqm, List<String> images, bool isAvailable, int minStayNights, DateTime createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$UnitModelCopyWithImpl<$Res>
    implements _$UnitModelCopyWith<$Res> {
  __$UnitModelCopyWithImpl(this._self, this._then);

  final _UnitModel _self;
  final $Res Function(_UnitModel) _then;

/// Create a copy of UnitModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? propertyId = null,Object? name = null,Object? description = freezed,Object? pricePerNight = null,Object? maxGuests = null,Object? bedrooms = null,Object? bathrooms = null,Object? areaSqm = freezed,Object? images = null,Object? isAvailable = null,Object? minStayNights = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_UnitModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,pricePerNight: null == pricePerNight ? _self.pricePerNight : pricePerNight // ignore: cast_nullable_to_non_nullable
as double,maxGuests: null == maxGuests ? _self.maxGuests : maxGuests // ignore: cast_nullable_to_non_nullable
as int,bedrooms: null == bedrooms ? _self.bedrooms : bedrooms // ignore: cast_nullable_to_non_nullable
as int,bathrooms: null == bathrooms ? _self.bathrooms : bathrooms // ignore: cast_nullable_to_non_nullable
as int,areaSqm: freezed == areaSqm ? _self.areaSqm : areaSqm // ignore: cast_nullable_to_non_nullable
as double?,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<String>,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,minStayNights: null == minStayNights ? _self.minStayNights : minStayNights // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
