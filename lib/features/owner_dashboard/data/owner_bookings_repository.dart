import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/property_model.dart';
import '../../property/domain/models/property_unit.dart';
import '../../booking/domain/models/booking_status.dart';

part 'owner_bookings_repository.g.dart';

/// Owner bookings model with extended property/unit info
class OwnerBooking {
  final BookingModel booking;
  final PropertyModel property;
  final PropertyUnit unit;
  final String guestName;
  final String guestEmail;
  final String? guestPhone;

  const OwnerBooking({
    required this.booking,
    required this.property,
    required this.unit,
    required this.guestName,
    required this.guestEmail,
    this.guestPhone,
  });
}

/// Owner bookings repository for managing bookings
class OwnerBookingsRepository {
  final SupabaseClient _supabase;

  OwnerBookingsRepository(this._supabase);

  /// Get all bookings for owner's properties
  Future<List<OwnerBooking>> getOwnerBookings({
    String? ownerId,
    String? propertyId,
    String? unitId,
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = ownerId ?? _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Start with base query - JOIN bookings with units, properties, and users (guests)
      dynamic query = _supabase
          .from('bookings')
          .select('''
            *,
            units!inner(
              *,
              properties!inner(
                *
              )
            ),
            users:guest_id(
              id,
              first_name,
              last_name,
              email,
              phone
            )
          ''');

      // Filter by owner (through properties)
      query = query.eq('units.properties.owner_id', userId);

      // Filter by property if specified
      if (propertyId != null) {
        query = query.eq('units.property_id', propertyId);
      }

      // Filter by unit if specified
      if (unitId != null) {
        query = query.eq('unit_id', unitId);
      }

      // Filter by status if specified
      if (status != null) {
        query = query.eq('status', status.value);
      }

      // Filter by date range if specified
      if (startDate != null) {
        query = query.gte('check_in', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('check_out', endDate.toIso8601String());
      }

      // Order by check-in date descending (most recent first)
      query = query.order('check_in', ascending: false);

      final response = await query;

      // Map to OwnerBooking models
      return (response as List).map((json) {
        final bookingData = Map<String, dynamic>.from(json);
        final unitData = bookingData['units'] as Map<String, dynamic>;
        final propertyData = unitData['properties'] as Map<String, dynamic>;
        final userData = bookingData['users'] as Map<String, dynamic>?;

        // Remove nested objects before parsing BookingModel
        bookingData.remove('units');
        bookingData.remove('users');

        return OwnerBooking(
          booking: BookingModel.fromJson(bookingData),
          property: PropertyModel.fromJson(propertyData),
          unit: PropertyUnit.fromJson(unitData),
          guestName: userData != null
              ? '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim()
              : 'Unknown Guest',
          guestEmail: userData?['email'] as String? ?? '',
          guestPhone: userData?['phone'] as String?,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch owner bookings: $e');
    }
  }

  /// Get bookings for calendar view (grouped by unit)
  Future<Map<String, List<BookingModel>>> getCalendarBookings({
    required String ownerId,
    String? propertyId,
    String? unitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      dynamic query = _supabase
          .from('bookings')
          .select('''
            *,
            units!inner(
              id,
              name,
              properties!inner(
                id,
                owner_id
              )
            )
          ''');

      // Filter by owner
      query = query.eq('units.properties.owner_id', ownerId);

      // Filter by property if specified
      if (propertyId != null) {
        query = query.eq('units.property_id', propertyId);
      }

      // Filter by unit if specified
      if (unitId != null) {
        query = query.eq('unit_id', unitId);
      }

      // Filter by date range (bookings that overlap with the range)
      query = query.or(
        'check_in.lte.${endDate.toIso8601String()},'
        'check_out.gte.${startDate.toIso8601String()}',
      );

      // Order by check-in date
      query = query.order('check_in', ascending: true);

      final response = await query;

      // Group bookings by unit_id
      final Map<String, List<BookingModel>> bookingsByUnit = {};

      for (final json in response as List) {
        final bookingData = Map<String, dynamic>.from(json);
        final unitId = bookingData['unit_id'] as String;

        // Remove nested objects
        bookingData.remove('units');

        final booking = BookingModel.fromJson(bookingData);

        if (!bookingsByUnit.containsKey(unitId)) {
          bookingsByUnit[unitId] = [];
        }
        bookingsByUnit[unitId]!.add(booking);
      }

      return bookingsByUnit;
    } catch (e) {
      throw Exception('Failed to fetch calendar bookings: $e');
    }
  }

  /// Confirm pending booking
  Future<void> confirmBooking(String bookingId) async {
    try {
      await _supabase.from('bookings').update({
        'status': BookingStatus.confirmed.value,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to confirm booking: $e');
    }
  }

  /// Cancel booking with reason
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await _supabase.from('bookings').update({
        'status': BookingStatus.cancelled.value,
        'cancellation_reason': reason,
        'cancelled_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Mark booking as completed
  Future<void> completeBooking(String bookingId) async {
    try {
      await _supabase.from('bookings').update({
        'status': BookingStatus.completed.value,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to complete booking: $e');
    }
  }

  /// Block dates for a unit (create blocked booking)
  Future<void> blockDates({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? reason,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('bookings').insert({
        'unit_id': unitId,
        'guest_id': userId, // Owner blocks their own dates
        'check_in': checkIn.toIso8601String(),
        'check_out': checkOut.toIso8601String(),
        'status': BookingStatus.blocked.value,
        'total_price': 0.0,
        'paid_amount': 0.0,
        'guest_count': 0,
        'notes': reason ?? 'Blocked by owner',
      });
    } catch (e) {
      throw Exception('Failed to block dates: $e');
    }
  }

  /// Unblock dates (delete blocked booking)
  Future<void> unblockDates(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .delete()
          .eq('id', bookingId)
          .eq('status', BookingStatus.blocked.value);
    } catch (e) {
      throw Exception('Failed to unblock dates: $e');
    }
  }
}

/// Provider for owner bookings repository
@riverpod
OwnerBookingsRepository ownerBookingsRepository(Ref ref) {
  return OwnerBookingsRepository(Supabase.instance.client);
}
