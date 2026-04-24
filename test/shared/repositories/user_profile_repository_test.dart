import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:bookbed/shared/repositories/user_profile_repository.dart';
import 'package:bookbed/shared/models/user_profile_model.dart';
import 'package:bookbed/shared/models/notification_preferences_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late UserProfileRepository repository;

  const testUserId = 'test_user_123';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = UserProfileRepository(firestore: fakeFirestore);
  });

  group('UserProfileRepository', () {
    group('User Profile', () {
      test('watchUserProfile emits null when no profile exists', () async {
        final stream = repository.watchUserProfile(testUserId);
        final profile = await stream.first;
        expect(profile, isNull);
      });

      test('watchUserProfile emits profile when it exists', () async {
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('profile')
            .set({
          'displayName': 'Test User',
          'emailContact': 'test@example.com',
          'phoneE164': '+1234567890',
        });

        final stream = repository.watchUserProfile(testUserId);
        final profile = await stream.first;
        expect(profile, isNotNull);
        expect(profile!.displayName, 'Test User');
        expect(profile.emailContact, 'test@example.com');
      });

      test('getUserProfile returns null when no profile exists', () async {
        final profile = await repository.getUserProfile(testUserId);
        expect(profile, isNull);
      });

      test('getUserProfile returns profile when it exists', () async {
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('profile')
            .set({
          'displayName': 'Test User 2',
        });

        final profile = await repository.getUserProfile(testUserId);
        expect(profile, isNotNull);
        expect(profile!.displayName, 'Test User 2');
      });

      test('updateUserProfile creates or updates profile', () async {
        final profile = const UserProfile(
          userId: testUserId,
          displayName: 'Updated User',
          emailContact: 'updated@example.com',
        );

        await repository.updateUserProfile(profile);

        final doc = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('profile')
            .get();

        expect(doc.exists, true);
        expect(doc.data()!['displayName'], 'Updated User');
        expect(doc.data()!['emailContact'], 'updated@example.com');
      });
    });

    group('Company Details', () {
      test('watchCompanyDetails emits null when no company details exist', () async {
        final stream = repository.watchCompanyDetails(testUserId);
        final company = await stream.first;
        expect(company, isNull);
      });

      test('watchCompanyDetails emits company details when they exist', () async {
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('company')
            .set({
          'companyName': 'Test Company',
          'taxId': '12345',
        });

        final stream = repository.watchCompanyDetails(testUserId);
        final company = await stream.first;
        expect(company, isNotNull);
        expect(company!.companyName, 'Test Company');
        expect(company.taxId, '12345');
      });

      test('getCompanyDetails returns null when no company details exist', () async {
        final company = await repository.getCompanyDetails(testUserId);
        expect(company, isNull);
      });

      test('getCompanyDetails returns company details when they exist', () async {
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('company')
            .set({
          'companyName': 'Get Company',
        });

        final company = await repository.getCompanyDetails(testUserId);
        expect(company, isNotNull);
        expect(company!.companyName, 'Get Company');
      });

      test('updateCompanyDetails creates or updates company details', () async {
        final company = const CompanyDetails(
          companyName: 'Updated Company',
          taxId: '98765',
        );

        await repository.updateCompanyDetails(testUserId, company);

        final doc = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('company')
            .get();

        expect(doc.exists, true);
        expect(doc.data()!['companyName'], 'Updated Company');
        expect(doc.data()!['taxId'], '98765');
      });
    });

    group('Notification Preferences', () {
      test('watchNotificationPreferences emits null when no preferences exist', () async {
        final stream = repository.watchNotificationPreferences(testUserId);
        final prefs = await stream.first;
        expect(prefs, isNull);
      });

      test('watchNotificationPreferences emits preferences when they exist', () async {
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('preferences')
            .set({
          'masterEnabled': false,
        });

        final stream = repository.watchNotificationPreferences(testUserId);
        final prefs = await stream.first;
        expect(prefs, isNotNull);
        expect(prefs!.masterEnabled, false);
      });

      test('getNotificationPreferences returns null when no preferences exist', () async {
        final prefs = await repository.getNotificationPreferences(testUserId);
        expect(prefs, isNull);
      });

      test('getNotificationPreferences returns preferences when they exist', () async {
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('preferences')
            .set({
          'masterEnabled': true,
        });

        final prefs = await repository.getNotificationPreferences(testUserId);
        expect(prefs, isNotNull);
        expect(prefs!.masterEnabled, true);
      });

      test('updateNotificationPreferences creates or updates preferences', () async {
        final prefs = const NotificationPreferences(
          userId: testUserId,
          masterEnabled: false,
        );

        await repository.updateNotificationPreferences(prefs);

        final doc = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('preferences')
            .get();

        expect(doc.exists, true);
        expect(doc.data()!['masterEnabled'], false);
      });
    });

    group('Combined Data', () {
      test('getUserData returns null when profile does not exist', () async {
        final userData = await repository.getUserData(testUserId);
        expect(userData, isNull);
      });

      test('getUserData returns UserData with empty company when only profile exists', () async {
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('profile')
            .set({
          'displayName': 'Combined User',
        });

        final userData = await repository.getUserData(testUserId);
        expect(userData, isNotNull);
        expect(userData!.profile.displayName, 'Combined User');
        expect(userData.company.companyName, '');
      });

      test('getUserData returns complete UserData when both exist', () async {
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('profile')
            .set({
          'displayName': 'Complete User',
        });
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('company')
            .set({
          'companyName': 'Complete Company',
        });

        final userData = await repository.getUserData(testUserId);
        expect(userData, isNotNull);
        expect(userData!.profile.displayName, 'Complete User');
        expect(userData.company.companyName, 'Complete Company');
      });

      test('watchUserData emits null when profile does not exist', () async {
        final stream = repository.watchUserData(testUserId);

        // Wait briefly then add a dummy doc to force the stream to emit
        Future.delayed(const Duration(milliseconds: 10), () {
          fakeFirestore
              .collection('users')
              .doc(testUserId)
              .collection('data')
              .doc('dummy')
              .set({'dummy': true});
        });

        final userData = await stream.first;
        expect(userData, isNull);
      });

      test('watchUserData emits UserData when profile exists', () async {
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('profile')
            .set({
          'displayName': 'Streamed User',
        });
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('company')
            .set({
          'companyName': 'Streamed Company',
        });

        final stream = repository.watchUserData(testUserId);
        final userData = await stream.first;
        expect(userData, isNotNull);
        expect(userData!.profile.displayName, 'Streamed User');
        expect(userData.company.companyName, 'Streamed Company');
      });
    });
  });
}
