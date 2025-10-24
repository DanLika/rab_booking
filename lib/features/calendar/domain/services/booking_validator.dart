import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/validation_result.dart';

/// Service for validating booking operations
class BookingValidator {
  final SupabaseClient _supabase;
  final BookingSettings settings;

  BookingValidator({
    required SupabaseClient supabase,
    required this.settings,
  }) : _supabase = supabase;

  // =============================================================================
  // DATE RANGE VALIDATION
  // =============================================================================

  /// Validate date range for booking
  ValidationResult validateDateRange(DateTime checkIn, DateTime checkOut) {
    // Rule 1: Check-out must be after check-in
    if (checkOut.isBefore(checkIn) || checkOut.isAtSameMomentAs(checkIn)) {
      return ValidationResult.error(
        'Check-out date must be after check-in date',
      );
    }

    // Get today at start of day (midnight)
    final today = DateTime.now().startOfDay;

    // Rule 2: Check-in must not be in the past
    if (checkIn.isBefore(today)) {
      return ValidationResult.error(
        'Cannot book dates in the past',
      );
    }

    // Rule 3: Check-in must not be today (unless allowed)
    if (!settings.allowSameDayBooking && _isSameDay(checkIn, DateTime.now())) {
      return ValidationResult.error(
        'Same-day bookings are not allowed. Please select a future date.',
      );
    }

    // Rule 4: Minimum advance booking
    final minCheckIn = today.add(Duration(days: settings.minAdvanceDays));
    if (checkIn.isBefore(minCheckIn)) {
      return ValidationResult.error(
        'Bookings require at least ${settings.minAdvanceDays} day(s) advance notice',
      );
    }

    // Rule 5: Maximum advance booking
    final maxCheckIn = today.add(Duration(days: settings.maxAdvanceDays));
    if (checkIn.isAfter(maxCheckIn)) {
      return ValidationResult.error(
        'Cannot book more than ${settings.maxAdvanceDays} days in advance',
      );
    }

    // Rule 6: Minimum nights
    final nights = checkOut.difference(checkIn).inDays;
    if (nights < settings.minNights) {
      return ValidationResult.error(
        'Minimum stay is ${settings.minNights} night${settings.minNights > 1 ? 's' : ''}',
      );
    }

    // Rule 7: Maximum nights
    if (nights > settings.maxNights) {
      return ValidationResult.error(
        'Maximum stay is ${settings.maxNights} night${settings.maxNights > 1 ? 's' : ''}',
      );
    }

    return ValidationResult.success();
  }

  // =============================================================================
  // CONFLICT CHECKING
  // =============================================================================

  /// Check for booking conflicts with existing bookings
  Future<ValidationResult> checkConflicts(
    String unitId,
    DateTime checkIn,
    DateTime checkOut, {
    String? excludeBookingId,
  }) async {
    try {
      final result = await _supabase.rpc(
        'check_booking_conflict',
        params: {
          'p_unit_id': unitId,
          'p_check_in': checkIn.toIso8601String(),
          'p_check_out': checkOut.toIso8601String(),
          'p_exclude_booking_id': excludeBookingId,
        },
      );

      if (result == null) {
        // No conflict
        return ValidationResult.success();
      }

      // Conflict exists
      final conflictData = result as Map<String, dynamic>;
      return ValidationResult.error(
        'Selected dates are no longer available. Please choose different dates.',
        metadata: {
          'conflictingBookingId': conflictData['booking_id'],
          'conflictCheckIn': conflictData['check_in'],
          'conflictCheckOut': conflictData['check_out'],
        },
      );
    } catch (e) {
      return ValidationResult.error(
        'Failed to check availability: ${e.toString()}',
      );
    }
  }

  /// Check if dates are blocked by owner
  Future<ValidationResult> checkBlocked(
    String unitId,
    DateTime checkIn,
    DateTime checkOut,
  ) async {
    try {
      final blockedDates = await _supabase
          .from('calendar_availability')
          .select('blocked_from, blocked_to, reason')
          .eq('unit_id', unitId)
          .eq('is_blocked', true)
          .gte('blocked_to', checkIn.toIso8601String())
          .lte('blocked_from', checkOut.toIso8601String());

      if (blockedDates.isEmpty) {
        return ValidationResult.success();
      }

      final firstBlocked = blockedDates.first;
      return ValidationResult.error(
        'Selected dates include blocked periods',
        metadata: {
          'blockedFrom': firstBlocked['blocked_from'],
          'blockedTo': firstBlocked['blocked_to'],
          'reason': firstBlocked['reason'],
        },
      );
    } catch (e) {
      return ValidationResult.error(
        'Failed to check blocked dates: ${e.toString()}',
      );
    }
  }

  // =============================================================================
  // SAME-DAY TURNOVER VALIDATION
  // =============================================================================

  /// Check if same-day turnover is allowed
  Future<ValidationResult> validateSameDayTurnover(
    String unitId,
    DateTime requestedCheckIn,
  ) async {
    // Check if same-day turnover is enabled
    if (!settings.allowSameDayTurnover) {
      return ValidationResult.success();
    }

    try {
      // Find booking that ends on requested check-in date
      final previousBooking = await _supabase
          .from('bookings')
          .select('check_out, check_out_time')
          .eq('unit_id', unitId)
          .eq('check_out', requestedCheckIn.toIso8601String().split('T')[0])
          .inFilter('status', ['confirmed', 'pending'])
          .maybeSingle();

      if (previousBooking == null) {
        // No same-day turnover
        return ValidationResult.success();
      }

      // Check if there's enough time for turnover
      final checkOutTime = _parseTime(previousBooking['check_out_time']);
      final checkInTime = TimeOfDay(
        hour: settings.checkInHour,
        minute: 0,
      );

      final timeDifference = (checkInTime.hour * 60 + checkInTime.minute) -
          (checkOutTime.hour * 60 + checkOutTime.minute);

      final minMinutes = settings.minTurnoverHours * 60;

      if (timeDifference < minMinutes) {
        return ValidationResult.error(
          'Same-day turnover requires at least ${settings.minTurnoverHours} hours between bookings. '
          'Previous guest checks out at ${checkOutTime.format()}, '
          'but check-in is at ${checkInTime.format()}.',
        );
      }

      // Valid same-day turnover
      return ValidationResult.warning(
        'This is a same-day turnover booking. '
        'Please ensure cleaning is scheduled between ${checkOutTime.format()} and ${checkInTime.format()}.',
      );
    } catch (e) {
      return ValidationResult.error(
        'Failed to validate same-day turnover: ${e.toString()}',
      );
    }
  }

  // =============================================================================
  // COMPREHENSIVE VALIDATION
  // =============================================================================

  /// Validate all booking rules
  Future<ValidationResult> validateBooking({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? excludeBookingId,
  }) async {
    // Step 1: Validate date range
    final dateRangeResult = validateDateRange(checkIn, checkOut);
    if (!dateRangeResult.isValid) {
      return dateRangeResult;
    }

    // Step 2: Check for conflicts
    final conflictResult = await checkConflicts(
      unitId,
      checkIn,
      checkOut,
      excludeBookingId: excludeBookingId,
    );
    if (!conflictResult.isValid) {
      return conflictResult;
    }

    // Step 3: Check for blocked dates
    final blockedResult = await checkBlocked(unitId, checkIn, checkOut);
    if (!blockedResult.isValid) {
      return blockedResult;
    }

    // Step 4: Validate same-day turnover (if applicable)
    final turnoverResult = await validateSameDayTurnover(unitId, checkIn);
    if (!turnoverResult.isValid) {
      return turnoverResult;
    }

    // All validations passed
    if (turnoverResult.hasWarning) {
      return turnoverResult; // Return with warning
    }

    return ValidationResult.success();
  }

  // =============================================================================
  // OWNER VALIDATION (Blocking Dates)
  // =============================================================================

  /// Validate owner blocking dates
  Future<ValidationResult> validateBlocking({
    required String unitId,
    required DateTime from,
    required DateTime to,
    required String ownerId,
  }) async {
    // Check for existing bookings in range
    try {
      final existingBookings = await _supabase
          .from('bookings')
          .select('id, check_in, check_out, guest_name')
          .eq('unit_id', unitId)
          .inFilter('status', ['confirmed', 'pending'])
          .gte('check_out', from.toIso8601String())
          .lte('check_in', to.toIso8601String());

      if (existingBookings.isNotEmpty) {
        return ValidationResult.error(
          'Cannot block dates with existing bookings. '
          'Found ${existingBookings.length} booking(s) in this range.',
          metadata: {
            'conflictingBookings': existingBookings,
          },
        );
      }

      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.error(
        'Failed to validate blocking: ${e.toString()}',
      );
    }
  }

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  /// Check if two dates are on the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Parse time string to TimeOfDay
  TimeOfDay _parseTime(String? timeString) {
    if (timeString == null) {
      return TimeOfDay(hour: settings.checkOutHour, minute: 0);
    }

    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}

/// Extension for DateTime
extension DateTimeX on DateTime {
  /// Get date at start of day (midnight)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Get date at end of day (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59);
  }
}

/// Extension for TimeOfDay
extension TimeOfDayX on TimeOfDay {
  /// Format time as string
  String format() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
