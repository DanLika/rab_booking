// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'property_unit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PropertyUnit _$PropertyUnitFromJson(Map<String, dynamic> json) {
  return _PropertyUnit.fromJson(json);
}

/// @nodoc
mixin _$PropertyUnit {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'property_id')
  String get propertyId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_price')
  double get pricePerNight => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_guests')
  int get maxGuests => throw _privateConstructorUsedError;
  int get bedrooms => throw _privateConstructorUsedError;
  int get bathrooms => throw _privateConstructorUsedError;
  double get area => throw _privateConstructorUsedError;
  List<String> get amenities => throw _privateConstructorUsedError;
  List<String> get images => throw _privateConstructorUsedError;
  @JsonKey(name: 'cover_image')
  String? get coverImage => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'min_stay_nights')
  int get minStayNights => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_available')
  bool get isAvailable => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this PropertyUnit to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PropertyUnit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PropertyUnitCopyWith<PropertyUnit> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PropertyUnitCopyWith<$Res> {
  factory $PropertyUnitCopyWith(
    PropertyUnit value,
    $Res Function(PropertyUnit) then,
  ) = _$PropertyUnitCopyWithImpl<$Res, PropertyUnit>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'property_id') String propertyId,
    String name,
    String? description,
    @JsonKey(name: 'base_price') double pricePerNight,
    @JsonKey(name: 'max_guests') int maxGuests,
    int bedrooms,
    int bathrooms,
    double area,
    List<String> amenities,
    List<String> images,
    @JsonKey(name: 'cover_image') String? coverImage,
    int quantity,
    @JsonKey(name: 'min_stay_nights') int minStayNights,
    @JsonKey(name: 'is_available') bool isAvailable,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$PropertyUnitCopyWithImpl<$Res, $Val extends PropertyUnit>
    implements $PropertyUnitCopyWith<$Res> {
  _$PropertyUnitCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PropertyUnit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? propertyId = null,
    Object? name = null,
    Object? description = freezed,
    Object? pricePerNight = null,
    Object? maxGuests = null,
    Object? bedrooms = null,
    Object? bathrooms = null,
    Object? area = null,
    Object? amenities = null,
    Object? images = null,
    Object? coverImage = freezed,
    Object? quantity = null,
    Object? minStayNights = null,
    Object? isAvailable = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            propertyId: null == propertyId
                ? _value.propertyId
                : propertyId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            pricePerNight: null == pricePerNight
                ? _value.pricePerNight
                : pricePerNight // ignore: cast_nullable_to_non_nullable
                      as double,
            maxGuests: null == maxGuests
                ? _value.maxGuests
                : maxGuests // ignore: cast_nullable_to_non_nullable
                      as int,
            bedrooms: null == bedrooms
                ? _value.bedrooms
                : bedrooms // ignore: cast_nullable_to_non_nullable
                      as int,
            bathrooms: null == bathrooms
                ? _value.bathrooms
                : bathrooms // ignore: cast_nullable_to_non_nullable
                      as int,
            area: null == area
                ? _value.area
                : area // ignore: cast_nullable_to_non_nullable
                      as double,
            amenities: null == amenities
                ? _value.amenities
                : amenities // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            images: null == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            coverImage: freezed == coverImage
                ? _value.coverImage
                : coverImage // ignore: cast_nullable_to_non_nullable
                      as String?,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            minStayNights: null == minStayNights
                ? _value.minStayNights
                : minStayNights // ignore: cast_nullable_to_non_nullable
                      as int,
            isAvailable: null == isAvailable
                ? _value.isAvailable
                : isAvailable // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PropertyUnitImplCopyWith<$Res>
    implements $PropertyUnitCopyWith<$Res> {
  factory _$$PropertyUnitImplCopyWith(
    _$PropertyUnitImpl value,
    $Res Function(_$PropertyUnitImpl) then,
  ) = __$$PropertyUnitImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'property_id') String propertyId,
    String name,
    String? description,
    @JsonKey(name: 'base_price') double pricePerNight,
    @JsonKey(name: 'max_guests') int maxGuests,
    int bedrooms,
    int bathrooms,
    double area,
    List<String> amenities,
    List<String> images,
    @JsonKey(name: 'cover_image') String? coverImage,
    int quantity,
    @JsonKey(name: 'min_stay_nights') int minStayNights,
    @JsonKey(name: 'is_available') bool isAvailable,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$PropertyUnitImplCopyWithImpl<$Res>
    extends _$PropertyUnitCopyWithImpl<$Res, _$PropertyUnitImpl>
    implements _$$PropertyUnitImplCopyWith<$Res> {
  __$$PropertyUnitImplCopyWithImpl(
    _$PropertyUnitImpl _value,
    $Res Function(_$PropertyUnitImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PropertyUnit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? propertyId = null,
    Object? name = null,
    Object? description = freezed,
    Object? pricePerNight = null,
    Object? maxGuests = null,
    Object? bedrooms = null,
    Object? bathrooms = null,
    Object? area = null,
    Object? amenities = null,
    Object? images = null,
    Object? coverImage = freezed,
    Object? quantity = null,
    Object? minStayNights = null,
    Object? isAvailable = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$PropertyUnitImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        propertyId: null == propertyId
            ? _value.propertyId
            : propertyId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        pricePerNight: null == pricePerNight
            ? _value.pricePerNight
            : pricePerNight // ignore: cast_nullable_to_non_nullable
                  as double,
        maxGuests: null == maxGuests
            ? _value.maxGuests
            : maxGuests // ignore: cast_nullable_to_non_nullable
                  as int,
        bedrooms: null == bedrooms
            ? _value.bedrooms
            : bedrooms // ignore: cast_nullable_to_non_nullable
                  as int,
        bathrooms: null == bathrooms
            ? _value.bathrooms
            : bathrooms // ignore: cast_nullable_to_non_nullable
                  as int,
        area: null == area
            ? _value.area
            : area // ignore: cast_nullable_to_non_nullable
                  as double,
        amenities: null == amenities
            ? _value._amenities
            : amenities // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        images: null == images
            ? _value._images
            : images // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        coverImage: freezed == coverImage
            ? _value.coverImage
            : coverImage // ignore: cast_nullable_to_non_nullable
                  as String?,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        minStayNights: null == minStayNights
            ? _value.minStayNights
            : minStayNights // ignore: cast_nullable_to_non_nullable
                  as int,
        isAvailable: null == isAvailable
            ? _value.isAvailable
            : isAvailable // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PropertyUnitImpl implements _PropertyUnit {
  const _$PropertyUnitImpl({
    required this.id,
    @JsonKey(name: 'property_id') required this.propertyId,
    required this.name,
    this.description,
    @JsonKey(name: 'base_price') required this.pricePerNight,
    @JsonKey(name: 'max_guests') required this.maxGuests,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    final List<String> amenities = const [],
    final List<String> images = const [],
    @JsonKey(name: 'cover_image') this.coverImage,
    this.quantity = 1,
    @JsonKey(name: 'min_stay_nights') this.minStayNights = 1,
    @JsonKey(name: 'is_available') this.isAvailable = true,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  }) : _amenities = amenities,
       _images = images;

  factory _$PropertyUnitImpl.fromJson(Map<String, dynamic> json) =>
      _$$PropertyUnitImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'property_id')
  final String propertyId;
  @override
  final String name;
  @override
  final String? description;
  @override
  @JsonKey(name: 'base_price')
  final double pricePerNight;
  @override
  @JsonKey(name: 'max_guests')
  final int maxGuests;
  @override
  final int bedrooms;
  @override
  final int bathrooms;
  @override
  final double area;
  final List<String> _amenities;
  @override
  @JsonKey()
  List<String> get amenities {
    if (_amenities is EqualUnmodifiableListView) return _amenities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_amenities);
  }

  final List<String> _images;
  @override
  @JsonKey()
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  @override
  @JsonKey(name: 'cover_image')
  final String? coverImage;
  @override
  @JsonKey()
  final int quantity;
  @override
  @JsonKey(name: 'min_stay_nights')
  final int minStayNights;
  @override
  @JsonKey(name: 'is_available')
  final bool isAvailable;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'PropertyUnit(id: $id, propertyId: $propertyId, name: $name, description: $description, pricePerNight: $pricePerNight, maxGuests: $maxGuests, bedrooms: $bedrooms, bathrooms: $bathrooms, area: $area, amenities: $amenities, images: $images, coverImage: $coverImage, quantity: $quantity, minStayNights: $minStayNights, isAvailable: $isAvailable, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PropertyUnitImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.propertyId, propertyId) ||
                other.propertyId == propertyId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.pricePerNight, pricePerNight) ||
                other.pricePerNight == pricePerNight) &&
            (identical(other.maxGuests, maxGuests) ||
                other.maxGuests == maxGuests) &&
            (identical(other.bedrooms, bedrooms) ||
                other.bedrooms == bedrooms) &&
            (identical(other.bathrooms, bathrooms) ||
                other.bathrooms == bathrooms) &&
            (identical(other.area, area) || other.area == area) &&
            const DeepCollectionEquality().equals(
              other._amenities,
              _amenities,
            ) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.coverImage, coverImage) ||
                other.coverImage == coverImage) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.minStayNights, minStayNights) ||
                other.minStayNights == minStayNights) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    propertyId,
    name,
    description,
    pricePerNight,
    maxGuests,
    bedrooms,
    bathrooms,
    area,
    const DeepCollectionEquality().hash(_amenities),
    const DeepCollectionEquality().hash(_images),
    coverImage,
    quantity,
    minStayNights,
    isAvailable,
    createdAt,
    updatedAt,
  );

  /// Create a copy of PropertyUnit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PropertyUnitImplCopyWith<_$PropertyUnitImpl> get copyWith =>
      __$$PropertyUnitImplCopyWithImpl<_$PropertyUnitImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PropertyUnitImplToJson(this);
  }
}

abstract class _PropertyUnit implements PropertyUnit {
  const factory _PropertyUnit({
    required final String id,
    @JsonKey(name: 'property_id') required final String propertyId,
    required final String name,
    final String? description,
    @JsonKey(name: 'base_price') required final double pricePerNight,
    @JsonKey(name: 'max_guests') required final int maxGuests,
    required final int bedrooms,
    required final int bathrooms,
    required final double area,
    final List<String> amenities,
    final List<String> images,
    @JsonKey(name: 'cover_image') final String? coverImage,
    final int quantity,
    @JsonKey(name: 'min_stay_nights') final int minStayNights,
    @JsonKey(name: 'is_available') final bool isAvailable,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$PropertyUnitImpl;

  factory _PropertyUnit.fromJson(Map<String, dynamic> json) =
      _$PropertyUnitImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'property_id')
  String get propertyId;
  @override
  String get name;
  @override
  String? get description;
  @override
  @JsonKey(name: 'base_price')
  double get pricePerNight;
  @override
  @JsonKey(name: 'max_guests')
  int get maxGuests;
  @override
  int get bedrooms;
  @override
  int get bathrooms;
  @override
  double get area;
  @override
  List<String> get amenities;
  @override
  List<String> get images;
  @override
  @JsonKey(name: 'cover_image')
  String? get coverImage;
  @override
  int get quantity;
  @override
  @JsonKey(name: 'min_stay_nights')
  int get minStayNights;
  @override
  @JsonKey(name: 'is_available')
  bool get isAvailable;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of PropertyUnit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PropertyUnitImplCopyWith<_$PropertyUnitImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
