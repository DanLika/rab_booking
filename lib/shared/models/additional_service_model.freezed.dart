// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'additional_service_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AdditionalServiceModel _$AdditionalServiceModelFromJson(
  Map<String, dynamic> json,
) {
  return _AdditionalServiceModel.fromJson(json);
}

/// @nodoc
mixin _$AdditionalServiceModel {
  /// Service ID (UUID)
  String get id => throw _privateConstructorUsedError;

  /// Owner ID (nullable for backwards compatibility with legacy services)
  @JsonKey(name: 'owner_id')
  String? get ownerId => throw _privateConstructorUsedError;

  /// Service name
  String get name => throw _privateConstructorUsedError;

  /// Service description
  String? get description => throw _privateConstructorUsedError;

  /// Service name (English)
  @JsonKey(name: 'name_en')
  String? get nameEn => throw _privateConstructorUsedError;

  /// Service description (English)
  @JsonKey(name: 'description_en')
  String? get descriptionEn => throw _privateConstructorUsedError;

  /// Service type
  @JsonKey(name: 'service_type')
  String get serviceType => throw _privateConstructorUsedError;

  /// Price
  double get price => throw _privateConstructorUsedError;

  /// Currency (default: EUR)
  String get currency => throw _privateConstructorUsedError;

  /// Pricing unit (per_booking, per_night, per_person, per_item)
  @JsonKey(name: 'pricing_unit')
  String get pricingUnit => throw _privateConstructorUsedError;

  /// Is service available
  @JsonKey(name: 'is_available')
  bool get isAvailable => throw _privateConstructorUsedError;

  /// Maximum quantity (null = unlimited)
  @JsonKey(name: 'max_quantity')
  int? get maxQuantity => throw _privateConstructorUsedError;

  /// Unit ID (null = available for all units)
  @JsonKey(name: 'unit_id')
  String? get unitId => throw _privateConstructorUsedError;

  /// Property ID (null = available for all properties)
  @JsonKey(name: 'property_id')
  String? get propertyId => throw _privateConstructorUsedError;

  /// Sort order for display
  @JsonKey(name: 'sort_order')
  int get sortOrder => throw _privateConstructorUsedError;

  /// Icon name (Material icon)
  @JsonKey(name: 'icon_name')
  String? get iconName => throw _privateConstructorUsedError;

  /// Image URL
  @JsonKey(name: 'image_url')
  String? get imageUrl => throw _privateConstructorUsedError;

  /// Created at timestamp
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Updated at timestamp
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Soft delete timestamp
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt => throw _privateConstructorUsedError;

  /// Serializes this AdditionalServiceModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdditionalServiceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdditionalServiceModelCopyWith<AdditionalServiceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdditionalServiceModelCopyWith<$Res> {
  factory $AdditionalServiceModelCopyWith(
    AdditionalServiceModel value,
    $Res Function(AdditionalServiceModel) then,
  ) = _$AdditionalServiceModelCopyWithImpl<$Res, AdditionalServiceModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'owner_id') String? ownerId,
    String name,
    String? description,
    @JsonKey(name: 'name_en') String? nameEn,
    @JsonKey(name: 'description_en') String? descriptionEn,
    @JsonKey(name: 'service_type') String serviceType,
    double price,
    String currency,
    @JsonKey(name: 'pricing_unit') String pricingUnit,
    @JsonKey(name: 'is_available') bool isAvailable,
    @JsonKey(name: 'max_quantity') int? maxQuantity,
    @JsonKey(name: 'unit_id') String? unitId,
    @JsonKey(name: 'property_id') String? propertyId,
    @JsonKey(name: 'sort_order') int sortOrder,
    @JsonKey(name: 'icon_name') String? iconName,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  });
}

/// @nodoc
class _$AdditionalServiceModelCopyWithImpl<
  $Res,
  $Val extends AdditionalServiceModel
>
    implements $AdditionalServiceModelCopyWith<$Res> {
  _$AdditionalServiceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdditionalServiceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = freezed,
    Object? name = null,
    Object? description = freezed,
    Object? nameEn = freezed,
    Object? descriptionEn = freezed,
    Object? serviceType = null,
    Object? price = null,
    Object? currency = null,
    Object? pricingUnit = null,
    Object? isAvailable = null,
    Object? maxQuantity = freezed,
    Object? unitId = freezed,
    Object? propertyId = freezed,
    Object? sortOrder = null,
    Object? iconName = freezed,
    Object? imageUrl = freezed,
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
            ownerId: freezed == ownerId
                ? _value.ownerId
                : ownerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            nameEn: freezed == nameEn
                ? _value.nameEn
                : nameEn // ignore: cast_nullable_to_non_nullable
                      as String?,
            descriptionEn: freezed == descriptionEn
                ? _value.descriptionEn
                : descriptionEn // ignore: cast_nullable_to_non_nullable
                      as String?,
            serviceType: null == serviceType
                ? _value.serviceType
                : serviceType // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            pricingUnit: null == pricingUnit
                ? _value.pricingUnit
                : pricingUnit // ignore: cast_nullable_to_non_nullable
                      as String,
            isAvailable: null == isAvailable
                ? _value.isAvailable
                : isAvailable // ignore: cast_nullable_to_non_nullable
                      as bool,
            maxQuantity: freezed == maxQuantity
                ? _value.maxQuantity
                : maxQuantity // ignore: cast_nullable_to_non_nullable
                      as int?,
            unitId: freezed == unitId
                ? _value.unitId
                : unitId // ignore: cast_nullable_to_non_nullable
                      as String?,
            propertyId: freezed == propertyId
                ? _value.propertyId
                : propertyId // ignore: cast_nullable_to_non_nullable
                      as String?,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            iconName: freezed == iconName
                ? _value.iconName
                : iconName // ignore: cast_nullable_to_non_nullable
                      as String?,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$AdditionalServiceModelImplCopyWith<$Res>
    implements $AdditionalServiceModelCopyWith<$Res> {
  factory _$$AdditionalServiceModelImplCopyWith(
    _$AdditionalServiceModelImpl value,
    $Res Function(_$AdditionalServiceModelImpl) then,
  ) = __$$AdditionalServiceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'owner_id') String? ownerId,
    String name,
    String? description,
    @JsonKey(name: 'name_en') String? nameEn,
    @JsonKey(name: 'description_en') String? descriptionEn,
    @JsonKey(name: 'service_type') String serviceType,
    double price,
    String currency,
    @JsonKey(name: 'pricing_unit') String pricingUnit,
    @JsonKey(name: 'is_available') bool isAvailable,
    @JsonKey(name: 'max_quantity') int? maxQuantity,
    @JsonKey(name: 'unit_id') String? unitId,
    @JsonKey(name: 'property_id') String? propertyId,
    @JsonKey(name: 'sort_order') int sortOrder,
    @JsonKey(name: 'icon_name') String? iconName,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  });
}

/// @nodoc
class __$$AdditionalServiceModelImplCopyWithImpl<$Res>
    extends
        _$AdditionalServiceModelCopyWithImpl<$Res, _$AdditionalServiceModelImpl>
    implements _$$AdditionalServiceModelImplCopyWith<$Res> {
  __$$AdditionalServiceModelImplCopyWithImpl(
    _$AdditionalServiceModelImpl _value,
    $Res Function(_$AdditionalServiceModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AdditionalServiceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = freezed,
    Object? name = null,
    Object? description = freezed,
    Object? nameEn = freezed,
    Object? descriptionEn = freezed,
    Object? serviceType = null,
    Object? price = null,
    Object? currency = null,
    Object? pricingUnit = null,
    Object? isAvailable = null,
    Object? maxQuantity = freezed,
    Object? unitId = freezed,
    Object? propertyId = freezed,
    Object? sortOrder = null,
    Object? iconName = freezed,
    Object? imageUrl = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? deletedAt = freezed,
  }) {
    return _then(
      _$AdditionalServiceModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        ownerId: freezed == ownerId
            ? _value.ownerId
            : ownerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        nameEn: freezed == nameEn
            ? _value.nameEn
            : nameEn // ignore: cast_nullable_to_non_nullable
                  as String?,
        descriptionEn: freezed == descriptionEn
            ? _value.descriptionEn
            : descriptionEn // ignore: cast_nullable_to_non_nullable
                  as String?,
        serviceType: null == serviceType
            ? _value.serviceType
            : serviceType // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        pricingUnit: null == pricingUnit
            ? _value.pricingUnit
            : pricingUnit // ignore: cast_nullable_to_non_nullable
                  as String,
        isAvailable: null == isAvailable
            ? _value.isAvailable
            : isAvailable // ignore: cast_nullable_to_non_nullable
                  as bool,
        maxQuantity: freezed == maxQuantity
            ? _value.maxQuantity
            : maxQuantity // ignore: cast_nullable_to_non_nullable
                  as int?,
        unitId: freezed == unitId
            ? _value.unitId
            : unitId // ignore: cast_nullable_to_non_nullable
                  as String?,
        propertyId: freezed == propertyId
            ? _value.propertyId
            : propertyId // ignore: cast_nullable_to_non_nullable
                  as String?,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        iconName: freezed == iconName
            ? _value.iconName
            : iconName // ignore: cast_nullable_to_non_nullable
                  as String?,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$AdditionalServiceModelImpl extends _AdditionalServiceModel {
  const _$AdditionalServiceModelImpl({
    required this.id,
    @JsonKey(name: 'owner_id') this.ownerId,
    required this.name,
    this.description,
    @JsonKey(name: 'name_en') this.nameEn,
    @JsonKey(name: 'description_en') this.descriptionEn,
    @JsonKey(name: 'service_type') required this.serviceType,
    required this.price,
    this.currency = 'EUR',
    @JsonKey(name: 'pricing_unit') this.pricingUnit = 'per_booking',
    @JsonKey(name: 'is_available') this.isAvailable = true,
    @JsonKey(name: 'max_quantity') this.maxQuantity,
    @JsonKey(name: 'unit_id') this.unitId,
    @JsonKey(name: 'property_id') this.propertyId,
    @JsonKey(name: 'sort_order') this.sortOrder = 0,
    @JsonKey(name: 'icon_name') this.iconName,
    @JsonKey(name: 'image_url') this.imageUrl,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
    @JsonKey(name: 'deleted_at') this.deletedAt,
  }) : super._();

  factory _$AdditionalServiceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdditionalServiceModelImplFromJson(json);

  /// Service ID (UUID)
  @override
  final String id;

  /// Owner ID (nullable for backwards compatibility with legacy services)
  @override
  @JsonKey(name: 'owner_id')
  final String? ownerId;

  /// Service name
  @override
  final String name;

  /// Service description
  @override
  final String? description;

  /// Service name (English)
  @override
  @JsonKey(name: 'name_en')
  final String? nameEn;

  /// Service description (English)
  @override
  @JsonKey(name: 'description_en')
  final String? descriptionEn;

  /// Service type
  @override
  @JsonKey(name: 'service_type')
  final String serviceType;

  /// Price
  @override
  final double price;

  /// Currency (default: EUR)
  @override
  @JsonKey()
  final String currency;

  /// Pricing unit (per_booking, per_night, per_person, per_item)
  @override
  @JsonKey(name: 'pricing_unit')
  final String pricingUnit;

  /// Is service available
  @override
  @JsonKey(name: 'is_available')
  final bool isAvailable;

  /// Maximum quantity (null = unlimited)
  @override
  @JsonKey(name: 'max_quantity')
  final int? maxQuantity;

  /// Unit ID (null = available for all units)
  @override
  @JsonKey(name: 'unit_id')
  final String? unitId;

  /// Property ID (null = available for all properties)
  @override
  @JsonKey(name: 'property_id')
  final String? propertyId;

  /// Sort order for display
  @override
  @JsonKey(name: 'sort_order')
  final int sortOrder;

  /// Icon name (Material icon)
  @override
  @JsonKey(name: 'icon_name')
  final String? iconName;

  /// Image URL
  @override
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  /// Created at timestamp
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Updated at timestamp
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Soft delete timestamp
  @override
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  @override
  String toString() {
    return 'AdditionalServiceModel(id: $id, ownerId: $ownerId, name: $name, description: $description, nameEn: $nameEn, descriptionEn: $descriptionEn, serviceType: $serviceType, price: $price, currency: $currency, pricingUnit: $pricingUnit, isAvailable: $isAvailable, maxQuantity: $maxQuantity, unitId: $unitId, propertyId: $propertyId, sortOrder: $sortOrder, iconName: $iconName, imageUrl: $imageUrl, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdditionalServiceModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.nameEn, nameEn) || other.nameEn == nameEn) &&
            (identical(other.descriptionEn, descriptionEn) ||
                other.descriptionEn == descriptionEn) &&
            (identical(other.serviceType, serviceType) ||
                other.serviceType == serviceType) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.pricingUnit, pricingUnit) ||
                other.pricingUnit == pricingUnit) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.maxQuantity, maxQuantity) ||
                other.maxQuantity == maxQuantity) &&
            (identical(other.unitId, unitId) || other.unitId == unitId) &&
            (identical(other.propertyId, propertyId) ||
                other.propertyId == propertyId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.iconName, iconName) ||
                other.iconName == iconName) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
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
    ownerId,
    name,
    description,
    nameEn,
    descriptionEn,
    serviceType,
    price,
    currency,
    pricingUnit,
    isAvailable,
    maxQuantity,
    unitId,
    propertyId,
    sortOrder,
    iconName,
    imageUrl,
    createdAt,
    updatedAt,
    deletedAt,
  ]);

  /// Create a copy of AdditionalServiceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdditionalServiceModelImplCopyWith<_$AdditionalServiceModelImpl>
  get copyWith =>
      __$$AdditionalServiceModelImplCopyWithImpl<_$AdditionalServiceModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AdditionalServiceModelImplToJson(this);
  }
}

abstract class _AdditionalServiceModel extends AdditionalServiceModel {
  const factory _AdditionalServiceModel({
    required final String id,
    @JsonKey(name: 'owner_id') final String? ownerId,
    required final String name,
    final String? description,
    @JsonKey(name: 'name_en') final String? nameEn,
    @JsonKey(name: 'description_en') final String? descriptionEn,
    @JsonKey(name: 'service_type') required final String serviceType,
    required final double price,
    final String currency,
    @JsonKey(name: 'pricing_unit') final String pricingUnit,
    @JsonKey(name: 'is_available') final bool isAvailable,
    @JsonKey(name: 'max_quantity') final int? maxQuantity,
    @JsonKey(name: 'unit_id') final String? unitId,
    @JsonKey(name: 'property_id') final String? propertyId,
    @JsonKey(name: 'sort_order') final int sortOrder,
    @JsonKey(name: 'icon_name') final String? iconName,
    @JsonKey(name: 'image_url') final String? imageUrl,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
    @JsonKey(name: 'deleted_at') final DateTime? deletedAt,
  }) = _$AdditionalServiceModelImpl;
  const _AdditionalServiceModel._() : super._();

  factory _AdditionalServiceModel.fromJson(Map<String, dynamic> json) =
      _$AdditionalServiceModelImpl.fromJson;

  /// Service ID (UUID)
  @override
  String get id;

  /// Owner ID (nullable for backwards compatibility with legacy services)
  @override
  @JsonKey(name: 'owner_id')
  String? get ownerId;

  /// Service name
  @override
  String get name;

  /// Service description
  @override
  String? get description;

  /// Service name (English)
  @override
  @JsonKey(name: 'name_en')
  String? get nameEn;

  /// Service description (English)
  @override
  @JsonKey(name: 'description_en')
  String? get descriptionEn;

  /// Service type
  @override
  @JsonKey(name: 'service_type')
  String get serviceType;

  /// Price
  @override
  double get price;

  /// Currency (default: EUR)
  @override
  String get currency;

  /// Pricing unit (per_booking, per_night, per_person, per_item)
  @override
  @JsonKey(name: 'pricing_unit')
  String get pricingUnit;

  /// Is service available
  @override
  @JsonKey(name: 'is_available')
  bool get isAvailable;

  /// Maximum quantity (null = unlimited)
  @override
  @JsonKey(name: 'max_quantity')
  int? get maxQuantity;

  /// Unit ID (null = available for all units)
  @override
  @JsonKey(name: 'unit_id')
  String? get unitId;

  /// Property ID (null = available for all properties)
  @override
  @JsonKey(name: 'property_id')
  String? get propertyId;

  /// Sort order for display
  @override
  @JsonKey(name: 'sort_order')
  int get sortOrder;

  /// Icon name (Material icon)
  @override
  @JsonKey(name: 'icon_name')
  String? get iconName;

  /// Image URL
  @override
  @JsonKey(name: 'image_url')
  String? get imageUrl;

  /// Created at timestamp
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Updated at timestamp
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Soft delete timestamp
  @override
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt;

  /// Create a copy of AdditionalServiceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdditionalServiceModelImplCopyWith<_$AdditionalServiceModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
