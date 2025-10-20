import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/property_model.dart';
import '../../property/domain/models/property_unit.dart';

part 'owner_properties_repository.g.dart';

/// Owner properties repository for CRUD operations
class OwnerPropertiesRepository {
  final SupabaseClient _supabase;

  OwnerPropertiesRepository(this._supabase);

  /// Get all properties for current owner with units count
  Future<List<PropertyModel>> getOwnerProperties(String ownerId) async {
    try {
      final response = await _supabase
          .from('properties')
          .select('*, units:units(count)')
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) {
            final propertyJson = Map<String, dynamic>.from(json);

            // Extract units count from aggregated data
            final unitsData = propertyJson['units'];
            int unitsCount = 0;

            if (unitsData is List && unitsData.isNotEmpty) {
              final firstUnit = unitsData[0];
              if (firstUnit is Map && firstUnit.containsKey('count')) {
                unitsCount = firstUnit['count'] as int? ?? 0;
              }
            }

            // Add units_count to property data
            propertyJson['units_count'] = unitsCount;

            // Remove units aggregate to avoid confusion
            propertyJson.remove('units');

            return PropertyModel.fromJson(propertyJson);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch properties: $e');
    }
  }

  /// Create new property
  Future<PropertyModel> createProperty({
    required String ownerId,
    required String name,
    required String description,
    required String propertyType,
    required String location,
    String? address,
    double? latitude,
    double? longitude,
    required List<String> amenities,
    List<String>? images,
    String? coverImage,
    bool isActive = false,
  }) async {
    try {
      final response = await _supabase.from('properties').insert({
        'owner_id': ownerId,
        'name': name,
        'description': description,
        'property_type': propertyType,
        'location': location,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'amenities': amenities,
        'images': images ?? [],
        'cover_image': coverImage,
        'is_active': isActive,
        'rating': 0.0,
        'review_count': 0,
      }).select().single();

      return PropertyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create property: $e');
    }
  }

  /// Update property
  Future<PropertyModel> updateProperty({
    required String propertyId,
    String? name,
    String? description,
    String? propertyType,
    String? location,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? amenities,
    List<String>? images,
    String? coverImage,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (propertyType != null) updates['property_type'] = propertyType;
      if (location != null) updates['location'] = location;
      if (address != null) updates['address'] = address;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (amenities != null) updates['amenities'] = amenities;
      if (images != null) updates['images'] = images;
      if (coverImage != null) updates['cover_image'] = coverImage;
      if (isActive != null) updates['is_active'] = isActive;

      if (updates.isNotEmpty) {
        updates['updated_at'] = DateTime.now().toIso8601String();

        final response = await _supabase
            .from('properties')
            .update(updates)
            .eq('id', propertyId)
            .select()
            .single();

        return PropertyModel.fromJson(response);
      }

      throw Exception('No updates provided');
    } catch (e) {
      throw Exception('Failed to update property: $e');
    }
  }

  /// Delete property
  Future<void> deleteProperty(String propertyId) async {
    try {
      // Check if property has units
      final unitsResponse = await _supabase
          .from('units')
          .select('id')
          .eq('property_id', propertyId);

      if ((unitsResponse as List).isNotEmpty) {
        throw Exception(
          'Cannot delete property with existing units. Please delete all units first.',
        );
      }

      // Check if property has bookings
      final bookingsResponse = await _supabase
          .from('bookings')
          .select('id')
          .inFilter('unit_id', [propertyId]);

      if ((bookingsResponse as List).isNotEmpty) {
        throw Exception(
          'Cannot delete property with existing bookings.',
        );
      }

      await _supabase.from('properties').delete().eq('id', propertyId);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload image to Supabase Storage
  Future<String> uploadPropertyImage({
    required String propertyId,
    required String filePath,
    required List<int> bytes,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
      final storagePath = 'property-images/$propertyId/$fileName';

      await _supabase.storage.from('property-images').uploadBinary(
            storagePath,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      final publicUrl = _supabase.storage
          .from('property-images')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete image from Supabase Storage
  Future<void> deletePropertyImage(String imageUrl) async {
    try {
      // Extract storage path from public URL
      final uri = Uri.parse(imageUrl);
      final path = uri.path.split('/property-images/').last;

      await _supabase.storage.from('property-images').remove([path]);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Get units for property
  Future<List<PropertyUnit>> getPropertyUnits(String propertyId) async {
    try {
      final response = await _supabase
          .from('units')
          .select('*')
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PropertyUnit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch units: $e');
    }
  }

  /// Create unit
  Future<PropertyUnit> createUnit({
    required String propertyId,
    required String name,
    String? description,
    required double pricePerNight,
    required int maxGuests,
    required int bedrooms,
    required int bathrooms,
    required double area,
    List<String>? amenities,
    List<String>? images,
    String? coverImage,
    int quantity = 1,
    int minStayNights = 1,
  }) async {
    try {
      final response = await _supabase.from('units').insert({
        'property_id': propertyId,
        'name': name,
        'description': description,
        'base_price': pricePerNight,
        'max_guests': maxGuests,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'area': area,
        'amenities': amenities ?? [],
        'images': images ?? [],
        'cover_image': coverImage,
        'quantity': quantity,
        'min_stay_nights': minStayNights,
        'is_available': true,
      }).select().single();

      return PropertyUnit.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create unit: $e');
    }
  }

  /// Update unit
  Future<PropertyUnit> updateUnit({
    required String unitId,
    String? name,
    String? description,
    double? pricePerNight,
    int? maxGuests,
    int? bedrooms,
    int? bathrooms,
    double? area,
    List<String>? amenities,
    List<String>? images,
    String? coverImage,
    int? quantity,
    int? minStayNights,
    bool? isAvailable,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (pricePerNight != null) updates['base_price'] = pricePerNight;
      if (maxGuests != null) updates['max_guests'] = maxGuests;
      if (bedrooms != null) updates['bedrooms'] = bedrooms;
      if (bathrooms != null) updates['bathrooms'] = bathrooms;
      if (area != null) updates['area'] = area;
      if (amenities != null) updates['amenities'] = amenities;
      if (images != null) updates['images'] = images;
      if (coverImage != null) updates['cover_image'] = coverImage;
      if (quantity != null) updates['quantity'] = quantity;
      if (minStayNights != null) updates['min_stay_nights'] = minStayNights;
      if (isAvailable != null) updates['is_available'] = isAvailable;

      if (updates.isNotEmpty) {
        updates['updated_at'] = DateTime.now().toIso8601String();

        final response = await _supabase
            .from('units')
            .update(updates)
            .eq('id', unitId)
            .select()
            .single();

        return PropertyUnit.fromJson(response);
      }

      throw Exception('No updates provided');
    } catch (e) {
      throw Exception('Failed to update unit: $e');
    }
  }

  /// Delete unit
  Future<void> deleteUnit(String unitId) async {
    try {
      // Check if unit has active bookings
      final bookingsResponse = await _supabase
          .from('bookings')
          .select('id')
          .eq('unit_id', unitId)
          .inFilter('status', ['pending', 'confirmed']);

      if ((bookingsResponse as List).isNotEmpty) {
        throw Exception(
          'Cannot delete unit with active bookings.',
        );
      }

      await _supabase.from('units').delete().eq('id', unitId);
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for owner properties repository
@riverpod
OwnerPropertiesRepository ownerPropertiesRepository(
  Ref ref,
) {
  return OwnerPropertiesRepository(Supabase.instance.client);
}
