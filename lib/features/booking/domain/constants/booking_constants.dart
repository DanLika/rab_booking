/// Booking business logic constants
/// Centralized configuration for pricing, fees, and booking rules
class BookingConstants {
  BookingConstants._(); // Private constructor to prevent instantiation

  // ============================================================================
  // PRICING CONFIGURATION
  // ============================================================================

  /// Service fee percentage (10% of base price)
  /// Applied to all bookings as platform commission
  static const double serviceFeePercent = 0.10;

  /// Cleaning fee in EUR
  /// Fixed fee applied to all bookings regardless of duration
  static const double cleaningFeeEur = 50.0;

  /// Advance payment percentage (20% of total)
  /// Amount required to confirm booking, rest paid on check-in
  static const double advancePaymentPercent = 0.20;

  // ============================================================================
  // CURRENCY
  // ============================================================================

  /// Default currency symbol
  static const String currencySymbol = '€';

  /// Currency code
  static const String currencyCode = 'EUR';

  // ============================================================================
  // BOOKING RULES
  // ============================================================================

  /// Minimum nights for booking (can be overridden by property)
  static const int defaultMinStayNights = 1;

  /// Maximum nights for booking
  static const int maxStayNights = 365;

  /// Maximum guests per booking (can be overridden by property)
  static const int defaultMaxGuests = 10;

  /// How many days in advance can booking be made
  static const int maxAdvanceBookingDays = 365;

  // ============================================================================
  // CANCELLATION POLICY
  // ============================================================================

  /// Full refund if cancelled at least X days before check-in
  static const int fullRefundDaysBeforeCheckIn = 7;

  /// Partial refund (50%) if cancelled X-Y days before check-in
  static const int partialRefundDaysBeforeCheckIn = 3;

  /// Partial refund percentage
  static const double partialRefundPercent = 0.50;

  // ============================================================================
  // CHECK-IN/CHECK-OUT TIMES
  // ============================================================================

  /// Default check-in time (24h format)
  static const String defaultCheckInTime = '14:00';

  /// Default check-out time (24h format)
  static const String defaultCheckOutTime = '11:00';

  // ============================================================================
  // VALIDATION
  // ============================================================================

  /// Minimum card number length
  static const int minCardNumberLength = 13;

  /// Maximum card number length
  static const int maxCardNumberLength = 19;

  /// Minimum CVV length
  static const int minCvvLength = 3;

  /// Maximum CVV length
  static const int maxCvvLength = 4;

  /// Minimum phone number length
  static const int minPhoneLength = 6;

  /// Maximum phone number length
  static const int maxPhoneLength = 15;

  // ============================================================================
  // UI CONSTANTS
  // ============================================================================

  /// Calendar cell minimum touch target (WCAG compliant)
  static const double calendarCellMinSize = 44.0;

  /// Booking card image size
  static const double bookingCardImageSize = 100.0;

  /// Booking card image aspect ratio
  static const double bookingCardAspectRatio = 1.0;

  // ============================================================================
  // PAGINATION
  // ============================================================================

  /// Number of bookings to load per page
  static const int bookingsPerPage = 20;

  /// Number of bookings to show in skeleton loader
  static const int skeletonLoadingCount = 3;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Calculate service fee
  static double calculateServiceFee(double basePrice) {
    return basePrice * serviceFeePercent;
  }

  /// Calculate total price
  static double calculateTotalPrice({
    required double basePrice,
    double? customServiceFee,
    double? customCleaningFee,
  }) {
    final serviceFee = customServiceFee ?? calculateServiceFee(basePrice);
    final cleaningFee = customCleaningFee ?? cleaningFeeEur;
    return basePrice + serviceFee + cleaningFee;
  }

  /// Calculate advance payment amount
  static double calculateAdvancePayment(double totalPrice) {
    return totalPrice * advancePaymentPercent;
  }

  /// Calculate remaining balance
  static double calculateRemainingBalance({
    required double totalPrice,
    required double paidAmount,
  }) {
    return totalPrice - paidAmount;
  }

  /// Check if booking can be cancelled with full refund
  static bool canGetFullRefund(DateTime checkInDate) {
    final now = DateTime.now();
    final daysUntilCheckIn = checkInDate.difference(now).inDays;
    return daysUntilCheckIn >= fullRefundDaysBeforeCheckIn;
  }

  /// Check if booking can be cancelled with partial refund
  static bool canGetPartialRefund(DateTime checkInDate) {
    final now = DateTime.now();
    final daysUntilCheckIn = checkInDate.difference(now).inDays;
    return daysUntilCheckIn >= partialRefundDaysBeforeCheckIn &&
        daysUntilCheckIn < fullRefundDaysBeforeCheckIn;
  }

  /// Calculate refund amount
  static double calculateRefundAmount({
    required double paidAmount,
    required DateTime checkInDate,
  }) {
    if (canGetFullRefund(checkInDate)) {
      return paidAmount;
    } else if (canGetPartialRefund(checkInDate)) {
      return paidAmount * partialRefundPercent;
    } else {
      return 0.0;
    }
  }

  /// Format currency
  static String formatCurrency(double amount, {int decimals = 2}) {
    return '$currencySymbol${amount.toStringAsFixed(decimals)}';
  }

  /// Format currency with code
  static String formatCurrencyWithCode(double amount, {int decimals = 2}) {
    return '${amount.toStringAsFixed(decimals)} $currencyCode';
  }
}
