// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'additional_service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AdditionalServiceModelImpl _$$AdditionalServiceModelImplFromJson(
  Map<String, dynamic> json,
) => _$AdditionalServiceModelImpl(
  id: json['id'] as String,
  ownerId: json['owner_id'] as String?,
  name: json['name'] as String,
  description: json['description'] as String?,
  nameEn: json['name_en'] as String?,
  descriptionEn: json['description_en'] as String?,
  serviceType: json['service_type'] as String,
  price: (json['price'] as num).toDouble(),
  currency: json['currency'] as String? ?? 'EUR',
  pricingUnit: json['pricing_unit'] as String? ?? 'per_booking',
  isAvailable: json['is_available'] as bool? ?? true,
  maxQuantity: (json['max_quantity'] as num?)?.toInt(),
  unitId: json['unit_id'] as String?,
  propertyId: json['property_id'] as String?,
  sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  iconName: json['icon_name'] as String?,
  imageUrl: json['image_url'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
);

Map<String, dynamic> _$$AdditionalServiceModelImplToJson(
  _$AdditionalServiceModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'owner_id': instance.ownerId,
  'name': instance.name,
  'description': instance.description,
  'name_en': instance.nameEn,
  'description_en': instance.descriptionEn,
  'service_type': instance.serviceType,
  'price': instance.price,
  'currency': instance.currency,
  'pricing_unit': instance.pricingUnit,
  'is_available': instance.isAvailable,
  'max_quantity': instance.maxQuantity,
  'unit_id': instance.unitId,
  'property_id': instance.propertyId,
  'sort_order': instance.sortOrder,
  'icon_name': instance.iconName,
  'image_url': instance.imageUrl,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'deleted_at': instance.deletedAt?.toIso8601String(),
};
