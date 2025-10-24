import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_info.freezed.dart';
part 'payment_info.g.dart';

/// Podaci za uplatu (IBAN, bank account)
@freezed
class PaymentInfo with _$PaymentInfo {
  const factory PaymentInfo({
    required String id,
    required String ownerId,
    String? bankName,
    required String iban,
    String? swift,
    required String accountHolder,
    @Default(20.0) double defaultAdvancePercentage,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PaymentInfo;

  factory PaymentInfo.fromJson(Map<String, dynamic> json) =>
      _$PaymentInfoFromJson(json);
}
