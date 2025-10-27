import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_service_model.freezed.dart';
part 'booking_service_model.g.dart';

/// Booking Service model (junction table: booking ↔ service)
@freezed
class BookingServiceModel with _$BookingServiceModel {
  const factory BookingServiceModel({
    /// Booking Service ID (UUID)
    required String id,

    /// Booking ID
    @JsonKey(name: 'booking_id') required String bookingId,

    /// Service ID
    @JsonKey(name: 'service_id') required String serviceId,

    /// Quantity
    @Default(1) int quantity,

    /// Unit price (snapshot at booking time)
    @JsonKey(name: 'unit_price') required double unitPrice,

    /// Total price (calculated: quantity × unit_price × multiplier)
    @JsonKey(name: 'total_price') required double totalPrice,

    /// Created at timestamp
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _BookingServiceModel;

  const BookingServiceModel._();

  /// Create from JSON
  factory BookingServiceModel.fromJson(Map<String, dynamic> json) =>
      _$BookingServiceModelFromJson(json);

  /// Get formatted unit price
  String get formattedUnitPrice => '€${unitPrice.toStringAsFixed(2)}';

  /// Get formatted total price
  String get formattedTotalPrice => '€${totalPrice.toStringAsFixed(2)}';

  /// Get quantity label
  String get quantityLabel {
    return quantity == 1 ? '1x' : '${quantity}x';
  }
}
