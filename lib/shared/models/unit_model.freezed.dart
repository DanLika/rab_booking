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
  /// Not written to Firestore - document ID is used instead
  @JsonKey(includeToJson: false)
  String get id => throw _privateConstructorUsedError;

  /// Parent property ID
  @JsonKey(name: 'property_id')
  String get propertyId => throw _privateConstructorUsedError;

  /// Owner user ID (for Firestore security rules)
  /// Made nullable for backwards compatibility with legacy units
  @JsonKey(name: 'owner_id')
  String? get ownerId => throw _privateConstructorUsedError;

  /// Unit name/title (e.g., "Apartment A1", "Studio 2")
  String get name => throw _privateConstructorUsedError;

  /// URL-friendly slug (e.g., "apartment-a1")
  String? get slug => throw _privateConstructorUsedError;

  /// Unit description
  String? get description => throw _privateConstructorUsedError;

  /// Price per night in EUR (base price for weekdays)
  @JsonKey(name: 'base_price')
  double get pricePerNight => throw _privateConstructorUsedError;

  /// Weekend base price in EUR (optional, for Fri-Sat nights by default)
  @JsonKey(name: 'weekend_base_price')
  double? get weekendBasePrice => throw _privateConstructorUsedError;

  /// Days considered as weekend (1=Mon...7=Sun, default: [5,6] = Fri-Sat nights)
  @JsonKey(name: 'weekend_days')
  List<int>? get weekendDays => throw _privateConstructorUsedError;

  /// Currency code (default: EUR)
  String? get currency => throw _privateConstructorUsedError;

  /// Maximum number of guests (base capacity, included in base price)
  @JsonKey(name: 'max_guests')
  int get maxGuests => throw _privateConstructorUsedError;

  /// Maximum total capacity including extra beds (null = no extra beds)
  @JsonKey(name: 'max_total_capacity')
  int? get maxTotalCapacity => throw _privateConstructorUsedError;

  /// Extra bed fee per person per night (null = extra beds not offered)
  @JsonKey(name: 'extra_bed_fee')
  double? get extraBedFee => throw _privateConstructorUsedError;

  /// Pet fee per pet per night (null = pets not allowed)
  @JsonKey(name: 'pet_fee')
  double? get petFee => throw _privateConstructorUsedError;

  /// Number of bedrooms
  int get bedrooms => throw _privateConstructorUsedError;

  /// Number of bathrooms
  int get bathrooms => throw _privateConstructorUsedError;

  /// Floor area in square meters
  @JsonKey(name: 'area_sqm')
  double? get areaSqm => throw _privateConstructorUsedError;

  /// List of unit-specific image URLs
  List<String> get images => throw _privateConstructorUsedError;

  /// Is unit available for booking
  @JsonKey(name: 'is_available')
  bool get isAvailable => throw _privateConstructorUsedError;

  /// Minimum stay in nights
  @JsonKey(name: 'min_stay_nights')
  int get minStayNights => throw _privateConstructorUsedError;

  /// Maximum stay in nights (null = unlimited)
  @JsonKey(name: 'max_stay_nights')
  int? get maxStayNights => throw _privateConstructorUsedError;

  /// Sort order for display (lower = first, null = end of list)
  @JsonKey(name: 'sort_order')
  int get sortOrder => throw _privateConstructorUsedError;

  /// Unit creation timestamp
  @JsonKey(name: 'created_at')
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Last update timestamp
  @JsonKey(name: 'updated_at')
  @NullableTimestampConverter()
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Soft delete timestamp
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt => throw _privateConstructorUsedError;

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
    @JsonKey(includeToJson: false) String id,
    @JsonKey(name: 'property_id') String propertyId,
    @JsonKey(name: 'owner_id') String? ownerId,
    String name,
    String? slug,
    String? description,
    @JsonKey(name: 'base_price') double pricePerNight,
    @JsonKey(name: 'weekend_base_price') double? weekendBasePrice,
    @JsonKey(name: 'weekend_days') List<int>? weekendDays,
    String? currency,
    @JsonKey(name: 'max_guests') int maxGuests,
    @JsonKey(name: 'max_total_capacity') int? maxTotalCapacity,
    @JsonKey(name: 'extra_bed_fee') double? extraBedFee,
    @JsonKey(name: 'pet_fee') double? petFee,
    int bedrooms,
    int bathrooms,
    @JsonKey(name: 'area_sqm') double? areaSqm,
    List<String> images,
    @JsonKey(name: 'is_available') bool isAvailable,
    @JsonKey(name: 'min_stay_nights') int minStayNights,
    @JsonKey(name: 'max_stay_nights') int? maxStayNights,
    @JsonKey(name: 'sort_order') int sortOrder,
    @JsonKey(name: 'created_at') @TimestampConverter() DateTime createdAt,
    @JsonKey(name: 'updated_at')
    @NullableTimestampConverter()
    DateTime? updatedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
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
    Object? ownerId = freezed,
    Object? name = null,
    Object? slug = freezed,
    Object? description = freezed,
    Object? pricePerNight = null,
    Object? weekendBasePrice = freezed,
    Object? weekendDays = freezed,
    Object? currency = freezed,
    Object? maxGuests = null,
    Object? maxTotalCapacity = freezed,
    Object? extraBedFee = freezed,
    Object? petFee = freezed,
    Object? bedrooms = null,
    Object? bathrooms = null,
    Object? areaSqm = freezed,
    Object? images = null,
    Object? isAvailable = null,
    Object? minStayNights = null,
    Object? maxStayNights = freezed,
    Object? sortOrder = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? deletedAt = freezed,
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
            ownerId: freezed == ownerId
                ? _value.ownerId
                : ownerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            slug: freezed == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            pricePerNight: null == pricePerNight
                ? _value.pricePerNight
                : pricePerNight // ignore: cast_nullable_to_non_nullable
                      as double,
            weekendBasePrice: freezed == weekendBasePrice
                ? _value.weekendBasePrice
                : weekendBasePrice // ignore: cast_nullable_to_non_nullable
                      as double?,
            weekendDays: freezed == weekendDays
                ? _value.weekendDays
                : weekendDays // ignore: cast_nullable_to_non_nullable
                      as List<int>?,
            currency: freezed == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String?,
            maxGuests: null == maxGuests
                ? _value.maxGuests
                : maxGuests // ignore: cast_nullable_to_non_nullable
                      as int,
            maxTotalCapacity: freezed == maxTotalCapacity
                ? _value.maxTotalCapacity
                : maxTotalCapacity // ignore: cast_nullable_to_non_nullable
                      as int?,
            extraBedFee: freezed == extraBedFee
                ? _value.extraBedFee
                : extraBedFee // ignore: cast_nullable_to_non_nullable
                      as double?,
            petFee: freezed == petFee
                ? _value.petFee
                : petFee // ignore: cast_nullable_to_non_nullable
                      as double?,
            bedrooms: null == bedrooms
                ? _value.bedrooms
                : bedrooms // ignore: cast_nullable_to_non_nullable
                      as int,
            bathrooms: null == bathrooms
                ? _value.bathrooms
                : bathrooms // ignore: cast_nullable_to_non_nullable
                      as int,
            areaSqm: freezed == areaSqm
                ? _value.areaSqm
                : areaSqm // ignore: cast_nullable_to_non_nullable
                      as double?,
            images: null == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            isAvailable: null == isAvailable
                ? _value.isAvailable
                : isAvailable // ignore: cast_nullable_to_non_nullable
                      as bool,
            minStayNights: null == minStayNights
                ? _value.minStayNights
                : minStayNights // ignore: cast_nullable_to_non_nullable
                      as int,
            maxStayNights: freezed == maxStayNights
                ? _value.maxStayNights
                : maxStayNights // ignore: cast_nullable_to_non_nullable
                      as int?,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            deletedAt: freezed == deletedAt
                ? _value.deletedAt
                : deletedAt // ignore: cast_nullable_to_non_nullable
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
    @JsonKey(includeToJson: false) String id,
    @JsonKey(name: 'property_id') String propertyId,
    @JsonKey(name: 'owner_id') String? ownerId,
    String name,
    String? slug,
    String? description,
    @JsonKey(name: 'base_price') double pricePerNight,
    @JsonKey(name: 'weekend_base_price') double? weekendBasePrice,
    @JsonKey(name: 'weekend_days') List<int>? weekendDays,
    String? currency,
    @JsonKey(name: 'max_guests') int maxGuests,
    @JsonKey(name: 'max_total_capacity') int? maxTotalCapacity,
    @JsonKey(name: 'extra_bed_fee') double? extraBedFee,
    @JsonKey(name: 'pet_fee') double? petFee,
    int bedrooms,
    int bathrooms,
    @JsonKey(name: 'area_sqm') double? areaSqm,
    List<String> images,
    @JsonKey(name: 'is_available') bool isAvailable,
    @JsonKey(name: 'min_stay_nights') int minStayNights,
    @JsonKey(name: 'max_stay_nights') int? maxStayNights,
    @JsonKey(name: 'sort_order') int sortOrder,
    @JsonKey(name: 'created_at') @TimestampConverter() DateTime createdAt,
    @JsonKey(name: 'updated_at')
    @NullableTimestampConverter()
    DateTime? updatedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
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
    Object? ownerId = freezed,
    Object? name = null,
    Object? slug = freezed,
    Object? description = freezed,
    Object? pricePerNight = null,
    Object? weekendBasePrice = freezed,
    Object? weekendDays = freezed,
    Object? currency = freezed,
    Object? maxGuests = null,
    Object? maxTotalCapacity = freezed,
    Object? extraBedFee = freezed,
    Object? petFee = freezed,
    Object? bedrooms = null,
    Object? bathrooms = null,
    Object? areaSqm = freezed,
    Object? images = null,
    Object? isAvailable = null,
    Object? minStayNights = null,
    Object? maxStayNights = freezed,
    Object? sortOrder = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? deletedAt = freezed,
  }) {
    return _then(
      _$UnitModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        propertyId: null == propertyId
            ? _value.propertyId
            : propertyId // ignore: cast_nullable_to_non_nullable
                  as String,
        ownerId: freezed == ownerId
            ? _value.ownerId
            : ownerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: freezed == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        pricePerNight: null == pricePerNight
            ? _value.pricePerNight
            : pricePerNight // ignore: cast_nullable_to_non_nullable
                  as double,
        weekendBasePrice: freezed == weekendBasePrice
            ? _value.weekendBasePrice
            : weekendBasePrice // ignore: cast_nullable_to_non_nullable
                  as double?,
        weekendDays: freezed == weekendDays
            ? _value._weekendDays
            : weekendDays // ignore: cast_nullable_to_non_nullable
                  as List<int>?,
        currency: freezed == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String?,
        maxGuests: null == maxGuests
            ? _value.maxGuests
            : maxGuests // ignore: cast_nullable_to_non_nullable
                  as int,
        maxTotalCapacity: freezed == maxTotalCapacity
            ? _value.maxTotalCapacity
            : maxTotalCapacity // ignore: cast_nullable_to_non_nullable
                  as int?,
        extraBedFee: freezed == extraBedFee
            ? _value.extraBedFee
            : extraBedFee // ignore: cast_nullable_to_non_nullable
                  as double?,
        petFee: freezed == petFee
            ? _value.petFee
            : petFee // ignore: cast_nullable_to_non_nullable
                  as double?,
        bedrooms: null == bedrooms
            ? _value.bedrooms
            : bedrooms // ignore: cast_nullable_to_non_nullable
                  as int,
        bathrooms: null == bathrooms
            ? _value.bathrooms
            : bathrooms // ignore: cast_nullable_to_non_nullable
                  as int,
        areaSqm: freezed == areaSqm
            ? _value.areaSqm
            : areaSqm // ignore: cast_nullable_to_non_nullable
                  as double?,
        images: null == images
            ? _value._images
            : images // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isAvailable: null == isAvailable
            ? _value.isAvailable
            : isAvailable // ignore: cast_nullable_to_non_nullable
                  as bool,
        minStayNights: null == minStayNights
            ? _value.minStayNights
            : minStayNights // ignore: cast_nullable_to_non_nullable
                  as int,
        maxStayNights: freezed == maxStayNights
            ? _value.maxStayNights
            : maxStayNights // ignore: cast_nullable_to_non_nullable
                  as int?,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        deletedAt: freezed == deletedAt
            ? _value.deletedAt
            : deletedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UnitModelImpl extends _UnitModel {
  const _$UnitModelImpl({
    @JsonKey(includeToJson: false) required this.id,
    @JsonKey(name: 'property_id') required this.propertyId,
    @JsonKey(name: 'owner_id') this.ownerId,
    required this.name,
    this.slug,
    this.description,
    @JsonKey(name: 'base_price') required this.pricePerNight,
    @JsonKey(name: 'weekend_base_price') this.weekendBasePrice,
    @JsonKey(name: 'weekend_days') final List<int>? weekendDays,
    this.currency = 'EUR',
    @JsonKey(name: 'max_guests') required this.maxGuests,
    @JsonKey(name: 'max_total_capacity') this.maxTotalCapacity,
    @JsonKey(name: 'extra_bed_fee') this.extraBedFee,
    @JsonKey(name: 'pet_fee') this.petFee,
    this.bedrooms = 1,
    this.bathrooms = 1,
    @JsonKey(name: 'area_sqm') this.areaSqm,
    final List<String> images = const [],
    @JsonKey(name: 'is_available') this.isAvailable = true,
    @JsonKey(name: 'min_stay_nights') this.minStayNights = 1,
    @JsonKey(name: 'max_stay_nights') this.maxStayNights,
    @JsonKey(name: 'sort_order') this.sortOrder = 0,
    @JsonKey(name: 'created_at') @TimestampConverter() required this.createdAt,
    @JsonKey(name: 'updated_at') @NullableTimestampConverter() this.updatedAt,
    @JsonKey(name: 'deleted_at') this.deletedAt,
  }) : _weekendDays = weekendDays,
       _images = images,
       super._();

  factory _$UnitModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UnitModelImplFromJson(json);

  /// Unit ID (UUID)
  /// Not written to Firestore - document ID is used instead
  @override
  @JsonKey(includeToJson: false)
  final String id;

  /// Parent property ID
  @override
  @JsonKey(name: 'property_id')
  final String propertyId;

  /// Owner user ID (for Firestore security rules)
  /// Made nullable for backwards compatibility with legacy units
  @override
  @JsonKey(name: 'owner_id')
  final String? ownerId;

  /// Unit name/title (e.g., "Apartment A1", "Studio 2")
  @override
  final String name;

  /// URL-friendly slug (e.g., "apartment-a1")
  @override
  final String? slug;

  /// Unit description
  @override
  final String? description;

  /// Price per night in EUR (base price for weekdays)
  @override
  @JsonKey(name: 'base_price')
  final double pricePerNight;

  /// Weekend base price in EUR (optional, for Fri-Sat nights by default)
  @override
  @JsonKey(name: 'weekend_base_price')
  final double? weekendBasePrice;

  /// Days considered as weekend (1=Mon...7=Sun, default: [5,6] = Fri-Sat nights)
  final List<int>? _weekendDays;

  /// Days considered as weekend (1=Mon...7=Sun, default: [5,6] = Fri-Sat nights)
  @override
  @JsonKey(name: 'weekend_days')
  List<int>? get weekendDays {
    final value = _weekendDays;
    if (value == null) return null;
    if (_weekendDays is EqualUnmodifiableListView) return _weekendDays;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Currency code (default: EUR)
  @override
  @JsonKey()
  final String? currency;

  /// Maximum number of guests (base capacity, included in base price)
  @override
  @JsonKey(name: 'max_guests')
  final int maxGuests;

  /// Maximum total capacity including extra beds (null = no extra beds)
  @override
  @JsonKey(name: 'max_total_capacity')
  final int? maxTotalCapacity;

  /// Extra bed fee per person per night (null = extra beds not offered)
  @override
  @JsonKey(name: 'extra_bed_fee')
  final double? extraBedFee;

  /// Pet fee per pet per night (null = pets not allowed)
  @override
  @JsonKey(name: 'pet_fee')
  final double? petFee;

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
  @JsonKey(name: 'area_sqm')
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
  @JsonKey(name: 'is_available')
  final bool isAvailable;

  /// Minimum stay in nights
  @override
  @JsonKey(name: 'min_stay_nights')
  final int minStayNights;

  /// Maximum stay in nights (null = unlimited)
  @override
  @JsonKey(name: 'max_stay_nights')
  final int? maxStayNights;

  /// Sort order for display (lower = first, null = end of list)
  @override
  @JsonKey(name: 'sort_order')
  final int sortOrder;

  /// Unit creation timestamp
  @override
  @JsonKey(name: 'created_at')
  @TimestampConverter()
  final DateTime createdAt;

  /// Last update timestamp
  @override
  @JsonKey(name: 'updated_at')
  @NullableTimestampConverter()
  final DateTime? updatedAt;

  /// Soft delete timestamp
  @override
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  @override
  String toString() {
    return 'UnitModel(id: $id, propertyId: $propertyId, ownerId: $ownerId, name: $name, slug: $slug, description: $description, pricePerNight: $pricePerNight, weekendBasePrice: $weekendBasePrice, weekendDays: $weekendDays, currency: $currency, maxGuests: $maxGuests, maxTotalCapacity: $maxTotalCapacity, extraBedFee: $extraBedFee, petFee: $petFee, bedrooms: $bedrooms, bathrooms: $bathrooms, areaSqm: $areaSqm, images: $images, isAvailable: $isAvailable, minStayNights: $minStayNights, maxStayNights: $maxStayNights, sortOrder: $sortOrder, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnitModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.propertyId, propertyId) ||
                other.propertyId == propertyId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.pricePerNight, pricePerNight) ||
                other.pricePerNight == pricePerNight) &&
            (identical(other.weekendBasePrice, weekendBasePrice) ||
                other.weekendBasePrice == weekendBasePrice) &&
            const DeepCollectionEquality().equals(
              other._weekendDays,
              _weekendDays,
            ) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.maxGuests, maxGuests) ||
                other.maxGuests == maxGuests) &&
            (identical(other.maxTotalCapacity, maxTotalCapacity) ||
                other.maxTotalCapacity == maxTotalCapacity) &&
            (identical(other.extraBedFee, extraBedFee) ||
                other.extraBedFee == extraBedFee) &&
            (identical(other.petFee, petFee) || other.petFee == petFee) &&
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
            (identical(other.maxStayNights, maxStayNights) ||
                other.maxStayNights == maxStayNights) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    propertyId,
    ownerId,
    name,
    slug,
    description,
    pricePerNight,
    weekendBasePrice,
    const DeepCollectionEquality().hash(_weekendDays),
    currency,
    maxGuests,
    maxTotalCapacity,
    extraBedFee,
    petFee,
    bedrooms,
    bathrooms,
    areaSqm,
    const DeepCollectionEquality().hash(_images),
    isAvailable,
    minStayNights,
    maxStayNights,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
  ]);

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
    @JsonKey(includeToJson: false) required final String id,
    @JsonKey(name: 'property_id') required final String propertyId,
    @JsonKey(name: 'owner_id') final String? ownerId,
    required final String name,
    final String? slug,
    final String? description,
    @JsonKey(name: 'base_price') required final double pricePerNight,
    @JsonKey(name: 'weekend_base_price') final double? weekendBasePrice,
    @JsonKey(name: 'weekend_days') final List<int>? weekendDays,
    final String? currency,
    @JsonKey(name: 'max_guests') required final int maxGuests,
    @JsonKey(name: 'max_total_capacity') final int? maxTotalCapacity,
    @JsonKey(name: 'extra_bed_fee') final double? extraBedFee,
    @JsonKey(name: 'pet_fee') final double? petFee,
    final int bedrooms,
    final int bathrooms,
    @JsonKey(name: 'area_sqm') final double? areaSqm,
    final List<String> images,
    @JsonKey(name: 'is_available') final bool isAvailable,
    @JsonKey(name: 'min_stay_nights') final int minStayNights,
    @JsonKey(name: 'max_stay_nights') final int? maxStayNights,
    @JsonKey(name: 'sort_order') final int sortOrder,
    @JsonKey(name: 'created_at')
    @TimestampConverter()
    required final DateTime createdAt,
    @JsonKey(name: 'updated_at')
    @NullableTimestampConverter()
    final DateTime? updatedAt,
    @JsonKey(name: 'deleted_at') final DateTime? deletedAt,
  }) = _$UnitModelImpl;
  const _UnitModel._() : super._();

  factory _UnitModel.fromJson(Map<String, dynamic> json) =
      _$UnitModelImpl.fromJson;

  /// Unit ID (UUID)
  /// Not written to Firestore - document ID is used instead
  @override
  @JsonKey(includeToJson: false)
  String get id;

  /// Parent property ID
  @override
  @JsonKey(name: 'property_id')
  String get propertyId;

  /// Owner user ID (for Firestore security rules)
  /// Made nullable for backwards compatibility with legacy units
  @override
  @JsonKey(name: 'owner_id')
  String? get ownerId;

  /// Unit name/title (e.g., "Apartment A1", "Studio 2")
  @override
  String get name;

  /// URL-friendly slug (e.g., "apartment-a1")
  @override
  String? get slug;

  /// Unit description
  @override
  String? get description;

  /// Price per night in EUR (base price for weekdays)
  @override
  @JsonKey(name: 'base_price')
  double get pricePerNight;

  /// Weekend base price in EUR (optional, for Fri-Sat nights by default)
  @override
  @JsonKey(name: 'weekend_base_price')
  double? get weekendBasePrice;

  /// Days considered as weekend (1=Mon...7=Sun, default: [5,6] = Fri-Sat nights)
  @override
  @JsonKey(name: 'weekend_days')
  List<int>? get weekendDays;

  /// Currency code (default: EUR)
  @override
  String? get currency;

  /// Maximum number of guests (base capacity, included in base price)
  @override
  @JsonKey(name: 'max_guests')
  int get maxGuests;

  /// Maximum total capacity including extra beds (null = no extra beds)
  @override
  @JsonKey(name: 'max_total_capacity')
  int? get maxTotalCapacity;

  /// Extra bed fee per person per night (null = extra beds not offered)
  @override
  @JsonKey(name: 'extra_bed_fee')
  double? get extraBedFee;

  /// Pet fee per pet per night (null = pets not allowed)
  @override
  @JsonKey(name: 'pet_fee')
  double? get petFee;

  /// Number of bedrooms
  @override
  int get bedrooms;

  /// Number of bathrooms
  @override
  int get bathrooms;

  /// Floor area in square meters
  @override
  @JsonKey(name: 'area_sqm')
  double? get areaSqm;

  /// List of unit-specific image URLs
  @override
  List<String> get images;

  /// Is unit available for booking
  @override
  @JsonKey(name: 'is_available')
  bool get isAvailable;

  /// Minimum stay in nights
  @override
  @JsonKey(name: 'min_stay_nights')
  int get minStayNights;

  /// Maximum stay in nights (null = unlimited)
  @override
  @JsonKey(name: 'max_stay_nights')
  int? get maxStayNights;

  /// Sort order for display (lower = first, null = end of list)
  @override
  @JsonKey(name: 'sort_order')
  int get sortOrder;

  /// Unit creation timestamp
  @override
  @JsonKey(name: 'created_at')
  @TimestampConverter()
  DateTime get createdAt;

  /// Last update timestamp
  @override
  @JsonKey(name: 'updated_at')
  @NullableTimestampConverter()
  DateTime? get updatedAt;

  /// Soft delete timestamp
  @override
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt;

  /// Create a copy of UnitModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnitModelImplCopyWith<_$UnitModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
