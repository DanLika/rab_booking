import 'package:freezed_annotation/freezed_annotation.dart';
import 'guest_details.dart';
import 'payment_option.dart';

part 'booking_request.freezed.dart';
part 'booking_request.g.dart';

@freezed
class BookingRequest with _$BookingRequest {
  const factory BookingRequest({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
    required GuestDetails guestDetails,
    required Map<String, int> additionalServices, // serviceId -> quantity
    required PaymentOption paymentOption,
    required PaymentMethod paymentMethod,
    required double totalAmount,
    @Default(0.0) double depositAmount, // 20% deposit for bank transfer
    @Default(0.0) double remainingAmount, // 80% to be paid on arrival
    String? notes, // Optional guest notes
  }) = _BookingRequest;

  factory BookingRequest.fromJson(Map<String, dynamic> json) =>
      _$BookingRequestFromJson(json);
}
