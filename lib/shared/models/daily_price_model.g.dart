// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_price_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DailyPriceModelImpl _$$DailyPriceModelImplFromJson(
  Map<String, dynamic> json,
) => _$DailyPriceModelImpl(
  id: json['id'] as String,
  unitId: json['unit_id'] as String,
  date: const TimestampConverter().fromJson(json['date']),
  price: (json['price'] as num).toDouble(),
  available: json['available'] as bool? ?? true,
  blockCheckIn: json['block_checkin'] as bool? ?? false,
  blockCheckOut: json['block_checkout'] as bool? ?? false,
  minNightsOnArrival: (json['min_nights_on_arrival'] as num?)?.toInt(),
  maxNightsOnArrival: (json['max_nights_on_arrival'] as num?)?.toInt(),
  weekendPrice: (json['weekend_price'] as num?)?.toDouble(),
  minDaysAdvance: (json['min_days_advance'] as num?)?.toInt(),
  maxDaysAdvance: (json['max_days_advance'] as num?)?.toInt(),
  createdAt: const TimestampConverter().fromJson(json['created_at']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$$DailyPriceModelImplToJson(
  _$DailyPriceModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'unit_id': instance.unitId,
  'date': const TimestampConverter().toJson(instance.date),
  'price': instance.price,
  'available': instance.available,
  'block_checkin': instance.blockCheckIn,
  'block_checkout': instance.blockCheckOut,
  'min_nights_on_arrival': instance.minNightsOnArrival,
  'max_nights_on_arrival': instance.maxNightsOnArrival,
  'weekend_price': instance.weekendPrice,
  'min_days_advance': instance.minDaysAdvance,
  'max_days_advance': instance.maxDaysAdvance,
  'created_at': const TimestampConverter().toJson(instance.createdAt),
  'updated_at': const NullableTimestampConverter().toJson(instance.updatedAt),
};
