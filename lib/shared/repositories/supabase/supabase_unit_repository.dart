import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/unit_model.dart';
import '../unit_repository.dart';
import '../../../core/exceptions/app_exceptions.dart';

/// Supabase implementation of UnitRepository
class SupabaseUnitRepository implements UnitRepository {
  SupabaseUnitRepository(this._client);

  final SupabaseClient _client;

  /// Table name
  static const String _tableName = 'units';
  static const String _bookingsTable = 'bookings';

  @override
  Future<UnitModel?> fetchUnitById(String id) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return UnitModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<List<UnitModel>> fetchUnitsByProperty(String propertyId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('property_id', propertyId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => UnitModel.fromJson(json))
          .toList();
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<List<UnitModel>> fetchAvailableUnits({
    required String propertyId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      // Get all units for the property
      final units = await fetchUnitsByProperty(propertyId);

      // Filter out unavailable units
      final availableUnits = <UnitModel>[];

      for (final unit in units) {
        if (!unit.isAvailable) continue;

        // Check if unit has overlapping bookings
        final isAvailable = await isUnitAvailable(
          unitId: unit.id,
          checkIn: checkIn,
          checkOut: checkOut,
        );

        if (isAvailable) {
          availableUnits.add(unit);
        }
      }

      return availableUnits;
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<UnitModel> createUnit(UnitModel unit) async {
    try {
      final data = unit.toJson();
      data.remove('id'); // Let database generate ID

      final response = await _client
          .from(_tableName)
          .insert(data)
          .select()
          .single();

      return UnitModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<UnitModel> updateUnit(UnitModel unit) async {
    try {
      final data = unit.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from(_tableName)
          .update(data)
          .eq('id', unit.id)
          .select()
          .single();

      return UnitModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<void> deleteUnit(String id) async {
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
  Future<UnitModel> toggleUnitAvailability(String id, bool isAvailable) async {
    try {
      final response = await _client
          .from(_tableName)
          .update({
            'is_available': isAvailable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return UnitModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<UnitModel> updateUnitPrice(String id, double pricePerNight) async {
    try {
      final response = await _client
          .from(_tableName)
          .update({
            'base_price': pricePerNight,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return UnitModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<bool> isUnitAvailable({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      // Check for overlapping confirmed bookings
      final response = await _client
          .from(_bookingsTable)
          .select('id')
          .eq('unit_id', unitId)
          .inFilter('status', ['confirmed', 'pending'])
          .lt('check_in', checkOut.toIso8601String())
          .gt('check_out', checkIn.toIso8601String());

      return (response as List).isEmpty;
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<List<UnitModel>> fetchFilteredUnits({
    String? propertyId,
    double? maxPrice,
    int? minGuests,
    bool? availableOnly,
  }) async {
    try {
      var query = _client.from(_tableName).select();

      // Apply filters
      if (propertyId != null) {
        query = query.eq('property_id', propertyId);
      }
      if (maxPrice != null) {
        query = query.lte('base_price', maxPrice);
      }
      if (minGuests != null) {
        query = query.gte('max_guests', minGuests);
      }
      if (availableOnly == true) {
        query = query.eq('is_available', true);
      }

      // Order by price (lowest first)
      final response = await query.order('base_price', ascending: true);

      return (response as List)
          .map((json) => UnitModel.fromJson(json))
          .toList();
    } catch (e) {
      throw e.toAppException();
    }
  }
}
