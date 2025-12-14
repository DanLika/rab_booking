import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/enums.dart';
import '../../core/utils/timestamp_converter.dart';
import '../../features/widget/utils/date_normalizer.dart';

part 'booking_model.freezed.dart';
part 'booking_model.g.dart';

/// Booking model representing a reservation
@freezed
class BookingModel with _$BookingModel {
  const factory BookingModel({
    /// Booking ID (UUID)
    required String id,

    /// Unit being booked
    @JsonKey(name: 'unit_id') required String unitId,

    /// Property ID (denormalized for queries)
    @JsonKey(name: 'property_id') String? propertyId,

    /// Guest user ID (nullable for anonymous widget bookings)
    @JsonKey(name: 'user_id') String? userId,

    /// Guest ID (for anonymous widget bookings)
    @JsonKey(name: 'guest_id') String? guestId,

    /// Owner ID (denormalized)
    @JsonKey(name: 'owner_id') String? ownerId,

    /// Guest name (for widget bookings without auth)
    @JsonKey(name: 'guest_name') String? guestName,

    /// Guest email (for widget bookings without auth)
    @JsonKey(name: 'guest_email') String? guestEmail,

    /// Guest phone (for widget bookings without auth)
    @JsonKey(name: 'guest_phone') String? guestPhone,

    /// Check-in date
    @TimestampConverter() @JsonKey(name: 'check_in') required DateTime checkIn,

    /// Check-in time
    @JsonKey(name: 'check_in_time') String? checkInTime,

    /// Check-out time
    @JsonKey(name: 'check_out_time') String? checkOutTime,

    /// Check-out date
    @TimestampConverter() @JsonKey(name: 'check_out') required DateTime checkOut,

    /// Booking status
    required BookingStatus status,

    /// Total price in EUR
    @JsonKey(name: 'total_price') @Default(0.0) double totalPrice,

    /// Amount paid (advance payment - 20%)
    @JsonKey(name: 'paid_amount') @Default(0.0) double paidAmount,

    /// Advance payment amount (20% of total)
    @JsonKey(name: 'advance_amount') double? advanceAmount,

    /// Deposit amount (same as advance, used by webhook)
    @JsonKey(name: 'deposit_amount') double? depositAmount,

    /// Remaining amount to be paid (totalPrice - depositAmount)
    @JsonKey(name: 'remaining_amount') double? remainingAmount,

    /// Payment method (bank_transfer, stripe, cash, other)
    @JsonKey(name: 'payment_method') String? paymentMethod,

    /// Payment status (pending, paid, refunded)
    @JsonKey(name: 'payment_status') String? paymentStatus,

    /// Payment option (deposit, full_payment)
    @JsonKey(name: 'payment_option') String? paymentOption,

    /// Whether booking requires owner approval
    @JsonKey(name: 'require_owner_approval') bool? requireOwnerApproval,

    /// Booking source (widget, admin, direct, api)
    String? source,

    /// Number of guests
    @JsonKey(name: 'guest_count') @Default(1) int guestCount,

    /// Special requests or notes
    String? notes,

    /// Tax/Legal disclaimer acceptance (for compliance audit trail)
    @JsonKey(name: 'tax_legal_accepted') bool? taxLegalAccepted,

    /// Stripe payment intent ID
    @JsonKey(name: 'payment_intent_id') String? paymentIntentId,

    /// Stripe checkout session ID (for webhook-created bookings)
    @JsonKey(name: 'stripe_session_id') String? stripeSessionId,

    /// Human-readable booking reference (e.g., BK-1234567890-1234)
    @JsonKey(name: 'booking_reference') String? bookingReference,

    /// Booking creation timestamp
    @TimestampConverter() @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Last update timestamp
    @NullableTimestampConverter() @JsonKey(name: 'updated_at') DateTime? updatedAt,

    /// Cancellation reason (if cancelled)
    @JsonKey(name: 'cancellation_reason') String? cancellationReason,

    /// Cancelled at timestamp
    @NullableTimestampConverter() @JsonKey(name: 'cancelled_at') DateTime? cancelledAt,

    /// User ID who cancelled the booking
    @JsonKey(name: 'cancelled_by') String? cancelledBy,
  }) = _BookingModel;

  const BookingModel._();

  /// Create from JSON
  factory BookingModel.fromJson(Map<String, dynamic> json) => _$BookingModelFromJson(json);

  /// Calculate number of nights
  int get numberOfNights {
    return checkOut.difference(checkIn).inDays;
  }

  /// Get remaining balance to be paid
  double get remainingBalance {
    return totalPrice - paidAmount;
  }

  /// Check if booking is fully paid
  bool get isFullyPaid {
    return paidAmount >= totalPrice;
  }

  /// Get payment completion percentage
  double get paymentPercentage {
    if (totalPrice == 0) return 0;
    return (paidAmount / totalPrice) * 100;
  }

  /// Check if booking is in the past
  bool get isPast {
    // Normalize dates for consistent comparison (ignores time components)
    final today = DateNormalizer.normalize(DateTime.now());
    final normalizedCheckOut = DateNormalizer.normalize(checkOut);
    return normalizedCheckOut.isBefore(today);
  }

  /// Check if booking is current (guest is currently staying)
  bool get isCurrent {
    // Normalize dates for consistent comparison (ignores time components)
    // Booking is current if today is >= checkIn and < checkOut
    final today = DateNormalizer.normalize(DateTime.now());
    final normalizedCheckIn = DateNormalizer.normalize(checkIn);
    final normalizedCheckOut = DateNormalizer.normalize(checkOut);
    return !normalizedCheckIn.isAfter(today) && normalizedCheckOut.isAfter(today);
  }

  /// Check if booking is upcoming
  bool get isUpcoming {
    // Normalize dates for consistent comparison (ignores time components)
    final today = DateNormalizer.normalize(DateTime.now());
    final normalizedCheckIn = DateNormalizer.normalize(checkIn);
    return normalizedCheckIn.isAfter(today);
  }

  /// Check if booking can be cancelled
  bool get canBeCancelled {
    return status.canBeCancelled && isUpcoming;
  }

  /// Check if this is an external/imported booking (Booking.com, Airbnb, iCal)
  /// External bookings are READ-ONLY and cannot be edited or deleted
  bool get isExternalBooking {
    // Check by ID prefix (most reliable)
    if (id.startsWith('ical_')) return true;

    // Check by source field
    if (source != null) {
      final src = source!.toLowerCase();
      return src == 'booking_com' || src == 'airbnb' || src == 'ical' || src == 'external';
    }

    // Check by payment method
    if (paymentMethod == 'external') return true;

    return false;
  }

  /// Get formatted source name for display
  String get sourceDisplayName {
    if (source == null) return 'Direct';
    switch (source!.toLowerCase()) {
      case 'booking_com':
        return 'Booking.com';
      case 'airbnb':
        return 'Airbnb';
      case 'ical':
        return 'iCal Import';
      case 'widget':
        return 'Website Widget';
      case 'manual':
      case 'direct':
        return 'Direct';
      case 'admin':
        return 'Admin';
      default:
        return source!;
    }
  }

  /// Get days until check-in
  int get daysUntilCheckIn {
    if (!isUpcoming) return 0;
    // Normalize to UTC for consistent comparison
    // checkIn comes from Firestore Timestamp which is UTC-based
    final checkInUtc = checkIn.isUtc ? checkIn : checkIn.toUtc();
    final nowUtc = DateTime.now().toUtc();
    return checkInUtc.difference(nowUtc).inDays;
  }

  /// Get days until check-out
  int get daysUntilCheckOut {
    if (isPast) return 0;
    // Normalize to UTC for consistent comparison
    // checkOut comes from Firestore Timestamp which is UTC-based
    final checkOutUtc = checkOut.isUtc ? checkOut : checkOut.toUtc();
    final nowUtc = DateTime.now().toUtc();
    return checkOutUtc.difference(nowUtc).inDays;
  }

  /// Get formatted date range (e.g., "Jan 15 - Jan 20, 2024")
  String get dateRangeFormatted {
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final checkInMonth = months[checkIn.month];
    final checkOutMonth = months[checkOut.month];

    if (checkIn.year == checkOut.year) {
      if (checkIn.month == checkOut.month) {
        return '$checkInMonth ${checkIn.day}-${checkOut.day}, ${checkIn.year}';
      }
      return '$checkInMonth ${checkIn.day} - $checkOutMonth ${checkOut.day}, ${checkIn.year}';
    }

    return '$checkInMonth ${checkIn.day}, ${checkIn.year} - $checkOutMonth ${checkOut.day}, ${checkOut.year}';
  }

  /// Get formatted total price
  String get formattedTotalPrice => '€${totalPrice.toStringAsFixed(2)}';

  /// Get formatted paid amount
  String get formattedPaidAmount => '€${paidAmount.toStringAsFixed(2)}';

  /// Get formatted remaining balance
  String get formattedRemainingBalance => '€${remainingBalance.toStringAsFixed(2)}';

  /// Get night count label
  String get nightsLabel {
    return numberOfNights == 1 ? '1 night' : '$numberOfNights nights';
  }

  /// Get guest count label
  String get guestsLabel {
    return guestCount == 1 ? '1 guest' : '$guestCount guests';
  }

  /// Get booking summary
  String get summary {
    return '$nightsLabel • $guestsLabel';
  }

  /// Calculate advance payment (20% of total)
  static double calculateAdvancePayment(double totalPrice) {
    return totalPrice * 0.20;
  }

  /// Check if two date ranges overlap
  static bool datesOverlap({
    required DateTime start1,
    required DateTime end1,
    required DateTime start2,
    required DateTime end2,
  }) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  /// Check if this booking overlaps with given dates
  bool overlapsWithDates(DateTime start, DateTime end) {
    return datesOverlap(start1: checkIn, end1: checkOut, start2: start, end2: end);
  }
}
