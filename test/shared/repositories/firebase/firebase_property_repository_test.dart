import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:bookbed/shared/repositories/firebase/firebase_property_repository.dart';
import 'package:bookbed/shared/repositories/property_repository.dart';
import 'package:bookbed/shared/models/property_model.dart';
import 'package:bookbed/core/constants/enums.dart';
import 'package:bookbed/core/exceptions/app_exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebasePropertyRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FirebasePropertyRepository(fakeFirestore);
  });

  PropertyModel createTestProperty({
    required String id,
    String? ownerId,
    String name = 'Test Property',
    String? city,
    int? maxGuests,
    double? pricePerNight,
    double rating = 0.0,
    List<PropertyAmenity> amenities = const [],
    bool isActive = true,
    String? subdomain,
    GeoPoint? latlng,
  }) {
    return PropertyModel(
      id: id,
      ownerId: ownerId,
      name: name,
      description: 'A test property',
      location: city ?? 'Test Location',
      city: city,
      maxGuests: maxGuests,
      pricePerNight: pricePerNight,
      rating: rating,
      amenities: amenities,
      isActive: isActive,
      subdomain: subdomain,
      latlng: latlng,
      createdAt: DateTime.now(),
    );
  }

  Future<void> seedProperty(PropertyModel property) async {
    // Explicitly include the ID in the seeded data
    final data = property.toJson();
    data['id'] = property.id;
    await fakeFirestore.collection('properties').doc(property.id).set(data);
  }

  group('FirebasePropertyRepository', () {
    test('initializes correctly', () {
      expect(repository, isNotNull);
    });

    group('fetchProperties', () {
      test('fetches all properties when no filters applied', () async {
        await seedProperty(createTestProperty(id: 'prop1'));
        await seedProperty(createTestProperty(id: 'prop2'));

        final properties = await repository.fetchProperties();

        expect(properties.length, 2);
        expect(properties.map((p) => p.id), containsAll(['prop1', 'prop2']));
      });

      test('filters by ownerId', () async {
        await seedProperty(createTestProperty(id: 'prop1', ownerId: 'owner1'));
        await seedProperty(createTestProperty(id: 'prop2', ownerId: 'owner2'));

        final filters = PropertyFilters(ownerId: 'owner1');
        final properties = await repository.fetchProperties(filters);

        expect(properties.length, 1);
        expect(properties.first.id, 'prop1');
      });

      test('filters by location (city)', () async {
        await seedProperty(createTestProperty(id: 'prop1', city: 'Split'));
        await seedProperty(createTestProperty(id: 'prop2', city: 'Zadar'));

        final filters = PropertyFilters(location: 'Split');
        final properties = await repository.fetchProperties(filters);

        expect(properties.length, 1);
        expect(properties.first.id, 'prop1');
      });

      test('filters by minGuests', () async {
        await seedProperty(createTestProperty(id: 'prop1', maxGuests: 2));
        await seedProperty(createTestProperty(id: 'prop2', maxGuests: 4));

        final filters = PropertyFilters(minGuests: 3);
        final properties = await repository.fetchProperties(filters);

        expect(properties.length, 1);
        expect(properties.first.id, 'prop2');
      });

      test('filters by minPrice and maxPrice (client-side)', () async {
        await seedProperty(createTestProperty(id: 'prop1', pricePerNight: 50));
        await seedProperty(createTestProperty(id: 'prop2', pricePerNight: 100));
        await seedProperty(createTestProperty(id: 'prop3', pricePerNight: 150));

        final filters = PropertyFilters(minPrice: 60, maxPrice: 120);
        final properties = await repository.fetchProperties(filters);

        expect(properties.length, 1);
        expect(properties.first.id, 'prop2');
      });

      test('filters by minRating (client-side)', () async {
        await seedProperty(createTestProperty(id: 'prop1', rating: 3.0));
        await seedProperty(createTestProperty(id: 'prop2', rating: 4.5));

        final filters = PropertyFilters(minRating: 4.0);
        final properties = await repository.fetchProperties(filters);

        expect(properties.length, 1);
        expect(properties.first.id, 'prop2');
      });

      test('filters by amenities (client-side)', () async {
        await seedProperty(createTestProperty(
          id: 'prop1',
          amenities: [PropertyAmenity.wifi]
        ));
        await seedProperty(createTestProperty(
          id: 'prop2',
          amenities: [PropertyAmenity.wifi, PropertyAmenity.pool]
        ));

        final filters = PropertyFilters(
          amenities: [PropertyAmenity.wifi, PropertyAmenity.pool]
        );
        final properties = await repository.fetchProperties(filters);

        expect(properties.length, 1);
        expect(properties.first.id, 'prop2');
      });
    });

    group('fetchPropertyById', () {
      test('returns property when found', () async {
        await seedProperty(createTestProperty(id: 'prop1', name: 'Villa Test'));

        final property = await repository.fetchPropertyById('prop1');

        expect(property, isNotNull);
        expect(property?.id, 'prop1');
        expect(property?.name, 'Villa Test');
      });

      test('returns null when not found', () async {
        final property = await repository.fetchPropertyById('non_existent');

        expect(property, isNull);
      });
    });

    group('fetchPropertiesByOwner', () {
      test('returns properties for given owner', () async {
        await seedProperty(createTestProperty(id: 'prop1', ownerId: 'ownerA'));
        await seedProperty(createTestProperty(id: 'prop2', ownerId: 'ownerA'));
        await seedProperty(createTestProperty(id: 'prop3', ownerId: 'ownerB'));

        final properties = await repository.fetchPropertiesByOwner('ownerA');

        expect(properties.length, 2);
        expect(properties.map((p) => p.id), containsAll(['prop1', 'prop2']));
      });
    });

    group('fetchPropertyBySubdomain', () {
      test('returns property when subdomain matches', () async {
        await seedProperty(createTestProperty(id: 'prop1', subdomain: 'test-villa'));
        await seedProperty(createTestProperty(id: 'prop2', subdomain: 'other-villa'));

        final property = await repository.fetchPropertyBySubdomain('test-villa');

        expect(property, isNotNull);
        expect(property?.id, 'prop1');
      });

      test('returns null when subdomain not found', () async {
        final property = await repository.fetchPropertyBySubdomain('missing');

        expect(property, isNull);
      });
    });
    group('createProperty', () {
      test('adds document and returns property with generated ID', () async {
        final newProperty = createTestProperty(id: '', name: 'New Villa');

        final created = await repository.createProperty(newProperty);

        expect(created.id, isNotEmpty);
        expect(created.name, 'New Villa');

        // Verify in firestore
        final doc = await fakeFirestore.collection('properties').doc(created.id).get();
        expect(doc.exists, isTrue);
        expect(doc.data()?['name'], 'New Villa');
      });
    });

    group('updateProperty', () {
      test('updates existing document', () async {
        await seedProperty(createTestProperty(id: 'prop1', name: 'Old Name'));

        final updatedProperty = createTestProperty(id: 'prop1', name: 'New Name');
        final result = await repository.updateProperty(updatedProperty);

        expect(result.name, 'New Name');

        // Verify in firestore
        final doc = await fakeFirestore.collection('properties').doc('prop1').get();
        expect(doc.data()?['name'], 'New Name');
      });
    });

    group('deleteProperty', () {
      test('removes document from firestore', () async {
        await seedProperty(createTestProperty(id: 'prop1'));

        // Verify it exists first
        var doc = await fakeFirestore.collection('properties').doc('prop1').get();
        expect(doc.exists, isTrue);

        await repository.deleteProperty('prop1');

        // Verify it was deleted
        doc = await fakeFirestore.collection('properties').doc('prop1').get();
        expect(doc.exists, isFalse);
      });
    });
    group('searchProperties', () {
      test('filters properties by query case-insensitively', () async {
        await seedProperty(createTestProperty(id: 'prop1', name: 'Sunny Villa', city: 'Split'));
        await seedProperty(createTestProperty(id: 'prop2', name: 'Mountain Retreat', city: 'Zagreb'));

        final results = await repository.searchProperties('sun');
        expect(results.length, 1);
        expect(results.first.id, 'prop1');

        final cityResults = await repository.searchProperties('split');
        expect(cityResults.length, 1);
        expect(cityResults.first.id, 'prop1');
      });
    });

    group('getFeaturedProperties', () {
      test('returns active properties ordered by rating descending with limit', () async {
        await seedProperty(createTestProperty(id: 'prop1', rating: 3.0, isActive: true));
        await seedProperty(createTestProperty(id: 'prop2', rating: 5.0, isActive: true));
        await seedProperty(createTestProperty(id: 'prop3', rating: 4.0, isActive: true));
        await seedProperty(createTestProperty(id: 'prop4', rating: 4.8, isActive: false)); // Should be ignored

        final results = await repository.getFeaturedProperties(limit: 2);

        expect(results.length, 2);
        expect(results[0].id, 'prop2'); // rating 5.0
        expect(results[1].id, 'prop3'); // rating 4.0
      });
    });

    group('getNearbyProperties', () {
      test('filters properties by distance using haversine formula', () async {
        // Point: 45.8150, 15.9819 (Zagreb)
        await seedProperty(createTestProperty(
          id: 'zagreb_center',
          latlng: const GeoPoint(45.8150, 15.9819)
        ));

        // Point: 45.7950, 15.9719 (~2.3km from Zagreb center)
        await seedProperty(createTestProperty(
          id: 'zagreb_suburb',
          latlng: const GeoPoint(45.7950, 15.9719)
        ));

        // Point: 43.5081, 16.4402 (Split, >200km away)
        await seedProperty(createTestProperty(
          id: 'split_center',
          latlng: const GeoPoint(43.5081, 16.4402)
        ));

        // Missing latlng, should be skipped safely
        await seedProperty(createTestProperty(
          id: 'unknown_location'
        ));

        // Search near Zagreb center with 5km radius
        final nearby = await repository.getNearbyProperties(
          latitude: 45.8150,
          longitude: 15.9819,
          radiusKm: 5
        );

        expect(nearby.length, 2);
        expect(nearby.map((p) => p.id), containsAll(['zagreb_center', 'zagreb_suburb']));

        // Search near Zagreb center with 1km radius
        final veryNearby = await repository.getNearbyProperties(
          latitude: 45.8150,
          longitude: 15.9819,
          radiusKm: 1
        );

        expect(veryNearby.length, 1);
        expect(veryNearby.first.id, 'zagreb_center');
      });
    });
    group('togglePropertyStatus', () {
      test('updates isActive status and returns updated model', () async {
        await seedProperty(createTestProperty(id: 'prop1', isActive: true));

        final result = await repository.togglePropertyStatus('prop1', false);

        expect(result.isActive, isFalse);

        final doc = await fakeFirestore.collection('properties').doc('prop1').get();
        expect(doc.data()?['is_active'], isFalse);
      });

      test('throws PropertyException if document does not exist', () async {
        expect(
          () => repository.togglePropertyStatus('missing', true),
          throwsA(isA<PropertyException>()),
        );
      });
    });

    group('updatePropertyRating', () {
      test('updates rating and reviewCount and returns updated model', () async {
        await seedProperty(createTestProperty(id: 'prop1', rating: 0, isActive: true));

        final result = await repository.updatePropertyRating('prop1', 4.5, 10);

        expect(result.rating, 4.5);
        expect(result.reviewCount, 10);

        final doc = await fakeFirestore.collection('properties').doc('prop1').get();
        expect(doc.data()?['rating'], 4.5);
        expect(doc.data()?['review_count'], 10);
      });

      test('throws PropertyException if document does not exist', () async {
        expect(
          () => repository.updatePropertyRating('missing', 5.0, 1),
          throwsA(isA<PropertyException>()),
        );
      });
    });
  });
}
