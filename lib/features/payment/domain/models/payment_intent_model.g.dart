// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_intent_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaymentIntentModelImpl _$$PaymentIntentModelImplFromJson(
  Map<String, dynamic> json,
) => _$PaymentIntentModelImpl(
  clientSecret: json['clientSecret'] as String,
  paymentIntentId: json['paymentIntentId'] as String,
  amount: (json['amount'] as num).toInt(),
  currency: json['currency'] as String? ?? 'eur',
  bookingId: json['bookingId'] as String?,
);

Map<String, dynamic> _$$PaymentIntentModelImplToJson(
  _$PaymentIntentModelImpl instance,
) => <String, dynamic>{
  'clientSecret': instance.clientSecret,
  'paymentIntentId': instance.paymentIntentId,
  'amount': instance.amount,
  'currency': instance.currency,
  'bookingId': instance.bookingId,
};
