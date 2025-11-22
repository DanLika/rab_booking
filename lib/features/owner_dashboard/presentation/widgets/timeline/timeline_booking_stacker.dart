import '../../../../../shared/models/booking_model.dart';

/// Helper class for stacking overlapping bookings in timeline calendar
///
/// When multiple bookings overlap (e.g., cancelled + new booking on same dates),
/// they need to be displayed vertically stacked instead of overlapping.
class TimelineBookingStacker {
  /// Assign stack levels to bookings within a unit
  ///
  /// Returns a map of booking ID → stack level (0, 1, 2...)
  /// Stack level determines the Y position of the booking block
  static Map<String, int> assignStackLevels(List<BookingModel> bookings) {
    final Map<String, int> stackLevels = {};

    if (bookings.isEmpty) return stackLevels;

    // Sort bookings by check-in date
    final sorted = List<BookingModel>.from(bookings)
      ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

    // Track active bookings at each stack level
    final List<DateTime?> stackEndDates = [];

    for (final booking in sorted) {
      // Find the first available stack level
      int assignedLevel = 0;

      for (int level = 0; level < stackEndDates.length; level++) {
        final endDate = stackEndDates[level];

        // Check if this level is free (previous booking ended before this one starts)
        // IMPORTANT: Check-out at 3pm means that day is available for new check-in at 10am
        // So we compare: booking.checkIn >= previousCheckOut (same day is OK)
        if (endDate == null || !booking.checkIn.isBefore(endDate)) {
          assignedLevel = level;
          stackEndDates[level] = booking.checkOut;
          break;
        }
      }

      // If all existing levels are occupied, create a new level
      if (assignedLevel >= stackEndDates.length) {
        stackEndDates.add(booking.checkOut);
      } else {
        stackEndDates[assignedLevel] = booking.checkOut;
      }

      stackLevels[booking.id] = assignedLevel;
    }

    return stackLevels;
  }

  /// Calculate the maximum stack level (height) needed for a list of bookings
  ///
  /// Returns 0 if no bookings, otherwise returns max stack level + 1
  static int calculateMaxStackCount(List<BookingModel> bookings) {
    if (bookings.isEmpty) return 1; // Minimum 1 for empty rows

    final stackLevels = assignStackLevels(bookings);
    final maxLevel = stackLevels.values.fold<int>(
      0,
      (max, level) => level > max ? level : max,
    );

    return maxLevel + 1; // +1 because levels are 0-indexed
  }

  /// Check if two bookings overlap
  ///
  /// Overlap occurs when:
  /// - booking1.checkIn < booking2.checkOut AND
  /// - booking2.checkIn < booking1.checkOut
  ///
  /// IMPORTANT: Same-day turnover is NOT considered overlap
  /// (checkOut = 15, checkIn = 15 → no overlap)
  static bool hasOverlap(BookingModel booking1, BookingModel booking2) {
    // Normalize dates to midnight for comparison
    final check1In = _normalizeDate(booking1.checkIn);
    final check1Out = _normalizeDate(booking1.checkOut);
    final check2In = _normalizeDate(booking2.checkIn);
    final check2Out = _normalizeDate(booking2.checkOut);

    // Overlap if: checkIn < otherCheckOut AND otherCheckIn < checkOut
    // Same day turnover is OK: checkOut = checkIn (no overlap)
    return check1In.isBefore(check2Out) && check2In.isBefore(check1Out);
  }

  /// Normalize date to midnight (remove time component)
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
