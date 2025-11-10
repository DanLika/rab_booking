import 'package:flutter/material.dart';
import '../../../../core/design_tokens/design_tokens.dart';

/// Status of a date in the calendar
enum DateStatus {
  available,
  booked,
  pending, // Pending approval - shown in orange
  blocked,
  partialCheckIn,
  partialCheckOut,
  disabled, // Past dates that cannot be selected
  pastReservation, // Past booking (historical) - shown in red with reduced opacity
}

/// Extension to get color for each status
/// Colors based on Design Tokens with theme support
extension DateStatusExtension on DateStatus {
  Color getColor(WidgetColorScheme colors) {
    switch (this) {
      case DateStatus.available:
        return colors.statusAvailableBackground;
      case DateStatus.booked:
        return colors.statusBookedBackground;
      case DateStatus.pending:
        return colors.statusPendingBackground;
      case DateStatus.blocked:
        return colors.backgroundTertiary;
      case DateStatus.partialCheckIn:
        return colors.statusAvailableBackground;
      case DateStatus.partialCheckOut:
        return colors.statusAvailableBackground;
      case DateStatus.disabled:
        return colors.statusDisabledBackground;
      case DateStatus.pastReservation:
        return colors.statusPastReservationBackground;
    }
  }

  Color getBorderColor(WidgetColorScheme colors) {
    switch (this) {
      case DateStatus.available:
        return colors.statusAvailableBorder;
      case DateStatus.booked:
        return colors.statusBookedBorder;
      case DateStatus.pending:
        return colors.statusPendingBorder;
      case DateStatus.blocked:
        return colors.borderDefault;
      case DateStatus.partialCheckIn:
        return colors.statusAvailableBorder;
      case DateStatus.partialCheckOut:
        return colors.statusAvailableBorder;
      case DateStatus.disabled:
        return colors.borderDefault;
      case DateStatus.pastReservation:
        return colors.statusPastReservationBorder;
    }
  }

  Color getDiagonalColor(WidgetColorScheme colors) {
    // Color for diagonal line on check-in/check-out days
    // When guest checks in/out, the other half is booked (red)
    switch (this) {
      case DateStatus.partialCheckIn:
        return colors.statusBookedBackground;
      case DateStatus.partialCheckOut:
        return colors.statusBookedBackground;
      default:
        return Colors.transparent;
    }
  }

  /// Get display name for legend
  String getDisplayName() {
    switch (this) {
      case DateStatus.available:
        return 'Available';
      case DateStatus.booked:
        return 'Booked';
      case DateStatus.pending:
        return 'Pending Approval';
      case DateStatus.blocked:
        return 'Blocked';
      case DateStatus.partialCheckIn:
        return 'Check-in';
      case DateStatus.partialCheckOut:
        return 'Check-out';
      case DateStatus.disabled:
        return 'Past Date';
      case DateStatus.pastReservation:
        return 'Past Reservation';
    }
  }
}

/// Model for a calendar date with status
class CalendarDateInfo {
  final DateTime date;
  final DateStatus status;
  final bool isSelected;
  final bool isInRange;
  final double? price; // Daily price for this date

  const CalendarDateInfo({
    required this.date,
    required this.status,
    this.isSelected = false,
    this.isInRange = false,
    this.price,
  });

  CalendarDateInfo copyWith({
    DateTime? date,
    DateStatus? status,
    bool? isSelected,
    bool? isInRange,
    double? price,
  }) {
    return CalendarDateInfo(
      date: date ?? this.date,
      status: status ?? this.status,
      isSelected: isSelected ?? this.isSelected,
      isInRange: isInRange ?? this.isInRange,
      price: price ?? this.price,
    );
  }

  /// Get formatted price (e.g., "€50")
  String? get formattedPrice {
    if (price == null) return null;
    return '€${price!.toStringAsFixed(0)}';
  }
}
