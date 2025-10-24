import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/unit.dart';

/// Repository za upravljanje smještajnim jedinicama (units)
class UnitsRepository {
  final SupabaseClient _supabase;

  UnitsRepository(this._supabase);

  /// Dohvata sve jedinice za određeni property
  Future<List<Unit>> getUnitsByProperty(String propertyId) async {
    try {
      final response = await _supabase
          .from('units')
          .select()
          .eq('property_id', propertyId)
          .order('name');

      return (response as List)
          .map((json) => Unit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch units: $e');
    }
  }

  /// Dohvata jednu jedinicu po ID-u
  Future<Unit?> getUnitById(String unitId) async {
    try {
      final response = await _supabase
          .from('units')
          .select()
          .eq('id', unitId)
          .maybeSingle();

      if (response == null) return null;

      return Unit.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch unit: $e');
    }
  }

  /// Kreira novu jedinicu
  Future<Unit> createUnit(Unit unit) async {
    try {
      final data = unit.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');

      final response = await _supabase
          .from('units')
          .insert(data)
          .select()
          .single();

      return Unit.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create unit: $e');
    }
  }

  /// Update-uje postojeću jedinicu
  Future<Unit> updateUnit(String unitId, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase
          .from('units')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', unitId)
          .select()
          .single();

      return Unit.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update unit: $e');
    }
  }

  /// Briše jedinicu
  Future<void> deleteUnit(String unitId) async {
    try {
      await _supabase.from('units').delete().eq('id', unitId);
    } catch (e) {
      throw Exception('Failed to delete unit: $e');
    }
  }

  /// Toggle isActive status
  Future<Unit> toggleUnitActive(String unitId, bool isActive) async {
    return updateUnit(unitId, {'is_active': isActive});
  }

  /// Dohvata sve aktivne jedinice (za public embed widget)
  Future<List<Unit>> getActiveUnits() async {
    try {
      final response = await _supabase
          .from('units')
          .select()
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => Unit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active units: $e');
    }
  }

  /// Stream za real-time updates jedinica
  Stream<List<Unit>> watchUnitsByProperty(String propertyId) {
    return _supabase
        .from('units')
        .stream(primaryKey: ['id'])
        .eq('property_id', propertyId)
        .order('name')
        .map((data) => data
            .map((json) => Unit.fromJson(json as Map<String, dynamic>))
            .toList());
  }
}
