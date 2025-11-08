import 'package:flutter/material.dart';
import '../../presentation/theme/minimalist_colors.dart';

/// Status of a date in the calendar
enum DateStatus {
  available,
  booked,
  pending, // Pending approval - shown in orange
  blocked,
  partialCheckIn,
  partialCheckOut,
  disabled, // Past dates that cannot be selected
}

/// Extension to get color for each status
/// Colors based on Minimalist Design System (black/white/grey palette)
extension DateStatusExtension on DateStatus {
  Color getColor() {
    switch (this) {
      case DateStatus.available:
        return MinimalistColors.statusAvailableBackground; // Light green
      case DateStatus.booked:
        return MinimalistColors.statusBookedBackground; // Light red
      case DateStatus.pending:
        return MinimalistColors.statusPendingBackground; // Light amber
      case DateStatus.blocked:
        return MinimalistColors.backgroundTertiary; // Light grey
      case DateStatus.partialCheckIn:
        return MinimalistColors.statusAvailableBackground; // Light green
      case DateStatus.partialCheckOut:
        return MinimalistColors.statusAvailableBackground; // Light green
      case DateStatus.disabled:
        return MinimalistColors.backgroundTertiary; // Light grey
    }
  }

  Color getBorderColor() {
    switch (this) {
      case DateStatus.available:
        return MinimalistColors.statusAvailableBorder; // Green border
      case DateStatus.booked:
        return MinimalistColors.statusBookedBorder; // Red border
      case DateStatus.pending:
        return MinimalistColors.statusPendingBorder; // Amber border
      case DateStatus.blocked:
        return MinimalistColors.borderDefault; // Light grey border
      case DateStatus.partialCheckIn:
        return MinimalistColors.statusAvailableBorder; // Green border
      case DateStatus.partialCheckOut:
        return MinimalistColors.statusAvailableBorder; // Green border
      case DateStatus.disabled:
        return MinimalistColors.borderDefault; // Light grey border
    }
  }

  Color getDiagonalColor() {
    // Color for diagonal line on check-in/check-out days
    // When guest checks in/out, the other half is booked (red)
    switch (this) {
      case DateStatus.partialCheckIn:
        return MinimalistColors.statusBookedBackground; // Light red for booked part
      case DateStatus.partialCheckOut:
        return MinimalistColors.statusBookedBackground; // Light red for booked part
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
