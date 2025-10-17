// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_filters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchFilters _$SearchFiltersFromJson(Map<String, dynamic> json) =>
    _SearchFilters(
      location: json['location'] as String?,
      checkIn: json['checkIn'] == null
          ? null
          : DateTime.parse(json['checkIn'] as String),
      checkOut: json['checkOut'] == null
          ? null
          : DateTime.parse(json['checkOut'] as String),
      guests: (json['guests'] as num?)?.toInt() ?? 2,
      minPrice: (json['minPrice'] as num?)?.toDouble(),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      propertyTypes:
          (json['propertyTypes'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$PropertyTypeEnumMap, e))
              .toList() ??
          const [],
      amenities:
          (json['amenities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      minBedrooms: (json['minBedrooms'] as num?)?.toInt(),
      minBathrooms: (json['minBathrooms'] as num?)?.toInt(),
      sortBy:
          $enumDecodeNullable(_$SortByEnumMap, json['sortBy']) ??
          SortBy.recommended,
      page: (json['page'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
    );

Map<String, dynamic> _$SearchFiltersToJson(_SearchFilters instance) =>
    <String, dynamic>{
      'location': instance.location,
      'checkIn': instance.checkIn?.toIso8601String(),
      'checkOut': instance.checkOut?.toIso8601String(),
      'guests': instance.guests,
      'minPrice': instance.minPrice,
      'maxPrice': instance.maxPrice,
      'propertyTypes': instance.propertyTypes
          .map((e) => _$PropertyTypeEnumMap[e]!)
          .toList(),
      'amenities': instance.amenities,
      'minBedrooms': instance.minBedrooms,
      'minBathrooms': instance.minBathrooms,
      'sortBy': _$SortByEnumMap[instance.sortBy]!,
      'page': instance.page,
      'pageSize': instance.pageSize,
    };

const _$PropertyTypeEnumMap = {
  PropertyType.villa: 'villa',
  PropertyType.apartment: 'apartment',
  PropertyType.house: 'house',
  PropertyType.studio: 'studio',
};

const _$SortByEnumMap = {
  SortBy.recommended: 'recommended',
  SortBy.priceLowToHigh: 'priceLowToHigh',
  SortBy.priceHighToLow: 'priceHighToLow',
  SortBy.rating: 'rating',
  SortBy.newest: 'newest',
};
