import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bookbed/shared/repositories/user_profile_repository.dart';
import 'package:bookbed/shared/models/user_profile_model.dart';
import 'package:bookbed/shared/models/notification_preferences_model.dart';
import 'package:bookbed/core/exceptions/app_exceptions.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference<T extends Object?> extends Mock implements CollectionReference<T> {}
class MockDocumentReference<T extends Object?> extends Mock implements DocumentReference<T> {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late UserProfileRepository repository;

  final testUserId = 'test-user-id';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = UserProfileRepository(firestore: fakeFirestore);

    registerFallbackValue(SetOptions(merge: true));
  });

  group('updateUserProfile', () {
    test('successfully updates user profile', () async {
      final profile = UserProfile(
        userId: testUserId,
        displayName: 'John Doe',
        emailContact: 'john@example.com',
      );

      await repository.updateUserProfile(profile);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('data')
          .doc('profile')
          .get();

      expect(snapshot.exists, true);
      expect(snapshot.data()!['displayName'], 'John Doe');
      expect(snapshot.data()!['emailContact'], 'john@example.com');
    });

    test('throws AuthException on failure', () async {
      final mockFirestore = MockFirebaseFirestore();
      final mockCollection1 = MockCollectionReference<Map<String, dynamic>>();
      final mockDoc1 = MockDocumentReference<Map<String, dynamic>>();
      final mockCollection2 = MockCollectionReference<Map<String, dynamic>>();
      final mockDoc2 = MockDocumentReference<Map<String, dynamic>>();

      when(() => mockFirestore.collection(any())).thenReturn(mockCollection1);
      when(() => mockCollection1.doc(any())).thenReturn(mockDoc1);
      when(() => mockDoc1.collection(any())).thenReturn(mockCollection2);
      when(() => mockCollection2.doc(any())).thenReturn(mockDoc2);
      when(() => mockDoc2.set(any(), any())).thenThrow(Exception('Firestore error'));

      final errorRepo = UserProfileRepository(firestore: mockFirestore);

      final profile = UserProfile(
        userId: testUserId,
        displayName: 'John Doe',
      );

      expect(
        () => errorRepo.updateUserProfile(profile),
        throwsA(
          isA<AuthException>()
              .having((e) => e.message, 'message', 'Failed to update profile')
              .having((e) => e.code, 'code', 'auth/profile-update-failed'),
        ),
      );
    });
  });

  group('updateCompanyDetails', () {
    test('successfully updates company details', () async {
      const company = CompanyDetails(
        companyName: 'Test Company',
        taxId: '12345',
      );

      await repository.updateCompanyDetails(testUserId, company);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('data')
          .doc('company')
          .get();

      expect(snapshot.exists, true);
      expect(snapshot.data()!['companyName'], 'Test Company');
      expect(snapshot.data()!['taxId'], '12345');
    });

    test('throws AuthException on failure', () async {
      final mockFirestore = MockFirebaseFirestore();
      final mockCollection1 = MockCollectionReference<Map<String, dynamic>>();
      final mockDoc1 = MockDocumentReference<Map<String, dynamic>>();
      final mockCollection2 = MockCollectionReference<Map<String, dynamic>>();
      final mockDoc2 = MockDocumentReference<Map<String, dynamic>>();

      when(() => mockFirestore.collection(any())).thenReturn(mockCollection1);
      when(() => mockCollection1.doc(any())).thenReturn(mockDoc1);
      when(() => mockDoc1.collection(any())).thenReturn(mockCollection2);
      when(() => mockCollection2.doc(any())).thenReturn(mockDoc2);
      when(() => mockDoc2.set(any(), any())).thenThrow(Exception('Firestore error'));

      final errorRepo = UserProfileRepository(firestore: mockFirestore);

      const company = CompanyDetails(
        companyName: 'Test Company',
      );

      expect(
        () => errorRepo.updateCompanyDetails(testUserId, company),
        throwsA(
          isA<AuthException>()
              .having((e) => e.message, 'message', 'Failed to update company details')
              .having((e) => e.code, 'code', 'auth/company-update-failed'),
        ),
      );
    });
  });

  group('updateNotificationPreferences', () {
    test('successfully updates notification preferences', () async {
      final preferences = NotificationPreferences(
        userId: testUserId,
        masterEnabled: false,
      );

      await repository.updateNotificationPreferences(preferences);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('data')
          .doc('preferences')
          .get();

      expect(snapshot.exists, true);
      expect(snapshot.data()!['masterEnabled'], false);
    });

    test('throws AuthException on failure', () async {
      final mockFirestore = MockFirebaseFirestore();
      final mockCollection1 = MockCollectionReference<Map<String, dynamic>>();
      final mockDoc1 = MockDocumentReference<Map<String, dynamic>>();
      final mockCollection2 = MockCollectionReference<Map<String, dynamic>>();
      final mockDoc2 = MockDocumentReference<Map<String, dynamic>>();

      when(() => mockFirestore.collection(any())).thenReturn(mockCollection1);
      when(() => mockCollection1.doc(any())).thenReturn(mockDoc1);
      when(() => mockDoc1.collection(any())).thenReturn(mockCollection2);
      when(() => mockCollection2.doc(any())).thenReturn(mockDoc2);
      when(() => mockDoc2.set(any(), any())).thenThrow(Exception('Firestore error'));

      final errorRepo = UserProfileRepository(firestore: mockFirestore);

      final preferences = NotificationPreferences(
        userId: testUserId,
      );

      expect(
        () => errorRepo.updateNotificationPreferences(preferences),
        throwsA(
          isA<AuthException>()
              .having((e) => e.message, 'message', 'Failed to update notification preferences')
              .having((e) => e.code, 'code', 'auth/preferences-update-failed'),
        ),
      );
    });
  });
}
