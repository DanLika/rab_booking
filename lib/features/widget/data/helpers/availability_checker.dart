import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/logging_service.dart';
import '../../../../shared/models/booking_model.dart';
import '../../utils/date_normalizer.dart';

/// Result of an availability check with detailed conflict information.
class AvailabilityCheckResult {
  /// Whether the dates are available for booking.
  final bool isAvailable;

  /// Type of conflict found (if any).
  final ConflictType? conflictType;

  /// Human-readable conflict message (if any).
  final String? conflictMessage;

  /// ID of the conflicting document (booking, iCal event, or daily_price).
  final String? conflictingDocId;

  const AvailabilityCheckResult({
    required this.isAvailable,
    this.conflictType,
    this.conflictMessage,
    this.conflictingDocId,
  });

  /// Factory for available result.
  const AvailabilityCheckResult.available()
      : isAvailable = true,
        conflictType = null,
        conflictMessage = null,
        conflictingDocId = null;

  /// Factory for booking conflict.
  factory AvailabilityCheckResult.bookingConflict(String bookingId) {
    return AvailabilityCheckResult(
      isAvailable: false,
      conflictType: ConflictType.booking,
      conflictMessage: 'Conflict with existing booking',
      conflictingDocId: bookingId,
    );
  }

  /// Factory for iCal conflict.
  factory AvailabilityCheckResult.icalConflict(String eventId, String source) {
    return AvailabilityCheckResult(
      isAvailable: false,
      conflictType: ConflictType.icalEvent,
      conflictMessage: 'Conflict with $source event',
      conflictingDocId: eventId,
    );
  }

  /// Factory for blocked date conflict.
  factory AvailabilityCheckResult.blockedDateConflict(
    String priceDocId,
    DateTime blockedDate,
  ) {
    return AvailabilityCheckResult(
      isAvailable: false,
      conflictType: ConflictType.blockedDate,
      conflictMessage: 'Date ${blockedDate.toString().split(' ')[0]} is blocked',
      conflictingDocId: priceDocId,
    );
  }
}

/// Type of availability conflict.
enum ConflictType {
  /// Conflict with an existing booking.
  booking,

  /// Conflict with an iCal event (Booking.com, Airbnb, etc.).
  icalEvent,

  /// Conflict with a manually blocked date.
  blockedDate,
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
///   print('Conflict: ${result.conflictMessage}');
/// }
/// ```
class AvailabilityChecker {
  final FirebaseFirestore _firestore;

  AvailabilityChecker(this._firestore);

  /// Check if date range is available for booking.
  ///
  /// Returns [AvailabilityCheckResult] with detailed conflict info.
  Future<AvailabilityCheckResult> check({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    // Normalize dates to midnight for consistent comparison
    final normalizedCheckIn = DateNormalizer.normalize(checkIn);
    final normalizedCheckOut = DateNormalizer.normalize(checkOut);

    // 1. Check regular bookings
    final bookingResult = await _checkBookings(
      unitId: unitId,
      checkIn: normalizedCheckIn,
      checkOut: normalizedCheckOut,
    );
    if (!bookingResult.isAvailable) return bookingResult;

    // 2. Check iCal events
    final icalResult = await _checkIcalEvents(
      unitId: unitId,
      checkIn: normalizedCheckIn,
      checkOut: normalizedCheckOut,
    );
    if (!icalResult.isAvailable) return icalResult;

    // 3. Check blocked dates
    final blockedResult = await _checkBlockedDates(
      unitId: unitId,
      checkIn: normalizedCheckIn,
      checkOut: normalizedCheckOut,
    );
    if (!blockedResult.isAvailable) return blockedResult;

    LoggingService.log(
      '✅ No conflicts found for $normalizedCheckIn to $normalizedCheckOut',
      tag: 'AVAILABILITY_CHECK',
    );

    return const AvailabilityCheckResult.available();
  }

  /// Simple boolean check for backward compatibility.
  Future<bool> isAvailable({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    final result = await check(
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
    );
    return result.isAvailable;
  }

  /// Check for conflicts with regular bookings.
  Future<AvailabilityCheckResult> _checkBookings({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      // Note: Using client-side filtering to avoid Firestore limitation of
      // whereIn + inequality filters requiring composite index
      final snapshot = await _firestore
          .collection('bookings')
          .where('unit_id', isEqualTo: unitId)
          .where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
          .get();

      for (final doc in snapshot.docs) {
        try {
          final booking = BookingModel.fromJson({...doc.data(), 'id': doc.id});

          // Normalize booking dates for comparison
          final bookingCheckIn = DateNormalizer.normalize(booking.checkIn);
          final bookingCheckOut = DateNormalizer.normalize(booking.checkOut);

          // Overlap logic with turnover day support:
          // Conflict exists if: (bookingCheckOut > checkIn) AND (bookingCheckIn < checkOut)
          // Using > (not >=) allows same-day turnover (checkOut = checkIn is OK)
          if (bookingCheckOut.isAfter(checkIn) &&
              bookingCheckIn.isBefore(checkOut)) {
            LoggingService.log(
              '❌ Booking conflict found: ${booking.id}',
              tag: 'AVAILABILITY_CHECK',
            );
            return AvailabilityCheckResult.bookingConflict(booking.id);
          }
        } catch (e) {
          unawaited(
            LoggingService.logError('Error checking booking availability', e),
          );
        }
      }

      return const AvailabilityCheckResult.available();
    } catch (e) {
      unawaited(LoggingService.logError('Error fetching bookings', e));
      // Return unavailable on error to be safe
      return const AvailabilityCheckResult(
        isAvailable: false,
        conflictType: ConflictType.booking,
        conflictMessage: 'Error checking booking availability',
      );
    }
  }

  /// Check for conflicts with iCal events (Booking.com, Airbnb, etc.).
  Future<AvailabilityCheckResult> _checkIcalEvents({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      // Note: Using client-side filtering to avoid Firestore index requirement
      final snapshot = await _firestore
          .collection('ical_events')
          .where('unit_id', isEqualTo: unitId)
          .get();

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final eventStart = DateNormalizer.fromTimestamp(
            data['start_date'] as Timestamp?,
          );
          final eventEnd = DateNormalizer.fromTimestamp(
            data['end_date'] as Timestamp?,
          );

          if (eventStart == null || eventEnd == null) continue;

          final source = data['source'] as String? ?? 'iCal';

          // Overlap logic with turnover day support
          if (eventEnd.isAfter(checkIn) && eventStart.isBefore(checkOut)) {
            LoggingService.log(
              '❌ iCal conflict found: $source event from $eventStart to $eventEnd',
              tag: 'AVAILABILITY_CHECK',
            );
            return AvailabilityCheckResult.icalConflict(doc.id, source);
          }
        } catch (e) {
          unawaited(
            LoggingService.logError('Error checking iCal event availability', e),
          );
        }
      }

      return const AvailabilityCheckResult.available();
    } catch (e) {
      unawaited(LoggingService.logError('Error fetching iCal events', e));
      return const AvailabilityCheckResult(
        isAvailable: false,
        conflictType: ConflictType.icalEvent,
        conflictMessage: 'Error checking iCal event availability',
      );
    }
  }

  /// Check for conflicts with blocked dates (daily_prices with available: false).
  Future<AvailabilityCheckResult> _checkBlockedDates({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('daily_prices')
          .where('unit_id', isEqualTo: unitId)
          .where('available', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final blockedDate = DateNormalizer.fromTimestamp(
            data['date'] as Timestamp?,
          );

          if (blockedDate == null) continue;

          // Blocked date is a conflict if: blockedDate >= checkIn AND blockedDate < checkOut
          // (checkOut day is not counted as a night stay)
          if ((blockedDate.isAfter(checkIn) ||
                  blockedDate.isAtSameMomentAs(checkIn)) &&
              blockedDate.isBefore(checkOut)) {
            LoggingService.log(
              '❌ Blocked date conflict found: $blockedDate',
              tag: 'AVAILABILITY_CHECK',
            );
            return AvailabilityCheckResult.blockedDateConflict(
              doc.id,
              blockedDate,
            );
          }
        } catch (e) {
          unawaited(
            LoggingService.logError('Error checking blocked date availability', e),
          );
        }
      }

      return const AvailabilityCheckResult.available();
    } catch (e) {
      unawaited(LoggingService.logError('Error fetching blocked dates', e));
      return const AvailabilityCheckResult(
        isAvailable: false,
        conflictType: ConflictType.blockedDate,
        conflictMessage: 'Error checking blocked date availability',
      );
    }
  }
}
