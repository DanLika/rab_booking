import 'package:bookbed/core/services/logging_service.dart';
import 'package:bookbed/features/admin/data/admin_users_repository.dart';
import 'package:bookbed/shared/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult<T> extends Mock
    implements HttpsCallableResult<T> {}

void main() {
  late AdminUsersRepository repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseFunctions mockFunctions;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    repository = AdminUsersRepository(
      firestore: fakeFirestore,
      functions: mockFunctions,
    );

    // Provide a dummy initial mock so we don't accidentally execute unmocked LoggingService
    // Since LoggingService might not be testable by default, let's verify if we need to mock it.
    // LoggingService uses static methods, so we can't easily mock it with mocktail unless we wrap it or intercept it.
    // For now we assume static calls to LoggingService.logError will just print or perform an action we can ignore in testing
    // However, if it throws, we might need a workaround.
  });

  group('AdminUsersRepository', () {
    test('getOwners retrieves paginated owners', () async {
      // Seed data
      await fakeFirestore.collection('users').doc('user1').set({
        'email': 'user1@test.com',
        'first_name': 'John',
        'last_name': 'Doe',
        'role': 'owner',
        'accountType': 'trial',
        'created_at': Timestamp.fromDate(DateTime(2023, 1, 1)),
      });
      await fakeFirestore.collection('users').doc('user2').set({
        'email': 'user2@test.com',
        'first_name': 'Jane',
        'last_name': 'Smith',
        'role': 'owner',
        'accountType': 'premium',
        'created_at': Timestamp.fromDate(DateTime(2023, 1, 2)),
      });
      await fakeFirestore.collection('users').doc('user3').set({
        'email': 'user3@test.com',
        'first_name': 'Guest',
        'last_name': 'User',
        'role': 'guest',
        'accountType': 'trial',
        'created_at': Timestamp.fromDate(DateTime(2023, 1, 3)),
      });

      final owners = await repository.getOwners(limit: 10);
      expect(owners.length, 2);
      // Order should be descending by created_at
      expect(owners[0].id, 'user2');
      expect(owners[1].id, 'user1');
    });

    test('getUserById retrieves existing user', () async {
      await fakeFirestore.collection('users').doc('user1').set({
        'email': 'user1@test.com',
        'first_name': 'John',
        'last_name': 'Doe',
        'role': 'owner',
        'accountType': 'trial',
        'created_at': Timestamp.now(),
      });

      final user = await repository.getUserById('user1');
      expect(user, isNotNull);
      expect(user!.id, 'user1');
      expect(user.role.name, 'owner');
    });

    test('getUserById returns null for missing user', () async {
      final user = await repository.getUserById('missing');
      expect(user, isNull);
    });

    test('updateAccountType updates accountType field', () async {
      await fakeFirestore.collection('users').doc('user1').set({
        'accountType': 'trial',
      });

      await repository.updateAccountType('user1', AccountType.premium);

      final doc = await fakeFirestore.collection('users').doc('user1').get();
      expect(doc.data()!['accountType'], 'premium');
      expect(doc.data()!['updatedAt'], isNotNull);
    });

    test('getDashboardStats aggregates correct counts', () async {
      final batch = fakeFirestore.batch();
      final usersColl = fakeFirestore.collection('users');

      batch.set(usersColl.doc('u1'), {'role': 'owner', 'accountType': 'trial'});
      batch.set(usersColl.doc('u2'), {'role': 'owner', 'accountType': 'premium'});
      batch.set(usersColl.doc('u3'), {'role': 'owner', 'accountType': 'premium'});
      batch.set(usersColl.doc('u4'), {'role': 'owner', 'accountType': 'lifetime'});
      batch.set(usersColl.doc('u5'), {'role': 'guest', 'accountType': 'premium'}); // Should be ignored

      await batch.commit();

      final stats = await repository.getDashboardStats();
      expect(stats['totalOwners'], 4);
      expect(stats['trialUsers'], 1);
      expect(stats['premiumUsers'], 2);
      expect(stats['lifetimeUsers'], 1);
    });

    test('getUserPropertiesCount counts properties for user', () async {
      final batch = fakeFirestore.batch();
      final propsColl = fakeFirestore.collection('properties');

      batch.set(propsColl.doc('p1'), {'owner_id': 'user1'});
      batch.set(propsColl.doc('p2'), {'owner_id': 'user1'});
      batch.set(propsColl.doc('p3'), {'owner_id': 'user2'});

      await batch.commit();

      final count = await repository.getUserPropertiesCount('user1');
      expect(count, 2);
    });

    test('getUserBookingsCount counts bookings via collectionGroup', () async {
      // fake_cloud_firestore supports collectionGroup queries.
      final batch = fakeFirestore.batch();

      final prop1Bookings = fakeFirestore.collection('properties').doc('p1').collection('bookings');
      final prop2Bookings = fakeFirestore.collection('properties').doc('p2').collection('bookings');

      batch.set(prop1Bookings.doc('b1'), {'owner_id': 'user1'});
      batch.set(prop1Bookings.doc('b2'), {'owner_id': 'user1'});
      batch.set(prop2Bookings.doc('b3'), {'owner_id': 'user1'});
      batch.set(prop2Bookings.doc('b4'), {'owner_id': 'user2'});

      await batch.commit();

      final count = await repository.getUserBookingsCount('user1');
      expect(count, 3);
    });

    test('getUserAccountStatus fetches custom field', () async {
      await fakeFirestore.collection('users').doc('user1').set({
        'accountStatus': 'suspended',
      });

      final status = await repository.getUserAccountStatus('user1');
      expect(status, 'suspended');
    });

    test('updateAdminFlags sets appropriate fields', () async {
      await fakeFirestore.collection('users').doc('user1').set({});

      await repository.updateAdminFlags(
        'user1',
        hideSubscription: true,
        adminOverrideAccountType: AccountType.lifetime,
      );

      var doc = await fakeFirestore.collection('users').doc('user1').get();
      var data = doc.data()!;
      expect(data['hide_subscription'], true);
      expect(data['admin_override_account_type'], 'lifetime');
      expect(data['updated_at'], isNotNull);

      // Test clearOverride
      await repository.updateAdminFlags('user1', clearOverride: true);
      doc = await fakeFirestore.collection('users').doc('user1').get();
      data = doc.data()!;
      expect(data.containsKey('admin_override_account_type'), isFalse);
    });

    test('getRecentSignupsCount filters by date', () async {
      final now = DateTime.now();
      final batch = fakeFirestore.batch();
      final usersColl = fakeFirestore.collection('users');

      // 2 days ago
      batch.set(usersColl.doc('u1'), {
        'role': 'owner',
        'created_at': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
      });
      // 10 days ago
      batch.set(usersColl.doc('u2'), {
        'role': 'owner',
        'created_at': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      });
      // Future
      batch.set(usersColl.doc('u3'), {
        'role': 'owner',
        'created_at': Timestamp.fromDate(now.add(const Duration(days: 1))),
      });

      await batch.commit();

      final count = await repository.getRecentSignupsCount(7);
      // Should include u1 and u3 (future is >= cutoff)
      expect(count, 2);
    });

    test('getActivityLog returns security events', () async {
      final batch = fakeFirestore.batch();
      final eventsColl = fakeFirestore.collection('security_events');

      batch.set(eventsColl.doc('e1'), {
        'event': 'login',
        'timestamp': Timestamp.fromDate(DateTime(2023, 1, 1)),
      });
      batch.set(eventsColl.doc('e2'), {
        'event': 'logout',
        'timestamp': Timestamp.fromDate(DateTime(2023, 1, 2)),
      });

      await batch.commit();

      final logs = await repository.getActivityLog();
      expect(logs.length, 2);
      expect(logs[0]['id'], 'e2'); // e2 is newer
      expect(logs[1]['id'], 'e1');
    });

    group('Cloud Functions calls', () {
      late MockHttpsCallable mockCallable;
      late MockHttpsCallableResult<Map<String, dynamic>> mockResult;

      setUp(() {
        mockCallable = MockHttpsCallable();
        mockResult = MockHttpsCallableResult<Map<String, dynamic>>();
      });

      test('updateUserStatus success', () async {
        when(() => mockFunctions.httpsCallable('updateUserStatus'))
            .thenReturn(mockCallable);
        when(() => mockCallable.call<Map<String, dynamic>>(any()))
            .thenAnswer((_) async => mockResult);
        when(() => mockResult.data).thenReturn({'message': 'Success'});

        final result = await repository.updateUserStatus(
          userId: 'user1',
          newStatus: 'active',
          reason: 'Test reason',
        );

        expect(result, 'Success');
        verify(() => mockCallable.call<Map<String, dynamic>>({
              'userId': 'user1',
              'newStatus': 'active',
              'reason': 'Test reason',
            })).called(1);
      });

      test('updateUserStatus throws exception on error', () async {
        when(() => mockFunctions.httpsCallable('updateUserStatus'))
            .thenReturn(mockCallable);
        when(() => mockCallable.call<Map<String, dynamic>>(any())).thenThrow(
          FirebaseFunctionsException(
            message: 'Error',
            code: 'internal',
          ),
        );

        expect(
          () => repository.updateUserStatus(
            userId: 'user1',
            newStatus: 'active',
          ),
          throwsA(isA<FirebaseFunctionsException>()),
        );
      });

      test('setLifetimeLicense success', () async {
        when(() => mockFunctions.httpsCallable('setLifetimeLicense'))
            .thenReturn(mockCallable);
        when(() => mockCallable.call<Map<String, dynamic>>(any()))
            .thenAnswer((_) async => mockResult);
        when(() => mockResult.data).thenReturn({'message': 'Done'});

        final result = await repository.setLifetimeLicense(
          userId: 'user1',
          grant: true,
        );

        expect(result, 'Done');
        verify(() => mockCallable.call<Map<String, dynamic>>({
              'userId': 'user1',
              'grant': true,
            })).called(1);
      });

      test('setLifetimeLicense throws exception on error', () async {
        when(() => mockFunctions.httpsCallable('setLifetimeLicense'))
            .thenReturn(mockCallable);
        when(() => mockCallable.call<Map<String, dynamic>>(any())).thenThrow(
          FirebaseFunctionsException(
            message: 'Error',
            code: 'internal',
          ),
        );

        expect(
          () => repository.setLifetimeLicense(
            userId: 'user1',
            grant: true,
          ),
          throwsA(isA<FirebaseFunctionsException>()),
        );
      });
    });
  });
}
