import 'package:freezed_annotation/freezed_annotation.dart';
import 'calendar_day.dart';

part 'booking_flow_state.freezed.dart';
part 'booking_flow_state.g.dart';

/// Booking flow steps
enum BookingFlowStep {
  selectDates,       // Step 1-4: Selecting dates on calendar
  reviewBooking,     // Step 5: Review booking summary
  guestDetails,      // Step 6: Enter guest information
  payment,           // Step 7: Payment
  confirmation,      // Step 8: Confirmation
}

/// Date blocking flow steps
enum BlockingFlowStep {
  selectDates,       // Select date range to block
  enterReason,       // Enter reason for blocking
  confirmation,      // Confirmation
}

/// Booking flow state for guest users
@freezed
class BookingFlowState with _$BookingFlowState {
  const factory BookingFlowState({
    required BookingFlowStep currentStep,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    @Default(2) int guestCount,
    String? guestName,
    String? guestEmail,
    String? guestPhone,
    String? specialRequests,
    double? pricePerNight,
    double? totalPrice,
    int? totalNights,
    String? propertyId,
    String? unitId,
    @Default(false) bool isProcessing,
    String? error,
  }) = _BookingFlowState;

  factory BookingFlowState.fromJson(Map<String, dynamic> json) =>
      _$BookingFlowStateFromJson(json);
}

/// Extension methods for booking flow state
extension BookingFlowStateX on BookingFlowState {
  /// Check if dates are selected
  bool get hasDatesSelected =>
      checkInDate != null && checkOutDate != null;

  /// Check if can proceed to next step
  bool get canProceed {
    switch (currentStep) {
      case BookingFlowStep.selectDates:
        return hasDatesSelected;
      case BookingFlowStep.reviewBooking:
        return hasDatesSelected && totalPrice != null;
      case BookingFlowStep.guestDetails:
        return guestName != null &&
            guestEmail != null &&
            guestPhone != null;
      case BookingFlowStep.payment:
        return false; // Payment completion is checked separately
      case BookingFlowStep.confirmation:
        return false; // Final step
    }
  }

  /// Get step title
  String get stepTitle {
    switch (currentStep) {
      case BookingFlowStep.selectDates:
        return 'Select Dates';
      case BookingFlowStep.reviewBooking:
        return 'Review Booking';
      case BookingFlowStep.guestDetails:
        return 'Guest Details';
      case BookingFlowStep.payment:
        return 'Payment';
      case BookingFlowStep.confirmation:
        return 'Booking Confirmed';
    }
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progress {
    switch (currentStep) {
      case BookingFlowStep.selectDates:
        return 0.2;
      case BookingFlowStep.reviewBooking:
        return 0.4;
      case BookingFlowStep.guestDetails:
        return 0.6;
      case BookingFlowStep.payment:
        return 0.8;
      case BookingFlowStep.confirmation:
        return 1.0;
    }
  }
}

/// Date blocking flow state for owners
@freezed
class BlockingFlowState with _$BlockingFlowState {
  const factory BlockingFlowState({
    required BlockingFlowStep currentStep,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? notes,
    String? unitId,
    @Default(false) bool isProcessing,
    String? error,
  }) = _BlockingFlowState;

  factory BlockingFlowState.fromJson(Map<String, dynamic> json) =>
      _$BlockingFlowStateFromJson(json);
}

/// Extension methods for blocking flow state
extension BlockingFlowStateX on BlockingFlowState {
  /// Check if dates are selected
  bool get hasDatesSelected => startDate != null && endDate != null;

  /// Check if can proceed to next step
  bool get canProceed {
    switch (currentStep) {
      case BlockingFlowStep.selectDates:
        return hasDatesSelected;
      case BlockingFlowStep.enterReason:
        return reason != null && reason!.isNotEmpty;
      case BlockingFlowStep.confirmation:
        return false; // Final step
    }
  }

  /// Get step title
  String get stepTitle {
    switch (currentStep) {
      case BlockingFlowStep.selectDates:
        return 'Select Dates to Block';
      case BlockingFlowStep.enterReason:
        return 'Enter Reason';
      case BlockingFlowStep.confirmation:
        return 'Dates Blocked';
    }
  }

  /// Calculate number of nights
  int? get nights {
    if (startDate == null || endDate == null) return null;
    return endDate!.difference(startDate!).inDays;
  }
}

/// Date selection mode
enum DateSelectionMode {
  checkIn,      // Selecting check-in date
  checkOut,     // Selecting check-out date
  complete,     // Both dates selected
}

/// Calendar interaction state
@freezed
class CalendarInteractionState with _$CalendarInteractionState {
  const factory CalendarInteractionState({
    required DateSelectionMode mode,
    DateTime? firstSelectedDate,
    DateTime? secondSelectedDate,
    DateTime? hoveredDate,
    @Default(false) bool isLongPressing,
    CalendarDay? longPressedDay,
  }) = _CalendarInteractionState;

  factory CalendarInteractionState.fromJson(Map<String, dynamic> json) =>
      _$CalendarInteractionStateFromJson(json);
}

/// Extension methods for calendar interaction state
extension CalendarInteractionStateX on CalendarInteractionState {
  /// Check if date is in selected range
  bool isInRange(DateTime date) {
    if (firstSelectedDate == null || secondSelectedDate == null) {
      return false;
    }

    final start = firstSelectedDate!.isBefore(secondSelectedDate!)
        ? firstSelectedDate!
        : secondSelectedDate!;
    final end = firstSelectedDate!.isAfter(secondSelectedDate!)
        ? firstSelectedDate!
        : secondSelectedDate!;

    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }

  /// Check if date is a range endpoint
  bool isRangeEndpoint(DateTime date) {
    if (firstSelectedDate == null) return false;

    final matchesFirst = date.year == firstSelectedDate!.year &&
        date.month == firstSelectedDate!.month &&
        date.day == firstSelectedDate!.day;

    if (secondSelectedDate == null) return matchesFirst;

    final matchesSecond = date.year == secondSelectedDate!.year &&
        date.month == secondSelectedDate!.month &&
        date.day == secondSelectedDate!.day;

    return matchesFirst || matchesSecond;
  }

  /// Get selected date range
  DateTimeRange? get selectedRange {
    if (firstSelectedDate == null || secondSelectedDate == null) {
      return null;
    }

    final start = firstSelectedDate!.isBefore(secondSelectedDate!)
        ? firstSelectedDate!
        : secondSelectedDate!;
    final end = firstSelectedDate!.isAfter(secondSelectedDate!)
        ? firstSelectedDate!
        : secondSelectedDate!;

    return DateTimeRange(start: start, end: end);
  }
}

/// Booking summary data
@freezed
class BookingSummary with _$BookingSummary {
  const factory BookingSummary({
    required DateTime checkIn,
    required DateTime checkOut,
    required String checkInTime,
    required String checkOutTime,
    required int nights,
    required double pricePerNight,
    required double subtotal,
    required double serviceFee,
    required double cleaningFee,
    required double taxes,
    required double total,
    required String currency,
    @Default(2) int guestCount,
    String? propertyName,
    String? unitName,
    String? propertyImage,
  }) = _BookingSummary;

  factory BookingSummary.fromJson(Map<String, dynamic> json) =>
      _$BookingSummaryFromJson(json);
}

/// Extension methods for booking summary
extension BookingSummaryX on BookingSummary {
  /// Format check-in display
  String get checkInDisplay =>
      '${_formatDate(checkIn)} (after $checkInTime)';

  /// Format check-out display
  String get checkOutDisplay =>
      '${_formatDate(checkOut)} (before $checkOutTime)';

  /// Format date helper
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Format currency amount
  String formatAmount(double amount) {
    return '$currency${amount.toStringAsFixed(2)}';
  }
}
