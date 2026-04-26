import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:bookbed/shared/repositories/firebase/firebase_property_repository.dart';
import 'package:bookbed/shared/models/property_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebasePropertyRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FirebasePropertyRepository(fakeFirestore);
  });

  PropertyModel createTestProperty({
    String id = 'prop1',
    String ownerId = 'owner1',
    String name = 'Test Property',
    String description = 'Test Description',
    String location = 'Test Location',
    bool isActive = true,
  }) {
    return PropertyModel(
      id: id,
      ownerId: ownerId,
      name: name,
      description: description,
      location: location,
      createdAt: DateTime.utc(2025),
      isActive: isActive,
    );
  }

  group('FirebasePropertyRepository CRUD', () {
    test('fetchProperties returns all valid properties', () async {
      final prop1 = createTestProperty(id: 'p1', name: 'Prop 1');
      final prop2 = createTestProperty(id: 'p2', name: 'Prop 2');
      final invalidProp = createTestProperty(id: '', name: 'Invalid');

      await fakeFirestore.collection('properties').doc('p1').set({
        ...prop1.toJson(),
        'id': 'p1',
      });
      await fakeFirestore.collection('properties').doc('p2').set({
        ...prop2.toJson(),
        'id': 'p2',
      });
      await fakeFirestore.collection('properties').doc('invalid').set({
        ...invalidProp.toJson(),
        'id': '',
      });

      final result = await repository.fetchProperties();

      expect(result.length, 2);
      expect(result.map((p) => p.id), containsAll(['p1', 'p2']));
    });

    test('searchProperties returns properties matching query', () async {
      final prop1 = createTestProperty(
        id: 'p1',
        name: 'Villa Marija',
        description: 'Nice villa',
      );
      final prop2 = createTestProperty(
        id: 'p2',
        name: 'Apartment Sea',
        description: 'Close to Marija',
      );
      // Using city here instead of location as the search checks p.city
      final prop3 = createTestProperty(
        id: 'p3',
        name: 'City Flat',
        description: 'Urban place',
      ).copyWith(city: 'Zagreb');

      await fakeFirestore.collection('properties').doc('p1').set({
        ...prop1.toJson(),
        'id': 'p1',
      });
      await fakeFirestore.collection('properties').doc('p2').set({
        ...prop2.toJson(),
        'id': 'p2',
      });
      await fakeFirestore.collection('properties').doc('p3').set({
        ...prop3.toJson(),
        'id': 'p3',
      });

      final result1 = await repository.searchProperties('marija');
      expect(result1.length, 2);
      expect(result1.map((p) => p.id), containsAll(['p1', 'p2']));

      final result2 = await repository.searchProperties('zagreb');
      expect(result2.length, 1);
      expect(result2.first.id, 'p3');
    });

    test(
      'getFeaturedProperties returns active properties ordered by rating limit',
      () async {
        final p1 = createTestProperty(
          id: 'p1',
          isActive: true,
        ).copyWith(rating: 4.5);
        final p2 = createTestProperty(
          id: 'p2',
          isActive: true,
        ).copyWith(rating: 5.0);
        final p3 = createTestProperty(
          id: 'p3',
          isActive: false,
        ).copyWith(rating: 4.8);

        await fakeFirestore.collection('properties').doc('p1').set(p1.toJson());
        await fakeFirestore.collection('properties').doc('p2').set(p2.toJson());
        await fakeFirestore.collection('properties').doc('p3').set(p3.toJson());

        final featured = await repository.getFeaturedProperties(limit: 10);

        expect(featured.length, 2);
        expect(featured.first.id, 'p2'); // Highest rating first
        expect(featured.last.id, 'p1');
      },
    );

    test(
      'getNearbyProperties calculates distance and filters correctly',
      () async {
        // Create properties with GeoPoint coordinates
        final centerLat = 45.0;
        final centerLng = 15.0;

        // Close property (~11km) -> Note, my manually created close distance might be slightly off. Let's make it definitely close.
        // 1 degree lat is ~111km. So 0.05 degree is ~5.5km
        final pClose = createTestProperty(
          id: 'p1',
        ).copyWith(latlng: const GeoPoint(45.05, 15.0));

        // Far property
        final pFar = createTestProperty(
          id: 'p2',
        ).copyWith(latlng: const GeoPoint(46.0, 16.0));

        // No coordinates
        final pNoCoords = createTestProperty(id: 'p3');

        await fakeFirestore
            .collection('properties')
            .doc('p1')
            .set(pClose.toJson());
        await fakeFirestore
            .collection('properties')
            .doc('p2')
            .set(pFar.toJson());
        await fakeFirestore
            .collection('properties')
            .doc('p3')
            .set(pNoCoords.toJson());

        final nearby = await repository.getNearbyProperties(
          latitude: centerLat,
          longitude: centerLng,
          radiusKm: 10.0,
        );

        expect(nearby.length, 1);
        expect(nearby.first.id, 'p1');
      },
    );

    test('togglePropertyStatus updates isActive flag', () async {
      final property = createTestProperty(id: 'p1', isActive: true);
      await fakeFirestore
          .collection('properties')
          .doc('p1')
          .set(property.toJson());

      final updated = await repository.togglePropertyStatus('p1', false);
      expect(updated.isActive, false);

      final doc = await fakeFirestore.collection('properties').doc('p1').get();
      expect(doc.data()!['is_active'], false);
    });

    test('togglePropertyStatus throws exception if not found', () async {
      expect(
        () => repository.togglePropertyStatus('nonexistent', false),
        throwsA(isA<Exception>()),
      );
    });

    test('updatePropertyRating updates rating and review count', () async {
      final property = createTestProperty(id: 'p1');
      await fakeFirestore
          .collection('properties')
          .doc('p1')
          .set(property.toJson());

      final updated = await repository.updatePropertyRating('p1', 4.5, 10);
      expect(updated.rating, 4.5);
      expect(updated.reviewCount, 10);

      final doc = await fakeFirestore.collection('properties').doc('p1').get();
      expect(doc.data()!['rating'], 4.5);
      expect(doc.data()!['review_count'], 10);
    });

    test('updatePropertyRating throws exception if not found', () async {
      expect(
        () => repository.updatePropertyRating('nonexistent', 4.5, 10),
        throwsA(isA<Exception>()),
      );
    });

    test('fetchPropertyBySubdomain returns correct property', () async {
      final p1 = createTestProperty(
        id: 'p1',
      ).copyWith(subdomain: 'test-subdomain');
      final p2 = createTestProperty(id: 'p2').copyWith(subdomain: 'other');

      await fakeFirestore.collection('properties').doc('p1').set(p1.toJson());
      await fakeFirestore.collection('properties').doc('p2').set(p2.toJson());

      final fetched = await repository.fetchPropertyBySubdomain(
        'test-subdomain',
      );

      expect(fetched, isNotNull);
      expect(fetched!.id, 'p1');

      final notFound = await repository.fetchPropertyBySubdomain('missing');
      expect(notFound, isNull);
    });

    test(
      'createProperty adds property to firestore and returns with id',
      () async {
        final property = createTestProperty(id: ''); // ID will be generated

        final created = await repository.createProperty(property);

        expect(created.id, isNotEmpty);
        expect(created.name, property.name);

        final doc = await fakeFirestore
            .collection('properties')
            .doc(created.id)
            .get();
        expect(doc.exists, true);
        expect(doc.data()!['name'], property.name);
      },
    );

    test('fetchPropertyById returns property when it exists', () async {
      final property = createTestProperty(id: 'prop123');
      await fakeFirestore
          .collection('properties')
          .doc('prop123')
          .set(property.toJson());

      final fetched = await repository.fetchPropertyById('prop123');

      expect(fetched, isNotNull);
      expect(fetched!.id, 'prop123');
      expect(fetched.name, property.name);
    });

    test('fetchPropertyById returns null when it does not exist', () async {
      final fetched = await repository.fetchPropertyById('nonexistent');
      expect(fetched, isNull);
    });

    test('updateProperty updates existing property in firestore', () async {
      final property = createTestProperty(id: 'prop123', name: 'Original Name');
      await fakeFirestore
          .collection('properties')
          .doc('prop123')
          .set(property.toJson());

      final updatedProperty = property.copyWith(name: 'Updated Name');
      final result = await repository.updateProperty(updatedProperty);

      expect(result.name, 'Updated Name');

      final doc = await fakeFirestore
          .collection('properties')
          .doc('prop123')
          .get();
      expect(doc.data()!['name'], 'Updated Name');
    });

    test('deleteProperty removes property from firestore', () async {
      final property = createTestProperty(id: 'prop123');
      await fakeFirestore
          .collection('properties')
          .doc('prop123')
          .set(property.toJson());

      await repository.deleteProperty('prop123');

      final doc = await fakeFirestore
          .collection('properties')
          .doc('prop123')
          .get();
      expect(doc.exists, false);
    });

    test(
      'fetchPropertiesByOwner returns properties for specific owner',
      () async {
        final prop1 = createTestProperty(id: 'p1', ownerId: 'owner1');
        final prop2 = createTestProperty(id: 'p2', ownerId: 'owner1');
        final prop3 = createTestProperty(id: 'p3', ownerId: 'owner2');

        await fakeFirestore
            .collection('properties')
            .doc('p1')
            .set(prop1.toJson());
        await fakeFirestore
            .collection('properties')
            .doc('p2')
            .set(prop2.toJson());
        await fakeFirestore
            .collection('properties')
            .doc('p3')
            .set(prop3.toJson());

        final owner1Props = await repository.fetchPropertiesByOwner('owner1');

        expect(owner1Props.length, 2);
        expect(owner1Props.map((p) => p.id), containsAll(['p1', 'p2']));

        final owner2Props = await repository.fetchPropertiesByOwner('owner2');
        expect(owner2Props.length, 1);
        expect(owner2Props.first.id, 'p3');
      },
    );
  });
}
