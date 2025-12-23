import '../../../../../shared/models/booking_model.dart';
import '../../../utils/booking_overlap_detector.dart';

/// Helper class for stacking overlapping bookings in timeline calendar
///
/// When multiple bookings overlap (e.g., cancelled + new booking on same dates),
/// they need to be displayed vertically stacked instead of overlapping.
class TimelineBookingStacker {
  /// Assign stack levels to bookings within a unit
  ///
  /// Returns a map of booking ID → stack level (0, 1, 2...)
  /// Stack level determines the Y position of the booking block
  ///
  /// Algorithm: Greedy assignment - assigns each booking to the first available level
  /// where the previous booking has ended before this one starts.
  ///
  /// Time complexity: O(n²) where n is number of bookings
  /// Space complexity: O(n) for stack levels map
  ///
  /// IMPORTANT: Only active bookings (pending/confirmed) are considered for stacking.
  /// Cancelled and completed bookings are assigned stack level 0 but don't block other bookings.
  ///
  /// Example:
  /// - Booking A: May 1-5 → Level 0
  /// - Booking B: May 6-10 → Level 0 (A ended before B starts)
  /// - Booking C: May 3-7 → Level 1 (overlaps with A, so new level)
  static Map<String, int> assignStackLevels(List<BookingModel> bookings) {
    // Input validation
    if (bookings.isEmpty) {
      return {};
    }

    final Map<String, int> stackLevels = {};

    // Filter to only active bookings for stack level calculation
    // Cancelled and completed bookings don't block dates, so they shouldn't affect stacking
    final activeBookings = bookings.where(isActiveBooking).toList();
    final inactiveBookings = bookings
        .where((b) => !isActiveBooking(b))
        .toList();

    // Sort active bookings by check-in date
    final sorted = List<BookingModel>.from(activeBookings)
      ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

    // Track active bookings at each stack level
    final List<DateTime?> stackEndDates = [];

    // Assign stack levels to active bookings
    for (final booking in sorted) {
      // Find the first available stack level
      int assignedLevel = stackEndDates.length; // Default: new level

      for (int level = 0; level < stackEndDates.length; level++) {
        final endDate = stackEndDates[level];

        // Check if this level is free (previous booking ended before this one starts)
        // IMPORTANT: Check-out at 3pm means that day is available for new check-in at 10am
        // So we compare: booking.checkIn >= previousCheckOut (same day is OK)
        if (endDate == null || !booking.checkIn.isBefore(endDate)) {
          assignedLevel = level;
          break;
        }
      }

      // Create new level if needed
      if (assignedLevel >= stackEndDates.length) {
        stackEndDates.add(booking.checkOut);
      } else {
        // FIXED: Only update if this booking ends later than current end date
        final currentEnd = stackEndDates[assignedLevel];
        if (currentEnd == null || booking.checkOut.isAfter(currentEnd)) {
          stackEndDates[assignedLevel] = booking.checkOut;
        }
      }

      stackLevels[booking.id] = assignedLevel;
    }

    // Assign stack level 0 to inactive bookings (they don't affect stacking)
    for (final booking in inactiveBookings) {
      stackLevels[booking.id] = 0;
    }

    return stackLevels;
  }

  /// Detect same-day turnover pairs (CheckOut + CheckIn on same day)
  ///
  /// Returns a map of date → list of booking pairs that have turnover on that date
  /// Each pair contains [checkOutBooking, checkInBooking]
  ///
  /// Optimized algorithm: O(n) complexity using hash map instead of O(n²) nested loops
  ///
  /// Time complexity: O(n) where n is number of bookings
  /// Space complexity: O(n) for the hash map
  ///
  /// Example:
  /// - Booking A: May 1-5 (checkOut = May 5)
  /// - Booking B: May 5-10 (checkIn = May 5)
  /// - Result: {May 5: [[A, B]]}
  static Map<DateTime, List<List<BookingModel>>> detectSameDayTurnovers(
    List<BookingModel> bookings,
  ) {
    // Input validation
    if (bookings.isEmpty || bookings.length < 2) {
      return {};
    }

    final Map<DateTime, List<List<BookingModel>>> turnovers = {};

    // Build check-out date index for O(1) lookup
    // Maps normalized check-out date → list of bookings that check out on that date
    final Map<DateTime, List<BookingModel>> checkOutIndex = {};
    for (final booking in bookings) {
      final checkOutDate = _normalizeDate(booking.checkOut);
      checkOutIndex.putIfAbsent(checkOutDate, () => []).add(booking);
    }

    // Find matching check-ins
    // For each booking, check if its check-in date matches any check-out dates
    for (final booking in bookings) {
      final checkInDate = _normalizeDate(booking.checkIn);
      final matchingCheckOuts = checkOutIndex[checkInDate];

      if (matchingCheckOuts != null) {
        for (final checkOutBooking in matchingCheckOuts) {
          // Don't match a booking with itself
          if (checkOutBooking.id != booking.id) {
            turnovers.putIfAbsent(checkInDate, () => []).add([
              checkOutBooking,
              booking,
            ]);
          }
        }
      }
    }

    return turnovers;
  }

  /// Calculate the maximum stack level (height) needed for a list of bookings
  ///
  /// Returns 1 if no bookings (minimum for empty rows), otherwise returns max stack level + 1
  ///
  /// Input validation: Handles empty lists gracefully
  static int calculateMaxStackCount(List<BookingModel> bookings) {
    // Input validation
    if (bookings.isEmpty) {
      return 1; // Minimum 1 for empty rows
    }

    final stackLevels = assignStackLevels(bookings);
    final maxLevel = stackLevels.values.fold<int>(
      0,
      (max, level) => level > max ? level : max,
    );

    return maxLevel + 1; // +1 because levels are 0-indexed
  }

  /// Normalize date to midnight (remove time component)
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
