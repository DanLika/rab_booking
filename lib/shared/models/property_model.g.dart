// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PropertyModel _$PropertyModelFromJson(Map<String, dynamic> json) =>
    _PropertyModel(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      amenities:
          (json['amenities'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$PropertyAmenityEnumMap, e))
              .toList() ??
          const [],
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      coverImage: json['coverImage'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$PropertyModelToJson(_PropertyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ownerId': instance.ownerId,
      'name': instance.name,
      'description': instance.description,
      'location': instance.location,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'amenities': instance.amenities
          .map((e) => _$PropertyAmenityEnumMap[e]!)
          .toList(),
      'images': instance.images,
      'coverImage': instance.coverImage,
      'rating': instance.rating,
      'reviewCount': instance.reviewCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isActive': instance.isActive,
    };

const _$PropertyAmenityEnumMap = {
  PropertyAmenity.wifi: 'wifi',
  PropertyAmenity.parking: 'parking',
  PropertyAmenity.pool: 'pool',
  PropertyAmenity.airConditioning: 'air_conditioning',
  PropertyAmenity.heating: 'heating',
  PropertyAmenity.kitchen: 'kitchen',
  PropertyAmenity.washingMachine: 'washing_machine',
  PropertyAmenity.tv: 'tv',
  PropertyAmenity.balcony: 'balcony',
  PropertyAmenity.seaView: 'sea_view',
  PropertyAmenity.petFriendly: 'pet_friendly',
  PropertyAmenity.bbq: 'bbq',
  PropertyAmenity.outdoorFurniture: 'outdoor_furniture',
  PropertyAmenity.beachAccess: 'beach_access',
  PropertyAmenity.fireplace: 'fireplace',
  PropertyAmenity.gym: 'gym',
  PropertyAmenity.hotTub: 'hot_tub',
  PropertyAmenity.sauna: 'sauna',
  PropertyAmenity.bicycleRental: 'bicycle_rental',
  PropertyAmenity.boatMooring: 'boat_mooring',
};
