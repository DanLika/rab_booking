import 'package:bookbed/shared/models/notification_preferences_model.dart';
import 'package:bookbed/shared/models/user_profile_model.dart';
import 'package:bookbed/shared/repositories/user_profile_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late UserProfileRepository repository;

  const String userId = 'test_user_id';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = UserProfileRepository(firestore: fakeFirestore);
  });

  group('UserProfileRepository - UserProfile', () {
    test('getUserProfile returns null if document does not exist', () async {
      final profile = await repository.getUserProfile(userId);
      expect(profile, isNull);
    });

    test('getUserProfile returns parsed UserProfile if document exists', () async {
      final data = {
        'displayName': 'John Doe',
        'emailContact': 'john@example.com',
        'propertyType': 'Villa',
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      };

      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('profile')
          .set(data);

      final profile = await repository.getUserProfile(userId);

      expect(profile, isNotNull);
      expect(profile?.userId, userId);
      expect(profile?.displayName, 'John Doe');
      expect(profile?.emailContact, 'john@example.com');
      expect(profile?.propertyType, 'Villa');
      expect(profile?.updatedAt, DateTime(2024, 1, 1));
    });

    test('watchUserProfile emits stream of changes', () async {
      final stream = repository.watchUserProfile(userId);

      final events = <UserProfile?>[];
      final subscription = stream.listen((profile) {
        events.add(profile);
      });

      // Allow stream to emit initial state
      await Future.delayed(Duration.zero);
      expect(events.first, isNull);

      final data = {
        'displayName': 'Jane Doe',
      };

      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('profile')
          .set(data);

      // Allow stream to emit new state
      await Future.delayed(Duration.zero);

      expect(events.length, greaterThan(1));
      expect(events.last?.displayName, 'Jane Doe');

      await subscription.cancel();
    });

    test('updateUserProfile correctly saves profile data', () async {
      const profileToSave = UserProfile(
        userId: userId,
        displayName: 'Test User',
        emailContact: 'test@example.com',
        phoneE164: '+1234567890',
      );

      await repository.updateUserProfile(profileToSave);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('profile')
          .get();

      expect(snapshot.exists, isTrue);
      final data = snapshot.data()!;
      expect(data['displayName'], 'Test User');
      expect(data['emailContact'], 'test@example.com');
      expect(data['phoneE164'], '+1234567890');
      expect(data.containsKey('updatedAt'), isTrue);
    });
  });

  group('UserProfileRepository - CompanyDetails', () {
    test('getCompanyDetails returns null if document does not exist', () async {
      final company = await repository.getCompanyDetails(userId);
      expect(company, isNull);
    });

    test('getCompanyDetails returns parsed CompanyDetails if document exists', () async {
      final data = {
        'companyName': 'My Company LLC',
        'taxId': '12345678',
        'vatId': 'HR12345678901',
      };

      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('company')
          .set(data);

      final company = await repository.getCompanyDetails(userId);

      expect(company, isNotNull);
      expect(company?.companyName, 'My Company LLC');
      expect(company?.taxId, '12345678');
      expect(company?.vatId, 'HR12345678901');
    });

    test('updateCompanyDetails correctly saves company data', () async {
      const companyToSave = CompanyDetails(
        companyName: 'Update Corp',
        vatId: 'VAT123',
        bankAccountIban: 'HR991234567890',
      );

      await repository.updateCompanyDetails(userId, companyToSave);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('company')
          .get();

      expect(snapshot.exists, isTrue);
      final data = snapshot.data()!;
      expect(data['companyName'], 'Update Corp');
      expect(data['vatId'], 'VAT123');
      expect(data['bankAccountIban'], 'HR991234567890');
      expect(data.containsKey('updatedAt'), isTrue);
    });
  });

  group('UserProfileRepository - NotificationPreferences', () {
    test('getNotificationPreferences returns null if document does not exist', () async {
      final preferences = await repository.getNotificationPreferences(userId);
      expect(preferences, isNull);
    });

    test('getNotificationPreferences returns parsed NotificationPreferences if document exists', () async {
      final data = {
        'masterEnabled': false,
        'categories': {
          'bookings': {'email': false, 'push': true, 'sms': false},
        }
      };

      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('preferences')
          .set(data);

      final preferences = await repository.getNotificationPreferences(userId);

      expect(preferences, isNotNull);
      expect(preferences?.userId, userId);
      expect(preferences?.masterEnabled, isFalse);
      expect(preferences?.categories.bookings.email, isFalse);
      expect(preferences?.categories.bookings.push, isTrue);
    });

    test('updateNotificationPreferences correctly saves preferences data', () async {
      const prefsToSave = NotificationPreferences(
        userId: userId,
        masterEnabled: false,
      );

      await repository.updateNotificationPreferences(prefsToSave);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('preferences')
          .get();

      expect(snapshot.exists, isTrue);
      final data = snapshot.data()!;
      expect(data['masterEnabled'], isFalse);
      expect(data.containsKey('categories'), isTrue);
      expect(data.containsKey('updatedAt'), isTrue);
    });
  });

  group('UserProfileRepository - Combined Data (UserData)', () {
    test('getUserData returns null if profile document does not exist', () async {
      final userData = await repository.getUserData(userId);
      expect(userData, isNull);
    });

    test('getUserData returns combined profile and company details', () async {
      final profileData = {'displayName': 'Test User'};
      final companyData = {'companyName': 'Test Company'};

      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('profile')
          .set(profileData);

      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('company')
          .set(companyData);

      final userData = await repository.getUserData(userId);

      expect(userData, isNotNull);
      expect(userData?.profile.displayName, 'Test User');
      expect(userData?.company.companyName, 'Test Company');
    });
  });
}
