// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BookingServiceModelImpl _$$BookingServiceModelImplFromJson(
  Map<String, dynamic> json,
) => _$BookingServiceModelImpl(
  id: json['id'] as String,
  bookingId: json['booking_id'] as String,
  serviceId: json['service_id'] as String,
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  unitPrice: (json['unit_price'] as num).toDouble(),
  totalPrice: (json['total_price'] as num).toDouble(),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$$BookingServiceModelImplToJson(
  _$BookingServiceModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'booking_id': instance.bookingId,
  'service_id': instance.serviceId,
  'quantity': instance.quantity,
  'unit_price': instance.unitPrice,
  'total_price': instance.totalPrice,
  'created_at': instance.createdAt.toIso8601String(),
};
