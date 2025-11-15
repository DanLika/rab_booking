import '../../../shared/models/booking_model.dart';

/// Booking overlap detector for drag-and-drop validation
/// Checks if a booking can be moved to a new date/unit without conflicts
///
/// IMPORTANT: This detector SUPPORTS same-day turnover (BedBooking-style)
/// - Booking A can check-out on May 5
/// - Booking B can check-in on May 5 (same day)
/// - This is NOT considered an overlap
class BookingOverlapDetector {
  /// Check if a booking overlaps with another booking
  ///
  /// SAME-DAY TURNOVER SUPPORT:
  /// - Uses isBefore/isAfter (not <=/>= comparisons)
  /// - This allows check-out date to equal check-in date of next booking
  /// - Example: Booking A (May 1-5) does NOT overlap with Booking B (May 5-10)
  static bool doBookingsOverlap({
    required DateTime start1,
    required DateTime end1,
    required DateTime start2,
    required DateTime end2,
  }) {
    // Two bookings overlap if:
    // - start1 is BEFORE end2 (not equal) AND
    // - end1 is AFTER start2 (not equal)
    //
    // This ensures same-day turnover is allowed:
    // - If end1 == start2, they DON'T overlap (checkout = next checkin)
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  /// Check if a booking can be placed in a unit without conflicts
  /// Returns true if there are NO conflicts (placement is valid)
  static bool canPlaceBooking({
    required String unitId,
    required DateTime newCheckIn,
    required DateTime newCheckOut,
    required String? bookingIdToExclude, // Exclude when editing existing booking
    required Map<String, List<BookingModel>> allBookings,
  }) {
    // Get all bookings for this unit
    final unitBookings = allBookings[unitId] ?? [];

    // Check each booking in the unit
    for (final booking in unitBookings) {
      // Skip the booking being moved (if editing)
      if (bookingIdToExclude != null && booking.id == bookingIdToExclude) {
        continue;
      }

      // Check for overlap
      if (doBookingsOverlap(
        start1: newCheckIn,
        end1: newCheckOut,
        start2: booking.checkIn,
        end2: booking.checkOut,
      )) {
        return false; // Conflict found
      }
    }

    return true; // No conflicts
  }

  /// Get all conflicting bookings for a date range in a unit
  static List<BookingModel> getConflictingBookings({
    required String unitId,
    required DateTime newCheckIn,
    required DateTime newCheckOut,
    required String? bookingIdToExclude,
    required Map<String, List<BookingModel>> allBookings,
  }) {
    final unitBookings = allBookings[unitId] ?? [];
    final conflicts = <BookingModel>[];

    for (final booking in unitBookings) {
      // Skip the booking being moved
      if (bookingIdToExclude != null && booking.id == bookingIdToExclude) {
        continue;
      }

      // Check for overlap
      if (doBookingsOverlap(
        start1: newCheckIn,
        end1: newCheckOut,
        start2: booking.checkIn,
        end2: booking.checkOut,
      )) {
        conflicts.add(booking);
      }
    }

    return conflicts;
  }

  /// Validate booking move (drag-and-drop)
  /// Returns validation result with details
  static BookingMoveValidation validateBookingMove({
    required String bookingId,
    required String currentUnitId,
    required String targetUnitId,
    required DateTime newCheckIn,
    required DateTime newCheckOut,
    required Map<String, List<BookingModel>> allBookings,
  }) {
    // Check if target unit exists in bookings map (unit is valid)
    if (!allBookings.containsKey(targetUnitId) && targetUnitId != currentUnitId) {
      return BookingMoveValidation(
        isValid: false,
        reason: 'Target unit does not exist',
      );
    }

    // Check for overlaps in target unit
    final canPlace = canPlaceBooking(
      unitId: targetUnitId,
      newCheckIn: newCheckIn,
      newCheckOut: newCheckOut,
      bookingIdToExclude: bookingId,
      allBookings: allBookings,
    );

    if (!canPlace) {
      final conflicts = getConflictingBookings(
        unitId: targetUnitId,
        newCheckIn: newCheckIn,
        newCheckOut: newCheckOut,
        bookingIdToExclude: bookingId,
        allBookings: allBookings,
      );

      return BookingMoveValidation(
        isValid: false,
        reason: 'Booking overlaps with ${conflicts.length} existing booking(s)',
        conflictingBookings: conflicts,
      );
    }

    // FIXED: Check if dates are in the past (compare dates only, not time)
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);
    final checkInNormalized = DateTime(newCheckIn.year, newCheckIn.month, newCheckIn.day);

    if (checkInNormalized.isBefore(todayNormalized)) {
      return BookingMoveValidation(
        isValid: false,
        reason: 'Cannot move booking to past dates',
      );
    }

    // Check if check-out is after check-in
    if (!newCheckOut.isAfter(newCheckIn)) {
      return BookingMoveValidation(
        isValid: false,
        reason: 'Check-out must be after check-in',
      );
    }

    // All validations passed
    return BookingMoveValidation(
      isValid: true,
      reason: 'Booking can be moved',
    );
  }

  /// Find available date slots in a unit
  /// Returns list of available date ranges (gaps between bookings)
  static List<DateRange> findAvailableSlots({
    required String unitId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required Map<String, List<BookingModel>> allBookings,
    int minNights = 1,
  }) {
    final unitBookings = allBookings[unitId] ?? [];
    final availableSlots = <DateRange>[];

    // Sort bookings by check-in date
    final sortedBookings = [...unitBookings]
      ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

    // Find gaps between bookings
    var currentStart = rangeStart;

    for (final booking in sortedBookings) {
      // If there's a gap before this booking
      if (booking.checkIn.isAfter(currentStart)) {
        final nights = booking.checkIn.difference(currentStart).inDays;
        if (nights >= minNights) {
          availableSlots.add(DateRange(
            start: currentStart,
            end: booking.checkIn,
          ));
        }
      }

      // Move current start to after this booking
      if (booking.checkOut.isAfter(currentStart)) {
        currentStart = booking.checkOut;
      }
    }

    // Check if there's a gap after the last booking
    if (currentStart.isBefore(rangeEnd)) {
      final nights = rangeEnd.difference(currentStart).inDays;
      if (nights >= minNights) {
        availableSlots.add(DateRange(
          start: currentStart,
          end: rangeEnd,
        ));
      }
    }

    return availableSlots;
  }
}

/// Booking move validation result
class BookingMoveValidation {
  final bool isValid;
  final String reason;
  final List<BookingModel>? conflictingBookings;

  BookingMoveValidation({
    required this.isValid,
    required this.reason,
    this.conflictingBookings,
  });
}

/// Date range helper class
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({
    required this.start,
    required this.end,
  });

  int get nights => end.difference(start).inDays;

  @override
  String toString() => '${start.toIso8601String()} - ${end.toIso8601String()}';
}
