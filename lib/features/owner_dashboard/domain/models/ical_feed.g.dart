// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ical_feed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IcalFeedImpl _$$IcalFeedImplFromJson(Map<String, dynamic> json) =>
    _$IcalFeedImpl(
      id: json['id'] as String,
      unitId: json['unitId'] as String,
      propertyId: json['propertyId'] as String,
      platform: $enumDecode(_$IcalPlatformEnumMap, json['platform']),
      icalUrl: json['icalUrl'] as String,
      syncIntervalMinutes: (json['syncIntervalMinutes'] as num?)?.toInt() ?? 60,
      lastSynced: json['lastSynced'] == null
          ? null
          : DateTime.parse(json['lastSynced'] as String),
      status:
          $enumDecodeNullable(_$IcalStatusEnumMap, json['status']) ??
          IcalStatus.active,
      lastError: json['lastError'] as String?,
      syncCount: (json['syncCount'] as num?)?.toInt() ?? 0,
      eventCount: (json['eventCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$IcalFeedImplToJson(_$IcalFeedImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'unitId': instance.unitId,
      'propertyId': instance.propertyId,
      'platform': _$IcalPlatformEnumMap[instance.platform]!,
      'icalUrl': instance.icalUrl,
      'syncIntervalMinutes': instance.syncIntervalMinutes,
      'lastSynced': instance.lastSynced?.toIso8601String(),
      'status': _$IcalStatusEnumMap[instance.status]!,
      'lastError': instance.lastError,
      'syncCount': instance.syncCount,
      'eventCount': instance.eventCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$IcalPlatformEnumMap = {
  IcalPlatform.bookingCom: 'booking_com',
  IcalPlatform.airbnb: 'airbnb',
  IcalPlatform.other: 'other',
};

const _$IcalStatusEnumMap = {
  IcalStatus.active: 'active',
  IcalStatus.error: 'error',
  IcalStatus.paused: 'paused',
};

_$IcalEventImpl _$$IcalEventImplFromJson(Map<String, dynamic> json) =>
    _$IcalEventImpl(
      id: json['id'] as String,
      unitId: json['unitId'] as String,
      feedId: json['feedId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      guestName: json['guestName'] as String,
      source: json['source'] as String,
      externalId: json['externalId'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$IcalEventImplToJson(_$IcalEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'unitId': instance.unitId,
      'feedId': instance.feedId,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'guestName': instance.guestName,
      'source': instance.source,
      'externalId': instance.externalId,
      'description': instance.description,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
