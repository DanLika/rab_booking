import 'package:flutter/material.dart';
import '../../../../core/design_tokens/design_tokens.dart';

/// Status of a date in the calendar
enum DateStatus {
  available,
  booked,
  pending, // Pending approval - shown in RED with diagonal pattern (blocks dates like booked)
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
  /// Background color for this status
  Color getColor(WidgetColorScheme colors) => switch (this) {
    DateStatus.available ||
    DateStatus.partialCheckIn ||
    DateStatus.partialCheckOut => colors.statusAvailableBackground,
    DateStatus.booked ||
    DateStatus.partialBoth => colors.statusBookedBackground,
    DateStatus.pending => colors.statusPendingBackground,
    DateStatus.blocked => colors.statusBlockedBackground,
    DateStatus.disabled => colors.statusDisabledBackground,
    DateStatus.pastReservation => colors.statusPastReservationBackground,
  };

  /// Border color for this status
  Color getBorderColor(WidgetColorScheme colors) => switch (this) {
    DateStatus.available ||
    DateStatus.partialCheckIn ||
    DateStatus.partialCheckOut => colors.statusAvailableBorder,
    DateStatus.booked || DateStatus.partialBoth => colors.statusBookedBorder,
    DateStatus.pending => colors.statusPendingBorder,
    DateStatus.blocked => colors.statusBlockedBorder,
    DateStatus.disabled => colors.borderDefault,
    DateStatus.pastReservation => colors.statusPastReservationBorder,
  };

  /// Color for diagonal line on check-in/check-out days
  /// When guest checks in/out, the other half is booked (red)
  Color getDiagonalColor(WidgetColorScheme colors) => switch (this) {
    DateStatus.partialCheckIn ||
    DateStatus.partialCheckOut => colors.statusBookedBackground,
    _ => Colors.transparent,
  };

  /// Display name for legend
  String get displayName => switch (this) {
    DateStatus.available => 'Available',
    DateStatus.booked => 'Booked',
    DateStatus.pending => 'Pending Approval',
    DateStatus.blocked => 'Blocked',
    DateStatus.partialCheckIn => 'Check-in',
    DateStatus.partialCheckOut => 'Check-out',
    DateStatus.partialBoth => 'Turnover Day',
    DateStatus.disabled => 'Past Date',
    DateStatus.pastReservation => 'Past Reservation',
  };

  /// Whether this status should show a diagonal pattern overlay
  /// Pending uses diagonal pattern to distinguish from solid booked dates
  bool get needsDiagonalPattern => this == DateStatus.pending;

  /// Pattern line color for diagonal overlay
  /// Returns a contrasting color for diagonal lines on yellow pending background
  Color getPatternLineColor(WidgetColorScheme colors) => switch (this) {
    DateStatus.pending => const Color(0xFF6B4C00).withValues(alpha: 0.6),
    _ => Colors.transparent,
  };
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
  final int?
  minNightsOnArrival; // Minimum nights required when arriving on this date
  final int?
  maxNightsOnArrival; // Maximum nights allowed when arriving on this date
  final bool
  isPendingBooking; // Whether this date belongs to a pending (awaiting approval) booking
  // For partialBoth (turnover day) - track which half is pending
  final bool
  isCheckOutPending; // Is the checkout half (top-left triangle) from a pending booking?
  final bool
  isCheckInPending; // Is the checkin half (bottom-right triangle) from a pending booking?

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
    this.minNightsOnArrival,
    this.maxNightsOnArrival,
    this.isPendingBooking = false,
    this.isCheckOutPending = false,
    this.isCheckInPending = false,
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
    int? minNightsOnArrival,
    int? maxNightsOnArrival,
    bool? isPendingBooking,
    bool? isCheckOutPending,
    bool? isCheckInPending,
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
      minNightsOnArrival: minNightsOnArrival ?? this.minNightsOnArrival,
      maxNightsOnArrival: maxNightsOnArrival ?? this.maxNightsOnArrival,
      isPendingBooking: isPendingBooking ?? this.isPendingBooking,
      isCheckOutPending: isCheckOutPending ?? this.isCheckOutPending,
      isCheckInPending: isCheckInPending ?? this.isCheckInPending,
    );
  }

  /// Get formatted price (e.g., "€50")
  String? get formattedPrice {
    if (price == null) return null;
    return '€${price!.toStringAsFixed(0)}';
  }
}
