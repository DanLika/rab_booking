import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking.freezed.dart';
part 'booking.g.dart';

/// Booking model - odgovara Supabase bookings tabeli
@freezed
class Booking with _$Booking {
  const factory Booking({
    required String id,
    required String unitId,
    String? userId, // Null za guest booking
    required String guestName,
    required String guestEmail,
    String? guestPhone,
    required DateTime checkIn,
    required DateTime checkOut,
    required String status, // 'confirmed', 'pending', 'cancelled'
    required double totalPrice,
    double? paidAmount,
    int? guestCount,
    String? notes,
    String? paymentIntentId,
    String? cancellationReason,
    DateTime? cancelledAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? paymentStatus, // 'awaiting_advance', 'advance_paid', 'fully_paid'
    double? advanceAmount, // 20% od total_price
    @Default('direct') String source, // 'direct', 'booking_com', 'airbnb'
  }) = _Booking;

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);
}

/// Helper extensions
extension BookingExtensions on Booking {
  int get nights {
    return checkOut.difference(checkIn).inDays;
  }

  bool get isConfirmed => status == 'confirmed';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';

  bool get isAdvancePaid => paymentStatus == 'advance_paid';
  bool get isFullyPaid => paymentStatus == 'fully_paid';
  bool get isAwaitingAdvance => paymentStatus == 'awaiting_advance';
}
