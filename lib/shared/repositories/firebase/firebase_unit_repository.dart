import 'package:cloud_firestore/cloud_firestore.dart';
import '../unit_repository.dart';
import '../../models/unit_model.dart';
import '../../../core/exceptions/app_exceptions.dart';

class FirebaseUnitRepository implements UnitRepository {
  final FirebaseFirestore _firestore;

  FirebaseUnitRepository(this._firestore);

  @override
  Future<List<UnitModel>> fetchUnitsByProperty(String propertyId) async {
    // Units are stored as subcollection under properties/{propertyId}/units
    final snapshot = await _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .orderBy('sort_order')
        .get();
    return snapshot.docs
        .map((doc) => UnitModel.fromJson({...doc.data(), 'id': doc.id, 'property_id': propertyId}))
        .toList();
  }

  @override
  Future<UnitModel?> fetchUnitById(String id) async {
    // Use collection group query to find unit across all properties
    // NOTE: Cannot use FieldPath.documentId with collectionGroup without full path
    // Instead, fetch all units and filter in code
    final querySnapshot = await _firestore.collectionGroup('units').get();

    for (final doc in querySnapshot.docs) {
      if (doc.id == id) {
        final propertyId = doc.reference.parent.parent?.id;
        return UnitModel.fromJson({...doc.data(), 'id': doc.id, 'property_id': propertyId});
      }
    }

    return null;
  }

  @override
  Future<UnitModel> createUnit(UnitModel unit) async {
    // Units are stored as subcollection under properties/{propertyId}/units
    final docRef = await _firestore
        .collection('properties')
        .doc(unit.propertyId)
        .collection('units')
        .add(unit.toJson());
    return unit.copyWith(id: docRef.id);
  }

  @override
  Future<UnitModel> updateUnit(UnitModel unit) async {
    // Units are stored as subcollection under properties/{propertyId}/units
    await _firestore
        .collection('properties')
        .doc(unit.propertyId)
        .collection('units')
        .doc(unit.id)
        .update(unit.toJson());
    return unit;
  }

  @override
  Future<void> deleteUnit(String id) async {
    // Use collectionGroup to find and delete the unit
    final querySnapshot = await _firestore.collectionGroup('units').get();
    for (final doc in querySnapshot.docs) {
      if (doc.id == id) {
        await doc.reference.delete();
        return;
      }
    }
    throw PropertyException('Unit not found', code: 'property/unit-not-found');
  }

  @override
  Future<List<UnitModel>> fetchAvailableUnits({
    required String propertyId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    final units = await fetchUnitsByProperty(propertyId);
    final List<UnitModel> available = [];

    for (var unit in units) {
      final isAvailable = await isUnitAvailable(unitId: unit.id, checkIn: checkIn, checkOut: checkOut);
      if (isAvailable) {
        available.add(unit);
      }
    }

    return available;
  }

  @override
  Future<UnitModel> toggleUnitAvailability(String id, bool isAvailable) async {
    // Use collectionGroup to find the unit across all properties
    final querySnapshot = await _firestore.collectionGroup('units').get();
    for (final doc in querySnapshot.docs) {
      if (doc.id == id) {
        final propertyId = doc.reference.parent.parent?.id;
        final unit = UnitModel.fromJson({...doc.data(), 'id': doc.id, 'property_id': propertyId});
        final updated = unit.copyWith(isAvailable: isAvailable);
        await doc.reference.update(updated.toJson());
        return updated;
      }
    }
    throw PropertyException('Unit not found', code: 'property/unit-not-found');
  }

  @override
  Future<UnitModel> updateUnitPrice(String id, double pricePerNight) async {
    // Use collectionGroup to find the unit across all properties
    final querySnapshot = await _firestore.collectionGroup('units').get();
    for (final doc in querySnapshot.docs) {
      if (doc.id == id) {
        final propertyId = doc.reference.parent.parent?.id;
        final unit = UnitModel.fromJson({...doc.data(), 'id': doc.id, 'property_id': propertyId});
        final updated = unit.copyWith(pricePerNight: pricePerNight);
        await doc.reference.update(updated.toJson());
        return updated;
      }
    }
    throw PropertyException('Unit not found', code: 'property/unit-not-found');
  }

  @override
  Future<bool> isUnitAvailable({required String unitId, required DateTime checkIn, required DateTime checkOut}) async {
    // Fetch all active bookings for this unit
    // Note: Using client-side filtering to avoid Firestore limitation of
    // multiple inequality filters on different fields (check_in and check_out)
    // NEW STRUCTURE: Use collection group query for subcollection
    final snapshot = await _firestore
        .collectionGroup('bookings')
        .where('unit_id', isEqualTo: unitId)
        .where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
        .get();

    // Check for overlap in memory (client-side)
    final hasOverlap = snapshot.docs.any((doc) {
      final data = doc.data();
      final bookingCheckIn = (data['check_in'] as Timestamp).toDate();
      final bookingCheckOut = (data['check_out'] as Timestamp).toDate();

      // Overlap logic: bookings overlap if:
      // (bookingCheckOut > checkIn) AND (bookingCheckIn < checkOut)
      return bookingCheckOut.isAfter(checkIn) && bookingCheckIn.isBefore(checkOut);
    });

    return !hasOverlap; // Return true if NO overlap (unit is available)
  }

  @override
  Future<List<UnitModel>> fetchFilteredUnits({
    String? propertyId,
    double? maxPrice,
    int? minGuests,
    bool? availableOnly,
  }) async {
    var query = _firestore.collection('units').where('id', isNotEqualTo: '');

    if (propertyId != null) {
      query = query.where('property_id', isEqualTo: propertyId);
    }

    if (availableOnly == true) {
      query = query.where('is_available', isEqualTo: true);
    }

    final snapshot = await query.get();
    var units = snapshot.docs.map((doc) => UnitModel.fromJson({...doc.data(), 'id': doc.id})).toList();

    // Client-side filtering
    if (maxPrice != null) {
      units = units.where((u) => u.pricePerNight <= maxPrice).toList();
    }

    if (minGuests != null) {
      units = units.where((u) => u.maxGuests >= minGuests).toList();
    }

    return units;
  }

  @override
  Future<void> updateUnitsSortOrder(List<UnitModel> units) async {
    // Use batch write to update all units atomically
    final batch = _firestore.batch();

    for (int i = 0; i < units.length; i++) {
      final unit = units[i];
      final docRef = _firestore.collection('properties').doc(unit.propertyId).collection('units').doc(unit.id);

      batch.update(docRef, {'sort_order': i, 'updated_at': FieldValue.serverTimestamp()});
    }

    await batch.commit();
  }

  @override
  Future<UnitModel?> fetchUnitBySlug(String propertyId, String slug) async {
    final snapshot = await _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .where('slug', isEqualTo: slug)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return UnitModel.fromJson({...doc.data(), 'id': doc.id, 'property_id': propertyId});
  }

  @override
  Future<bool> isSlugUniqueInProperty(String propertyId, String slug, {String? excludeUnitId}) async {
    final snapshot = await _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .where('slug', isEqualTo: slug)
        .get();

    if (snapshot.docs.isEmpty) return true;

    // If we're excluding a unit (during edit), check if the only match is that unit
    if (excludeUnitId != null) {
      return snapshot.docs.length == 1 && snapshot.docs.first.id == excludeUnitId;
    }

    return false;
  }
}
