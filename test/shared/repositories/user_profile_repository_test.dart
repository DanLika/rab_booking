import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookbed/shared/repositories/user_profile_repository.dart';
import 'package:bookbed/shared/models/user_profile_model.dart';
import 'package:bookbed/shared/models/notification_preferences_model.dart';
import 'package:bookbed/core/exceptions/app_exceptions.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late UserProfileRepository repository;

  const testUserId = 'user123';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = UserProfileRepository(firestore: fakeFirestore);
  });

  group('UserProfileRepository', () {
    group('UserProfile', () {
      final testProfile = UserProfile(
        userId: testUserId,
        displayName: 'Test User',
        emailContact: 'test@example.com',
        phoneE164: '+385911234567',
        address: const Address(
          country: 'Croatia',
          city: 'Zagreb',
          street: 'Test Street 1',
        ),
        propertyType: 'Apartment',
        logoUrl: 'https://example.com/logo.png',
      );

      test('getUserProfile returns null when document does not exist', () async {
        final profile = await repository.getUserProfile(testUserId);
        expect(profile, isNull);
      });

      test('getUserProfile returns profile when document exists', () async {
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('profile')
            .set(testProfile.toFirestore());

        final profile = await repository.getUserProfile(testUserId);

        expect(profile, isNotNull);
        expect(profile!.userId, testUserId);
        expect(profile.displayName, 'Test User');
        expect(profile.emailContact, 'test@example.com');
      });

      test('watchUserProfile emits null when document does not exist', () async {
        final stream = repository.watchUserProfile(testUserId);
        final profile = await stream.first;
        expect(profile, isNull);
      });

      test('watchUserProfile emits profile when document exists', () async {
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('profile')
            .set(testProfile.toFirestore());

        final stream = repository.watchUserProfile(testUserId);
        final profile = await stream.first;

        expect(profile, isNotNull);
        expect(profile!.displayName, 'Test User');
      });

      test('updateUserProfile creates new document or updates existing one', () async {
        await repository.updateUserProfile(testProfile);

        final doc = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('profile')
            .get();

        expect(doc.exists, true);
        expect(doc.data()!['displayName'], 'Test User');
        expect(doc.data()!['emailContact'], 'test@example.com');
      });

      test('completionPercentage calculates correctly', () {
        // Empty profile (0/7 = 0%)
        expect(const UserProfile(userId: '1').completionPercentage, 0);

        // Partially filled profile (4/7 = ~57%)
        final partialProfile = const UserProfile(
          userId: '1',
          displayName: 'Test',
          emailContact: 'test@example.com',
          phoneE164: '+123',
          propertyType: 'Apartment',
        );
        expect(partialProfile.completionPercentage, 57);

        // Fully filled profile (7/7 = 100%)
        final fullProfile = UserProfile(
          userId: '1',
          displayName: 'Test',
          emailContact: 'test@example.com',
          phoneE164: '+123',
          address: const Address(country: 'Country', city: 'City'),
          propertyType: 'Apartment',
          logoUrl: 'url',
        );
        expect(fullProfile.completionPercentage, 100);
      });
    });

    group('CompanyDetails', () {
      final testCompany = CompanyDetails(
        companyName: 'Test Company',
        taxId: '123456789',
        vatId: 'HR123456789',
        bankAccountIban: 'HR1234567890123456789',
        swift: 'TESTHR2X',
        bankName: 'Test Bank',
        accountHolder: 'Test User',
      );

      test('getCompanyDetails returns null when document does not exist', () async {
        final company = await repository.getCompanyDetails(testUserId);
        expect(company, isNull);
      });

      test('getCompanyDetails returns company when document exists', () async {
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('company')
            .set({
              'companyName': testCompany.companyName,
              'taxId': testCompany.taxId,
              'vatId': testCompany.vatId,
              'bankAccountIban': testCompany.bankAccountIban,
              'swift': testCompany.swift,
              'bankName': testCompany.bankName,
              'accountHolder': testCompany.accountHolder,
              'address': testCompany.address.toJson(),
            });

        final company = await repository.getCompanyDetails(testUserId);

        expect(company, isNotNull);
        expect(company!.companyName, 'Test Company');
        expect(company.taxId, '123456789');
      });

      test('watchCompanyDetails emits null when document does not exist', () async {
        final stream = repository.watchCompanyDetails(testUserId);
        final company = await stream.first;
        expect(company, isNull);
      });

      test('updateCompanyDetails creates or updates document', () async {
        await repository.updateCompanyDetails(testUserId, testCompany);

        final doc = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('company')
            .get();

        expect(doc.exists, true);
        expect(doc.data()!['companyName'], 'Test Company');
        expect(doc.data()!['bankName'], 'Test Bank');
      });

      test('hasBankDetails returns correct status', () {
        // Complete bank details
        expect(testCompany.hasBankDetails, true);

        // Missing IBAN
        expect(testCompany.copyWith(bankAccountIban: '').hasBankDetails, false);

        // Missing bank name
        expect(testCompany.copyWith(bankName: '').hasBankDetails, false);

        // Missing account holder
        expect(testCompany.copyWith(accountHolder: '').hasBankDetails, false);
      });
    });

    group('NotificationPreferences', () {
      final testPreferences = NotificationPreferences(
        userId: testUserId,
        masterEnabled: false,
        categories: NotificationCategories(
          bookings: NotificationChannels(email: true, push: false, sms: false),
        ),
      );

      test('getNotificationPreferences returns null when document does not exist', () async {
        final prefs = await repository.getNotificationPreferences(testUserId);
        expect(prefs, isNull);
      });

      test('getNotificationPreferences returns preferences when document exists', () async {
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('preferences')
            .set(testPreferences.toFirestore());

        final prefs = await repository.getNotificationPreferences(testUserId);

        expect(prefs, isNotNull);
        expect(prefs!.masterEnabled, false);
        expect(prefs.categories.bookings.push, false);
      });

      test('watchNotificationPreferences emits null when document does not exist', () async {
        final stream = repository.watchNotificationPreferences(testUserId);
        final prefs = await stream.first;
        expect(prefs, isNull);
      });

      test('updateNotificationPreferences creates or updates document', () async {
        await repository.updateNotificationPreferences(testPreferences);

        final doc = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('preferences')
            .get();

        expect(doc.exists, true);
        expect(doc.data()!['masterEnabled'], false);
        expect(doc.data()!['categories']['bookings']['push'], false);
      });
    });

    group('Combined UserData', () {
      final testProfile = UserProfile(
        userId: testUserId,
        displayName: 'Test User',
      );

      final testCompany = CompanyDetails(
        companyName: 'Test Company',
      );

      test('getUserData returns null if profile does not exist', () async {
        final userData = await repository.getUserData(testUserId);
        expect(userData, isNull);
      });

      test('getUserData returns UserData with default company if company does not exist', () async {
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('profile')
            .set(testProfile.toFirestore());

        final userData = await repository.getUserData(testUserId);

        expect(userData, isNotNull);
        expect(userData!.profile.displayName, 'Test User');
        expect(userData.company.companyName, '');
      });

      test('getUserData returns UserData with both profile and company', () async {
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('profile')
            .set(testProfile.toFirestore());

        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('company')
            .set({
              'companyName': testCompany.companyName,
              'address': testCompany.address.toJson(),
            });

        final userData = await repository.getUserData(testUserId);

        expect(userData, isNotNull);
        expect(userData!.profile.displayName, 'Test User');
        expect(userData.company.companyName, 'Test Company');
      });

      test('watchUserData emits null when profile does not exist', () async {
        final stream = repository.watchUserData(testUserId);
        final userData = await stream.first;
        expect(userData, isNull);
      });

      test('watchUserData emits UserData when profile exists', () async {
        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('profile')
            .set(testProfile.toFirestore());

        await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('data')
            .doc('company')
            .set({
              'companyName': testCompany.companyName,
              'address': testCompany.address.toJson(),
            });

        final stream = repository.watchUserData(testUserId);
        final userData = await stream.first;

        expect(userData, isNotNull);
        expect(userData!.profile.displayName, 'Test User');
        expect(userData.company.companyName, 'Test Company');
      });
    });
  });
}
