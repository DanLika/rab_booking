// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PropertyModelImpl _$$PropertyModelImplFromJson(
  Map<String, dynamic> json,
) => _$PropertyModelImpl(
  id: json['id'] as String,
  ownerId: json['owner_id'] as String,
  name: json['name'] as String,
  slug: json['slug'] as String?,
  description: json['description'] as String,
  propertyType:
      $enumDecodeNullable(_$PropertyTypeEnumMap, json['property_type']) ??
      PropertyType.apartment,
  location: json['location'] as String,
  city: json['city'] as String?,
  country: json['country'] as String? ?? 'Croatia',
  postalCode: json['postal_code'] as String?,
  address: json['address'] as String?,
  latlng: geoPointFromJson(json['latlng']),
  amenities:
      (json['amenities'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$PropertyAmenityEnumMap, e))
          .toList() ??
      const [],
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  coverImage: json['cover_image'] as String?,
  rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
  reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
  unitsCount: (json['units_count'] as num?)?.toInt() ?? 0,
  createdAt: const TimestampConverter().fromJson(json['created_at']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updated_at']),
  isActive: json['is_active'] as bool? ?? true,
  pricePerNight: (json['base_price'] as num?)?.toDouble(),
  maxGuests: (json['max_guests'] as num?)?.toInt(),
  bedrooms: (json['bedrooms'] as num?)?.toInt(),
  bathrooms: (json['bathrooms'] as num?)?.toInt(),
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
);

Map<String, dynamic> _$$PropertyModelImplToJson(
  _$PropertyModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'owner_id': instance.ownerId,
  'name': instance.name,
  'slug': instance.slug,
  'description': instance.description,
  'property_type': _$PropertyTypeEnumMap[instance.propertyType]!,
  'location': instance.location,
  'city': instance.city,
  'country': instance.country,
  'postal_code': instance.postalCode,
  'address': instance.address,
  'latlng': geoPointToJson(instance.latlng),
  'amenities': instance.amenities
      .map((e) => _$PropertyAmenityEnumMap[e]!)
      .toList(),
  'images': instance.images,
  'cover_image': instance.coverImage,
  'rating': instance.rating,
  'review_count': instance.reviewCount,
  'units_count': instance.unitsCount,
  'created_at': const TimestampConverter().toJson(instance.createdAt),
  'updated_at': const NullableTimestampConverter().toJson(instance.updatedAt),
  'is_active': instance.isActive,
  'base_price': instance.pricePerNight,
  'max_guests': instance.maxGuests,
  'bedrooms': instance.bedrooms,
  'bathrooms': instance.bathrooms,
  'deleted_at': instance.deletedAt?.toIso8601String(),
};

const _$PropertyTypeEnumMap = {
  PropertyType.villa: 'villa',
  PropertyType.apartment: 'apartment',
  PropertyType.studio: 'studio',
  PropertyType.house: 'house',
  PropertyType.room: 'room',
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
