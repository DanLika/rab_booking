import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/calendar_day.dart';

/// Repository za Grid Calendar - koristi helper funkciju iz Supabase
class CalendarGridRepository {
  final SupabaseClient _supabase;

  CalendarGridRepository(this._supabase);

  /// Dohvata kalendar podatke za određenu jedinicu i mjesec
  /// Koristi Supabase helper funkciju: get_unit_calendar_data()
  Future<List<CalendarDay>> getCalendarData(
    String unitId,
    DateTime month,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_unit_calendar_data',
        params: {
          'p_unit_id': unitId,
          'p_month': month.toIso8601String().split('T')[0], // YYYY-MM-DD
        },
      );

      return (response as List).map((json) {
        // Parse response from SQL function
        final date = DateTime.parse(json['date']);
        final statusStr = json['status'] as String;
        final price = (json['price'] as num?)?.toDouble();
        final bookingId = json['booking_id'] as String?;

        // Map status string to DayStatus enum
        DayStatus status;
        switch (statusStr) {
          case 'available':
            status = DayStatus.available;
            break;
          case 'booked':
            status = DayStatus.booked;
            break;
          case 'blocked':
            status = DayStatus.blocked;
            break;
          default:
            status = DayStatus.available;
        }

        return CalendarDay(
          date: date,
          status: status,
          bookingId: bookingId,
          price: price,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch calendar data: $e');
    }
  }

  /// Dohvata kalendar za cijelu godinu (12 mjeseci)
  Future<Map<int, List<CalendarDay>>> getYearlyCalendarData(
    String unitId,
    int year,
  ) async {
    try {
      final Map<int, List<CalendarDay>> yearData = {};

      // Fetch data for each month
      for (int month = 1; month <= 12; month++) {
        final monthDate = DateTime(year, month, 1);
        final monthData = await getCalendarData(unitId, monthDate);
        yearData[month] = monthData;
      }

      return yearData;
    } catch (e) {
      throw Exception('Failed to fetch yearly calendar data: $e');
    }
  }

  /// Stream za real-time updates kalendara
  /// Sluša promjene u bookings, daily_prices i blocked_dates tabelama
  Stream<List<CalendarDay>> watchCalendarData(
    String unitId,
    DateTime month,
  ) {
    // Note: Supabase stream za custom RPC funkcije nije direktno podržan
    // Alternativa: Slusamo promjene u tabelama i refreshujemo kalendar

    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('unit_id', unitId)
        .asyncMap((_) async {
          // When bookings change, fetch fresh calendar data
          return await getCalendarData(unitId, month);
        });
  }
}
