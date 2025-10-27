import 'package:cloud_firestore/cloud_firestore.dart';
import '../unit_repository.dart';
import '../../models/unit_model.dart';

class FirebaseUnitRepository implements UnitRepository {
  final FirebaseFirestore _firestore;

  FirebaseUnitRepository(this._firestore);

  @override
  Future<List<UnitModel>> fetchUnitsByProperty(String propertyId) async {
    final snapshot = await _firestore
        .collection('units')
        .where('property_id', isEqualTo: propertyId)
        .get();
    return snapshot.docs
        .map((doc) => UnitModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<UnitModel?> fetchUnitById(String id) async {
    final doc = await _firestore.collection('units').doc(id).get();
    if (!doc.exists) return null;
    return UnitModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<UnitModel> createUnit(UnitModel unit) async {
    final docRef = await _firestore.collection('units').add(unit.toJson());
    return unit.copyWith(id: docRef.id);
  }

  @override
  Future<UnitModel> updateUnit(UnitModel unit) async {
    await _firestore.collection('units').doc(unit.id).update(unit.toJson());
    return unit;
  }

  @override
  Future<void> deleteUnit(String id) async {
    await _firestore.collection('units').doc(id).delete();
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
      final isAvailable = await isUnitAvailable(
        unitId: unit.id,
        checkIn: checkIn,
        checkOut: checkOut,
      );
      if (isAvailable) {
        available.add(unit);
      }
    }

    return available;
  }

  @override
  Future<UnitModel> toggleUnitAvailability(String id, bool isAvailable) async {
    final doc = await _firestore.collection('units').doc(id).get();
    if (!doc.exists) throw Exception('Unit not found');

    final unit = UnitModel.fromJson({...doc.data()!, 'id': doc.id});
    final updated = unit.copyWith(isAvailable: isAvailable);

    await _firestore.collection('units').doc(id).update(updated.toJson());
    return updated;
  }

  @override
  Future<UnitModel> updateUnitPrice(String id, double pricePerNight) async {
    final doc = await _firestore.collection('units').doc(id).get();
    if (!doc.exists) throw Exception('Unit not found');

    final unit = UnitModel.fromJson({...doc.data()!, 'id': doc.id});
    final updated = unit.copyWith(pricePerNight: pricePerNight);

    await _firestore.collection('units').doc(id).update(updated.toJson());
    return updated;
  }

  @override
  Future<bool> isUnitAvailable({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    // Check for overlapping bookings
    final snapshot = await _firestore
        .collection('bookings')
        .where('unit_id', isEqualTo: unitId)
        .where('check_out', isGreaterThan: Timestamp.fromDate(checkIn))
        .where('check_in', isLessThan: Timestamp.fromDate(checkOut))
        .get();

    return snapshot.docs.isEmpty;
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
      query = query.where('property_id', isEqualTo: propertyId) as Query<Map<String, dynamic>>;
    }

    if (availableOnly == true) {
      query = query.where('is_available', isEqualTo: true) as Query<Map<String, dynamic>>;
    }

    final snapshot = await query.get();
    var units = snapshot.docs
        .map((doc) => UnitModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    // Client-side filtering
    if (maxPrice != null) {
      units = units.where((u) => u.pricePerNight <= maxPrice).toList();
    }

    if (minGuests != null) {
      units = units.where((u) => u.maxGuests >= minGuests).toList();
    }

    return units;
  }
}
