import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookbed/shared/repositories/user_profile_repository.dart';
import 'package:bookbed/shared/models/user_profile_model.dart';
import 'package:bookbed/core/exceptions/app_exceptions.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockUsersCollection;
  late MockDocumentReference mockUserDoc;
  late MockCollectionReference mockDataCollection;
  late MockDocumentReference mockProfileDoc;
  late UserProfileRepository repository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockUsersCollection = MockCollectionReference();
    mockUserDoc = MockDocumentReference();
    mockDataCollection = MockCollectionReference();
    mockProfileDoc = MockDocumentReference();

    when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
    when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDoc);
    when(() => mockUserDoc.collection('data')).thenReturn(mockDataCollection);
    when(() => mockDataCollection.doc('profile')).thenReturn(mockProfileDoc);

    // Register fallback value for SetOptions
    registerFallbackValue(SetOptions(merge: true));

    repository = UserProfileRepository(firestore: mockFirestore);
  });

  group('updateUserProfile', () {
    final testProfile = UserProfile(
      userId: 'test-user-id',
      displayName: 'Test User',
      emailContact: 'test@example.com',
    );

    test('successfully updates user profile', () async {
      when(() => mockProfileDoc.set(any(), any())).thenAnswer((_) async => {});

      await expectLater(repository.updateUserProfile(testProfile), completes);

      verify(() => mockProfileDoc.set(
        testProfile.toFirestore(),
        any(that: isA<SetOptions>()),
      )).called(1);
    });

    test('throws AuthException when Firestore throws an error', () async {
      final firestoreException = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      );

      when(() => mockProfileDoc.set(any(), any())).thenThrow(firestoreException);

      await expectLater(
        () => repository.updateUserProfile(testProfile),
        throwsA(
          isA<AuthException>()
            .having((e) => e.code, 'code', 'auth/profile-update-failed')
            .having((e) => e.message, 'message', 'Failed to update profile')
            .having((e) => e.originalError, 'originalError', firestoreException),
        ),
      );

      verify(() => mockProfileDoc.set(
        testProfile.toFirestore(),
        any(that: isA<SetOptions>()),
      )).called(1);
    });
  });
}
