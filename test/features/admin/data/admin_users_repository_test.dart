import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bookbed/features/admin/data/admin_users_repository.dart';
import 'package:bookbed/shared/models/user_model.dart';
import 'package:bookbed/core/constants/enums.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}
class MockHttpsCallable extends Mock implements HttpsCallable {}
class MockHttpsCallableResult<T> extends Mock implements HttpsCallableResult<T> {}

void main() {
  group('AdminUsersRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseFunctions mockFunctions;
    late MockHttpsCallable mockCallable;
    late AdminUsersRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockFunctions = MockFirebaseFunctions();
      mockCallable = MockHttpsCallable();
      repository = AdminUsersRepository(
        firestore: fakeFirestore,
        functions: mockFunctions,
      );
    });


    group('Firestore Read Operations', () {
      test('getOwners returns paginated owners sorted by created_at', () async {
        final now = DateTime.now();
        // Setup users
        await fakeFirestore.collection('users').doc('user1').set({
          'email': 'owner1@test.com',
          'first_name': 'Owner',
          'last_name': 'One',
          'role': 'owner',
          'created_at': Timestamp.fromDate(now),
        });
        await fakeFirestore.collection('users').doc('user2').set({
          'email': 'guest1@test.com',
          'first_name': 'Guest',
          'last_name': 'One',
          'role': 'guest',
          'created_at': Timestamp.fromDate(now),
        });
        await fakeFirestore.collection('users').doc('user3').set({
          'email': 'owner2@test.com',
          'first_name': 'Owner',
          'last_name': 'Two',
          'role': 'owner',
          'created_at': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        });

        final owners = await repository.getOwners(limit: 2);

        expect(owners.length, 2);
        expect(owners[0].id, 'user1'); // Newest first
        expect(owners[1].id, 'user3');
        expect(owners.every((u) => u.role == UserRole.owner), isTrue);
      });

      test('getUserById returns user when it exists', () async {
        await fakeFirestore.collection('users').doc('user123').set({
          'email': 'test@test.com',
          'first_name': 'Test',
          'last_name': 'User',
          'role': 'owner',
        });

        final user = await repository.getUserById('user123');

        expect(user, isNotNull);
        expect(user!.id, 'user123');
        expect(user.email, 'test@test.com');
      });

      test('getUserById returns null when it does not exist', () async {
        final user = await repository.getUserById('nonexistent');
        expect(user, isNull);
      });

      test('getDashboardStats aggregates correctly', () async {
        // Owner Trial
        await fakeFirestore.collection('users').doc('u1').set({
          'role': 'owner',
          'accountType': 'trial',
        });
        // Owner Premium
        await fakeFirestore.collection('users').doc('u2').set({
          'role': 'owner',
          'accountType': 'premium',
        });
        // Owner Premium 2
        await fakeFirestore.collection('users').doc('u3').set({
          'role': 'owner',
          'accountType': 'premium',
        });
        // Owner Lifetime
        await fakeFirestore.collection('users').doc('u4').set({
          'role': 'owner',
          'accountType': 'lifetime',
        });
        // Guest (ignored)
        await fakeFirestore.collection('users').doc('u5').set({
          'role': 'guest',
          'accountType': 'trial',
        });

        final stats = await repository.getDashboardStats();

        expect(stats['totalOwners'], 4);
        expect(stats['trialUsers'], 1);
        expect(stats['premiumUsers'], 2);
        expect(stats['lifetimeUsers'], 1);
      });

      test('getUserPropertiesCount counts properties for specific owner', () async {
        await fakeFirestore.collection('properties').doc('p1').set({'owner_id': 'owner1'});
        await fakeFirestore.collection('properties').doc('p2').set({'owner_id': 'owner1'});
        await fakeFirestore.collection('properties').doc('p3').set({'owner_id': 'owner2'});

        final count = await repository.getUserPropertiesCount('owner1');
        expect(count, 2);
      });

      test('getUserAccountStatus returns raw accountStatus', () async {
        await fakeFirestore.collection('users').doc('user1').set({
          'accountStatus': 'suspended'
        });

        final status = await repository.getUserAccountStatus('user1');
        expect(status, 'suspended');
      });

      test('getUserAccountStatus returns null if not set', () async {
        await fakeFirestore.collection('users').doc('user2').set({
          'email': 'test@test.com'
        });

        final status = await repository.getUserAccountStatus('user2');
        expect(status, isNull);
      });

      test('getRecentSignupsCount filters by date and role', () async {
        final now = DateTime.now();
        await fakeFirestore.collection('users').doc('u1').set({
          'role': 'owner',
          'created_at': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        });
        await fakeFirestore.collection('users').doc('u2').set({
          'role': 'owner',
          'created_at': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
        });
        await fakeFirestore.collection('users').doc('u3').set({
          'role': 'guest',
          'created_at': Timestamp.fromDate(now),
        });

        final recentCount = await repository.getRecentSignupsCount(7);
        expect(recentCount, 1);
      });

      test('getActivityLog returns limited and ordered logs', () async {
        final now = DateTime.now();
        await fakeFirestore.collection('security_events').doc('e1').set({
          'action': 'login',
          'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
        });
        await fakeFirestore.collection('security_events').doc('e2').set({
          'action': 'logout',
          'timestamp': Timestamp.fromDate(now),
        });

        final logs = await repository.getActivityLog(limit: 2);

        expect(logs.length, 2);
        expect(logs[0]['action'], 'logout'); // Newer first
        expect(logs[1]['action'], 'login');
      });
    });

    group('Firestore Write Operations', () {
      test('updateAccountType updates type and server timestamp', () async {
        await fakeFirestore.collection('users').doc('user1').set({
          'accountType': 'trial',
        });

        await repository.updateAccountType('user1', AccountType.premium);

        final doc = await fakeFirestore.collection('users').doc('user1').get();
        expect(doc.data()!['accountType'], 'premium');
        expect(doc.data()!['updatedAt'], isNotNull); // FieldValue.serverTimestamp() creates FieldValue locally
      });

      test('updateAdminFlags sets and clears admin flags', () async {
        await fakeFirestore.collection('users').doc('user1').set({
          'hide_subscription': false,
          'admin_override_account_type': 'premium',
        });

        // Update to hide subscription and clear override
        await repository.updateAdminFlags(
          'user1',
          hideSubscription: true,
          clearOverride: true,
        );

        final doc = await fakeFirestore.collection('users').doc('user1').get();
        expect(doc.data()!['hide_subscription'], true);
        expect(doc.data()!.containsKey('admin_override_account_type'), false);
        expect(doc.data()!['updated_at'], isNotNull);
      });

      test('updateAdminFlags sets admin override', () async {
         await fakeFirestore.collection('users').doc('user1').set({});

         await repository.updateAdminFlags(
          'user1',
          adminOverrideAccountType: AccountType.lifetime,
        );

        final doc = await fakeFirestore.collection('users').doc('user1').get();
        expect(doc.data()!['admin_override_account_type'], 'lifetime');
      });
    });

    group('Cloud Functions Integrations', () {
      setUp(() {
        when(() => mockFunctions.httpsCallable(any()))
            .thenReturn(mockCallable);
      });

      test('updateUserStatus calls function and returns message', () async {
        final mockResult = MockHttpsCallableResult<Map<String, dynamic>>();
        when(() => mockResult.data).thenReturn({'message': 'Status successfully updated'});

        when(() => mockCallable.call<Map<String, dynamic>>(any()))
            .thenAnswer((_) async => mockResult);

        final result = await repository.updateUserStatus(
          userId: 'user1',
          newStatus: 'active',
          reason: 'Subscription paid'
        );

        expect(result, 'Status successfully updated');
        verify(() => mockFunctions.httpsCallable('updateUserStatus')).called(1);
        verify(() => mockCallable.call<Map<String, dynamic>>({
          'userId': 'user1',
          'newStatus': 'active',
          'reason': 'Subscription paid',
        })).called(1);
      });

      test('updateUserStatus handles errors', () async {
        when(() => mockCallable.call<Map<String, dynamic>>(any()))
            .thenThrow(FirebaseFunctionsException(message: 'Error', code: 'internal'));

        expect(
          () => repository.updateUserStatus(userId: 'user1', newStatus: 'active'),
          throwsA(isA<FirebaseFunctionsException>())
        );
      });

      test('setLifetimeLicense calls function and returns message', () async {
        final mockResult = MockHttpsCallableResult<Map<String, dynamic>>();
        when(() => mockResult.data).thenReturn({'message': 'License granted'});

        when(() => mockCallable.call<Map<String, dynamic>>(any()))
            .thenAnswer((_) async => mockResult);

        final result = await repository.setLifetimeLicense(
          userId: 'user1',
          grant: true,
        );

        expect(result, 'License granted');
        verify(() => mockFunctions.httpsCallable('setLifetimeLicense')).called(1);
        verify(() => mockCallable.call<Map<String, dynamic>>({
          'userId': 'user1',
          'grant': true,
        })).called(1);
      });

      test('setLifetimeLicense handles errors', () async {
        when(() => mockCallable.call<Map<String, dynamic>>(any()))
            .thenThrow(Exception('Generic error'));

        expect(
          () => repository.setLifetimeLicense(userId: 'user1', grant: true),
          throwsA(isA<Exception>())
        );
      });
    });
  });
}
