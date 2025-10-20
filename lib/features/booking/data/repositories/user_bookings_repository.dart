import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_booking.dart';
import '../../domain/models/booking_status.dart';

part 'user_bookings_repository.g.dart';

@riverpod
UserBookingsRepository userBookingsRepository(Ref ref) {
  return UserBookingsRepository(Supabase.instance.client);
}

class UserBookingsRepository {
  final SupabaseClient _supabase;

  UserBookingsRepository(this._supabase);

  Future<List<UserBooking>> getUserBookings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('bookings')
          .select('''
            id,
            unit_id,
            check_in,
            check_out,
            guest_count,
            total_price,
            status,
            created_at,
            cancellation_reason,
            cancelled_at,
            units!inner(
              id,
              name,
              property_id,
              properties!inner(
                id,
                name,
                location,
                images
              )
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((booking) {
        final unit = booking['units'] as Map<String, dynamic>;
        final property = unit['properties'] as Map<String, dynamic>;
        final images = property['images'] as List?;
        final firstImage = images?.isNotEmpty == true ? images!.first : '';

        return UserBooking(
          id: booking['id'] as String,
          propertyId: property['id'] as String,
          propertyName: property['name'] as String,
          propertyImage: firstImage as String,
          propertyLocation: property['location'] as String,
          checkInDate: DateTime.parse(booking['check_in'] as String),
          checkOutDate: DateTime.parse(booking['check_out'] as String),
          guests: booking['guest_count'] as int,
          totalPrice: (booking['total_price'] as num).toDouble(),
          status: BookingStatus.fromString(booking['status'] as String),
          bookingDate: DateTime.parse(booking['created_at'] as String),
          cancellationReason: booking['cancellation_reason'] as String?,
          cancellationDate: booking['cancelled_at'] != null
              ? DateTime.parse(booking['cancelled_at'] as String)
              : null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load bookings: $e');
    }
  }

  Future<UserBooking> getBookingById(String bookingId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            id,
            unit_id,
            check_in,
            check_out,
            guest_count,
            total_price,
            status,
            created_at,
            cancellation_reason,
            cancelled_at,
            units!inner(
              id,
              name,
              property_id,
              properties!inner(
                id,
                name,
                location,
                images
              )
            )
          ''')
          .eq('id', bookingId)
          .single();

      final unit = response['units'] as Map<String, dynamic>;
      final property = unit['properties'] as Map<String, dynamic>;
      final images = property['images'] as List?;
      final firstImage = images?.isNotEmpty == true ? images!.first : '';

      return UserBooking(
        id: response['id'] as String,
        propertyId: property['id'] as String,
        propertyName: property['name'] as String,
        propertyImage: firstImage as String,
        propertyLocation: property['location'] as String,
        checkInDate: DateTime.parse(response['check_in'] as String),
        checkOutDate: DateTime.parse(response['check_out'] as String),
        guests: response['guest_count'] as int,
        totalPrice: (response['total_price'] as num).toDouble(),
        status: BookingStatus.fromString(response['status'] as String),
        bookingDate: DateTime.parse(response['created_at'] as String),
        cancellationReason: response['cancellation_reason'] as String?,
        cancellationDate: response['cancelled_at'] != null
            ? DateTime.parse(response['cancelled_at'] as String)
            : null,
      );
    } catch (e) {
      throw Exception('Failed to load booking: $e');
    }
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await _supabase.from('bookings').update({
        'status': BookingStatus.cancelled.value,
        'cancellation_reason': reason,
        'cancellation_date': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      await _supabase.from('bookings').update({
        'status': status.value,
      }).eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }
}
