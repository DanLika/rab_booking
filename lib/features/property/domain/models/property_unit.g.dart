// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_unit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PropertyUnitImpl _$$PropertyUnitImplFromJson(
  Map<String, dynamic> json,
) => _$PropertyUnitImpl(
  id: json['id'] as String,
  propertyId: json['property_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  pricePerNight: (json['base_price'] as num).toDouble(),
  maxGuests: (json['max_guests'] as num).toInt(),
  bedrooms: (json['bedrooms'] as num).toInt(),
  bathrooms: (json['bathrooms'] as num).toInt(),
  area: (json['area'] as num).toDouble(),
  amenities:
      (json['amenities'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  coverImage: json['cover_image'] as String?,
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  minStayNights: (json['min_stay_nights'] as num?)?.toInt() ?? 1,
  isAvailable: json['is_available'] as bool? ?? true,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$$PropertyUnitImplToJson(_$PropertyUnitImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'property_id': instance.propertyId,
      'name': instance.name,
      'description': instance.description,
      'base_price': instance.pricePerNight,
      'max_guests': instance.maxGuests,
      'bedrooms': instance.bedrooms,
      'bathrooms': instance.bathrooms,
      'area': instance.area,
      'amenities': instance.amenities,
      'images': instance.images,
      'cover_image': instance.coverImage,
      'quantity': instance.quantity,
      'min_stay_nights': instance.minStayNights,
      'is_available': instance.isAvailable,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
