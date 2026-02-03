import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_details_model.freezed.dart';
part 'booking_details_model.g.dart';

/// Guest count for booking details
@freezed
class GuestCount with _$GuestCount {
  const factory GuestCount({required int adults, @Default(0) int children}) =
      _GuestCount;

  factory GuestCount.fromJson(Map<String, dynamic> json) =>
      _$GuestCountFromJson(json);
}

/// Bank details for bank transfer payments
@freezed
class BankDetails with _$BankDetails {
  const factory BankDetails({
    String? bankName,
    String? accountHolder,
    String? iban,
    String? swift,
  }) = _BankDetails;

  factory BankDetails.fromJson(Map<String, dynamic> json) =>
      _$BankDetailsFromJson(json);
}

/// Booking details model for guest booking lookup
/// Matches the response from verifyBookingAccess Cloud Function
@freezed
class BookingDetailsModel with _$BookingDetailsModel {
  const factory BookingDetailsModel({
    required String bookingId,
    required String bookingReference,
    String? propertyId, // Property ID for fetching widget settings
    String? unitId, // Unit ID for fetching widget settings
    required String propertyName,
    required String unitName,
    required String guestName,
    required String guestEmail,
    String? guestPhone,
    required String checkIn, // ISO 8601 string
    required String checkOut, // ISO 8601 string
    required int nights,
    required GuestCount guestCount,
    required double totalPrice,
    double? roomPrice, // Nightly accommodation price
    double? extraGuestFees, // Extra guest fees
    double? petFees, // Pet fees
    double? servicesTotal, // Total non-nightly fees
    required double depositAmount,
    required double remainingAmount,
    required double paidAmount,
    required String paymentStatus,
    required String paymentMethod,
    required String status,
    String? ownerEmail,
    String? ownerPhone,
    String? notes,
    String? createdAt, // ISO 8601 string
    String? paymentDeadline, // ISO 8601 string
    BankDetails? bankDetails, // Bank transfer payment details
  }) = _BookingDetailsModel;

  factory BookingDetailsModel.fromJson(Map<String, dynamic> json) =>
      _$BookingDetailsModelFromJson(json);
}

/// Response from verifyBookingAccess Cloud Function
@freezed
class BookingLookupResponse with _$BookingLookupResponse {
  const factory BookingLookupResponse({
    required bool success,
    required BookingDetailsModel booking,
  }) = _BookingLookupResponse;

  factory BookingLookupResponse.fromJson(Map<String, dynamic> json) =>
      _$BookingLookupResponseFromJson(json);
}
