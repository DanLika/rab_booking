// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_filter_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CalendarFilterOptionsImpl _$$CalendarFilterOptionsImplFromJson(
  Map<String, dynamic> json,
) => _$CalendarFilterOptionsImpl(
  propertyIds:
      (json['propertyIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  unitIds:
      (json['unitIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  statuses:
      (json['statuses'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  sources:
      (json['sources'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  startDate: json['startDate'] == null
      ? null
      : DateTime.parse(json['startDate'] as String),
  endDate: json['endDate'] == null
      ? null
      : DateTime.parse(json['endDate'] as String),
  guestSearchQuery: json['guestSearchQuery'] as String?,
  bookingIdSearch: json['bookingIdSearch'] as String?,
);

Map<String, dynamic> _$$CalendarFilterOptionsImplToJson(
  _$CalendarFilterOptionsImpl instance,
) => <String, dynamic>{
  'propertyIds': instance.propertyIds,
  'unitIds': instance.unitIds,
  'statuses': instance.statuses,
  'sources': instance.sources,
  'startDate': instance.startDate?.toIso8601String(),
  'endDate': instance.endDate?.toIso8601String(),
  'guestSearchQuery': instance.guestSearchQuery,
  'bookingIdSearch': instance.bookingIdSearch,
};
