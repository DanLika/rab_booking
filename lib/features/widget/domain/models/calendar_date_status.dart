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
  partialBoth, // Both check-in and check-out on same day (turnover day)
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
      case DateStatus.partialBoth:
        return colors.statusBookedBackground; // Fully booked - turnover day
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
      case DateStatus.partialBoth:
        return colors.statusBookedBorder; // Fully booked border
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
      case DateStatus.partialBoth:
        return Colors.transparent; // No diagonal needed - fully booked
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
      case DateStatus.partialBoth:
        return 'Turnover Day';
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
  final bool blockCheckIn; // Block check-in on this date
  final bool blockCheckOut; // Block check-out on this date
  final int? minDaysAdvance; // Minimum days in advance to book
  final int? maxDaysAdvance; // Maximum days in advance to book

  const CalendarDateInfo({
    required this.date,
    required this.status,
    this.isSelected = false,
    this.isInRange = false,
    this.price,
    this.blockCheckIn = false,
    this.blockCheckOut = false,
    this.minDaysAdvance,
    this.maxDaysAdvance,
  });

  CalendarDateInfo copyWith({
    DateTime? date,
    DateStatus? status,
    bool? isSelected,
    bool? isInRange,
    double? price,
    bool? blockCheckIn,
    bool? blockCheckOut,
    int? minDaysAdvance,
    int? maxDaysAdvance,
  }) {
    return CalendarDateInfo(
      date: date ?? this.date,
      status: status ?? this.status,
      isSelected: isSelected ?? this.isSelected,
      isInRange: isInRange ?? this.isInRange,
      price: price ?? this.price,
      blockCheckIn: blockCheckIn ?? this.blockCheckIn,
      blockCheckOut: blockCheckOut ?? this.blockCheckOut,
      minDaysAdvance: minDaysAdvance ?? this.minDaysAdvance,
      maxDaysAdvance: maxDaysAdvance ?? this.maxDaysAdvance,
    );
  }

  /// Get formatted price (e.g., "€50")
  String? get formattedPrice {
    if (price == null) return null;
    return '€${price!.toStringAsFixed(0)}';
  }
}
