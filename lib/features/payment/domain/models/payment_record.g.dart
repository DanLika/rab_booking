// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentRecord _$PaymentRecordFromJson(Map<String, dynamic> json) =>
    _PaymentRecord(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      amount: (json['amount'] as num).toInt(),
      status: json['status'] as String,
      stripePaymentId: json['stripePaymentId'] as String,
      currency: json['currency'] as String? ?? 'eur',
      stripeChargeId: json['stripeChargeId'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      failureMessage: json['failureMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt:
          json['updatedAt'] == null
              ? null
              : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$PaymentRecordToJson(_PaymentRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookingId': instance.bookingId,
      'amount': instance.amount,
      'status': instance.status,
      'stripePaymentId': instance.stripePaymentId,
      'currency': instance.currency,
      'stripeChargeId': instance.stripeChargeId,
      'receiptUrl': instance.receiptUrl,
      'failureMessage': instance.failureMessage,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
