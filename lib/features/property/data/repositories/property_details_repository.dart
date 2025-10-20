import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/property_model.dart';
import '../../domain/models/property_unit.dart';

part 'property_details_repository.g.dart';

/// Property details repository for fetching property and units
class PropertyDetailsRepository {
  final SupabaseClient _supabase;

  PropertyDetailsRepository(this._supabase);

  /// Get property by ID with full details
  Future<PropertyModel?> getPropertyById(String propertyId) async {
    try {
      final response = await _supabase
          .from('properties')
          .select('*')
          .eq('id', propertyId)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ Property not found: $propertyId');
        return null;
      }

      // Check is_active in memory instead of in query (in case column doesn't exist)
      final property = PropertyModel.fromJson(response);
      if (!property.isActive) {
        debugPrint('⚠️ Property is not active: $propertyId');
        return null;
      }

      return property;
    } catch (e) {
      debugPrint('❌ Error fetching property $propertyId: $e');
      rethrow; // Rethrow to see actual error
    }
  }

  /// Get all units for a property
  Future<List<PropertyUnit>> getUnitsForProperty(String propertyId) async {
    try {
      final response = await _supabase
          .from('units')
          .select('*')
          .eq('property_id', propertyId)
          .eq('is_available', true)
          .order('base_price', ascending: true);

      return (response as List)
          .map((json) => PropertyUnit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get single unit by ID
  Future<PropertyUnit?> getUnitById(String unitId) async {
    try {
      final response = await _supabase
          .from('units')
          .select('*')
          .eq('id', unitId)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ Unit not found: $unitId');
        return null;
      }

      final unit = PropertyUnit.fromJson(response);
      if (!unit.isAvailable) {
        debugPrint('⚠️ Unit is not available: $unitId');
        return null;
      }

      return unit;
    } catch (e) {
      debugPrint('❌ Error fetching unit $unitId: $e');
      rethrow;
    }
  }

  /// Check unit availability for date range
  Future<bool> checkUnitAvailability({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      final result = await _supabase.rpc(
        'is_unit_available',
        params: {
          'p_unit_id': unitId,
          'p_check_in': checkIn.toIso8601String().split('T')[0],
          'p_check_out': checkOut.toIso8601String().split('T')[0],
        },
      );

      return result as bool;
    } catch (e) {
      return false;
    }
  }

  /// Get blocked dates for a unit (for calendar display)
  Future<List<DateTime>> getBlockedDatesForUnit(String unitId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('check_in, check_out')
          .eq('unit_id', unitId)
          .inFilter('status', ['confirmed', 'pending']);

      final blockedDates = <DateTime>[];

      for (final booking in response as List) {
        final checkIn = DateTime.parse(booking['check_in'] as String);
        final checkOut = DateTime.parse(booking['check_out'] as String);

        // Add all dates between check-in and check-out
        for (var date = checkIn;
            date.isBefore(checkOut);
            date = date.add(const Duration(days: 1))) {
          blockedDates.add(date);
        }
      }

      return blockedDates;
    } catch (e) {
      return [];
    }
  }

  /// Calculate booking price
  Future<Map<String, dynamic>> calculateBookingPrice({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
  }) async {
    try {
      final result = await _supabase.rpc(
        'calculate_booking_price',
        params: {
          'p_unit_id': unitId,
          'p_check_in': checkIn.toIso8601String().split('T')[0],
          'p_check_out': checkOut.toIso8601String().split('T')[0],
          'p_guests': guests,
        },
      );

      return result as Map<String, dynamic>;
    } catch (e) {
      // Fallback calculation if RPC fails
      final nights = checkOut.difference(checkIn).inDays;
      final unit = await _supabase
          .from('units')
          .select('base_price')
          .eq('id', unitId)
          .single();

      final pricePerNight = unit['base_price'] as double;
      final subtotal = pricePerNight * nights;
      final serviceFee = subtotal * 0.10; // 10% service fee
      final cleaningFee = 30.0; // Fixed cleaning fee
      final total = subtotal + serviceFee + cleaningFee;

      return {
        'nights': nights,
        'base_price': pricePerNight,
        'subtotal': subtotal,
        'service_fee': serviceFee,
        'cleaning_fee': cleaningFee,
        'total': total,
      };
    }
  }
}

/// Provider for property details repository
@riverpod
PropertyDetailsRepository propertyDetailsRepository(
    Ref ref) {
  return PropertyDetailsRepository(Supabase.instance.client);
}
