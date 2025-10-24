import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import '../models/validation_result.dart';
import '../../data/local/booking_local_storage.dart';

// =============================================================================
// ATOMIC BOOKING HANDLER
// =============================================================================

/// Handles atomic booking creation with conflict checking
class AtomicBookingHandler {
  final SupabaseClient _supabase;

  AtomicBookingHandler(this._supabase);

  /// Create booking atomically (prevents race conditions)
  Future<Map<String, dynamic>> createBookingAtomic({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required String userId,
    required int guestCount,
    required double totalPrice,
    String? notes,
  }) async {
    try {
      // Call PostgreSQL function that uses transaction
      final result = await _supabase.rpc(
        'create_booking_atomic',
        params: {
          'p_unit_id': unitId,
          'p_user_id': userId,
          'p_check_in': checkIn.toIso8601String(),
          'p_check_out': checkOut.toIso8601String(),
          'p_check_in_time': '15:00:00',
          'p_check_out_time': '10:00:00',
          'p_guest_count': guestCount,
          'p_total_price': totalPrice,
          'p_notes': notes,
        },
      );

      // Check for conflict
      if (result['conflict'] == true) {
        throw BookingConflictException(
          'Sorry, these dates were just booked by another guest. '
          'Please select different dates.',
          conflictDetails: result['conflict_details'],
        );
      }

      // Return booking data
      return result as Map<String, dynamic>;
    } catch (e) {
      if (e is BookingConflictException) {
        rethrow;
      }
      throw Exception('Failed to create booking: ${e.toString()}');
    }
  }

  /// Update booking atomically
  Future<Map<String, dynamic>> updateBookingAtomic({
    required String bookingId,
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? notes,
  }) async {
    try {
      final result = await _supabase.rpc(
        'update_booking_atomic',
        params: {
          'p_booking_id': bookingId,
          'p_unit_id': unitId,
          'p_check_in': checkIn.toIso8601String(),
          'p_check_out': checkOut.toIso8601String(),
          'p_notes': notes,
        },
      );

      if (result['conflict'] == true) {
        throw BookingConflictException(
          'Cannot update booking - dates conflict with another booking.',
          conflictDetails: result['conflict_details'],
        );
      }

      return result as Map<String, dynamic>;
    } catch (e) {
      if (e is BookingConflictException) {
        rethrow;
      }
      throw Exception('Failed to update booking: ${e.toString()}');
    }
  }
}

// =============================================================================
// OFFLINE BOOKING QUEUE
// =============================================================================

/// Handles offline booking requests
class OfflineBookingQueue {
  final BookingLocalStorage _localStorage;
  final AtomicBookingHandler _atomicHandler;

  OfflineBookingQueue({
    required BookingLocalStorage localStorage,
    required AtomicBookingHandler atomicHandler,
  })  : _localStorage = localStorage,
        _atomicHandler = atomicHandler;

  /// Queue booking for later submission
  Future<void> queueBooking(Map<String, dynamic> bookingData) async {
    await _localStorage.savePendingBooking(bookingData);
  }

  /// Process all pending bookings when online
  Future<List<BookingProcessResult>> processPendingBookings() async {
    final pending = await _localStorage.getPendingBookings();
    final results = <BookingProcessResult>[];

    for (final booking in pending) {
      try {
        // Re-validate availability
        final isAvailable = await _checkAvailability(booking);

        if (!isAvailable) {
          // Dates no longer available
          results.add(BookingProcessResult(
            bookingId: booking['id'],
            success: false,
            message: 'Sorry, dates for ${booking['property_name']} are no longer available.',
          ));

          // Remove from queue
          await _localStorage.deletePendingBooking(booking['id']);
          continue;
        }

        // Attempt to create booking
        final result = await _atomicHandler.createBookingAtomic(
          unitId: booking['unit_id'],
          checkIn: DateTime.parse(booking['check_in']),
          checkOut: DateTime.parse(booking['check_out']),
          userId: booking['user_id'],
          guestCount: booking['guest_count'],
          totalPrice: booking['total_price'],
          notes: booking['notes'],
        );

        results.add(BookingProcessResult(
          bookingId: result['id'],
          success: true,
          message: 'Booking confirmed!',
        ));

        // Remove from queue
        await _localStorage.deletePendingBooking(booking['id']);
      } catch (e) {
        // Keep in queue for retry
        results.add(BookingProcessResult(
          bookingId: booking['id'],
          success: false,
          message: 'Failed to process booking. Will retry later.',
          shouldRetry: true,
        ));
      }
    }

    return results;
  }

  /// Check if dates are still available
  Future<bool> _checkAvailability(Map<String, dynamic> booking) async {
    // This would call the validation service
    // Simplified here
    return true; // TODO: Implement actual check
  }
}

/// Result of processing a pending booking
class BookingProcessResult {
  final String bookingId;
  final bool success;
  final String message;
  final bool shouldRetry;

  BookingProcessResult({
    required this.bookingId,
    required this.success,
    required this.message,
    this.shouldRetry = false,
  });
}

// =============================================================================
// TIME ZONE HANDLER
// =============================================================================

/// Handles time zone conversions for bookings
class TimeZoneHandler {
  final String propertyTimeZone;
  late final tz.Location _propertyLocation;

  TimeZoneHandler({
    this.propertyTimeZone = 'Europe/Zagreb', // Croatia
  }) {
    _propertyLocation = tz.getLocation(propertyTimeZone);
  }

  /// Convert UTC to property local time
  DateTime toPropertyTime(DateTime utcDate) {
    return tz.TZDateTime.from(utcDate, _propertyLocation);
  }

  /// Convert property local time to UTC
  DateTime toUtc(DateTime localDate) {
    final tzDate = tz.TZDateTime(
      _propertyLocation,
      localDate.year,
      localDate.month,
      localDate.day,
      localDate.hour,
      localDate.minute,
    );
    return tzDate.toUtc();
  }

  /// Get date at start of day in property timezone
  DateTime getPropertyStartOfDay(DateTime date) {
    final propertyDate = toPropertyTime(date);
    final startOfDay = tz.TZDateTime(
      _propertyLocation,
      propertyDate.year,
      propertyDate.month,
      propertyDate.day,
    );
    return startOfDay.toUtc();
  }

  /// Format check-in time with timezone info
  String formatCheckInTime(TimeOfDay time) {
    return '${time.format()} (${_getTimeZoneAbbreviation()})';
  }

  /// Format check-out time with timezone info
  String formatCheckOutTime(TimeOfDay time) {
    return '${time.format()} (${_getTimeZoneAbbreviation()})';
  }

  /// Get timezone abbreviation (e.g., "CET", "CEST")
  String _getTimeZoneAbbreviation() {
    final now = tz.TZDateTime.now(_propertyLocation);
    return now.timeZoneAbbreviation;
  }

  /// Get current time in property timezone
  DateTime getNowInPropertyTimeZone() {
    return tz.TZDateTime.now(_propertyLocation);
  }

  /// Check if dates cross DST boundary
  bool crossesDstBoundary(DateTime checkIn, DateTime checkOut) {
    final checkInTz = tz.TZDateTime.from(checkIn, _propertyLocation);
    final checkOutTz = tz.TZDateTime.from(checkOut, _propertyLocation);

    return checkInTz.timeZoneOffset != checkOutTz.timeZoneOffset;
  }
}

// =============================================================================
// OWNER CONFLICT HANDLER
// =============================================================================

/// Handles conflicts when owner tries to block dates with existing bookings
class OwnerConflictHandler {
  final SupabaseClient _supabase;

  OwnerConflictHandler(this._supabase);

  /// Get existing bookings that conflict with blocking request
  Future<List<BookingConflict>> getConflictingBookings({
    required String unitId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final bookings = await _supabase
          .from('bookings')
          .select('id, check_in, check_out, guest_name, guest_email, status')
          .eq('unit_id', unitId)
          .inFilter('status', ['confirmed', 'pending'])
          .gte('check_out', from.toIso8601String())
          .lte('check_in', to.toIso8601String());

      return bookings
          .map((b) => BookingConflict(
                bookingId: b['id'],
                checkIn: DateTime.parse(b['check_in']),
                checkOut: DateTime.parse(b['check_out']),
                guestName: b['guest_name'],
                guestEmail: b['guest_email'],
                status: b['status'],
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to check conflicts: ${e.toString()}');
    }
  }

  /// Show conflict dialog to owner
  Future<BlockingConflictAction?> showConflictDialog(
    BuildContext context,
    List<BookingConflict> conflicts,
  ) async {
    return showDialog<BlockingConflictAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Existing Bookings Found'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following bookings overlap with your selected dates:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...conflicts.map((conflict) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(conflict.guestName),
                      subtitle: Text(
                        '${_formatDate(conflict.checkIn)} - ${_formatDate(conflict.checkOut)}\n'
                        'Status: ${conflict.status}',
                      ),
                      trailing: Icon(
                        Icons.warning,
                        color: Colors.orange,
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
              const Text(
                'Please cancel these bookings first or choose different dates.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, BlockingConflictAction.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, BlockingConflictAction.chooseDifferentDates),
            child: const Text('Choose Different Dates'),
          ),
          if (conflicts.length == 1)
            TextButton(
              onPressed: () => Navigator.pop(context, BlockingConflictAction.cancelBooking),
              child: Text(
                'Cancel Booking',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Booking conflict details
class BookingConflict {
  final String bookingId;
  final DateTime checkIn;
  final DateTime checkOut;
  final String guestName;
  final String guestEmail;
  final String status;

  BookingConflict({
    required this.bookingId,
    required this.checkIn,
    required this.checkOut,
    required this.guestName,
    required this.guestEmail,
    required this.status,
  });
}

/// Actions for blocking conflict resolution
enum BlockingConflictAction {
  cancel,
  chooseDifferentDates,
  cancelBooking,
}

// =============================================================================
// REALTIME CONFLICT DETECTOR
// =============================================================================

/// Detects conflicts during multi-step booking process
class RealtimeConflictDetector {
  final SupabaseClient _supabase;

  RealtimeConflictDetector(this._supabase);

  /// Check if selected dates are still available during checkout
  Future<bool> validateBeforePayment({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      final conflict = await _supabase.rpc(
        'check_booking_conflict',
        params: {
          'p_unit_id': unitId,
          'p_check_in': checkIn.toIso8601String(),
          'p_check_out': checkOut.toIso8601String(),
        },
      );

      return conflict == null; // No conflict = available
    } catch (e) {
      // On error, assume not available (fail safe)
      return false;
    }
  }

  /// Continuous validation during booking flow
  Stream<bool> watchAvailability({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async* {
    // Check immediately
    yield await validateBeforePayment(
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
    );

    // Re-check every 5 seconds
    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      yield await validateBeforePayment(
        unitId: unitId,
        checkIn: checkIn,
        checkOut: checkOut,
      );
    }
  }
}

// =============================================================================
// TIME OF DAY EXTENSION
// =============================================================================

extension TimeOfDayFormat on TimeOfDay {
  String format() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
