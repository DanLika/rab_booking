import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_intent_model.freezed.dart';
part 'payment_intent_model.g.dart';

/// Payment Intent model for Stripe
@freezed
class PaymentIntentModel with _$PaymentIntentModel {
  const factory PaymentIntentModel({
    required String clientSecret,
    required String paymentIntentId,
    required int amount,
    @Default('eur') String currency,
    String? bookingId,
  }) = _PaymentIntentModel;

  factory PaymentIntentModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentIntentModelFromJson(json);
}
