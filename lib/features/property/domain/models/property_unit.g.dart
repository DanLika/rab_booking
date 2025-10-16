// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_unit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PropertyUnitImpl _$$PropertyUnitImplFromJson(
  Map<String, dynamic> json,
) => _$PropertyUnitImpl(
  id: json['id'] as String,
  propertyId: json['propertyId'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  pricePerNight: (json['pricePerNight'] as num).toDouble(),
  maxGuests: (json['maxGuests'] as num).toInt(),
  bedrooms: (json['bedrooms'] as num).toInt(),
  bathrooms: (json['bathrooms'] as num).toInt(),
  area: (json['area'] as num).toDouble(),
  amenities:
      (json['amenities'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  coverImage: json['coverImage'] as String?,
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  minStayNights: (json['minStayNights'] as num?)?.toInt() ?? 1,
  isAvailable: json['isAvailable'] as bool? ?? true,
  createdAt:
      json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
  updatedAt:
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$PropertyUnitImplToJson(_$PropertyUnitImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'propertyId': instance.propertyId,
      'name': instance.name,
      'description': instance.description,
      'pricePerNight': instance.pricePerNight,
      'maxGuests': instance.maxGuests,
      'bedrooms': instance.bedrooms,
      'bathrooms': instance.bathrooms,
      'area': instance.area,
      'amenities': instance.amenities,
      'images': instance.images,
      'coverImage': instance.coverImage,
      'quantity': instance.quantity,
      'minStayNights': instance.minStayNights,
      'isAvailable': instance.isAvailable,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
