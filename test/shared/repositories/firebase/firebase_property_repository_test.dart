import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/shared/repositories/firebase/firebase_property_repository.dart';
// ignore_for_file: avoid_redundant_argument_values

import 'package:bookbed/shared/repositories/property_repository.dart';
import 'package:bookbed/shared/models/property_model.dart';
import 'package:bookbed/core/exceptions/app_exceptions.dart';
import 'package:bookbed/core/constants/enums.dart';

void main() {
  group('FirebasePropertyRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebasePropertyRepository repository;

    final testDate = DateTime.utc(2024, 1, 1);

    PropertyModel createTestProperty({
      String id = 'prop1',
      String name = 'Test Property',
      String? ownerId = 'owner1',
      String city = 'Zagreb',
      int maxGuests = 4,
      double pricePerNight = 100,
      double rating = 4.5,
      List<PropertyAmenity> amenities = const [PropertyAmenity.wifi],
      bool isActive = true,
      String? subdomain = 'test-prop',
      double? lat,
      double? lng,
    }) {
      return PropertyModel(
        id: id,
        name: name,
        description: 'A nice place',
        location: city,
        city: city,
        createdAt: testDate,
        ownerId: ownerId,
        maxGuests: maxGuests,
        pricePerNight: pricePerNight,
        rating: rating,
        amenities: amenities,
        isActive: isActive,
        subdomain: subdomain,
        latlng: lat != null && lng != null ? GeoPoint(lat, lng) : null,
      );
    }

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirebasePropertyRepository(fakeFirestore);
    });

    group('fetchProperties', () {
      test('returns all properties matching id != empty', () async {
        await fakeFirestore.collection('properties').doc('prop1').set({
          'id': 'prop1',
          'name': 'Prop 1',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });

        // This won't be returned because we're querying where id != ''
        await fakeFirestore.collection('properties').doc('prop2').set({
          'id': '',
          'name': 'Prop 2',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });

        final properties = await repository.fetchProperties();
        expect(properties.length, 1);
        expect(properties.first.id, 'prop1');
      });

      test('filters by ownerId', () async {
        await fakeFirestore.collection('properties').doc('prop1').set({
          'id': 'prop1',
          'owner_id': 'owner1',
          'name': 'Prop 1',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });
        await fakeFirestore.collection('properties').doc('prop2').set({
          'id': 'prop2',
          'owner_id': 'owner2',
          'name': 'Prop 2',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });

        final properties = await repository.fetchProperties(
          const PropertyFilters(ownerId: 'owner1'),
        );
        expect(properties.length, 1);
        expect(properties.first.id, 'prop1');
      });

      test('filters by location (city)', () async {
        await fakeFirestore.collection('properties').doc('prop1').set({
          'id': 'prop1',
          'city': 'Zagreb',
          'name': 'Prop 1',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });
        await fakeFirestore.collection('properties').doc('prop2').set({
          'id': 'prop2',
          'city': 'Split',
          'name': 'Prop 2',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });

        final properties = await repository.fetchProperties(
          const PropertyFilters(location: 'Zagreb'),
        );
        expect(properties.length, 1);
        expect(properties.first.city, 'Zagreb');
      });

      test('filters by minGuests', () async {
        await fakeFirestore.collection('properties').doc('prop1').set({
          'id': 'prop1',
          'max_guests': 2,
          'name': 'Prop 1',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });
        await fakeFirestore.collection('properties').doc('prop2').set({
          'id': 'prop2',
          'max_guests': 4,
          'name': 'Prop 2',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });

        final properties = await repository.fetchProperties(
          const PropertyFilters(minGuests: 3),
        );
        expect(properties.length, 1);
        expect(properties.first.id, 'prop2');
      });

      test('applies client-side filters (minPrice, maxPrice, minRating, amenities)', () async {
        await fakeFirestore.collection('properties').doc('prop1').set({
          'id': 'prop1',
          'base_price': 50.0,
          'rating': 3.0,
          'amenities': ['wifi'],
          'name': 'Prop 1',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });
        await fakeFirestore.collection('properties').doc('prop2').set({
          'id': 'prop2',
          'base_price': 150.0,
          'rating': 4.5,
          'amenities': ['wifi', 'pool'],
          'name': 'Prop 2',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });
        await fakeFirestore.collection('properties').doc('prop3').set({
          'id': 'prop3',
          'base_price': 100.0,
          'rating': 4.8,
          'amenities': ['wifi', 'pool'],
          'name': 'Prop 3',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });

        final properties = await repository.fetchProperties(
          const PropertyFilters(
            minPrice: 80,
            maxPrice: 120,
            minRating: 4.0,
            amenities: [PropertyAmenity.pool],
          ),
        );

        expect(properties.length, 1);
        expect(properties.first.id, 'prop3');
      });
    });

    group('fetchPropertyById', () {
      test('returns property when it exists', () async {
        await fakeFirestore.collection('properties').doc('prop1').set({
          'name': 'Test Prop',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });

        final property = await repository.fetchPropertyById('prop1');
        expect(property, isNotNull);
        expect(property!.id, 'prop1');
        expect(property.name, 'Test Prop');
      });

      test('returns null when property does not exist', () async {
        final property = await repository.fetchPropertyById('non_existent');
        expect(property, isNull);
      });
    });

    group('fetchPropertiesByOwner', () {
      test('returns properties matching ownerId', () async {
        await fakeFirestore.collection('properties').doc('prop1').set({
          'owner_id': 'owner1',
          'name': 'Test Prop',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });

        final properties = await repository.fetchPropertiesByOwner('owner1');
        expect(properties.length, 1);
        expect(properties.first.id, 'prop1');
      });
    });

    group('createProperty', () {
      test('adds property and returns it with new ID', () async {
        final propertyToCreate = createTestProperty(id: ''); // ID shouldn't matter here

        final createdProperty = await repository.createProperty(propertyToCreate);

        expect(createdProperty.id, isNotEmpty);

        final doc = await fakeFirestore.collection('properties').doc(createdProperty.id).get();
        expect(doc.exists, isTrue);
        expect(doc.data()!['name'], 'Test Property');
      });
    });

    group('updateProperty', () {
      test('updates existing property', () async {
        await fakeFirestore.collection('properties').doc('prop1').set({
          'name': 'Old Name',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });

        final updatedModel = createTestProperty(id: 'prop1', name: 'New Name');
        await repository.updateProperty(updatedModel);

        final doc = await fakeFirestore.collection('properties').doc('prop1').get();
        expect(doc.data()!['name'], 'New Name');
      });
    });

    group('deleteProperty', () {
      test('deletes property by ID', () async {
        await fakeFirestore.collection('properties').doc('prop1').set({
          'name': 'To be deleted',
        });

        await repository.deleteProperty('prop1');

        final doc = await fakeFirestore.collection('properties').doc('prop1').get();
        expect(doc.exists, isFalse);
      });
    });

    group('searchProperties', () {
      test('searches locally by name, description, address, and city', () async {
        await fakeFirestore.collection('properties').doc('prop1').set({
          'name': 'Sunny Villa',
          'description': 'Beautiful place',
          'address': 'Main St 1',
          'city': 'Split',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });
        await fakeFirestore.collection('properties').doc('prop2').set({
          'name': 'Mountain Cabin',
          'description': 'Sunny retreat',
          'address': 'High St 2',
          'city': 'Zagreb',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });

        var results = await repository.searchProperties('sunny');
        expect(results.length, 2); // Sunny Villa (name) and Mountain Cabin (description)

        results = await repository.searchProperties('split');
        expect(results.length, 1);
        expect(results.first.id, 'prop1');
      });
    });

    group('getFeaturedProperties', () {
      test('returns active properties ordered by rating', () async {
        await fakeFirestore.collection('properties').doc('prop1').set({
          'is_active': true,
          'rating': 4.0,
          'name': 'Prop 1',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });
        await fakeFirestore.collection('properties').doc('prop2').set({
          'is_active': true,
          'rating': 4.8,
          'name': 'Prop 2',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });
        await fakeFirestore.collection('properties').doc('prop3').set({
          'is_active': false,
          'rating': 5.0,
          'name': 'Prop 3',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });

        final properties = await repository.getFeaturedProperties(limit: 2);
        expect(properties.length, 2);
        expect(properties.first.id, 'prop2'); // Highest active rating
        expect(properties.last.id, 'prop1');
      });
    });

    group('getNearbyProperties', () {
      test('returns properties within radius', () async {
        await fakeFirestore.collection('properties').doc('prop1').set({
          'latlng': const GeoPoint(45.8150, 15.9819), // Zagreb center
          'name': 'Zagreb Center',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });
        await fakeFirestore.collection('properties').doc('prop2').set({
          'latlng': const GeoPoint(45.7950, 15.9900), // Zagreb south (close)
          'name': 'Zagreb South',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });
        await fakeFirestore.collection('properties').doc('prop3').set({
          'latlng': const GeoPoint(43.5081, 16.4402), // Split (far)
          'name': 'Split',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });

        // Search near Zagreb center, 10km radius
        final properties = await repository.getNearbyProperties(
          latitude: 45.8150,
          longitude: 15.9819,
          radiusKm: 10,
        );

        expect(properties.length, 2);
        expect(properties.map((p) => p.id), containsAll(['prop1', 'prop2']));
      });
    });

    group('togglePropertyStatus', () {
      test('toggles is_active flag', () async {
        await fakeFirestore.collection('properties').doc('prop1').set({
          'is_active': false,
          'name': 'Prop 1',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });

        final updated = await repository.togglePropertyStatus('prop1', true);
        expect(updated.isActive, isTrue);

        final doc = await fakeFirestore.collection('properties').doc('prop1').get();
        expect(doc.data()!['is_active'], isTrue);
      });

      test('throws PropertyException if not found', () async {
        expect(
          () => repository.togglePropertyStatus('non_existent', true),
          throwsA(isA<PropertyException>()),
        );
      });
    });

    group('updatePropertyRating', () {
      test('updates rating and review_count', () async {
        await fakeFirestore.collection('properties').doc('prop1').set({
          'rating': 4.0,
          'review_count': 10,
          'name': 'Prop 1',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });

        final updated = await repository.updatePropertyRating('prop1', 4.5, 11);
        expect(updated.rating, 4.5);
        expect(updated.reviewCount, 11);

        final doc = await fakeFirestore.collection('properties').doc('prop1').get();
        expect(doc.data()!['rating'], 4.5);
        expect(doc.data()!['review_count'], 11);
      });

      test('throws PropertyException if not found', () async {
        expect(
          () => repository.updatePropertyRating('non_existent', 5.0, 1),
          throwsA(isA<PropertyException>()),
        );
      });
    });

    group('fetchPropertyBySubdomain', () {
      test('returns property when subdomain matches', () async {
        await fakeFirestore.collection('properties').doc('prop1').set({
          'subdomain': 'my-villa',
          'name': 'Prop 1',
          'description': '',
          'location': '',
          'created_at': Timestamp.fromDate(testDate),
        });

        final property = await repository.fetchPropertyBySubdomain('my-villa');
        expect(property, isNotNull);
        expect(property!.id, 'prop1');
      });

      test('returns null when no matching subdomain', () async {
        final property = await repository.fetchPropertyBySubdomain('non-existent');
        expect(property, isNull);
      });
    });
  });
}
