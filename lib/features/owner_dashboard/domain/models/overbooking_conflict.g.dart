// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overbooking_conflict.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OverbookingConflictImpl _$$OverbookingConflictImplFromJson(
  Map<String, dynamic> json,
) => _$OverbookingConflictImpl(
  id: json['id'] as String,
  unitId: json['unitId'] as String,
  unitName: json['unitName'] as String,
  booking1: BookingModel.fromJson(json['booking1'] as Map<String, dynamic>),
  booking2: BookingModel.fromJson(json['booking2'] as Map<String, dynamic>),
  conflictDates: (json['conflictDates'] as List<dynamic>)
      .map((e) => DateTime.parse(e as String))
      .toList(),
  detectedAt: DateTime.parse(json['detectedAt'] as String),
  isResolved: json['isResolved'] as bool? ?? false,
);

Map<String, dynamic> _$$OverbookingConflictImplToJson(
  _$OverbookingConflictImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'unitId': instance.unitId,
  'unitName': instance.unitName,
  'booking1': instance.booking1,
  'booking2': instance.booking2,
  'conflictDates': instance.conflictDates
      .map((e) => e.toIso8601String())
      .toList(),
  'detectedAt': instance.detectedAt.toIso8601String(),
  'isResolved': instance.isResolved,
};
