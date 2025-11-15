import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../models/additional_service_model.dart';
import '../additional_services_repository.dart';

part 'firebase_additional_services_repository.g.dart';

@riverpod
AdditionalServicesRepository additionalServicesRepository(
  AdditionalServicesRepositoryRef ref,
) {
  return FirebaseAdditionalServicesRepository(
    FirebaseFirestore.instance,
  );
}

class FirebaseAdditionalServicesRepository implements AdditionalServicesRepository {
  final FirebaseFirestore _firestore;

  FirebaseAdditionalServicesRepository(this._firestore);

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('additional_services');

  @override
  Future<List<AdditionalServiceModel>> fetchByOwner(String ownerId) async {
    final query = await _collection
        .where('owner_id', isEqualTo: ownerId)
        .where('deleted_at', isNull: true)
        .orderBy('sort_order', descending: false)
        .get();

    return query.docs
        .map((doc) => AdditionalServiceModel.fromJson({
              'id': doc.id,
              ...doc.data(),
              if (doc.data()['created_at'] != null)
                'created_at':
                    (doc.data()['created_at'] as Timestamp).toDate().toIso8601String(),
              if (doc.data()['updated_at'] != null)
                'updated_at':
                    (doc.data()['updated_at'] as Timestamp).toDate().toIso8601String(),
              if (doc.data()['deleted_at'] != null)
                'deleted_at':
                    (doc.data()['deleted_at'] as Timestamp).toDate().toIso8601String(),
            }))
        .toList();
  }

  @override
  Future<List<AdditionalServiceModel>> fetchByUnit(
    String unitId,
    String ownerId,
  ) async {
    // Fetch services where unitId matches OR unitId is null (available for all)
    final query = await _collection
        .where('owner_id', isEqualTo: ownerId)
        .where('is_available', isEqualTo: true)
        .where('deleted_at', isNull: true)
        .orderBy('sort_order', descending: false)
        .get();

    // Filter in memory for unitId (Firestore doesn't support OR on where clauses)
    final services = query.docs
        .map((doc) => AdditionalServiceModel.fromJson({
              'id': doc.id,
              ...doc.data(),
              if (doc.data()['created_at'] != null)
                'created_at':
                    (doc.data()['created_at'] as Timestamp).toDate().toIso8601String(),
              if (doc.data()['updated_at'] != null)
                'updated_at':
                    (doc.data()['updated_at'] as Timestamp).toDate().toIso8601String(),
            }))
        .where((service) => service.unitId == null || service.unitId == unitId)
        .toList();

    return services;
  }

  @override
  Future<AdditionalServiceModel> create(AdditionalServiceModel service) async {
    final docRef = _collection.doc(); // Auto-generate ID

    final data = service.toJson();
    data['id'] = docRef.id;
    data['created_at'] = Timestamp.fromDate(service.createdAt);
    if (service.updatedAt != null) {
      data['updated_at'] = Timestamp.fromDate(service.updatedAt!);
    }
    data.remove('deleted_at'); // Don't set on creation

    await docRef.set(data);

    return service.copyWith(id: docRef.id);
  }

  @override
  Future<void> update(AdditionalServiceModel service) async {
    final data = service.toJson();
    data['updated_at'] = Timestamp.now();
    data['created_at'] = Timestamp.fromDate(service.createdAt);
    if (service.deletedAt != null) {
      data['deleted_at'] = Timestamp.fromDate(service.deletedAt!);
    }
    data.remove('id'); // Don't store ID in document

    await _collection.doc(service.id).update(data);
  }

  @override
  Future<void> delete(String id) async {
    // Soft delete
    await _collection.doc(id).update({
      'deleted_at': Timestamp.now(),
      'is_available': false,
    });
  }

  @override
  Future<void> reorder(List<String> serviceIds) async {
    final batch = _firestore.batch();

    for (var i = 0; i < serviceIds.length; i++) {
      final docRef = _collection.doc(serviceIds[i]);
      batch.update(docRef, {
        'sort_order': i,
        'updated_at': Timestamp.now(),
      });
    }

    await batch.commit();
  }

  @override
  Stream<List<AdditionalServiceModel>> watchByOwner(String ownerId) {
    return _collection
        .where('owner_id', isEqualTo: ownerId)
        .where('deleted_at', isNull: true)
        .orderBy('sort_order', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdditionalServiceModel.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                  if (doc.data()['created_at'] != null)
                    'created_at':
                        (doc.data()['created_at'] as Timestamp).toDate().toIso8601String(),
                  if (doc.data()['updated_at'] != null)
                    'updated_at':
                        (doc.data()['updated_at'] as Timestamp).toDate().toIso8601String(),
                  if (doc.data()['deleted_at'] != null)
                    'deleted_at':
                        (doc.data()['deleted_at'] as Timestamp).toDate().toIso8601String(),
                }))
            .toList());
  }

  @override
  Stream<List<AdditionalServiceModel>> watchByUnit(
    String unitId,
    String ownerId,
  ) {
    return _collection
        .where('owner_id', isEqualTo: ownerId)
        .where('is_available', isEqualTo: true)
        .where('deleted_at', isNull: true)
        .orderBy('sort_order', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdditionalServiceModel.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                  if (doc.data()['created_at'] != null)
                    'created_at':
                        (doc.data()['created_at'] as Timestamp).toDate().toIso8601String(),
                  if (doc.data()['updated_at'] != null)
                    'updated_at':
                        (doc.data()['updated_at'] as Timestamp).toDate().toIso8601String(),
                }))
            .where((service) =>
                service.unitId == null || service.unitId == unitId)
            .toList());
  }
}
