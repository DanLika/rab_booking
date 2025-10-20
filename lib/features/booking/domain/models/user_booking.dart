import 'booking_status.dart';

class UserBooking {
  final String id;
  final String propertyId;
  final String propertyName;
  final String propertyImage;
  final String propertyLocation;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guests;
  final double totalPrice;
  final BookingStatus status;
  final DateTime bookingDate;
  final String? cancellationReason;
  final DateTime? cancellationDate;

  UserBooking({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.propertyImage,
    required this.propertyLocation,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guests,
    required this.totalPrice,
    required this.status,
    required this.bookingDate,
    this.cancellationReason,
    this.cancellationDate,
  });

  factory UserBooking.fromJson(Map<String, dynamic> json) {
    return UserBooking(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      propertyName: json['property_name'] as String,
      propertyImage: json['property_image'] as String,
      propertyLocation: json['property_location'] as String,
      checkInDate: DateTime.parse(json['check_in_date'] as String),
      checkOutDate: DateTime.parse(json['check_out_date'] as String),
      guests: json['guests'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      status: BookingStatus.fromString(json['status'] as String),
      bookingDate: DateTime.parse(json['booking_date'] as String),
      cancellationReason: json['cancellation_reason'] as String?,
      cancellationDate: json['cancellation_date'] != null
          ? DateTime.parse(json['cancellation_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'property_name': propertyName,
      'property_image': propertyImage,
      'property_location': propertyLocation,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate.toIso8601String(),
      'guests': guests,
      'total_price': totalPrice,
      'status': status.value,
      'booking_date': bookingDate.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'cancellation_date': cancellationDate?.toIso8601String(),
    };
  }

  int get nightsCount {
    return checkOutDate.difference(checkInDate).inDays;
  }

  bool get canCancel {
    return status == BookingStatus.confirmed &&
        DateTime.now().isBefore(checkInDate.subtract(const Duration(days: 1)));
  }

  bool get isUpcoming {
    return status == BookingStatus.confirmed &&
        DateTime.now().isBefore(checkInDate);
  }

  bool get isPast {
    return status == BookingStatus.completed ||
        (DateTime.now().isAfter(checkOutDate) &&
            status == BookingStatus.confirmed);
  }

  bool get isCancelled {
    return status == BookingStatus.cancelled || status == BookingStatus.refunded;
  }
}
