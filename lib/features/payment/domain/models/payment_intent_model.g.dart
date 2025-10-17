// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_intent_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentIntentModel _$PaymentIntentModelFromJson(Map<String, dynamic> json) =>
    _PaymentIntentModel(
      clientSecret: json['clientSecret'] as String,
      paymentIntentId: json['paymentIntentId'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String? ?? 'eur',
      bookingId: json['bookingId'] as String?,
    );

Map<String, dynamic> _$PaymentIntentModelToJson(_PaymentIntentModel instance) =>
    <String, dynamic>{
      'clientSecret': instance.clientSecret,
      'paymentIntentId': instance.paymentIntentId,
      'amount': instance.amount,
      'currency': instance.currency,
      'bookingId': instance.bookingId,
    };
