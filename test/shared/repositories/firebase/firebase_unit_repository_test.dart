import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:bookbed/shared/repositories/firebase/firebase_unit_repository.dart';
import 'package:bookbed/shared/models/unit_model.dart';
import 'package:bookbed/core/exceptions/app_exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseUnitRepository repository;

  final testPropertyId = 'test-property-1';
  final testUnitId = 'test-unit-1';

  UnitModel createTestUnit({
    String? id,
    String? propertyId,
    String name = 'Test Unit',
    double basePrice = 100.0,
    int maxGuests = 2,
    bool isAvailable = true,
    String? slug,
    int sortOrder = 0,
  }) {
    return UnitModel(
      id: id ?? testUnitId,
      propertyId: propertyId ?? testPropertyId,
      name: name,
      pricePerNight: basePrice,
      maxGuests: maxGuests,
      isAvailable: isAvailable,
      slug: slug,
      sortOrder: sortOrder,
      createdAt: DateTime.utc(2025),
    );
  }

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FirebaseUnitRepository(fakeFirestore);
  });

  group('FirebaseUnitRepository', () {
    test('createUnit', () async {
      final unit = createTestUnit(id: '');
      final createdUnit = await repository.createUnit(unit);

      expect(createdUnit.id, isNotEmpty);
      expect(createdUnit.propertyId, testPropertyId);
      expect(createdUnit.name, 'Test Unit');

      final doc = await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc(createdUnit.id)
          .get();

      expect(doc.exists, true);
      expect(doc.data()!['name'], 'Test Unit');
    });

    test('fetchUnitsByProperty', () async {
      await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u1')
          .set({
        'id': 'u1',
        'property_id': testPropertyId,
        'name': 'Unit 1',
        'base_price': 100.0,
        'max_guests': 2,
        'sort_order': 1,
        'created_at': Timestamp.now(),
      });

      await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u2')
          .set({
        'id': 'u2',
        'property_id': testPropertyId,
        'name': 'Unit 2',
        'base_price': 150.0,
        'max_guests': 4,
        'sort_order': 0,
        'created_at': Timestamp.now(),
      });

      final units = await repository.fetchUnitsByProperty(testPropertyId);

      expect(units.length, 2);
      expect(units[0].id, 'u2'); // sort_order 0
      expect(units[1].id, 'u1'); // sort_order 1
    });

    test('fetchUnitById', () async {
      await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u1')
          .set({
        'id': 'u1',
        'name': 'Unit 1',
        'base_price': 100.0,
        'max_guests': 2,
        'created_at': Timestamp.now(),
      });

      final unit = await repository.fetchUnitById('u1');
      expect(unit, isNotNull);
      expect(unit!.name, 'Unit 1');
      expect(unit.propertyId, testPropertyId);

      final notFound = await repository.fetchUnitById('missing');
      expect(notFound, isNull);
    });

    test('updateUnit', () async {
      await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u1')
          .set({
        'id': 'u1',
        'property_id': testPropertyId,
        'name': 'Old Name',
        'base_price': 100.0,
        'max_guests': 2,
        'created_at': Timestamp.now(),
      });

      final unit = createTestUnit(id: 'u1', name: 'New Name');
      await repository.updateUnit(unit);

      final doc = await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u1')
          .get();

      expect(doc.data()!['name'], 'New Name');
    });

    test('deleteUnit', () async {
      await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u1')
          .set({
        'id': 'u1',
        'name': 'Unit 1',
        'created_at': Timestamp.now(),
      });

      await repository.deleteUnit('u1');

      final doc = await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u1')
          .get();
      expect(doc.exists, false);

      expect(
        () => repository.deleteUnit('missing'),
        throwsA(isA<PropertyException>()),
      );
    });

    test('isUnitAvailable', () async {
      final unitId = 'u1';
      final now = DateTime.utc(2025, 1, 15);

      // Add a booking
      await fakeFirestore.collection('bookings').add({
        'unit_id': unitId,
        'status': 'confirmed',
        'check_in': Timestamp.fromDate(now),
        'check_out': Timestamp.fromDate(now.add(const Duration(days: 5))), // Jan 15 - Jan 20
      });

      // No overlap
      var isAvailable = await repository.isUnitAvailable(
        unitId: unitId,
        checkIn: now.add(const Duration(days: 10)), // Jan 25
        checkOut: now.add(const Duration(days: 12)), // Jan 27
      );
      expect(isAvailable, true);

      // Overlap
      isAvailable = await repository.isUnitAvailable(
        unitId: unitId,
        checkIn: now.add(const Duration(days: 3)), // Jan 18
        checkOut: now.add(const Duration(days: 8)), // Jan 23
      );
      expect(isAvailable, false);
    });

    test('fetchAvailableUnits', () async {
      final now = DateTime.utc(2025, 1, 15);

      // Unit 1
      await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u1')
          .set({
        'id': 'u1',
        'property_id': testPropertyId,
        'name': 'Unit 1',
        'base_price': 100.0,
        'max_guests': 2,
        'sort_order': 0,
        'created_at': Timestamp.now(),
      });

      // Unit 2
      await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u2')
          .set({
        'id': 'u2',
        'property_id': testPropertyId,
        'name': 'Unit 2',
        'base_price': 150.0,
        'max_guests': 4,
        'sort_order': 1,
        'created_at': Timestamp.now(),
      });

      // Booking for Unit 1 overlapping dates
      await fakeFirestore.collection('bookings').add({
        'unit_id': 'u1',
        'status': 'confirmed',
        'check_in': Timestamp.fromDate(now),
        'check_out': Timestamp.fromDate(now.add(const Duration(days: 5))), // Jan 15 - Jan 20
      });

      final availableUnits = await repository.fetchAvailableUnits(
        propertyId: testPropertyId,
        checkIn: now.add(const Duration(days: 1)), // Jan 16
        checkOut: now.add(const Duration(days: 3)), // Jan 18
      );

      expect(availableUnits.length, 1);
      expect(availableUnits[0].id, 'u2');
    });

    test('toggleUnitAvailability', () async {
      await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u1')
          .set({
        'id': 'u1',
        'name': 'Unit 1',
        'base_price': 100.0,
        'max_guests': 2,
        'is_available': true,
        'created_at': Timestamp.now(),
      });

      final updatedUnit = await repository.toggleUnitAvailability('u1', false);
      expect(updatedUnit.isAvailable, false);

      final doc = await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u1')
          .get();
      expect(doc.data()!['is_available'], false);

      expect(
        () => repository.toggleUnitAvailability('missing', false),
        throwsA(isA<PropertyException>()),
      );
    });

    test('updateUnitPrice', () async {
      await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u1')
          .set({
        'id': 'u1',
        'name': 'Unit 1',
        'base_price': 100.0,
        'max_guests': 2,
        'created_at': Timestamp.now(),
      });

      final updatedUnit = await repository.updateUnitPrice('u1', 200.0);
      expect(updatedUnit.pricePerNight, 200.0);

      final doc = await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u1')
          .get();
      expect(doc.data()!['base_price'], 200.0);

      expect(
        () => repository.updateUnitPrice('missing', 200.0),
        throwsA(isA<PropertyException>()),
      );
    });

    test('fetchFilteredUnits', () async {
      // Global units collection setup
      await fakeFirestore.collection('units').doc('u1').set({
        'id': 'u1',
        'property_id': testPropertyId,
        'name': 'Unit 1',
        'base_price': 100.0,
        'max_guests': 2,
        'is_available': true,
        'created_at': Timestamp.now(),
      });

      await fakeFirestore.collection('units').doc('u2').set({
        'id': 'u2',
        'property_id': testPropertyId,
        'name': 'Unit 2',
        'base_price': 200.0,
        'max_guests': 4,
        'is_available': true,
        'created_at': Timestamp.now(),
      });

      await fakeFirestore.collection('units').doc('u3').set({
        'id': 'u3',
        'property_id': 'other_property',
        'name': 'Unit 3',
        'base_price': 50.0,
        'max_guests': 1,
        'is_available': false,
        'created_at': Timestamp.now(),
      });

      var units = await repository.fetchFilteredUnits(
        propertyId: testPropertyId,
      );
      expect(units.length, 2);

      units = await repository.fetchFilteredUnits(
        maxPrice: 150.0,
      );
      expect(units.length, 2); // u1, u3
      expect(units.map((u) => u.id), containsAll(['u1', 'u3']));

      units = await repository.fetchFilteredUnits(
        minGuests: 3,
      );
      expect(units.length, 1);
      expect(units[0].id, 'u2');

      units = await repository.fetchFilteredUnits(
        availableOnly: true,
      );
      expect(units.length, 2);
      expect(units.map((u) => u.id), containsAll(['u1', 'u2']));
    });

    test('updateUnitsSortOrder', () async {
      final unit1 = createTestUnit(id: 'u1');
      final unit2 = createTestUnit(id: 'u2');

      await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u1')
          .set({'id': 'u1', 'sort_order': 0});

      await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u2')
          .set({'id': 'u2', 'sort_order': 1});

      await repository.updateUnitsSortOrder([unit2, unit1]);

      final doc1 = await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u1')
          .get();
      final doc2 = await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u2')
          .get();

      expect(doc2.data()!['sort_order'], 0);
      expect(doc1.data()!['sort_order'], 1);
    });

    test('fetchUnitBySlug', () async {
      await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u1')
          .set({
        'id': 'u1',
        'name': 'Unit 1',
        'slug': 'unit-1',
        'base_price': 100.0,
        'max_guests': 2,
        'created_at': Timestamp.now(),
      });

      final unit = await repository.fetchUnitBySlug(testPropertyId, 'unit-1');
      expect(unit, isNotNull);
      expect(unit!.id, 'u1');

      final notFound = await repository.fetchUnitBySlug(testPropertyId, 'missing');
      expect(notFound, isNull);
    });

    test('isSlugUniqueInProperty', () async {
      await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u1')
          .set({
        'id': 'u1',
        'name': 'Unit 1',
        'slug': 'unit-1',
      });

      var isUnique = await repository.isSlugUniqueInProperty(testPropertyId, 'new-slug');
      expect(isUnique, true);

      isUnique = await repository.isSlugUniqueInProperty(testPropertyId, 'unit-1');
      expect(isUnique, false);

      isUnique = await repository.isSlugUniqueInProperty(testPropertyId, 'unit-1', excludeUnitId: 'u1');
      expect(isUnique, true);
    });

    test('fetchUnitByIdFresh', () async {
      await fakeFirestore
          .collection('properties')
          .doc(testPropertyId)
          .collection('units')
          .doc('u1')
          .set({
        'id': 'u1',
        'name': 'Unit 1',
        'base_price': 100.0,
        'max_guests': 2,
        'created_at': Timestamp.now(),
      });

      final unit = await repository.fetchUnitByIdFresh(
        unitId: 'u1',
        propertyId: testPropertyId,
      );

      expect(unit, isNotNull);
      expect(unit!.name, 'Unit 1');
      expect(unit.propertyId, testPropertyId);

      final notFound = await repository.fetchUnitByIdFresh(
        unitId: 'missing',
        propertyId: testPropertyId,
      );
      expect(notFound, isNull);
    });
  });
}
