// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UnitModel _$UnitModelFromJson(Map<String, dynamic> json) => _UnitModel(
  id: json['id'] as String,
  propertyId: json['propertyId'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  pricePerNight: (json['pricePerNight'] as num).toDouble(),
  maxGuests: (json['maxGuests'] as num).toInt(),
  bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 1,
  bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 1,
  areaSqm: (json['areaSqm'] as num?)?.toDouble(),
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isAvailable: json['isAvailable'] as bool? ?? true,
  minStayNights: (json['minStayNights'] as num?)?.toInt() ?? 1,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UnitModelToJson(_UnitModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'propertyId': instance.propertyId,
      'name': instance.name,
      'description': instance.description,
      'pricePerNight': instance.pricePerNight,
      'maxGuests': instance.maxGuests,
      'bedrooms': instance.bedrooms,
      'bathrooms': instance.bathrooms,
      'areaSqm': instance.areaSqm,
      'images': instance.images,
      'isAvailable': instance.isAvailable,
      'minStayNights': instance.minStayNights,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
