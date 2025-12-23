import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/utils/async_utils.dart';
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
  /// OPTIMIZED: Uses parallel queries instead of sequential N+1 pattern
  Future<List<PropertyModel>> getOwnerProperties(String ownerId) async {
    try {
      // Get properties for owner
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .orderBy('created_at', descending: true)
          .get();

      if (propertiesSnapshot.docs.isEmpty) {
        return [];
      }

      // PERFORMANCE FIX: Fetch all unit counts in parallel instead of sequential
      final unitCountFutures = propertiesSnapshot.docs.map((doc) async {
        final unitsSnapshot = await _firestore
            .collection('properties')
            .doc(doc.id)
            .collection('units')
            .count()
            .get();
        return MapEntry(doc.id, unitsSnapshot.count ?? 0);
      }).toList();

      final unitCounts = Map.fromEntries(
        await Future.wait(
          unitCountFutures,
        ).withListFetchTimeout('getOwnerProperties'),
      );

      // Build properties with cached unit counts
      final properties = propertiesSnapshot.docs.map((doc) {
        final propertyData = {...doc.data(), 'id': doc.id};
        propertyData['units_count'] = unitCounts[doc.id] ?? 0;
        return PropertyModel.fromJson(propertyData);
      }).toList();

      return properties;
    } catch (e) {
      throw PropertyException(
        'Failed to fetch properties',
        code: 'property/fetch-failed',
        originalError: e,
      );
    }
  }

  /// Get property by ID
  Future<PropertyModel?> getPropertyById(String propertyId) async {
    try {
      final doc = await _firestore
          .collection('properties')
          .doc(propertyId)
          .get();

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
      throw PropertyException(
        'Failed to fetch property',
        code: 'property/fetch-failed',
        originalError: e,
      );
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
      throw PropertyException(
        'Failed to fetch unit',
        code: 'property/unit-fetch-failed',
        originalError: e,
      );
    }
  }

  /// Get unit by ID using collection group query (searches across all properties)
  /// This is useful when we only have the unitId and need to find which property it belongs to
  Future<UnitModel?> getUnitByIdAcrossProperties(String unitId) async {
    try {
      // NOTE: Cannot use FieldPath.documentId with collectionGroup without full path
      // Instead, get all units and filter in code
      final snapshot = await _firestore.collectionGroup('units').get();

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
      throw PropertyException(
        'Failed to fetch unit',
        code: 'property/unit-fetch-failed',
        originalError: e,
      );
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
    String? subdomain,
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
        'subdomain': subdomain,
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
      throw PropertyException.creationFailed(e);
    }
  }

  /// Update property
  Future<PropertyModel> updateProperty({
    required String propertyId,
    String? name,
    String? slug,
    String? subdomain,
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
      if (subdomain != null) updates['subdomain'] = subdomain;
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
        throw PropertyException(
          'No updates provided',
          code: 'property/no-updates',
        );
      }

      updates['updated_at'] = FieldValue.serverTimestamp();

      await _firestore.collection('properties').doc(propertyId).update(updates);

      final doc = await _firestore
          .collection('properties')
          .doc(propertyId)
          .get();
      return PropertyModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw PropertyException.updateFailed(e);
    }
  }

  /// Delete property
  Future<void> deleteProperty(String propertyId) async {
    try {
      // Check if property has units in NEW subcollection
      final unitsInSubcollection = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .limit(1)
          .get();

      if (unitsInSubcollection.docs.isNotEmpty) {
        throw PropertyException(
          'Cannot delete property with existing units. Please delete all units first.',
          code: 'property/has-units',
        );
      }

      // ALSO check OLD top-level units collection (for backwards compatibility)
      final unitsInOldCollection = await _firestore
          .collection('units')
          .where('property_id', isEqualTo: propertyId)
          .limit(1)
          .get();

      if (unitsInOldCollection.docs.isNotEmpty) {
        throw PropertyException(
          'Cannot delete property with existing units in old location. Please delete all units first.',
          code: 'property/has-units-legacy',
        );
      }

      await _firestore.collection('properties').doc(propertyId).delete();
    } catch (e) {
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
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
      final storagePath = 'property-images/$propertyId/$fileName';

      final ref = _storage.ref().child(storagePath);
      final uploadTask = await ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw PropertyException(
        'Failed to upload image',
        code: 'property/image-upload-failed',
        originalError: e,
      );
    }
  }

  /// Delete image from Firebase Storage
  Future<void> deletePropertyImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw PropertyException(
        'Failed to delete image',
        code: 'property/image-delete-failed',
        originalError: e,
      );
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
      throw PropertyException(
        'Failed to fetch units',
        code: 'property/units-fetch-failed',
        originalError: e,
      );
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
      throw PropertyException(
        'Failed to fetch owner units',
        code: 'property/owner-units-fetch-failed',
        originalError: e,
      );
    }
  }

  /// Watch owner properties (real-time stream)
  Stream<List<PropertyModel>> watchOwnerProperties(String ownerId) {
    return _firestore
        .collection('properties')
        .where('owner_id', isEqualTo: ownerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final properties = <PropertyModel>[];
          for (final doc in snapshot.docs) {
            final propertyData = {...doc.data(), 'id': doc.id};

            // Get units count for this property
            final unitsSnapshot = await _firestore
                .collection('properties')
                .doc(doc.id)
                .collection('units')
                .get();

            propertyData['units_count'] = unitsSnapshot.docs.length;
            properties.add(PropertyModel.fromJson(propertyData));
          }
          return properties;
        });
  }

  /// Watch all owner units (real-time stream using collection group)
  Stream<List<UnitModel>> watchAllOwnerUnits(String ownerId) {
    // First watch properties, then for each emit, get all units
    return watchOwnerProperties(ownerId).asyncMap((properties) async {
      final allUnits = <UnitModel>[];
      for (final property in properties) {
        final snapshot = await _firestore
            .collection('properties')
            .doc(property.id)
            .collection('units')
            .orderBy('created_at', descending: true)
            .get();

        for (final doc in snapshot.docs) {
          allUnits.add(
            UnitModel.fromJson({
              ...doc.data(),
              'id': doc.id,
              'property_id': property.id,
            }),
          );
        }
      }
      return allUnits;
    });
  }

  /// Create unit (in property subcollection)
  Future<UnitModel> createUnit({
    required String propertyId,
    required String ownerId,
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
            'owner_id': ownerId, // Required for Firestore security rules
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
          ownerId: ownerId,
        );
        LoggingService.log(
          'Widget settings auto-created for unit: $unitId',
          tag: 'OwnerPropertiesRepository',
        );
      } catch (e) {
        // Log error but don't fail unit creation
        LoggingService.log(
          'Warning: Failed to create widget settings for unit $unitId: $e',
          tag: 'OwnerPropertiesRepository',
        );
      }

      return UnitModel.fromJson({...doc.data()!, 'id': unitId});
    } catch (e) {
      throw PropertyException.creationFailed(e);
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
        throw PropertyException(
          'No updates provided',
          code: 'property/no-updates',
        );
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
      throw PropertyException.updateFailed(e);
    }
  }

  /// Delete unit (from property subcollection)
  Future<void> deleteUnit(String propertyId, String unitId) async {
    try {
      // Check if unit has active bookings
      // NEW STRUCTURE: Use subcollection path
      final bookingsSnapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .doc(unitId)
          .collection('bookings')
          .where('status', whereIn: ['pending', 'confirmed'])
          .limit(1)
          .get();

      if (bookingsSnapshot.docs.isNotEmpty) {
        throw PropertyException(
          'Cannot delete unit with active bookings.',
          code: 'property/unit-has-bookings',
        );
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
