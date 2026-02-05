import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../models/additional_service_model.dart';
import '../additional_services_repository.dart';

part 'firebase_additional_services_repository.g.dart';

@riverpod
AdditionalServicesRepository additionalServicesRepository(Ref ref) {
  return FirebaseAdditionalServicesRepository(FirebaseFirestore.instance);
}

class FirebaseAdditionalServicesRepository
    implements AdditionalServicesRepository {
  final FirebaseFirestore _firestore;

  FirebaseAdditionalServicesRepository(this._firestore);

  /// Get collection reference for a unit's additional services
  /// Path: properties/{propertyId}/units/{unitId}/additional_services
  CollectionReference<Map<String, dynamic>> _getCollection(
    String propertyId,
    String unitId,
  ) {
    return _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId)
        .collection('additional_services');
  }

  /// Parse Firestore document to AdditionalServiceModel
  AdditionalServiceModel _parseDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AdditionalServiceModel.fromJson({
      'id': doc.id,
      ...data,
      if (data['created_at'] != null)
        'created_at': (data['created_at'] as Timestamp)
            .toDate()
            .toIso8601String(),
      if (data['updated_at'] != null)
        'updated_at': (data['updated_at'] as Timestamp)
            .toDate()
            .toIso8601String(),
      if (data['deleted_at'] != null)
        'deleted_at': (data['deleted_at'] as Timestamp)
            .toDate()
            .toIso8601String(),
    });
  }

  @override
  Future<List<AdditionalServiceModel>> fetchByUnit({
    required String propertyId,
    required String unitId,
  }) async {
    final query = await _getCollection(propertyId, unitId)
        .where('is_available', isEqualTo: true)
        .orderBy('sort_order', descending: false)
        .get();

    return query.docs.map(_parseDocument).toList();
  }

  @override
  Future<AdditionalServiceModel> create({
    required String propertyId,
    required String unitId,
    required AdditionalServiceModel service,
  }) async {
    final collection = _getCollection(propertyId, unitId);
    final docRef = collection.doc(); // Auto-generate ID

    final data = service.toJson();
    data['id'] = docRef.id;
    data['unit_id'] = unitId;
    data['property_id'] = propertyId;
    data['created_at'] = Timestamp.fromDate(service.createdAt);
    if (service.updatedAt != null) {
      data['updated_at'] = Timestamp.fromDate(service.updatedAt!);
    }
    // Remove owner_id as it's not needed in subcollection structure
    data.remove('owner_id');

    await docRef.set(data);

    return service.copyWith(
      id: docRef.id,
      unitId: unitId,
      propertyId: propertyId,
    );
  }

  @override
  Future<void> update({
    required String propertyId,
    required String unitId,
    required AdditionalServiceModel service,
  }) async {
    final data = service.toJson();
    data['updated_at'] = Timestamp.now();
    data['created_at'] = Timestamp.fromDate(service.createdAt);
    data['unit_id'] = unitId;
    data['property_id'] = propertyId;
    data.remove('id'); // Don't store ID in document
    data.remove('owner_id'); // Not needed in subcollection structure

    await _getCollection(propertyId, unitId).doc(service.id).update(data);
  }

  @override
  Future<void> delete({
    required String propertyId,
    required String unitId,
    required String serviceId,
  }) async {
    // Hard delete - remove document completely
    await _getCollection(propertyId, unitId).doc(serviceId).delete();
  }

  @override
  Future<void> reorder({
    required String propertyId,
    required String unitId,
    required List<String> serviceIds,
  }) async {
    final batch = _firestore.batch();
    final collection = _getCollection(propertyId, unitId);

    for (var i = 0; i < serviceIds.length; i++) {
      final docRef = collection.doc(serviceIds[i]);
      batch.update(docRef, {'sort_order': i, 'updated_at': Timestamp.now()});
    }

    await batch.commit();
  }

  @override
  Stream<List<AdditionalServiceModel>> watchByUnit({
    required String propertyId,
    required String unitId,
  }) {
    return _getCollection(propertyId, unitId)
        .where('is_available', isEqualTo: true)
        .orderBy('sort_order', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_parseDocument).toList());
  }
}
