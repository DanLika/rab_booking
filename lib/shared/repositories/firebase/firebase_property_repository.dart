import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../property_repository.dart';
import '../../models/property_model.dart';
import '../../../core/exceptions/app_exceptions.dart';

/// Firebase implementation of PropertyRepository
class FirebasePropertyRepository implements PropertyRepository {
  final FirebaseFirestore _firestore;

  FirebasePropertyRepository(this._firestore);

  @override
  Future<List<PropertyModel>> fetchProperties([PropertyFilters? filters]) async {
    var query = _firestore.collection('properties').where('id', isNotEqualTo: '');

    if (filters?.ownerId != null) {
      query = query.where('owner_id', isEqualTo: filters!.ownerId);
    }

    if (filters?.location != null) {
      query = query.where('city', isEqualTo: filters!.location);
    }

    if (filters?.minGuests != null) {
      query = query.where('max_guests', isGreaterThanOrEqualTo: filters!.minGuests);
    }

    final snapshot = await query.get();
    var properties = snapshot.docs
        .map((doc) => PropertyModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    // Client-side filtering for complex conditions
    if (filters != null) {
      if (filters.minPrice != null) {
        properties = properties.where((p) => (p.pricePerNight ?? 0) >= filters.minPrice!).toList();
      }
      if (filters.maxPrice != null) {
        properties = properties.where((p) => (p.pricePerNight ?? double.infinity) <= filters.maxPrice!).toList();
      }
      if (filters.minRating != null) {
        properties = properties.where((p) => p.rating >= filters.minRating!).toList();
      }
      if (filters.amenities != null && filters.amenities!.isNotEmpty) {
        properties = properties.where((p) {
          return filters.amenities!.every((amenity) => p.amenities.contains(amenity));
        }).toList();
      }
    }

    return properties;
  }

  @override
  Future<PropertyModel?> fetchPropertyById(String id) async {
    final doc = await _firestore.collection('properties').doc(id).get();
    if (!doc.exists) return null;
    return PropertyModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<List<PropertyModel>> fetchPropertiesByOwner(String ownerId) async {
    final snapshot = await _firestore
        .collection('properties')
        .where('owner_id', isEqualTo: ownerId)
        .get();
    return snapshot.docs
        .map((doc) => PropertyModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<PropertyModel> createProperty(PropertyModel property) async {
    final docRef = await _firestore.collection('properties').add(property.toJson());
    return property.copyWith(id: docRef.id);
  }

  @override
  Future<PropertyModel> updateProperty(PropertyModel property) async {
    await _firestore.collection('properties').doc(property.id).update(property.toJson());
    return property;
  }

  @override
  Future<void> deleteProperty(String id) async {
    await _firestore.collection('properties').doc(id).delete();
  }

  @override
  Future<List<PropertyModel>> searchProperties(String query) async {
    final snapshot = await _firestore.collection('properties').get();
    final properties = snapshot.docs
        .map((doc) => PropertyModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    // Client-side search (for simple implementation)
    final queryLower = query.toLowerCase();
    return properties.where((p) {
      return p.name.toLowerCase().contains(queryLower) ||
          p.description.toLowerCase().contains(queryLower) ||
          (p.address?.toLowerCase().contains(queryLower) ?? false) ||
          (p.city?.toLowerCase().contains(queryLower) ?? false);
    }).toList();
  }

  @override
  Future<List<PropertyModel>> getFeaturedProperties({int limit = 10}) async {
    final snapshot = await _firestore
        .collection('properties')
        .where('is_active', isEqualTo: true)
        .orderBy('rating', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => PropertyModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<List<PropertyModel>> getNearbyProperties({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    // Simple implementation - fetch all and filter client-side
    // For production, use GeoFirestore or similar for geoqueries
    final snapshot = await _firestore.collection('properties').get();
    final properties = snapshot.docs
        .map((doc) => PropertyModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    return properties.where((p) {
      if (p.latitude == null || p.longitude == null) return false;
      final distance = _calculateDistance(
        latitude,
        longitude,
        p.latitude!,
        p.longitude!,
      );
      return distance <= radiusKm;
    }).toList();
  }

  @override
  Future<PropertyModel> togglePropertyStatus(String id, bool isActive) async {
    final doc = await _firestore.collection('properties').doc(id).get();
    if (!doc.exists) throw PropertyException('Property not found', code: 'property/not-found');

    final property = PropertyModel.fromJson({...doc.data()!, 'id': doc.id});
    final updated = property.copyWith(isActive: isActive);

    await _firestore.collection('properties').doc(id).update(updated.toJson());
    return updated;
  }

  @override
  Future<PropertyModel> updatePropertyRating(String id, double rating, int reviewCount) async {
    final doc = await _firestore.collection('properties').doc(id).get();
    if (!doc.exists) throw PropertyException('Property not found', code: 'property/not-found');

    final property = PropertyModel.fromJson({...doc.data()!, 'id': doc.id});
    final updated = property.copyWith(
      rating: rating,
      reviewCount: reviewCount,
    );

    await _firestore.collection('properties').doc(id).update(updated.toJson());
    return updated;
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  @override
  Future<PropertyModel?> fetchPropertyBySubdomain(String subdomain) async {
    final snapshot = await _firestore
        .collection('properties')
        .where('subdomain', isEqualTo: subdomain)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return PropertyModel.fromJson({...doc.data(), 'id': doc.id});
  }
}
