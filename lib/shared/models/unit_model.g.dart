// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UnitModelImpl _$$UnitModelImplFromJson(
  Map<String, dynamic> json,
) => _$UnitModelImpl(
  id: json['id'] as String,
  propertyId: json['property_id'] as String,
  ownerId: json['owner_id'] as String?,
  name: json['name'] as String,
  slug: json['slug'] as String?,
  description: json['description'] as String?,
  pricePerNight: (json['base_price'] as num).toDouble(),
  weekendBasePrice: (json['weekend_base_price'] as num?)?.toDouble(),
  weekendDays: (json['weekend_days'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  currency: json['currency'] as String? ?? 'EUR',
  maxGuests: (json['max_guests'] as num).toInt(),
  bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 1,
  bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 1,
  areaSqm: (json['area_sqm'] as num?)?.toDouble(),
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isAvailable: json['is_available'] as bool? ?? true,
  minStayNights: (json['min_stay_nights'] as num?)?.toInt() ?? 1,
  maxStayNights: (json['max_stay_nights'] as num?)?.toInt(),
  sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  createdAt: const TimestampConverter().fromJson(json['created_at']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updated_at']),
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
);

Map<String, dynamic> _$$UnitModelImplToJson(
  _$UnitModelImpl instance,
) => <String, dynamic>{
  'property_id': instance.propertyId,
  'owner_id': instance.ownerId,
  'name': instance.name,
  'slug': instance.slug,
  'description': instance.description,
  'base_price': instance.pricePerNight,
  'weekend_base_price': instance.weekendBasePrice,
  'weekend_days': instance.weekendDays,
  'currency': instance.currency,
  'max_guests': instance.maxGuests,
  'bedrooms': instance.bedrooms,
  'bathrooms': instance.bathrooms,
  'area_sqm': instance.areaSqm,
  'images': instance.images,
  'is_available': instance.isAvailable,
  'min_stay_nights': instance.minStayNights,
  'max_stay_nights': instance.maxStayNights,
  'sort_order': instance.sortOrder,
  'created_at': const TimestampConverter().toJson(instance.createdAt),
  'updated_at': const NullableTimestampConverter().toJson(instance.updatedAt),
  'deleted_at': instance.deletedAt?.toIso8601String(),
};
