// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BookingModelImpl _$$BookingModelImplFromJson(Map<String, dynamic> json) =>
    _$BookingModelImpl(
      id: json['id'] as String,
      unitId: json['unit_id'] as String,
      userId: json['user_id'] as String?,
      guestId: json['guest_id'] as String?,
      ownerId: json['owner_id'] as String?,
      guestName: json['guest_name'] as String?,
      guestEmail: json['guest_email'] as String?,
      guestPhone: json['guest_phone'] as String?,
      checkIn: const TimestampConverter().fromJson(json['check_in']),
      checkInTime: json['check_in_time'] as String?,
      checkOutTime: json['check_out_time'] as String?,
      checkOut: const TimestampConverter().fromJson(json['check_out']),
      status: $enumDecode(_$BookingStatusEnumMap, json['status']),
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      advanceAmount: (json['advance_amount'] as num?)?.toDouble(),
      paymentMethod: json['payment_method'] as String?,
      paymentStatus: json['payment_status'] as String?,
      source: json['source'] as String?,
      guestCount: (json['guest_count'] as num?)?.toInt() ?? 1,
      notes: json['notes'] as String?,
      paymentIntentId: json['payment_intent_id'] as String?,
      createdAt: const TimestampConverter().fromJson(json['created_at']),
      updatedAt: const NullableTimestampConverter().fromJson(
        json['updated_at'],
      ),
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledAt: const NullableTimestampConverter().fromJson(
        json['cancelled_at'],
      ),
      cancelledBy: json['cancelled_by'] as String?,
    );

Map<String, dynamic> _$$BookingModelImplToJson(
  _$BookingModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'unit_id': instance.unitId,
  'user_id': instance.userId,
  'guest_id': instance.guestId,
  'owner_id': instance.ownerId,
  'guest_name': instance.guestName,
  'guest_email': instance.guestEmail,
  'guest_phone': instance.guestPhone,
  'check_in': const TimestampConverter().toJson(instance.checkIn),
  'check_in_time': instance.checkInTime,
  'check_out_time': instance.checkOutTime,
  'check_out': const TimestampConverter().toJson(instance.checkOut),
  'status': _$BookingStatusEnumMap[instance.status]!,
  'total_price': instance.totalPrice,
  'paid_amount': instance.paidAmount,
  'advance_amount': instance.advanceAmount,
  'payment_method': instance.paymentMethod,
  'payment_status': instance.paymentStatus,
  'source': instance.source,
  'guest_count': instance.guestCount,
  'notes': instance.notes,
  'payment_intent_id': instance.paymentIntentId,
  'created_at': const TimestampConverter().toJson(instance.createdAt),
  'updated_at': const NullableTimestampConverter().toJson(instance.updatedAt),
  'cancellation_reason': instance.cancellationReason,
  'cancelled_at': const NullableTimestampConverter().toJson(
    instance.cancelledAt,
  ),
  'cancelled_by': instance.cancelledBy,
};

const _$BookingStatusEnumMap = {
  BookingStatus.pending: 'pending',
  BookingStatus.confirmed: 'confirmed',
  BookingStatus.checkedIn: 'checked_in',
  BookingStatus.checkedOut: 'checked_out',
  BookingStatus.cancelled: 'cancelled',
  BookingStatus.completed: 'completed',
  BookingStatus.inProgress: 'in_progress',
  BookingStatus.blocked: 'blocked',
};
