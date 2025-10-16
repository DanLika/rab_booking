// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'property_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PropertyModel _$PropertyModelFromJson(Map<String, dynamic> json) {
  return _PropertyModel.fromJson(json);
}

/// @nodoc
mixin _$PropertyModel {
  /// Property ID (UUID)
  String get id => throw _privateConstructorUsedError;

  /// Owner user ID
  String get ownerId => throw _privateConstructorUsedError;

  /// Property name/title
  String get name => throw _privateConstructorUsedError;

  /// Detailed description
  String get description => throw _privateConstructorUsedError;

  /// Location (city, address, etc.)
  String get location => throw _privateConstructorUsedError;

  /// Latitude coordinate
  double? get latitude => throw _privateConstructorUsedError;

  /// Longitude coordinate
  double? get longitude => throw _privateConstructorUsedError;

  /// List of amenities
  List<PropertyAmenity> get amenities => throw _privateConstructorUsedError;

  /// List of image URLs
  List<String> get images => throw _privateConstructorUsedError;

  /// Main cover image URL
  String? get coverImage => throw _privateConstructorUsedError;

  /// Average rating (0-5)
  double get rating => throw _privateConstructorUsedError;

  /// Number of reviews
  int get reviewCount => throw _privateConstructorUsedError;

  /// Property creation timestamp
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Last update timestamp
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Is property active/published
  bool get isActive => throw _privateConstructorUsedError;

  /// Serializes this PropertyModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PropertyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PropertyModelCopyWith<PropertyModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PropertyModelCopyWith<$Res> {
  factory $PropertyModelCopyWith(
    PropertyModel value,
    $Res Function(PropertyModel) then,
  ) = _$PropertyModelCopyWithImpl<$Res, PropertyModel>;
  @useResult
  $Res call({
    String id,
    String ownerId,
    String name,
    String description,
    String location,
    double? latitude,
    double? longitude,
    List<PropertyAmenity> amenities,
    List<String> images,
    String? coverImage,
    double rating,
    int reviewCount,
    DateTime createdAt,
    DateTime? updatedAt,
    bool isActive,
  });
}

/// @nodoc
class _$PropertyModelCopyWithImpl<$Res, $Val extends PropertyModel>
    implements $PropertyModelCopyWith<$Res> {
  _$PropertyModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PropertyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? name = null,
    Object? description = null,
    Object? location = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? amenities = null,
    Object? images = null,
    Object? coverImage = freezed,
    Object? rating = null,
    Object? reviewCount = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? isActive = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            ownerId:
                null == ownerId
                    ? _value.ownerId
                    : ownerId // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            description:
                null == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String,
            location:
                null == location
                    ? _value.location
                    : location // ignore: cast_nullable_to_non_nullable
                        as String,
            latitude:
                freezed == latitude
                    ? _value.latitude
                    : latitude // ignore: cast_nullable_to_non_nullable
                        as double?,
            longitude:
                freezed == longitude
                    ? _value.longitude
                    : longitude // ignore: cast_nullable_to_non_nullable
                        as double?,
            amenities:
                null == amenities
                    ? _value.amenities
                    : amenities // ignore: cast_nullable_to_non_nullable
                        as List<PropertyAmenity>,
            images:
                null == images
                    ? _value.images
                    : images // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            coverImage:
                freezed == coverImage
                    ? _value.coverImage
                    : coverImage // ignore: cast_nullable_to_non_nullable
                        as String?,
            rating:
                null == rating
                    ? _value.rating
                    : rating // ignore: cast_nullable_to_non_nullable
                        as double,
            reviewCount:
                null == reviewCount
                    ? _value.reviewCount
                    : reviewCount // ignore: cast_nullable_to_non_nullable
                        as int,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            updatedAt:
                freezed == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            isActive:
                null == isActive
                    ? _value.isActive
                    : isActive // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PropertyModelImplCopyWith<$Res>
    implements $PropertyModelCopyWith<$Res> {
  factory _$$PropertyModelImplCopyWith(
    _$PropertyModelImpl value,
    $Res Function(_$PropertyModelImpl) then,
  ) = __$$PropertyModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String ownerId,
    String name,
    String description,
    String location,
    double? latitude,
    double? longitude,
    List<PropertyAmenity> amenities,
    List<String> images,
    String? coverImage,
    double rating,
    int reviewCount,
    DateTime createdAt,
    DateTime? updatedAt,
    bool isActive,
  });
}

/// @nodoc
class __$$PropertyModelImplCopyWithImpl<$Res>
    extends _$PropertyModelCopyWithImpl<$Res, _$PropertyModelImpl>
    implements _$$PropertyModelImplCopyWith<$Res> {
  __$$PropertyModelImplCopyWithImpl(
    _$PropertyModelImpl _value,
    $Res Function(_$PropertyModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PropertyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? name = null,
    Object? description = null,
    Object? location = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? amenities = null,
    Object? images = null,
    Object? coverImage = freezed,
    Object? rating = null,
    Object? reviewCount = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? isActive = null,
  }) {
    return _then(
      _$PropertyModelImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        ownerId:
            null == ownerId
                ? _value.ownerId
                : ownerId // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        description:
            null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String,
        location:
            null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                    as String,
        latitude:
            freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                    as double?,
        longitude:
            freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                    as double?,
        amenities:
            null == amenities
                ? _value._amenities
                : amenities // ignore: cast_nullable_to_non_nullable
                    as List<PropertyAmenity>,
        images:
            null == images
                ? _value._images
                : images // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        coverImage:
            freezed == coverImage
                ? _value.coverImage
                : coverImage // ignore: cast_nullable_to_non_nullable
                    as String?,
        rating:
            null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                    as double,
        reviewCount:
            null == reviewCount
                ? _value.reviewCount
                : reviewCount // ignore: cast_nullable_to_non_nullable
                    as int,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        updatedAt:
            freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        isActive:
            null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PropertyModelImpl extends _PropertyModel {
  const _$PropertyModelImpl({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    final List<PropertyAmenity> amenities = const [],
    final List<String> images = const [],
    this.coverImage,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  }) : _amenities = amenities,
       _images = images,
       super._();

  factory _$PropertyModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PropertyModelImplFromJson(json);

  /// Property ID (UUID)
  @override
  final String id;

  /// Owner user ID
  @override
  final String ownerId;

  /// Property name/title
  @override
  final String name;

  /// Detailed description
  @override
  final String description;

  /// Location (city, address, etc.)
  @override
  final String location;

  /// Latitude coordinate
  @override
  final double? latitude;

  /// Longitude coordinate
  @override
  final double? longitude;

  /// List of amenities
  final List<PropertyAmenity> _amenities;

  /// List of amenities
  @override
  @JsonKey()
  List<PropertyAmenity> get amenities {
    if (_amenities is EqualUnmodifiableListView) return _amenities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_amenities);
  }

  /// List of image URLs
  final List<String> _images;

  /// List of image URLs
  @override
  @JsonKey()
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  /// Main cover image URL
  @override
  final String? coverImage;

  /// Average rating (0-5)
  @override
  @JsonKey()
  final double rating;

  /// Number of reviews
  @override
  @JsonKey()
  final int reviewCount;

  /// Property creation timestamp
  @override
  final DateTime createdAt;

  /// Last update timestamp
  @override
  final DateTime? updatedAt;

  /// Is property active/published
  @override
  @JsonKey()
  final bool isActive;

  @override
  String toString() {
    return 'PropertyModel(id: $id, ownerId: $ownerId, name: $name, description: $description, location: $location, latitude: $latitude, longitude: $longitude, amenities: $amenities, images: $images, coverImage: $coverImage, rating: $rating, reviewCount: $reviewCount, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PropertyModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            const DeepCollectionEquality().equals(
              other._amenities,
              _amenities,
            ) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.coverImage, coverImage) ||
                other.coverImage == coverImage) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.reviewCount, reviewCount) ||
                other.reviewCount == reviewCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    ownerId,
    name,
    description,
    location,
    latitude,
    longitude,
    const DeepCollectionEquality().hash(_amenities),
    const DeepCollectionEquality().hash(_images),
    coverImage,
    rating,
    reviewCount,
    createdAt,
    updatedAt,
    isActive,
  );

  /// Create a copy of PropertyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PropertyModelImplCopyWith<_$PropertyModelImpl> get copyWith =>
      __$$PropertyModelImplCopyWithImpl<_$PropertyModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PropertyModelImplToJson(this);
  }
}

abstract class _PropertyModel extends PropertyModel {
  const factory _PropertyModel({
    required final String id,
    required final String ownerId,
    required final String name,
    required final String description,
    required final String location,
    final double? latitude,
    final double? longitude,
    final List<PropertyAmenity> amenities,
    final List<String> images,
    final String? coverImage,
    final double rating,
    final int reviewCount,
    required final DateTime createdAt,
    final DateTime? updatedAt,
    final bool isActive,
  }) = _$PropertyModelImpl;
  const _PropertyModel._() : super._();

  factory _PropertyModel.fromJson(Map<String, dynamic> json) =
      _$PropertyModelImpl.fromJson;

  /// Property ID (UUID)
  @override
  String get id;

  /// Owner user ID
  @override
  String get ownerId;

  /// Property name/title
  @override
  String get name;

  /// Detailed description
  @override
  String get description;

  /// Location (city, address, etc.)
  @override
  String get location;

  /// Latitude coordinate
  @override
  double? get latitude;

  /// Longitude coordinate
  @override
  double? get longitude;

  /// List of amenities
  @override
  List<PropertyAmenity> get amenities;

  /// List of image URLs
  @override
  List<String> get images;

  /// Main cover image URL
  @override
  String? get coverImage;

  /// Average rating (0-5)
  @override
  double get rating;

  /// Number of reviews
  @override
  int get reviewCount;

  /// Property creation timestamp
  @override
  DateTime get createdAt;

  /// Last update timestamp
  @override
  DateTime? get updatedAt;

  /// Is property active/published
  @override
  bool get isActive;

  /// Create a copy of PropertyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PropertyModelImplCopyWith<_$PropertyModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
