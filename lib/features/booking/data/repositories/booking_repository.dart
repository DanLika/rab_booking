import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/booking.dart';

/// Repository za Booking CRUD operacije
class BookingRepository {
  final SupabaseClient _supabase;

  BookingRepository(this._supabase);

  /// Kreira novu rezervaciju
  Future<Booking> createBooking(Booking booking) async {
    try {
      final response = await _supabase
          .from('bookings')
          .insert({
            'unit_id': booking.unitId,
            'user_id': booking.userId,
            'guest_name': booking.guestName,
            'guest_email': booking.guestEmail,
            'guest_phone': booking.guestPhone,
            'check_in': booking.checkIn.toIso8601String(),
            'check_out': booking.checkOut.toIso8601String(),
            'status': booking.status,
            'total_price': booking.totalPrice,
            'paid_amount': booking.paidAmount ?? 0.0,
            'guest_count': booking.guestCount,
            'notes': booking.notes,
            'payment_intent_id': booking.paymentIntentId,
            'cancellation_reason': booking.cancellationReason,
            'cancelled_at': booking.cancelledAt?.toIso8601String(),
            'payment_status': booking.paymentStatus,
            'advance_amount': booking.advanceAmount,
            'source': booking.source,
          })
          .select()
          .single();

      return Booking.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Dohvata rezervaciju po ID-u
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .single();

      return Booking.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Dohvata sve rezervacije za određenu jedinicu
  Future<List<Booking>> getBookingsByUnit(String unitId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('unit_id', unitId)
          .order('check_in', ascending: false);

      return (response as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }

  /// Dohvata rezervacije za vlasnika (sve njegove jedinice)
  Future<List<Booking>> getBookingsByOwner(String ownerId) async {
    try {
      // Join sa units i properties da dohvatimo samo rezervacije vlasnika
      final response = await _supabase
          .from('bookings')
          .select('''
            *,
            units!inner(
              property_id,
              properties!inner(owner_id)
            )
          ''')
          .eq('units.properties.owner_id', ownerId)
          .order('check_in', ascending: false);

      return (response as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch owner bookings: $e');
    }
  }

  /// Ažurira status rezervacije
  Future<Booking> updateBookingStatus(
    String bookingId,
    String status, {
    String? cancellationReason,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == 'cancelled') {
        updates['cancelled_at'] = DateTime.now().toIso8601String();
        if (cancellationReason != null) {
          updates['cancellation_reason'] = cancellationReason;
        }
      }

      final response = await _supabase
          .from('bookings')
          .update(updates)
          .eq('id', bookingId)
          .select()
          .single();

      return Booking.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  /// Ažurira payment status
  Future<Booking> updatePaymentStatus(
    String bookingId,
    String paymentStatus, {
    double? paidAmount,
    String? paymentIntentId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'payment_status': paymentStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (paidAmount != null) {
        updates['paid_amount'] = paidAmount;
      }

      if (paymentIntentId != null) {
        updates['payment_intent_id'] = paymentIntentId;
      }

      final response = await _supabase
          .from('bookings')
          .update(updates)
          .eq('id', bookingId)
          .select()
          .single();

      return Booking.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  /// Stream za praćenje rezervacija određene jedinice
  Stream<List<Booking>> watchBookingsByUnit(String unitId) {
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('unit_id', unitId)
        .order('check_in', ascending: false)
        .map((data) =>
            data.map((json) => Booking.fromJson(json)).toList());
  }

  /// Stream za praćenje pojedinačne rezervacije
  Stream<Booking?> watchBooking(String bookingId) {
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('id', bookingId)
        .map((data) =>
            data.isNotEmpty ? Booking.fromJson(data.first) : null);
  }

  /// Briše rezervaciju (koristiti samo za testing ili admin)
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _supabase.from('bookings').delete().eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to delete booking: $e');
    }
  }

  /// Provjera dostupnosti za odabrane datume
  /// Vraća true ako su datumi dostupni, false ako su zauzeti
  Future<bool> checkAvailability(
    String unitId,
    DateTime checkIn,
    DateTime checkOut,
  ) async {
    try {
      // Provjeravamo da li postoje preklapajuće rezervacije
      final response = await _supabase
          .from('bookings')
          .select('id')
          .eq('unit_id', unitId)
          .in_('status', ['confirmed', 'pending'])
          .or('check_in.gte.${checkIn.toIso8601String()},check_in.lt.${checkOut.toIso8601String()}')
          .or('check_out.gt.${checkIn.toIso8601String()},check_out.lte.${checkOut.toIso8601String()}');

      // Ako nema rezultata, datumi su dostupni
      return (response as List).isEmpty;
    } catch (e) {
      throw Exception('Failed to check availability: $e');
    }
  }
}
