import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum BookingStatus {
  pending('pending', 'Na čekanju'),
  confirmed('confirmed', 'Potvrđeno'),
  cancelled('cancelled', 'Otkazano'),
  completed('completed', 'Završeno'),
  refunded('refunded', 'Refundirano'),
  blocked('blocked', 'Blokirano');

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

  /// Get the color associated with this booking status
  Color get color {
    switch (this) {
      case BookingStatus.confirmed:
        return AppColors.statusConfirmed;
      case BookingStatus.pending:
        return AppColors.statusPending;
      case BookingStatus.cancelled:
      case BookingStatus.refunded:
        return AppColors.statusCancelled;
      case BookingStatus.completed:
        return AppColors.statusCompleted;
      case BookingStatus.blocked:
        return AppColors.textDisabled;
    }
  }
}
