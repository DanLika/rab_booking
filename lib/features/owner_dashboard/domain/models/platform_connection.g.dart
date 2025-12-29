// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlatformConnectionImpl _$$PlatformConnectionImplFromJson(
  Map<String, dynamic> json,
) => _$PlatformConnectionImpl(
  id: json['id'] as String,
  ownerId: json['ownerId'] as String,
  platform: $enumDecode(_$PlatformTypeEnumMap, json['platform']),
  unitId: json['unitId'] as String,
  externalPropertyId: json['externalPropertyId'] as String,
  externalUnitId: json['externalUnitId'] as String,
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  status:
      $enumDecodeNullable(_$ConnectionStatusEnumMap, json['status']) ??
      ConnectionStatus.pending,
  lastError: json['lastError'] as String?,
  lastSyncedAt: json['lastSyncedAt'] == null
      ? null
      : DateTime.parse(json['lastSyncedAt'] as String),
  lastSyncEventCount: (json['lastSyncEventCount'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$PlatformConnectionImplToJson(
  _$PlatformConnectionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'ownerId': instance.ownerId,
  'platform': _$PlatformTypeEnumMap[instance.platform]!,
  'unitId': instance.unitId,
  'externalPropertyId': instance.externalPropertyId,
  'externalUnitId': instance.externalUnitId,
  'expiresAt': instance.expiresAt.toIso8601String(),
  'status': _$ConnectionStatusEnumMap[instance.status]!,
  'lastError': instance.lastError,
  'lastSyncedAt': instance.lastSyncedAt?.toIso8601String(),
  'lastSyncEventCount': instance.lastSyncEventCount,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$PlatformTypeEnumMap = {
  PlatformType.bookingCom: 'booking_com',
  PlatformType.airbnb: 'airbnb',
};

const _$ConnectionStatusEnumMap = {
  ConnectionStatus.active: 'active',
  ConnectionStatus.expired: 'expired',
  ConnectionStatus.error: 'error',
  ConnectionStatus.pending: 'pending',
};
