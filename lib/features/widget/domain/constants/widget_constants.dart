/// Constants used throughout the Widget feature.
///
/// Centralizes magic numbers and default values for easier maintenance
/// and consistency across the codebase.
///
/// ## Usage
/// ```dart
/// import 'package:bookbed/features/widget/domain/constants/widget_constants.dart';
///
/// final isWeekend = WidgetConstants.defaultWeekendDays.contains(date.weekday);
/// final checkInTime = WidgetConstants.defaultCheckInHour;
/// ```
library;

/// Core widget constants and default values.
abstract final class WidgetConstants {
  // ============================================================
  // TIME & SCHEDULING
  // ============================================================

  /// Default check-in time (3 PM / 15:00).
  ///
  /// Used when determining if a date is available for same-day booking.
  static const int defaultCheckInHour = 15;

  /// Default check-out time (10 AM / 10:00).
  static const int defaultCheckOutHour = 10;

  /// Default weekend days using ISO weekday format.
  ///
  /// - Monday = 1
  /// - Friday = 5
  /// - Saturday = 6
  /// - Sunday = 7
  ///
  /// For hotel pricing, "weekend night" means the night you SLEEP on that day:
  /// - Friday night (sleep Fri→Sat) = weekend price
  /// - Saturday night (sleep Sat→Sun) = weekend price
  /// - Sunday night (sleep Sun→Mon) = weekday price
  ///
  /// Therefore default is [5, 6] (Friday, Saturday), NOT [6, 7] (Sat, Sun).
  static const List<int> defaultWeekendDays = [5, 6];

  // ============================================================
  // BOOKING DEFAULTS
  // ============================================================

  /// Default minimum stay in nights.
  static const int defaultMinStayNights = 1;

  /// Default maximum stay in nights (0 = no limit).
  static const int defaultMaxStayNights = 0;

  /// Default maximum number of guests.
  static const int defaultMaxGuests = 4;

  // ============================================================
  // PRICING
  // ============================================================

  /// Default deposit percentage for bookings (20%).
  static const int defaultDepositPercentage = 20;

  /// Minimum deposit percentage allowed.
  static const int minDepositPercentage = 0;

  /// Maximum deposit percentage allowed (100% = full payment).
  static const int maxDepositPercentage = 100;

  /// Price comparison tolerance for floating point comparisons.
  ///
  /// Used when checking if prices have changed (e.g., in price lock service).
  /// Two prices are considered equal if their difference is less than this.
  static const double priceTolerance = 0.01;

  /// Default currency code.
  static const String defaultCurrency = 'EUR';

  // ============================================================
  // VALIDATION
  // ============================================================

  /// Minimum days in advance for booking.
  ///
  /// 0 = same-day booking allowed.
  static const int defaultMinDaysAdvance = 0;

  /// Maximum days in advance for booking.
  ///
  /// 365 = can book up to 1 year ahead.
  static const int defaultMaxDaysAdvance = 365;

  /// Minimum guest name length.
  static const int minGuestNameLength = 2;

  /// Maximum guest name length.
  static const int maxGuestNameLength = 100;

  /// Maximum notes/comments length.
  static const int maxNotesLength = 500;

  // ============================================================
  // UI & DISPLAY
  // ============================================================

  /// Number of months to display in year calendar view.
  static const int yearCalendarMonths = 12;

  /// Default blur intensity for glassmorphism effects.
  static const double defaultBlurIntensity = 10.0;

  /// Animation duration for calendar transitions (milliseconds).
  static const int calendarAnimationDuration = 300;

  /// Debounce delay for search/filter inputs (milliseconds).
  static const int inputDebounceDelay = 300;

  // ============================================================
  // FIRESTORE
  // ============================================================

  /// Maximum batch size for Firestore bulk operations.
  ///
  /// Firestore limit is 500 writes per batch.
  static const int firestoreBatchSize = 500;

  /// Cache duration for widget settings (minutes).
  static const int settingsCacheDuration = 5;

  // ============================================================
  // EXTERNAL INTEGRATIONS
  // ============================================================

  /// iCal sync interval (hours).
  ///
  /// How often to sync external calendar feeds.
  static const int icalSyncIntervalHours = 1;

  /// Maximum iCal feeds per unit.
  static const int maxIcalFeedsPerUnit = 5;
}

/// Booking status values used in Firestore.
///
/// These match the values stored in the 'status' field of booking documents.
abstract final class BookingStatusValues {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';
  static const String rejected = 'rejected';
}

/// Payment method identifiers.
abstract final class PaymentMethodValues {
  static const String stripe = 'stripe';
  static const String bankTransfer = 'bank_transfer';
  static const String payOnArrival = 'pay_on_arrival';
  static const String none = 'none';
}

/// Payment option identifiers.
abstract final class PaymentOptionValues {
  static const String fullPayment = 'full_payment';
  static const String deposit = 'deposit';
  static const String none = 'none';
}

/// Active booking statuses for availability checks.
///
/// These statuses indicate bookings that block dates from being booked.
/// Used by [AvailabilityChecker] and calendar building logic.
abstract final class ActiveBookingStatuses {
  /// Statuses that block dates from being available.
  static const List<String> values = [
    BookingStatusValues.pending,
    BookingStatusValues.confirmed,
    'in_progress', // Legacy status still in some documents
  ];
}

/// Error codes for availability check conflicts.
///
/// Used to communicate conflict types without hardcoded UI strings.
/// The UI layer maps these to localized messages.
enum AvailabilityErrorCode {
  /// Dates conflict with an existing booking.
  bookingConflict,

  /// Dates conflict with an iCal event (Booking.com, Airbnb, etc.).
  icalConflict,

  /// A date in the range is manually blocked.
  blockedDate,

  /// Check-in is not allowed on the requested date.
  blockedCheckIn,

  /// Check-out is not allowed on the requested date.
  blockedCheckOut,

  /// Error occurred while checking availability (fail-safe: unavailable).
  checkError,
}
