import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../core/services/logging_service.dart';
import '../../../widget/data/repositories/firebase_widget_settings_repository.dart';

/// Firebase implementation of Owner Properties Repository
class FirebaseOwnerPropertiesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseWidgetSettingsRepository _widgetSettingsRepository;

  FirebaseOwnerPropertiesRepository(
    this._firestore,
    this._storage,
    this._widgetSettingsRepository,
  );

  /// Get all properties for current owner with units count
  Future<List<PropertyModel>> getOwnerProperties(String ownerId) async {
    try {
      // Get properties for owner
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .orderBy('created_at', descending: true)
          .get();

      // For each property, get units count
      final properties = <PropertyModel>[];
      for (final doc in propertiesSnapshot.docs) {
        final propertyData = {...doc.data(), 'id': doc.id};

        // Get units count for this property from subcollection
        final unitsSnapshot = await _firestore
            .collection('properties')
            .doc(doc.id)
            .collection('units')
            .get();

        propertyData['units_count'] = unitsSnapshot.docs.length;

        properties.add(PropertyModel.fromJson(propertyData));
      }

      return properties;
    } catch (e) {
      throw Exception('Failed to fetch properties: $e');
    }
  }

  /// Get property by ID
  Future<PropertyModel?> getPropertyById(String propertyId) async {
    try {
      final doc = await _firestore.collection('properties').doc(propertyId).get();

      if (!doc.exists) {
        return null;
      }

      final propertyData = {...doc.data()!, 'id': doc.id};

      // Get units count for this property from subcollection
      final unitsSnapshot = await _firestore
          .collection('properties')
          .doc(doc.id)
          .collection('units')
          .get();

      propertyData['units_count'] = unitsSnapshot.docs.length;

      return PropertyModel.fromJson(propertyData);
    } catch (e) {
      throw Exception('Failed to fetch property: $e');
    }
  }

  /// Get unit by ID (requires propertyId since units are in subcollection)
  Future<UnitModel?> getUnitById(String propertyId, String unitId) async {
    try {
      final doc = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .doc(unitId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return UnitModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to fetch unit: $e');
    }
  }

  /// Get unit by ID using collection group query (searches across all properties)
  /// This is useful when we only have the unitId and need to find which property it belongs to
  Future<UnitModel?> getUnitByIdAcrossProperties(String unitId) async {
    try {
      // NOTE: Cannot use FieldPath.documentId with collectionGroup without full path
      // Instead, get all units and filter in code
      final snapshot = await _firestore
          .collectionGroup('units')
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      // Find unit with matching ID
      for (final doc in snapshot.docs) {
        if (doc.id == unitId) {
          final data = doc.data();

          // Extract propertyId from document path
          // Path format: properties/{propertyId}/units/{unitId}
          final propertyId = doc.reference.parent.parent?.id;

          return UnitModel.fromJson({
            ...data,
            'id': doc.id,
            'property_id': propertyId,
          });
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch unit: $e');
    }
  }

  /// Create new property
  Future<PropertyModel> createProperty({
    required String ownerId,
    required String name,
    required String description,
    required String propertyType,
    required String location,
    String? slug,
    String? address,
    double? latitude,
    double? longitude,
    required List<String> amenities,
    List<String>? images,
    String? coverImage,
    bool isActive = false,
  }) async {
    try {
      final docRef = await _firestore.collection('properties').add({
        'owner_id': ownerId,
        'name': name,
        'slug': slug,
        'description': description,
        'property_type': propertyType,
        'location': location,
        'city': location, // For compatibility
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'amenities': amenities,
        'images': images ?? [],
        'cover_image': coverImage,
        'is_active': isActive,
        'rating': 0.0,
        'review_count': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      final doc = await docRef.get();
      return PropertyModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to create property: $e');
    }
  }

  /// Update property
  Future<PropertyModel> updateProperty({
    required String propertyId,
    String? name,
    String? slug,
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
      if (slug != null) updates['slug'] = slug;
      if (description != null) updates['description'] = description;
      if (propertyType != null) updates['property_type'] = propertyType;
      if (location != null) {
        updates['location'] = location;
        updates['city'] = location; // For compatibility
      }
      if (address != null) updates['address'] = address;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (amenities != null) updates['amenities'] = amenities;
      if (images != null) updates['images'] = images;
      if (coverImage != null) updates['cover_image'] = coverImage;
      if (isActive != null) updates['is_active'] = isActive;

      if (updates.isEmpty) {
        throw Exception('No updates provided');
      }

      updates['updated_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('properties')
          .doc(propertyId)
          .update(updates);

      final doc = await _firestore.collection('properties').doc(propertyId).get();
      return PropertyModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to update property: $e');
    }
  }

  /// Delete property
  Future<void> deleteProperty(String propertyId) async {
    try {
      print('[REPO] deleteProperty called for: $propertyId');

      // Check if property has units in NEW subcollection
      print('[REPO] Checking NEW subcollection units...');
      final unitsInSubcollection = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .limit(1)
          .get();

      print('[REPO] NEW subcollection check: ${unitsInSubcollection.docs.length} units found');
      if (unitsInSubcollection.docs.isNotEmpty) {
        throw Exception(
          'Cannot delete property with existing units. Please delete all units first.',
        );
      }

      // ALSO check OLD top-level units collection (for backwards compatibility)
      print('[REPO] Checking OLD top-level units collection...');
      final unitsInOldCollection = await _firestore
          .collection('units')
          .where('property_id', isEqualTo: propertyId)
          .limit(1)
          .get();

      print('[REPO] OLD collection check: ${unitsInOldCollection.docs.length} units found');
      if (unitsInOldCollection.docs.isNotEmpty) {
        throw Exception(
          'Cannot delete property with existing units in old location. Please delete all units first.',
        );
      }

      print('[REPO] No units found, proceeding with delete...');
      await _firestore.collection('properties').doc(propertyId).delete();
      print('[REPO] Property deleted from Firestore');
    } catch (e) {
      print('[REPO] Error in deleteProperty: $e');
      rethrow;
    }
  }

  /// Upload image to Firebase Storage
  Future<String> uploadPropertyImage({
    required String propertyId,
    required String filePath,
    required List<int> bytes,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
      final storagePath = 'property-images/$propertyId/$fileName';

      final ref = _storage.ref().child(storagePath);
      final uploadTask = await ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete image from Firebase Storage
  Future<void> deletePropertyImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Get units for property (from subcollection)
  Future<List<UnitModel>> getPropertyUnits(String propertyId) async {
    try {
      final snapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UnitModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch units: $e');
    }
  }

  /// Get ALL units for owner (across all properties)
  Future<List<UnitModel>> getAllOwnerUnits(String ownerId) async {
    try {
      // First get all properties for owner
      final properties = await getOwnerProperties(ownerId);

      // Then get units for each property
      final allUnits = <UnitModel>[];
      for (final property in properties) {
        final units = await getPropertyUnits(property.id);
        allUnits.addAll(units);
      }

      return allUnits;
    } catch (e) {
      throw Exception('Failed to fetch owner units: $e');
    }
  }

  /// Create unit (in property subcollection)
  Future<UnitModel> createUnit({
    required String propertyId,
    required String name,
    String? slug,
    String? description,
    required double basePrice,
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
      final docRef = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .add({
        'property_id': propertyId, // Keep for reference
        'name': name,
        'slug': slug,
        'description': description,
        'base_price': basePrice,
        'max_guests': maxGuests,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'area_sqm': area,
        'amenities': amenities ?? [],
        'images': images ?? [],
        'cover_image': coverImage,
        'quantity': quantity,
        'min_stay_nights': minStayNights,
        'is_available': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      final doc = await docRef.get();
      final unitId = doc.id;

      // Auto-create default widget settings for this unit
      try {
        await _widgetSettingsRepository.createDefaultSettings(
          propertyId: propertyId,
          unitId: unitId,
        );
        LoggingService.log('Widget settings auto-created for unit: $unitId', tag: 'OwnerPropertiesRepository');
      } catch (e) {
        // Log error but don't fail unit creation
        LoggingService.log('Warning: Failed to create widget settings for unit $unitId: $e', tag: 'OwnerPropertiesRepository');
      }

      return UnitModel.fromJson({...doc.data()!, 'id': unitId});
    } catch (e) {
      throw Exception('Failed to create unit: $e');
    }
  }

  /// Update unit (in property subcollection)
  Future<UnitModel> updateUnit({
    required String propertyId,
    required String unitId,
    String? name,
    String? slug,
    String? description,
    double? basePrice,
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
      if (slug != null) updates['slug'] = slug;
      if (description != null) updates['description'] = description;
      if (basePrice != null) updates['base_price'] = basePrice;
      if (maxGuests != null) updates['max_guests'] = maxGuests;
      if (bedrooms != null) updates['bedrooms'] = bedrooms;
      if (bathrooms != null) updates['bathrooms'] = bathrooms;
      if (area != null) updates['area_sqm'] = area;
      if (amenities != null) updates['amenities'] = amenities;
      if (images != null) updates['images'] = images;
      if (coverImage != null) updates['cover_image'] = coverImage;
      if (quantity != null) updates['quantity'] = quantity;
      if (minStayNights != null) updates['min_stay_nights'] = minStayNights;
      if (isAvailable != null) updates['is_available'] = isAvailable;

      if (updates.isEmpty) {
        throw Exception('No updates provided');
      }

      updates['updated_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .doc(unitId)
          .update(updates);

      final doc = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .doc(unitId)
          .get();
      return UnitModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to update unit: $e');
    }
  }

  /// Delete unit (from property subcollection)
  Future<void> deleteUnit(String propertyId, String unitId) async {
    try {
      // Check if unit has active bookings
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('unit_id', isEqualTo: unitId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .limit(1)
          .get();

      if (bookingsSnapshot.docs.isNotEmpty) {
        throw Exception('Cannot delete unit with active bookings.');
      }

      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .doc(unitId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}
