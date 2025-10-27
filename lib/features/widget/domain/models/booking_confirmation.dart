import 'package:freezed_annotation/freezed_annotation.dart';
import 'payment_option.dart';

part 'booking_confirmation.freezed.dart';
part 'booking_confirmation.g.dart';

@freezed
class BookingConfirmation with _$BookingConfirmation {
  const factory BookingConfirmation({
    required String bookingNumber,
    required String email,
    required PaymentMethod paymentMethod,
    required double totalAmount,
    required String propertyName,
    String? propertyUrl,
  }) = _BookingConfirmation;

  factory BookingConfirmation.fromJson(Map<String, dynamic> json) =>
      _$BookingConfirmationFromJson(json);
}
