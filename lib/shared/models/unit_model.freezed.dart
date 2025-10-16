// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unit_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UnitModel _$UnitModelFromJson(Map<String, dynamic> json) {
  return _UnitModel.fromJson(json);
}

/// @nodoc
mixin _$UnitModel {
  /// Unit ID (UUID)
  String get id => throw _privateConstructorUsedError;

  /// Parent property ID
  String get propertyId => throw _privateConstructorUsedError;

  /// Unit name/title (e.g., "Apartment A1", "Studio 2")
  String get name => throw _privateConstructorUsedError;

  /// Unit description
  String? get description => throw _privateConstructorUsedError;

  /// Price per night in EUR
  double get pricePerNight => throw _privateConstructorUsedError;

  /// Maximum number of guests
  int get maxGuests => throw _privateConstructorUsedError;

  /// Number of bedrooms
  int get bedrooms => throw _privateConstructorUsedError;

  /// Number of bathrooms
  int get bathrooms => throw _privateConstructorUsedError;

  /// Floor area in square meters
  double? get areaSqm => throw _privateConstructorUsedError;

  /// List of unit-specific image URLs
  List<String> get images => throw _privateConstructorUsedError;

  /// Is unit available for booking
  bool get isAvailable => throw _privateConstructorUsedError;

  /// Minimum stay in nights
  int get minStayNights => throw _privateConstructorUsedError;

  /// Unit creation timestamp
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Last update timestamp
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this UnitModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UnitModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UnitModelCopyWith<UnitModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnitModelCopyWith<$Res> {
  factory $UnitModelCopyWith(UnitModel value, $Res Function(UnitModel) then) =
      _$UnitModelCopyWithImpl<$Res, UnitModel>;
  @useResult
  $Res call({
    String id,
    String propertyId,
    String name,
    String? description,
    double pricePerNight,
    int maxGuests,
    int bedrooms,
    int bathrooms,
    double? areaSqm,
    List<String> images,
    bool isAvailable,
    int minStayNights,
    DateTime createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$UnitModelCopyWithImpl<$Res, $Val extends UnitModel>
    implements $UnitModelCopyWith<$Res> {
  _$UnitModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UnitModel
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
    Object? areaSqm = freezed,
    Object? images = null,
    Object? isAvailable = null,
    Object? minStayNights = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            propertyId:
                null == propertyId
                    ? _value.propertyId
                    : propertyId // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            description:
                freezed == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String?,
            pricePerNight:
                null == pricePerNight
                    ? _value.pricePerNight
                    : pricePerNight // ignore: cast_nullable_to_non_nullable
                        as double,
            maxGuests:
                null == maxGuests
                    ? _value.maxGuests
                    : maxGuests // ignore: cast_nullable_to_non_nullable
                        as int,
            bedrooms:
                null == bedrooms
                    ? _value.bedrooms
                    : bedrooms // ignore: cast_nullable_to_non_nullable
                        as int,
            bathrooms:
                null == bathrooms
                    ? _value.bathrooms
                    : bathrooms // ignore: cast_nullable_to_non_nullable
                        as int,
            areaSqm:
                freezed == areaSqm
                    ? _value.areaSqm
                    : areaSqm // ignore: cast_nullable_to_non_nullable
                        as double?,
            images:
                null == images
                    ? _value.images
                    : images // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            isAvailable:
                null == isAvailable
                    ? _value.isAvailable
                    : isAvailable // ignore: cast_nullable_to_non_nullable
                        as bool,
            minStayNights:
                null == minStayNights
                    ? _value.minStayNights
                    : minStayNights // ignore: cast_nullable_to_non_nullable
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UnitModelImplCopyWith<$Res>
    implements $UnitModelCopyWith<$Res> {
  factory _$$UnitModelImplCopyWith(
    _$UnitModelImpl value,
    $Res Function(_$UnitModelImpl) then,
  ) = __$$UnitModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String propertyId,
    String name,
    String? description,
    double pricePerNight,
    int maxGuests,
    int bedrooms,
    int bathrooms,
    double? areaSqm,
    List<String> images,
    bool isAvailable,
    int minStayNights,
    DateTime createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$UnitModelImplCopyWithImpl<$Res>
    extends _$UnitModelCopyWithImpl<$Res, _$UnitModelImpl>
    implements _$$UnitModelImplCopyWith<$Res> {
  __$$UnitModelImplCopyWithImpl(
    _$UnitModelImpl _value,
    $Res Function(_$UnitModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UnitModel
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
    Object? areaSqm = freezed,
    Object? images = null,
    Object? isAvailable = null,
    Object? minStayNights = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$UnitModelImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        propertyId:
            null == propertyId
                ? _value.propertyId
                : propertyId // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        description:
            freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String?,
        pricePerNight:
            null == pricePerNight
                ? _value.pricePerNight
                : pricePerNight // ignore: cast_nullable_to_non_nullable
                    as double,
        maxGuests:
            null == maxGuests
                ? _value.maxGuests
                : maxGuests // ignore: cast_nullable_to_non_nullable
                    as int,
        bedrooms:
            null == bedrooms
                ? _value.bedrooms
                : bedrooms // ignore: cast_nullable_to_non_nullable
                    as int,
        bathrooms:
            null == bathrooms
                ? _value.bathrooms
                : bathrooms // ignore: cast_nullable_to_non_nullable
                    as int,
        areaSqm:
            freezed == areaSqm
                ? _value.areaSqm
                : areaSqm // ignore: cast_nullable_to_non_nullable
                    as double?,
        images:
            null == images
                ? _value._images
                : images // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        isAvailable:
            null == isAvailable
                ? _value.isAvailable
                : isAvailable // ignore: cast_nullable_to_non_nullable
                    as bool,
        minStayNights:
            null == minStayNights
                ? _value.minStayNights
                : minStayNights // ignore: cast_nullable_to_non_nullable
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UnitModelImpl extends _UnitModel {
  const _$UnitModelImpl({
    required this.id,
    required this.propertyId,
    required this.name,
    this.description,
    required this.pricePerNight,
    required this.maxGuests,
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.areaSqm,
    final List<String> images = const [],
    this.isAvailable = true,
    this.minStayNights = 1,
    required this.createdAt,
    this.updatedAt,
  }) : _images = images,
       super._();

  factory _$UnitModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UnitModelImplFromJson(json);

  /// Unit ID (UUID)
  @override
  final String id;

  /// Parent property ID
  @override
  final String propertyId;

  /// Unit name/title (e.g., "Apartment A1", "Studio 2")
  @override
  final String name;

  /// Unit description
  @override
  final String? description;

  /// Price per night in EUR
  @override
  final double pricePerNight;

  /// Maximum number of guests
  @override
  final int maxGuests;

  /// Number of bedrooms
  @override
  @JsonKey()
  final int bedrooms;

  /// Number of bathrooms
  @override
  @JsonKey()
  final int bathrooms;

  /// Floor area in square meters
  @override
  final double? areaSqm;

  /// List of unit-specific image URLs
  final List<String> _images;

  /// List of unit-specific image URLs
  @override
  @JsonKey()
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  /// Is unit available for booking
  @override
  @JsonKey()
  final bool isAvailable;

  /// Minimum stay in nights
  @override
  @JsonKey()
  final int minStayNights;

  /// Unit creation timestamp
  @override
  final DateTime createdAt;

  /// Last update timestamp
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'UnitModel(id: $id, propertyId: $propertyId, name: $name, description: $description, pricePerNight: $pricePerNight, maxGuests: $maxGuests, bedrooms: $bedrooms, bathrooms: $bathrooms, areaSqm: $areaSqm, images: $images, isAvailable: $isAvailable, minStayNights: $minStayNights, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnitModelImpl &&
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
            (identical(other.areaSqm, areaSqm) || other.areaSqm == areaSqm) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.minStayNights, minStayNights) ||
                other.minStayNights == minStayNights) &&
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
    areaSqm,
    const DeepCollectionEquality().hash(_images),
    isAvailable,
    minStayNights,
    createdAt,
    updatedAt,
  );

  /// Create a copy of UnitModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnitModelImplCopyWith<_$UnitModelImpl> get copyWith =>
      __$$UnitModelImplCopyWithImpl<_$UnitModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UnitModelImplToJson(this);
  }
}

abstract class _UnitModel extends UnitModel {
  const factory _UnitModel({
    required final String id,
    required final String propertyId,
    required final String name,
    final String? description,
    required final double pricePerNight,
    required final int maxGuests,
    final int bedrooms,
    final int bathrooms,
    final double? areaSqm,
    final List<String> images,
    final bool isAvailable,
    final int minStayNights,
    required final DateTime createdAt,
    final DateTime? updatedAt,
  }) = _$UnitModelImpl;
  const _UnitModel._() : super._();

  factory _UnitModel.fromJson(Map<String, dynamic> json) =
      _$UnitModelImpl.fromJson;

  /// Unit ID (UUID)
  @override
  String get id;

  /// Parent property ID
  @override
  String get propertyId;

  /// Unit name/title (e.g., "Apartment A1", "Studio 2")
  @override
  String get name;

  /// Unit description
  @override
  String? get description;

  /// Price per night in EUR
  @override
  double get pricePerNight;

  /// Maximum number of guests
  @override
  int get maxGuests;

  /// Number of bedrooms
  @override
  int get bedrooms;

  /// Number of bathrooms
  @override
  int get bathrooms;

  /// Floor area in square meters
  @override
  double? get areaSqm;

  /// List of unit-specific image URLs
  @override
  List<String> get images;

  /// Is unit available for booking
  @override
  bool get isAvailable;

  /// Minimum stay in nights
  @override
  int get minStayNights;

  /// Unit creation timestamp
  @override
  DateTime get createdAt;

  /// Last update timestamp
  @override
  DateTime? get updatedAt;

  /// Create a copy of UnitModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnitModelImplCopyWith<_$UnitModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
