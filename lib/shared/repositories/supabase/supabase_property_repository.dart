import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/property_model.dart';
import '../property_repository.dart';
import '../../../core/exceptions/app_exceptions.dart';

/// Supabase implementation of PropertyRepository
class SupabasePropertyRepository implements PropertyRepository {
  SupabasePropertyRepository(this._client);

  final SupabaseClient _client;

  /// Table name
  static const String _tableName = 'properties';

  @override
  Future<List<PropertyModel>> fetchProperties([PropertyFilters? filters]) async {
    try {
      var query = _client.from(_tableName).select();

      // Apply filters
      if (filters != null) {
        if (filters.location != null) {
          query = query.ilike('location', '%${filters.location}%');
        }
        if (filters.minRating != null) {
          query = query.gte('rating', filters.minRating!);
        }
        if (filters.ownerId != null) {
          query = query.eq('owner_id', filters.ownerId!);
        }
      }

      // Order by rating (highest first) and created date
      final response = await query
          .order('rating', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PropertyModel.fromJson(json))
          .toList();
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<PropertyModel?> fetchPropertyById(String id) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return PropertyModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<List<PropertyModel>> fetchPropertiesByOwner(String ownerId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PropertyModel.fromJson(json))
          .toList();
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<PropertyModel> createProperty(PropertyModel property) async {
    try {
      final data = property.toJson();
      data.remove('id'); // Let database generate ID

      final response = await _client
          .from(_tableName)
          .insert(data)
          .select()
          .single();

      return PropertyModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<PropertyModel> updateProperty(PropertyModel property) async {
    try {
      final data = property.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from(_tableName)
          .update(data)
          .eq('id', property.id)
          .select()
          .single();

      return PropertyModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<void> deleteProperty(String id) async {
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
  Future<List<PropertyModel>> searchProperties(String query) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .or('name.ilike.%$query%,location.ilike.%$query%,description.ilike.%$query%')
          .eq('is_active', true)
          .order('rating', ascending: false);

      return (response as List)
          .map((json) => PropertyModel.fromJson(json))
          .toList();
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<List<PropertyModel>> getFeaturedProperties({int limit = 10}) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('is_active', true)
          .gte('rating', 4.0)
          .order('rating', ascending: false)
          .order('review_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => PropertyModel.fromJson(json))
          .toList();
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<List<PropertyModel>> getNearbyProperties({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    try {
      // Note: This is a simplified version. For production, use PostGIS extension
      // with proper distance calculations using ST_Distance_Sphere or ST_DWithin
      final response = await _client
          .from(_tableName)
          .select()
          .eq('is_active', true)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null);

      final properties = (response as List)
          .map((json) => PropertyModel.fromJson(json))
          .toList();

      // Filter by approximate distance (simplified calculation)
      // For production, this should be done in the database query
      return properties.where((property) {
        if (property.latitude == null || property.longitude == null) {
          return false;
        }
        final distance = _calculateDistance(
          latitude,
          longitude,
          property.latitude!,
          property.longitude!,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<PropertyModel> togglePropertyStatus(String id, bool isActive) async {
    try {
      final response = await _client
          .from(_tableName)
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return PropertyModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<PropertyModel> updatePropertyRating(
    String id,
    double rating,
    int reviewCount,
  ) async {
    try {
      final response = await _client
          .from(_tableName)
          .update({
            'rating': rating,
            'review_count': reviewCount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return PropertyModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  /// Calculate distance between two coordinates (Haversine formula)
  /// Returns distance in kilometers
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.cos() * lat2.cos() * (dLon / 2).sin() * (dLon / 2).sin();

    final c = 2 * (a.sqrt()).atan2((1 - a).sqrt());

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }
}

/// Extension for trigonometric functions
extension _MathExtension on double {
  double sin() => math.sin(this);
  double cos() => math.cos(this);
  double sqrt() => math.sqrt(this);
  double atan2(double other) => math.atan2(this, other);
}
