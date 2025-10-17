// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookingModel _$BookingModelFromJson(Map<String, dynamic> json) =>
    _BookingModel(
      id: json['id'] as String,
      unitId: json['unitId'] as String,
      guestId: json['guestId'] as String,
      checkIn: DateTime.parse(json['checkIn'] as String),
      checkOut: DateTime.parse(json['checkOut'] as String),
      status: $enumDecode(_$BookingStatusEnumMap, json['status']),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      guestCount: (json['guestCount'] as num).toInt(),
      notes: json['notes'] as String?,
      paymentIntentId: json['paymentIntentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt:
          json['updatedAt'] == null
              ? null
              : DateTime.parse(json['updatedAt'] as String),
      cancellationReason: json['cancellationReason'] as String?,
      cancelledAt:
          json['cancelledAt'] == null
              ? null
              : DateTime.parse(json['cancelledAt'] as String),
    );

Map<String, dynamic> _$BookingModelToJson(_BookingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'unitId': instance.unitId,
      'guestId': instance.guestId,
      'checkIn': instance.checkIn.toIso8601String(),
      'checkOut': instance.checkOut.toIso8601String(),
      'status': _$BookingStatusEnumMap[instance.status]!,
      'totalPrice': instance.totalPrice,
      'paidAmount': instance.paidAmount,
      'guestCount': instance.guestCount,
      'notes': instance.notes,
      'paymentIntentId': instance.paymentIntentId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'cancellationReason': instance.cancellationReason,
      'cancelledAt': instance.cancelledAt?.toIso8601String(),
    };

const _$BookingStatusEnumMap = {
  BookingStatus.pending: 'pending',
  BookingStatus.confirmed: 'confirmed',
  BookingStatus.cancelled: 'cancelled',
  BookingStatus.completed: 'completed',
};
