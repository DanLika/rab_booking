import 'package:flutter/material.dart' show Color;

enum BookingStatus {
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Confirmed'),
  cancelled('cancelled', 'Cancelled'),
  completed('completed', 'Completed'),
  refunded('refunded', 'Refunded'),
  blocked('blocked', 'Blocked');

  final String value;
  final String displayName;

  const BookingStatus(this.value, this.displayName);

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BookingStatus.pending,
    );
  }

  /// Check if booking can be cancelled
  bool get canBeCancelled {
    return this == BookingStatus.pending || this == BookingStatus.confirmed;
  }

  /// Get color for status
  /// Used for calendar and UI display
  Color get color {
    switch (this) {
      case BookingStatus.confirmed:
        return const Color(0xFF4CAF50); // Green
      case BookingStatus.pending:
        return const Color(0xFFFF9800); // Orange
      case BookingStatus.cancelled:
        return const Color(0xFFF44336); // Red
      case BookingStatus.blocked:
        return const Color(0xFF2196F3); // Blue
      case BookingStatus.completed:
        return const Color(0xFF9E9E9E); // Grey
      case BookingStatus.refunded:
        return const Color(0xFF9C27B0); // Purple
    }
  }
}
