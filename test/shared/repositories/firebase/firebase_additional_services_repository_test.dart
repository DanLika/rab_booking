import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/shared/models/additional_service_model.dart';
import 'package:bookbed/shared/repositories/firebase/firebase_additional_services_repository.dart';

void main() {
  group('FirebaseAdditionalServicesRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseAdditionalServicesRepository repository;

    const propertyId = 'property123';
    const unitId = 'unit123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirebaseAdditionalServicesRepository(fakeFirestore);
    });

    final testService = AdditionalServiceModel(
      id: 'service1',
      name: 'Breakfast',
      serviceType: 'breakfast',
      price: 15.0,
      pricingUnit: 'per_person',


      createdAt: DateTime(2024),
    );

    final unavailableService = AdditionalServiceModel(
      id: 'service2',
      name: 'Parking',
      serviceType: 'parking',
      price: 10.0,
      pricingUnit: 'per_night',
      isAvailable: false,
      sortOrder: 1,
      createdAt: DateTime(2024),
    );

    group('fetchByUnit', () {
      test('fetches only available services sorted by sort_order', () async {
        // Add services
        final collection = fakeFirestore
            .collection('properties')
            .doc(propertyId)
            .collection('units')
            .doc(unitId)
            .collection('additional_services');

        await collection.doc(testService.id).set({
          ...testService.toJson(),
          'created_at': Timestamp.fromDate(testService.createdAt),
        });

        await collection.doc(unavailableService.id).set({
          ...unavailableService.toJson(),
          'created_at': Timestamp.fromDate(unavailableService.createdAt),
        });

        // Add another available service but with higher sort order
        final anotherService = testService.copyWith(
          id: 'service3',
          name: 'Late Check-out',
          sortOrder: 2,
        );
        await collection.doc(anotherService.id).set({
          ...anotherService.toJson(),
          'created_at': Timestamp.fromDate(anotherService.createdAt),
        });

        final services = await repository.fetchByUnit(
          propertyId: propertyId,
          unitId: unitId,
        );

        // Should return 2 available services
        expect(services.length, 2);
        // Verify sort order
        expect(services[0].id, 'service1');
        expect(services[1].id, 'service3');
      });
    });

    group('create', () {
      test('creates a new service and returns it with populated ids', () async {
        final result = await repository.create(
          propertyId: propertyId,
          unitId: unitId,
          service: testService,
        );

        expect(result.id, isNot('service1')); // ID should be generated
        expect(result.unitId, unitId);
        expect(result.propertyId, propertyId);

        // Verify in firestore
        final doc = await fakeFirestore
            .collection('properties')
            .doc(propertyId)
            .collection('units')
            .doc(unitId)
            .collection('additional_services')
            .doc(result.id)
            .get();

        expect(doc.exists, true);
        final data = doc.data()!;
        expect(data['id'], result.id);
        expect(data['unit_id'], unitId);
        expect(data['property_id'], propertyId);
        expect(data['name'], 'Breakfast');
        expect(data['created_at'], isA<Timestamp>());
        expect(data.containsKey('owner_id'), false);
      });
    });

    group('update', () {
      test('updates existing service without storing id in document', () async {
        final collection = fakeFirestore
            .collection('properties')
            .doc(propertyId)
            .collection('units')
            .doc(unitId)
            .collection('additional_services');

        final initialData = testService.toJson();
        initialData.remove('id'); // Simulate no ID in doc body (or it was just ignored)
        initialData['owner_id'] = 'some_owner'; // Add owner_id to test it gets removed

        await collection.doc(testService.id).set({
          ...initialData,
          'created_at': Timestamp.fromDate(testService.createdAt),
        });

        final updatedService = testService.copyWith(
          name: 'Updated Breakfast',
          price: 20.0,
        );

        await repository.update(
          propertyId: propertyId,
          unitId: unitId,
          service: updatedService,
        );

        final doc = await collection.doc(testService.id).get();
        final data = doc.data()!;

        expect(data['name'], 'Updated Breakfast');
        expect(data['price'], 20.0);
        expect(data['unit_id'], unitId);
        expect(data['property_id'], propertyId);

        expect(data.containsKey('id'), false);
        expect(data['updated_at'], isA<Timestamp>());
      });
    });

    group('delete', () {
      test('hard deletes the service document', () async {
        final collection = fakeFirestore
            .collection('properties')
            .doc(propertyId)
            .collection('units')
            .doc(unitId)
            .collection('additional_services');

        await collection.doc(testService.id).set(testService.toJson());

        await repository.delete(
          propertyId: propertyId,
          unitId: unitId,
          serviceId: testService.id,
        );

        final doc = await collection.doc(testService.id).get();
        expect(doc.exists, false);
      });
    });

    group('reorder', () {
      test('updates sort_order for multiple services', () async {
        final collection = fakeFirestore
            .collection('properties')
            .doc(propertyId)
            .collection('units')
            .doc(unitId)
            .collection('additional_services');

        await collection.doc('id1').set({'name': 'S1', 'sort_order': 0});
        await collection.doc('id2').set({'name': 'S2', 'sort_order': 1});
        await collection.doc('id3').set({'name': 'S3', 'sort_order': 2});

        await repository.reorder(
          propertyId: propertyId,
          unitId: unitId,
          serviceIds: ['id3', 'id1', 'id2'],
        );

        final doc1 = await collection.doc('id1').get();
        final doc2 = await collection.doc('id2').get();
        final doc3 = await collection.doc('id3').get();

        expect(doc1.data()!['sort_order'], 1);
        expect(doc2.data()!['sort_order'], 2);
        expect(doc3.data()!['sort_order'], 0);
        expect(doc1.data()!['updated_at'], isA<Timestamp>());
      });
    });

    group('watchByUnit', () {
      test('emits updates when services change', () async {
        final collection = fakeFirestore
            .collection('properties')
            .doc(propertyId)
            .collection('units')
            .doc(unitId)
            .collection('additional_services');

        final stream = repository.watchByUnit(
          propertyId: propertyId,
          unitId: unitId,
        );

        // First emission will be empty
        expect(await stream.first, isEmpty);

        // Add an available service
        await collection.doc(testService.id).set({
          ...testService.toJson(),
          'created_at': Timestamp.fromDate(testService.createdAt),
        });

        // Listen for the next emission
        final event1 = await stream.first;
        expect(event1.length, 1);
        expect(event1.first.id, testService.id);

        // Add unavailable service (should be ignored)
        await collection.doc(unavailableService.id).set({
          ...unavailableService.toJson(),
          'created_at': Timestamp.fromDate(unavailableService.createdAt),
        });

        // Add another available service
        final service3 = testService.copyWith(id: 'service3', sortOrder: 5);
        await collection.doc(service3.id).set({
          ...service3.toJson(),
          'created_at': Timestamp.fromDate(service3.createdAt),
        });

        // Should now have 2 items
        final event2 = await stream.first;
        expect(event2.length, 2);
        expect(event2[0].id, testService.id);
        expect(event2[1].id, service3.id);
      });
    });
  });
}
