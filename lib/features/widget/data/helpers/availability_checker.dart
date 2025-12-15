import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/logging_service.dart';
import '../../../../shared/models/booking_model.dart';
import '../../domain/constants/widget_constants.dart';
import '../../domain/services/i_availability_checker.dart';
import '../../utils/date_normalizer.dart';

/// Type of availability conflict.
enum ConflictType {
  /// Conflict with an existing booking.
  booking,

  /// Conflict with an iCal event (Booking.com, Airbnb, etc.).
  icalEvent,

  /// Conflict with a manually blocked date.
  blockedDate,

  /// Check-in is blocked on the requested check-in date.
  blockedCheckIn,

  /// Check-out is blocked on the requested check-out date.
  blockedCheckOut,
}

/// Result of an availability check with detailed conflict information.
///
/// Uses [AvailabilityErrorCode] instead of hardcoded strings to support
/// internationalization. The UI layer maps error codes to localized messages.
class AvailabilityCheckResult {
  /// Whether the dates are available for booking.
  final bool isAvailable;

  /// Type of conflict found (if any).
  final ConflictType? conflictType;

  /// Error code for UI localization (if any).
  ///
  /// Use this instead of [conflictMessage] for i18n support.
  final AvailabilityErrorCode? errorCode;

  /// ID of the conflicting document (booking, iCal event, or daily_price).
  final String? conflictingDocId;

  /// Date involved in the conflict (for formatting in UI).
  final DateTime? conflictDate;

  /// Source of iCal conflict (e.g., "Booking.com", "Airbnb").
  final String? icalSource;

  const AvailabilityCheckResult({
    required this.isAvailable,
    this.conflictType,
    this.errorCode,
    this.conflictingDocId,
    this.conflictDate,
    this.icalSource,
  });

  /// Factory for available result.
  const AvailabilityCheckResult.available()
    : isAvailable = true,
      conflictType = null,
      errorCode = null,
      conflictingDocId = null,
      conflictDate = null,
      icalSource = null;

  /// Factory for booking conflict.
  factory AvailabilityCheckResult.bookingConflict(String bookingId) => AvailabilityCheckResult(
    isAvailable: false,
    conflictType: ConflictType.booking,
    errorCode: AvailabilityErrorCode.bookingConflict,
    conflictingDocId: bookingId,
  );

  /// Factory for iCal conflict.
  factory AvailabilityCheckResult.icalConflict(String eventId, String source) => AvailabilityCheckResult(
    isAvailable: false,
    conflictType: ConflictType.icalEvent,
    errorCode: AvailabilityErrorCode.icalConflict,
    conflictingDocId: eventId,
    icalSource: source,
  );

  /// Factory for blocked date conflict.
  factory AvailabilityCheckResult.blockedDateConflict(String priceDocId, DateTime blockedDate) =>
      AvailabilityCheckResult(
        isAvailable: false,
        conflictType: ConflictType.blockedDate,
        errorCode: AvailabilityErrorCode.blockedDate,
        conflictingDocId: priceDocId,
        conflictDate: blockedDate,
      );

  /// Factory for blocked check-in conflict.
  factory AvailabilityCheckResult.blockedCheckInConflict(String priceDocId, DateTime checkInDate) =>
      AvailabilityCheckResult(
        isAvailable: false,
        conflictType: ConflictType.blockedCheckIn,
        errorCode: AvailabilityErrorCode.blockedCheckIn,
        conflictingDocId: priceDocId,
        conflictDate: checkInDate,
      );

  /// Factory for blocked check-out conflict.
  factory AvailabilityCheckResult.blockedCheckOutConflict(String priceDocId, DateTime checkOutDate) =>
      AvailabilityCheckResult(
        isAvailable: false,
        conflictType: ConflictType.blockedCheckOut,
        errorCode: AvailabilityErrorCode.blockedCheckOut,
        conflictingDocId: priceDocId,
        conflictDate: checkOutDate,
      );

  /// Factory for error state (fails safe - unavailable).
  factory AvailabilityCheckResult.error(ConflictType type) =>
      AvailabilityCheckResult(isAvailable: false, conflictType: type, errorCode: AvailabilityErrorCode.checkError);
}

/// Checks availability for bookings against multiple sources.
///
/// This helper class extracts availability checking logic from
/// the booking calendar repository for better separation of concerns.
///
/// ## Checks Performed
/// 1. Regular bookings (pending, confirmed, in_progress)
/// 2. iCal events (Booking.com, Airbnb, etc.)
/// 3. Blocked dates (daily_prices with available: false)
/// 4. Blocked check-in/check-out (daily_prices with block_checkin/block_checkout: true)
///
/// ## Usage
/// ```dart
/// final checker = AvailabilityChecker(firestore);
/// final result = await checker.check(
///   unitId: 'unit123',
///   checkIn: DateTime(2024, 1, 15),
///   checkOut: DateTime(2024, 1, 20),
/// );
///
/// if (!result.isAvailable) {
///   // Use result.errorCode for localized messages
///   print('Error code: ${result.errorCode}');
/// }
/// ```
class AvailabilityChecker implements IAvailabilityChecker {
  final FirebaseFirestore _firestore;

  // Collection names
  static const _bookingsCollection = 'bookings';
  static const _icalEventsCollection = 'ical_events';
  static const _dailyPricesCollection = 'daily_prices';

  AvailabilityChecker(this._firestore);

  /// Check if date range is available for booking.
  ///
  /// Returns [AvailabilityCheckResult] with detailed conflict info.
  /// Use [AvailabilityCheckResult.errorCode] for localized error messages.
  @override
  Future<AvailabilityCheckResult> check({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    final normalizedCheckIn = DateNormalizer.normalize(checkIn);
    final normalizedCheckOut = DateNormalizer.normalize(checkOut);

    // Check bookings first (most common conflict)
    var result = await _checkBookings(unitId: unitId, checkIn: normalizedCheckIn, checkOut: normalizedCheckOut);
    if (!result.isAvailable) return result;

    // Check iCal events (external calendar sync)
    result = await _checkIcalEvents(unitId: unitId, checkIn: normalizedCheckIn, checkOut: normalizedCheckOut);
    if (!result.isAvailable) return result;

    // Check blocked dates
    result = await _checkBlockedDates(unitId: unitId, checkIn: normalizedCheckIn, checkOut: normalizedCheckOut);
    if (!result.isAvailable) return result;

    // Check blocked check-in/check-out
    result = await _checkBlockedCheckInOut(unitId: unitId, checkIn: normalizedCheckIn, checkOut: normalizedCheckOut);
    if (!result.isAvailable) return result;

    LoggingService.log('✅ No conflicts found for $normalizedCheckIn to $normalizedCheckOut', tag: 'AVAILABILITY_CHECK');

    return const AvailabilityCheckResult.available();
  }

  /// Simple boolean check for backward compatibility.
  @override
  Future<bool> isAvailable({required String unitId, required DateTime checkIn, required DateTime checkOut}) async {
    final result = await check(unitId: unitId, checkIn: checkIn, checkOut: checkOut);
    return result.isAvailable;
  }

  /// Check for conflicts with regular bookings.
  Future<AvailabilityCheckResult> _checkBookings({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      // Using client-side filtering to avoid Firestore composite index requirement
      // NEW STRUCTURE: Use collection group query for subcollection
      final snapshot = await _firestore
          .collectionGroup(_bookingsCollection)
          .where('unit_id', isEqualTo: unitId)
          .where('status', whereIn: ActiveBookingStatuses.values)
          .get();

      for (final doc in snapshot.docs) {
        try {
          final booking = BookingModel.fromJson({...doc.data(), 'id': doc.id});

          final bookingCheckIn = DateNormalizer.normalize(booking.checkIn);
          final bookingCheckOut = DateNormalizer.normalize(booking.checkOut);

          if (_hasDateOverlap(start1: bookingCheckIn, end1: bookingCheckOut, start2: checkIn, end2: checkOut)) {
            LoggingService.log('❌ Booking conflict found: ${booking.id}', tag: 'AVAILABILITY_CHECK');
            return AvailabilityCheckResult.bookingConflict(booking.id);
          }
        } catch (e) {
          unawaited(LoggingService.logError('Error parsing booking document', e));
        }
      }

      return const AvailabilityCheckResult.available();
    } catch (e) {
      unawaited(LoggingService.logError('Error fetching bookings', e));
      return AvailabilityCheckResult.error(ConflictType.booking);
    }
  }

  /// Check for conflicts with iCal events (Booking.com, Airbnb, etc.).
  Future<AvailabilityCheckResult> _checkIcalEvents({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      // Using client-side filtering to avoid Firestore index requirement
      // NEW STRUCTURE: Use collection group query for subcollection
      final snapshot = await _firestore.collectionGroup(_icalEventsCollection).where('unit_id', isEqualTo: unitId).get();

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final eventStart = DateNormalizer.fromTimestamp(data['start_date'] as Timestamp?);
          final eventEnd = DateNormalizer.fromTimestamp(data['end_date'] as Timestamp?);

          if (eventStart == null || eventEnd == null) continue;

          final source = data['source'] as String? ?? 'iCal';

          if (_hasDateOverlap(start1: eventStart, end1: eventEnd, start2: checkIn, end2: checkOut)) {
            LoggingService.log(
              '❌ iCal conflict found: $source event from $eventStart to $eventEnd',
              tag: 'AVAILABILITY_CHECK',
            );
            return AvailabilityCheckResult.icalConflict(doc.id, source);
          }
        } catch (e) {
          unawaited(LoggingService.logError('Error parsing iCal event document', e));
        }
      }

      return const AvailabilityCheckResult.available();
    } catch (e) {
      unawaited(LoggingService.logError('Error fetching iCal events', e));
      return AvailabilityCheckResult.error(ConflictType.icalEvent);
    }
  }

  /// Check for conflicts with blocked dates (daily_prices with available: false).
  Future<AvailabilityCheckResult> _checkBlockedDates({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      // NEW STRUCTURE: Use collection group query for subcollection
      final snapshot = await _firestore
          .collectionGroup(_dailyPricesCollection)
          .where('unit_id', isEqualTo: unitId)
          .where('available', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final blockedDate = DateNormalizer.fromTimestamp(data['date'] as Timestamp?);

          if (blockedDate == null) continue;

          // Blocked date conflicts if within stay nights: checkIn <= blockedDate < checkOut
          final isWithinStay = !blockedDate.isBefore(checkIn) && blockedDate.isBefore(checkOut);

          if (isWithinStay) {
            LoggingService.log('❌ Blocked date conflict found: $blockedDate', tag: 'AVAILABILITY_CHECK');
            return AvailabilityCheckResult.blockedDateConflict(doc.id, blockedDate);
          }
        } catch (e) {
          unawaited(LoggingService.logError('Error parsing blocked date document', e));
        }
      }

      return const AvailabilityCheckResult.available();
    } catch (e) {
      unawaited(LoggingService.logError('Error fetching blocked dates', e));
      return AvailabilityCheckResult.error(ConflictType.blockedDate);
    }
  }

  /// Check for blockCheckIn on check-in date and blockCheckOut on check-out date.
  ///
  /// This is separate from _checkBlockedDates because:
  /// - blockCheckIn only applies to the CHECK-IN date
  /// - blockCheckOut only applies to the CHECK-OUT date
  /// - available:false blocks the entire date for all purposes
  Future<AvailabilityCheckResult> _checkBlockedCheckInOut({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      // Batch both queries together for efficiency
      final checkInTimestamp = Timestamp.fromDate(checkIn);
      final checkOutTimestamp = Timestamp.fromDate(checkOut);

      // Single query fetching both dates if they exist
      // NEW STRUCTURE: Use collection group query for subcollection
      final snapshot = await _firestore
          .collectionGroup(_dailyPricesCollection)
          .where('unit_id', isEqualTo: unitId)
          .where('date', whereIn: [checkInTimestamp, checkOutTimestamp])
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final docDate = DateNormalizer.fromTimestamp(data['date'] as Timestamp?);

        if (docDate == null) continue;

        // Check if this doc is for check-in date
        if (docDate.isAtSameMomentAs(checkIn)) {
          final isBlockedCheckIn = data['block_checkin'] as bool? ?? false;
          if (isBlockedCheckIn) {
            LoggingService.log('❌ Check-in blocked on $checkIn', tag: 'AVAILABILITY_CHECK');
            return AvailabilityCheckResult.blockedCheckInConflict(doc.id, checkIn);
          }
        }

        // Check if this doc is for check-out date
        if (docDate.isAtSameMomentAs(checkOut)) {
          final isBlockedCheckOut = data['block_checkout'] as bool? ?? false;
          if (isBlockedCheckOut) {
            LoggingService.log('❌ Check-out blocked on $checkOut', tag: 'AVAILABILITY_CHECK');
            return AvailabilityCheckResult.blockedCheckOutConflict(doc.id, checkOut);
          }
        }
      }

      return const AvailabilityCheckResult.available();
    } catch (e) {
      unawaited(LoggingService.logError('Error checking blockCheckIn/blockCheckOut', e));
      // Return available on error - don't block legitimate bookings
      return const AvailabilityCheckResult.available();
    }
  }

  /// Check if two date ranges overlap with turnover day support.
  ///
  /// Overlap exists if: (end1 > start2) AND (start1 < end2)
  /// Using > (not >=) allows same-day turnover (checkOut = checkIn is OK)
  ///
  /// Example: Booking A (Jan 10-15, checkout 10:00 AM) and Booking B (Jan 15-20, check-in 3:00 PM)
  /// are NOT overlapping because checkout day (Jan 15) does NOT block check-in for new booking.
  /// This enables turnover day scenarios where one guest checks out in the morning
  /// and another guest checks in in the afternoon on the same day.
  bool _hasDateOverlap({
    required DateTime start1,
    required DateTime end1,
    required DateTime start2,
    required DateTime end2,
  }) => end1.isAfter(start2) && start1.isBefore(end2);
}
