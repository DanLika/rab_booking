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
  /// ENHANCED: Detects same-day turnover (CheckOut + CheckIn on same day)
  /// and assigns special stack levels for split rendering
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

  /// Detect same-day turnover pairs (CheckOut + CheckIn on same day)
  ///
  /// Returns a map of date → list of booking pairs that have turnover on that date
  /// Each pair contains [checkOutBooking, checkInBooking]
  static Map<DateTime, List<List<BookingModel>>> detectSameDayTurnovers(
    List<BookingModel> bookings,
  ) {
    final Map<DateTime, List<List<BookingModel>>> turnovers = {};

    if (bookings.length < 2) return turnovers;

    // Sort bookings by check-in date
    final sorted = List<BookingModel>.from(bookings)
      ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

    // Find pairs where checkOut date matches checkIn date
    for (int i = 0; i < sorted.length - 1; i++) {
      final currentBooking = sorted[i];
      final currentCheckOut = _normalizeDate(currentBooking.checkOut);

      for (int j = i + 1; j < sorted.length; j++) {
        final nextBooking = sorted[j];
        final nextCheckIn = _normalizeDate(nextBooking.checkIn);

        // Check if checkOut and checkIn are on the same day
        if (currentCheckOut.isAtSameMomentAs(nextCheckIn)) {
          turnovers.putIfAbsent(currentCheckOut, () => []);
          turnovers[currentCheckOut]!.add([currentBooking, nextBooking]);
        }
      }
    }

    return turnovers;
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
  /// Delegates to BookingOverlapDetector for consistent overlap logic.
  /// Same-day turnover is NOT considered overlap.
  ///
  /// @deprecated Use BookingOverlapDetector.doBookingsOverlap directly
  static bool hasOverlap(BookingModel booking1, BookingModel booking2) {
    return BookingOverlapDetector.doBookingsOverlap(
      start1: booking1.checkIn,
      end1: booking1.checkOut,
      start2: booking2.checkIn,
      end2: booking2.checkOut,
    );
  }

  /// Normalize date to midnight (remove time component)
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
