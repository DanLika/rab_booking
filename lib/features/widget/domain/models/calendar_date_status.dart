import 'package:flutter/material.dart';

/// Status of a date in the calendar
enum DateStatus {
  available,
  booked,
  blocked,
  partialCheckIn,
  partialCheckOut,
}

/// Extension to get color for each status
extension DateStatusExtension on DateStatus {
  Color getColor() {
    switch (this) {
      case DateStatus.available:
        return const Color(0xFFC8E6C9); // Light green matching reference
      case DateStatus.booked:
        return const Color(0xFFFFCDD2); // Light pink matching reference
      case DateStatus.blocked:
        return const Color(0xFFE0E0E0); // Light gray for invalid days
      case DateStatus.partialCheckIn:
        return const Color(0xFFC8E6C9); // Use available color as base
      case DateStatus.partialCheckOut:
        return const Color(0xFFC8E6C9); // Use available color as base
    }
  }

  Color getBorderColor() {
    switch (this) {
      case DateStatus.available:
        return const Color(0xFFDCDCDC); // Subtle border
      case DateStatus.booked:
        return const Color(0xFFDCDCDC); // Subtle border
      case DateStatus.blocked:
        return const Color(0xFFDCDCDC); // Subtle border
      case DateStatus.partialCheckIn:
        return const Color(0xFFDCDCDC); // Subtle border
      case DateStatus.partialCheckOut:
        return const Color(0xFFDCDCDC); // Subtle border
    }
  }

  Color getDiagonalColor() {
    // Color for diagonal line on check-in/check-out days
    switch (this) {
      case DateStatus.partialCheckIn:
        return const Color(0xFFFFCDD2); // Pink for booked part
      case DateStatus.partialCheckOut:
        return const Color(0xFFFFCDD2); // Pink for booked part
      default:
        return Colors.transparent;
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
