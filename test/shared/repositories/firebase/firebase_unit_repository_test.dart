import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bookbed/shared/repositories/firebase/firebase_unit_repository.dart';
import 'package:bookbed/shared/models/unit_model.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('FirebaseUnitRepository.fetchUnitByIdFresh', () {
    late MockFirebaseFirestore mockFirestore;
    late FirebaseUnitRepository repository;

    late MockCollectionReference mockPropertiesCollection;
    late MockDocumentReference mockPropertyDoc;
    late MockCollectionReference mockUnitsCollection;
    late MockDocumentReference mockUnitDoc;

    setUpAll(() {
      registerFallbackValue(const GetOptions(source: Source.server));
    });

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      repository = FirebaseUnitRepository(mockFirestore);

      mockPropertiesCollection = MockCollectionReference();
      mockPropertyDoc = MockDocumentReference();
      mockUnitsCollection = MockCollectionReference();
      mockUnitDoc = MockDocumentReference();

      when(() => mockFirestore.collection('properties')).thenReturn(mockPropertiesCollection);
      when(() => mockPropertiesCollection.doc(any())).thenReturn(mockPropertyDoc);
      when(() => mockPropertyDoc.id).thenReturn('test-property-id');
      when(() => mockPropertyDoc.collection('units')).thenReturn(mockUnitsCollection);
      when(() => mockUnitsCollection.doc(any())).thenReturn(mockUnitDoc);
    });

    test('should return unit when document exists and passes GetOptions(source: Source.server)', () async {
      final mockDocSnapshot = MockDocumentSnapshot();
      when(() => mockUnitDoc.get(any())).thenAnswer((_) async => mockDocSnapshot);
      when(() => mockDocSnapshot.exists).thenReturn(true);
      when(() => mockDocSnapshot.id).thenReturn('test-unit-id');
      when(() => mockDocSnapshot.data()).thenReturn({
        'name': 'Test Unit',
        'base_price': 150.0,
        'max_guests': 2,
        'created_at': Timestamp.now(),
        'is_available': true,
        'created_at': Timestamp.now(),
      });

      final result = await repository.fetchUnitByIdFresh(
        propertyId: 'test-property-id',
        unitId: 'test-unit-id',
      );

      // Verify that get() was called exactly once with Source.server
      verify(() => mockUnitDoc.get(const GetOptions(source: Source.server))).called(1);

      expect(result, isA<UnitModel>());
      expect(result?.id, 'test-unit-id');
      expect(result?.propertyId, 'test-property-id');
      expect(result?.name, 'Test Unit');
      expect(result?.pricePerNight, 150.0);
    });

    test('should return null when document does not exist', () async {
      final mockDocSnapshot = MockDocumentSnapshot();
      when(() => mockUnitDoc.get(any())).thenAnswer((_) async => mockDocSnapshot);
      when(() => mockDocSnapshot.exists).thenReturn(false);

      final result = await repository.fetchUnitByIdFresh(
        propertyId: 'test-property-id',
        unitId: 'test-unit-id',
      );

      verify(() => mockUnitDoc.get(const GetOptions(source: Source.server))).called(1);
      expect(result, isNull);
    });

    test('should fall back to fetchUnitById when FirebaseException(unavailable) is thrown', () async {
      // Mock the fresh fetch to throw
      when(() => mockUnitDoc.get(any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      // Mock the fallback fetchUnitById behavior
      final mockCollectionGroup = MockQuerySnapshot();
      final mockQueryDocSnapshot = MockQueryDocumentSnapshot();
      final mockParentRef = MockDocumentReference();
      final mockGrandparentRef = MockDocumentReference();

      when(() => mockFirestore.collectionGroup('units'))
          .thenReturn(mockUnitsCollection as dynamic); // collectionGroup returns Query, CollectionReference is a Query
      when(() => (mockUnitsCollection as dynamic).get())
          .thenAnswer((_) async => mockCollectionGroup);
      when(() => mockCollectionGroup.docs).thenReturn([mockQueryDocSnapshot]);
      when(() => mockQueryDocSnapshot.id).thenReturn('test-unit-id');
      when(() => mockQueryDocSnapshot.reference).thenReturn(mockUnitDoc);
      when(() => mockUnitDoc.parent).thenReturn(mockUnitsCollection);
      when(() => mockUnitsCollection.parent).thenReturn(mockPropertyDoc);
      when(() => mockGrandparentRef.id).thenReturn('test-property-id');

      when(() => mockQueryDocSnapshot.data()).thenReturn({
        'name': 'Fallback Unit',
        'base_price': 100.0,
        'max_guests': 2,
        'created_at': Timestamp.now(),
      });

      final result = await repository.fetchUnitByIdFresh(
        propertyId: 'test-property-id',
        unitId: 'test-unit-id',
      );

      verify(() => mockUnitDoc.get(const GetOptions(source: Source.server))).called(1);
      verify(() => mockFirestore.collectionGroup('units')).called(1);

      expect(result, isA<UnitModel>());
      expect(result?.id, 'test-unit-id');
      expect(result?.name, 'Fallback Unit');
    });

    test('should rethrow FirebaseException if code is not unavailable', () async {
      when(() => mockUnitDoc.get(any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );

      expect(
        () => repository.fetchUnitByIdFresh(
          propertyId: 'test-property-id',
          unitId: 'test-unit-id',
        ),
        throwsA(isA<FirebaseException>().having((e) => e.code, 'code', 'permission-denied')),
      );

      verify(() => mockUnitDoc.get(const GetOptions(source: Source.server))).called(1);
    });
  });
}
