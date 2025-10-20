// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UnitModelImpl _$$UnitModelImplFromJson(Map<String, dynamic> json) =>
    _$UnitModelImpl(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      pricePerNight: (json['base_price'] as num).toDouble(),
      maxGuests: (json['max_guests'] as num).toInt(),
      bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 1,
      bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 1,
      areaSqm: (json['area_sqm'] as num?)?.toDouble(),
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isAvailable: json['is_available'] as bool? ?? true,
      minStayNights: (json['min_stay_nights'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$UnitModelImplToJson(_$UnitModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'property_id': instance.propertyId,
      'name': instance.name,
      'description': instance.description,
      'base_price': instance.pricePerNight,
      'max_guests': instance.maxGuests,
      'bedrooms': instance.bedrooms,
      'bathrooms': instance.bathrooms,
      'area_sqm': instance.areaSqm,
      'images': instance.images,
      'is_available': instance.isAvailable,
      'min_stay_nights': instance.minStayNights,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
