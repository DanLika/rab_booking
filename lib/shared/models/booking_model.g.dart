// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BookingModelImpl _$$BookingModelImplFromJson(Map<String, dynamic> json) =>
    _$BookingModelImpl(
      id: json['id'] as String,
      unitId: json['unit_id'] as String,
      userId: json['user_id'] as String,
      checkIn: DateTime.parse(json['check_in'] as String),
      checkOut: DateTime.parse(json['check_out'] as String),
      status: $enumDecode(_$BookingStatusEnumMap, json['status']),
      totalPrice: (json['total_price'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num).toDouble(),
      guestCount: (json['guest_count'] as num).toInt(),
      notes: json['notes'] as String?,
      paymentIntentId: json['payment_intent_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledAt: json['cancelled_at'] == null
          ? null
          : DateTime.parse(json['cancelled_at'] as String),
    );

Map<String, dynamic> _$$BookingModelImplToJson(_$BookingModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'unit_id': instance.unitId,
      'user_id': instance.userId,
      'check_in': instance.checkIn.toIso8601String(),
      'check_out': instance.checkOut.toIso8601String(),
      'status': _$BookingStatusEnumMap[instance.status]!,
      'total_price': instance.totalPrice,
      'paid_amount': instance.paidAmount,
      'guest_count': instance.guestCount,
      'notes': instance.notes,
      'payment_intent_id': instance.paymentIntentId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'cancellation_reason': instance.cancellationReason,
      'cancelled_at': instance.cancelledAt?.toIso8601String(),
    };

const _$BookingStatusEnumMap = {
  BookingStatus.pending: 'pending',
  BookingStatus.confirmed: 'confirmed',
  BookingStatus.cancelled: 'cancelled',
  BookingStatus.completed: 'completed',
  BookingStatus.refunded: 'refunded',
  BookingStatus.blocked: 'blocked',
};
