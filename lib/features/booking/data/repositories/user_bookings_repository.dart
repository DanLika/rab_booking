import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rab_booking/features/booking/domain/models/user_booking.dart';
import 'package:rab_booking/features/booking/domain/models/booking_status.dart';

part 'user_bookings_repository.g.dart';

@riverpod
UserBookingsRepository userBookingsRepository(UserBookingsRepositoryRef ref) {
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
            property_id,
            check_in_date,
            check_out_date,
            guests,
            total_price,
            status,
            created_at,
            cancellation_reason,
            cancellation_date,
            properties!inner(
              id,
              title,
              location,
              images
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((booking) {
        final property = booking['properties'] as Map<String, dynamic>;
        final images = property['images'] as List?;
        final firstImage = images?.isNotEmpty == true ? images!.first : '';

        return UserBooking(
          id: booking['id'] as String,
          propertyId: booking['property_id'] as String,
          propertyName: property['title'] as String,
          propertyImage: firstImage as String,
          propertyLocation: property['location'] as String,
          checkInDate: DateTime.parse(booking['check_in_date'] as String),
          checkOutDate: DateTime.parse(booking['check_out_date'] as String),
          guests: booking['guests'] as int,
          totalPrice: (booking['total_price'] as num).toDouble(),
          status: BookingStatus.fromString(booking['status'] as String),
          bookingDate: DateTime.parse(booking['created_at'] as String),
          cancellationReason: booking['cancellation_reason'] as String?,
          cancellationDate: booking['cancellation_date'] != null
              ? DateTime.parse(booking['cancellation_date'] as String)
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
            property_id,
            check_in_date,
            check_out_date,
            guests,
            total_price,
            status,
            created_at,
            cancellation_reason,
            cancellation_date,
            properties!inner(
              id,
              title,
              location,
              images
            )
          ''')
          .eq('id', bookingId)
          .single();

      final property = response['properties'] as Map<String, dynamic>;
      final images = property['images'] as List?;
      final firstImage = images?.isNotEmpty == true ? images!.first : '';

      return UserBooking(
        id: response['id'] as String,
        propertyId: response['property_id'] as String,
        propertyName: property['title'] as String,
        propertyImage: firstImage as String,
        propertyLocation: property['location'] as String,
        checkInDate: DateTime.parse(response['check_in_date'] as String),
        checkOutDate: DateTime.parse(response['check_out_date'] as String),
        guests: response['guests'] as int,
        totalPrice: (response['total_price'] as num).toDouble(),
        status: BookingStatus.fromString(response['status'] as String),
        bookingDate: DateTime.parse(response['created_at'] as String),
        cancellationReason: response['cancellation_reason'] as String?,
        cancellationDate: response['cancellation_date'] != null
            ? DateTime.parse(response['cancellation_date'] as String)
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
