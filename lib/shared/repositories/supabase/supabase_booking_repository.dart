import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/booking_model.dart';
import '../booking_repository.dart';
import '../../../features/booking/domain/models/booking_status.dart';
import '../../../core/exceptions/app_exceptions.dart';

/// Supabase implementation of BookingRepository
class SupabaseBookingRepository implements BookingRepository {
  SupabaseBookingRepository(this._client);

  final SupabaseClient _client;

  /// Table name
  static const String _tableName = 'bookings';

  @override
  Future<BookingModel> createBooking(BookingModel booking) async {
    try {
      // Validate booking dates
      if (booking.checkOut.isBefore(booking.checkIn)) {
        throw BookingException.invalidDateRange();
      }

      if (booking.checkIn.isBefore(DateTime.now())) {
        throw BookingException.pastDate();
      }

      // Check if dates are available
      final isAvailable = await areDatesAvailable(
        unitId: booking.unitId,
        checkIn: booking.checkIn,
        checkOut: booking.checkOut,
      );

      if (!isAvailable) {
        throw BookingException.datesOverlap();
      }

      final data = booking.toJson();
      data.remove('id'); // Let database generate ID

      final response = await _client
          .from(_tableName)
          .insert(data)
          .select()
          .single();

      return BookingModel.fromJson(response);
    } catch (e) {
      if (e is BookingException) rethrow;
      throw e.toAppException();
    }
  }

  @override
  Future<BookingModel?> fetchBookingById(String id) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return BookingModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<List<BookingModel>> fetchUserBookings(String userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<List<BookingModel>> fetchUnitBookings(String unitId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('unit_id', unitId)
          .order('check_in', ascending: true);

      return (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<List<BookingModel>> fetchPropertyBookings(String propertyId) async {
    try {
      // Note: This requires a join with units table
      // For now, we'll use a simpler approach with RPC or multiple queries
      final response = await _client
          .rpc('get_property_bookings', params: {'property_id_param': propertyId});

      return (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback: return empty list if RPC function doesn't exist yet
      // In production, implement the RPC function in Supabase
      return [];
    }
  }

  @override
  Future<BookingModel> updateBooking(BookingModel booking) async {
    try {
      final data = booking.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from(_tableName)
          .update(data)
          .eq('id', booking.id)
          .select()
          .single();

      return BookingModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<BookingModel> updateBookingStatus(String id, BookingStatus status) async {
    try {
      final response = await _client
          .from(_tableName)
          .update({
            'status': status.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return BookingModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<BookingModel> cancelBooking(String id, String reason) async {
    try {
      final booking = await fetchBookingById(id);
      if (booking == null) {
        throw NotFoundException.resource('Booking', id);
      }

      if (!booking.canBeCancelled) {
        throw BookingException.cannotCancel('Booking cannot be cancelled');
      }

      final response = await _client
          .from(_tableName)
          .update({
            'status': BookingStatus.cancelled.value,
            'cancellation_reason': reason,
            'cancelled_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return BookingModel.fromJson(response);
    } catch (e) {
      if (e is AppException) rethrow;
      throw e.toAppException();
    }
  }

  @override
  Future<void> deleteBooking(String id) async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<bool> areDatesAvailable({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? excludeBookingId,
  }) async {
    try {
      var query = _client
          .from(_tableName)
          .select('id')
          .eq('unit_id', unitId)
          .inFilter('status', ['confirmed', 'pending'])
          .lt('check_in', checkOut.toIso8601String())
          .gt('check_out', checkIn.toIso8601String());

      if (excludeBookingId != null) {
        query = query.neq('id', excludeBookingId);
      }

      final response = await query;

      return (response as List).isEmpty;
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<List<BookingModel>> getOverlappingBookings({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('unit_id', unitId)
          .inFilter('status', ['confirmed', 'pending'])
          .lt('check_in', checkOut.toIso8601String())
          .gt('check_out', checkIn.toIso8601String());

      return (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<List<BookingModel>> getUpcomingBookings(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .inFilter('status', ['confirmed', 'pending'])
          .gte('check_in', now)
          .order('check_in', ascending: true);

      return (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<List<BookingModel>> getPastBookings(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .lt('check_out', now)
          .order('check_out', ascending: false);

      return (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<List<BookingModel>> getCurrentBookings(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .lte('check_in', now)
          .gte('check_out', now);

      return (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<List<BookingModel>> getBookingsByStatus({
    required String userId,
    required BookingStatus status,
  }) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('status', status.value)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<List<BookingModel>> getOwnerBookings(String ownerId) async {
    try {
      // Note: This requires a complex join query
      // For now, use RPC function or implement in future
      final response = await _client
          .rpc('get_owner_bookings', params: {'owner_id_param': ownerId});

      return (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback: return empty list if RPC function doesn't exist yet
      return [];
    }
  }

  @override
  Future<BookingModel> updateBookingPayment({
    required String bookingId,
    required double paidAmount,
    String? paymentIntentId,
  }) async {
    try {
      final updates = {
        'paid_amount': paidAmount,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (paymentIntentId != null) {
        updates['payment_intent_id'] = paymentIntentId;
      }

      final response = await _client
          .from(_tableName)
          .update(updates)
          .eq('id', bookingId)
          .select()
          .single();

      return BookingModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<BookingModel> completeBookingPayment(String bookingId) async {
    try {
      final booking = await fetchBookingById(bookingId);
      if (booking == null) {
        throw NotFoundException.resource('Booking', bookingId);
      }

      final response = await _client
          .from(_tableName)
          .update({
            'paid_amount': booking.totalPrice,
            'status': BookingStatus.confirmed.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId)
          .select()
          .single();

      return BookingModel.fromJson(response);
    } catch (e) {
      if (e is AppException) rethrow;
      throw e.toAppException();
    }
  }

  @override
  Future<List<BookingModel>> getBookingsInRange({
    String? userId,
    String? unitId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from(_tableName).select();

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (unitId != null) {
        query = query.eq('unit_id', unitId);
      }

      if (startDate != null) {
        query = query.gte('check_in', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('check_out', endDate.toIso8601String());
      }

      final response = await query.order('check_in', ascending: true);

      return (response as List)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw e.toAppException();
    }
  }
}
