import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/calendar_day.dart';
import 'package:intl/intl.dart';

part 'calendar_repository.g.dart';

@riverpod
CalendarRepository calendarRepository(CalendarRepositoryRef ref) {
  return CalendarRepository(Supabase.instance.client);
}

class CalendarRepository {
  final SupabaseClient _client;

  CalendarRepository(this._client);

  /// Get calendar data for a specific month using the get_calendar_data() function
  Future<List<CalendarDay>> getCalendarData({
    required String unitId,
    required DateTime month,
  }) async {
    try {
      // Format month as first day of month (YYYY-MM-01)
      final firstDayOfMonth = DateTime(month.year, month.month, 1);
      final formattedDate = DateFormat('yyyy-MM-dd').format(firstDayOfMonth);

      // Call PostgreSQL function
      final response = await _client.rpc(
        'get_calendar_data',
        params: {
          'p_unit_id': unitId,
          'p_month': formattedDate,
        },
      );

      if (response == null) return [];

      // Convert response to CalendarDay objects
      final List<dynamic> data = response as List<dynamic>;

      return data.map((item) {
        final dbResponse = CalendarDataResponse.fromJson(item);

        return CalendarDay(
          date: dbResponse.date,
          status: dbResponse.status.toDayStatus(),
          bookingId: dbResponse.bookingId,
          checkInTime: _parseTime(dbResponse.checkInTime),
          checkOutTime: _parseTime(dbResponse.checkOutTime),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load calendar data: $e');
    }
  }

  /// Check if dates have booking conflict
  Future<bool> checkBookingConflict({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? excludeBookingId,
  }) async {
    try {
      final response = await _client.rpc(
        'check_booking_conflict',
        params: {
          'p_unit_id': unitId,
          'p_check_in': DateFormat('yyyy-MM-dd').format(checkIn),
          'p_check_out': DateFormat('yyyy-MM-dd').format(checkOut),
          'p_exclude_booking_id': excludeBookingId,
        },
      );

      return response as bool;
    } catch (e) {
      throw Exception('Failed to check booking conflict: $e');
    }
  }

  /// Create booking atomically
  Future<Map<String, dynamic>> createBookingAtomic({
    required String unitId,
    required String guestId,
    required DateTime checkIn,
    required DateTime checkOut,
    required String checkInTime,
    required String checkOutTime,
    required int guestCount,
    required double totalPrice,
    String? notes,
  }) async {
    try {
      final response = await _client.rpc(
        'create_booking_atomic',
        params: {
          'p_unit_id': unitId,
          'p_guest_id': guestId,
          'p_check_in': DateFormat('yyyy-MM-dd').format(checkIn),
          'p_check_out': DateFormat('yyyy-MM-dd').format(checkOut),
          'p_check_in_time': checkInTime,
          'p_check_out_time': checkOutTime,
          'p_guest_count': guestCount,
          'p_total_price': totalPrice,
          'p_notes': notes,
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Get calendar settings for a unit
  Future<CalendarSettings?> getCalendarSettings(String unitId) async {
    try {
      final response = await _client
          .from('calendar_settings')
          .select()
          .eq('unit_id', unitId)
          .maybeSingle();

      if (response == null) return null;

      return CalendarSettings.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load calendar settings: $e');
    }
  }

  /// Get blocked dates for a unit
  Future<List<CalendarAvailability>> getBlockedDates(String unitId) async {
    try {
      final response = await _client
          .from('calendar_availability')
          .select()
          .eq('unit_id', unitId)
          .order('blocked_from');

      return (response as List)
          .map((item) => CalendarAvailability.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to load blocked dates: $e');
    }
  }

  /// Block dates (owner only)
  Future<void> blockDates({
    required String unitId,
    required String ownerId,
    required DateTime from,
    required DateTime to,
    required String reason,
    String? notes,
  }) async {
    try {
      await _client.from('calendar_availability').insert({
        'unit_id': unitId,
        'owner_id': ownerId,
        'blocked_from': DateFormat('yyyy-MM-dd').format(from),
        'blocked_to': DateFormat('yyyy-MM-dd').format(to),
        'reason': reason,
        'notes': notes,
      });
    } catch (e) {
      throw Exception('Failed to block dates: $e');
    }
  }

  /// Subscribe to real-time calendar changes
  RealtimeChannel subscribeToCalendarChanges({
    required String unitId,
    required void Function(List<CalendarDay>) onCalendarUpdate,
    required void Function(CalendarAvailability) onAvailabilityUpdate,
  }) {
    final channel = _client.channel('calendar:$unitId');

    // Subscribe to bookings changes
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'bookings',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'unit_id',
        value: unitId,
      ),
      callback: (payload) async {
        // Reload calendar data when bookings change
        final now = DateTime.now();
        final calendarData = await getCalendarData(
          unitId: unitId,
          month: now,
        );
        onCalendarUpdate(calendarData);
      },
    );

    // Subscribe to availability changes
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'calendar_availability',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'unit_id',
        value: unitId,
      ),
      callback: (payload) async {
        if (payload.newRecord != null) {
          final availability = CalendarAvailability.fromJson(payload.newRecord!);
          onAvailabilityUpdate(availability);
        }

        // Reload calendar data
        final now = DateTime.now();
        final calendarData = await getCalendarData(
          unitId: unitId,
          month: now,
        );
        onCalendarUpdate(calendarData);
      },
    );

    channel.subscribe();
    return channel;
  }

  /// Helper to parse time string to DateTime
  DateTime? _parseTime(String? timeString) {
    if (timeString == null) return null;

    try {
      // Parse time like "15:00:00" and combine with today's date
      final parts = timeString.split(':');
      final now = DateTime.now();
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
        parts.length > 2 ? int.parse(parts[2]) : 0,
      );
    } catch (e) {
      return null;
    }
  }
}
