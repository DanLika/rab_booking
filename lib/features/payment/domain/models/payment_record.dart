import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_record.freezed.dart';
part 'payment_record.g.dart';

/// Payment record model for database
@freezed
class PaymentRecord with _$PaymentRecord {
  const factory PaymentRecord({
    required String id,
    required String bookingId,
    required int amount,
    required String status, // pending, completed, failed, refunded
    required String stripePaymentId,
    @Default('eur') String currency,
    String? stripeChargeId,
    String? receiptUrl,
    String? failureMessage,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _PaymentRecord;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) =>
      _$PaymentRecordFromJson(json);
}

/// Payment status enum
enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded;

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Na čekanju';
      case PaymentStatus.completed:
        return 'Uspješno';
      case PaymentStatus.failed:
        return 'Neuspješno';
      case PaymentStatus.refunded:
        return 'Refundirano';
    }
  }
}
