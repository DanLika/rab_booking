import 'package:bookbed/features/admin/data/admin_users_repository.dart';
import 'package:bookbed/shared/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}
class MockHttpsCallable extends Mock implements HttpsCallable {}
class MockHttpsCallableResult<T> extends Mock implements HttpsCallableResult<T> {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseFunctions mockFunctions;
  late AdminUsersRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    repository = AdminUsersRepository(
      firestore: fakeFirestore,
      functions: mockFunctions,
    );
  });

  group('AdminUsersRepository', () {
    test('getOwners retrieves paginated owner users', () async {
      await fakeFirestore.collection('users').doc('owner1').set({
        'role': 'owner',
        'email': 'owner1@test.com',
        'created_at': Timestamp.fromDate(DateTime(2024)),
      });
      await fakeFirestore.collection('users').doc('guest1').set({
        'role': 'guest',
        'email': 'guest1@test.com',
        'created_at': Timestamp.fromDate(DateTime(2024)),
      });
      await fakeFirestore.collection('users').doc('owner2').set({
        'role': 'owner',
        'email': 'owner2@test.com',
        'created_at': Timestamp.fromDate(DateTime(2024, 1, 2)),
      });

      final owners = await repository.getOwners(limit: 10);

      expect(owners.length, 2);
      expect(owners[0].id, 'owner2'); // Descending order
      expect(owners[1].id, 'owner1');
    });

    test('getDashboardStats counts users by account types', () async {
      // Trial owner
      await fakeFirestore.collection('users').add({
        'role': 'owner',
        'accountType': 'trial',
      });
      // Premium owner
      await fakeFirestore.collection('users').add({
        'role': 'owner',
        'accountType': 'premium',
      });
      // Lifetime owner
      await fakeFirestore.collection('users').add({
        'role': 'owner',
        'accountType': 'lifetime',
      });
      // Guest (should not be counted)
      await fakeFirestore.collection('users').add({
        'role': 'guest',
        'accountType': 'premium',
      });

      final stats = await repository.getDashboardStats();

      expect(stats['totalOwners'], 3);
      expect(stats['trialUsers'], 1);
      expect(stats['premiumUsers'], 1);
      expect(stats['lifetimeUsers'], 1);
    });

    test('getUserPropertiesCount returns properties count', () async {
      await fakeFirestore.collection('properties').add({
        'owner_id': 'user123',
      });
      await fakeFirestore.collection('properties').add({
        'owner_id': 'user123',
      });
      await fakeFirestore.collection('properties').add({
        'owner_id': 'other',
      });

      final count = await repository.getUserPropertiesCount('user123');
      expect(count, 2);
    });

    test('getUserBookingsCount returns collectionGroup count', () async {
      await fakeFirestore.collection('properties').doc('prop1').collection('bookings').add({
        'owner_id': 'user123',
      });
      await fakeFirestore.collection('properties').doc('prop2').collection('bookings').add({
        'owner_id': 'user123',
      });
      await fakeFirestore.collection('properties').doc('prop1').collection('bookings').add({
        'owner_id': 'other',
      });

      final count = await repository.getUserBookingsCount('user123');
      expect(count, 2);
    });

    test('updateAdminFlags updates hide_subscription and override type', () async {
      await fakeFirestore.collection('users').doc('user123').set({
        'email': 'test@test.com',
      });

      await repository.updateAdminFlags(
        'user123',
        hideSubscription: true,
        adminOverrideAccountType: AccountType.premium,
      );

      final doc = await fakeFirestore.collection('users').doc('user123').get();
      final data = doc.data()!;
      expect(data['hide_subscription'], true);
      expect(data['admin_override_account_type'], 'premium');
      expect(data['updated_at'], isNotNull);
    });

    test('updateAdminFlags clears override', () async {
      await fakeFirestore.collection('users').doc('user123').set({
        'admin_override_account_type': 'lifetime',
      });

      await repository.updateAdminFlags(
        'user123',
        clearOverride: true,
      );

      final doc = await fakeFirestore.collection('users').doc('user123').get();
      expect(doc.data()!.containsKey('admin_override_account_type'), false);
    });

    test('updateUserStatus calls Cloud Function', () async {
      final mockCallable = MockHttpsCallable();
      final mockResult = MockHttpsCallableResult<Map<String, dynamic>>();

      when(() => mockFunctions.httpsCallable('updateUserStatus')).thenReturn(mockCallable);
      when(() => mockResult.data).thenReturn({'message': 'Success'});
      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenAnswer((_) async => mockResult);

      final message = await repository.updateUserStatus(
        userId: 'user123',
        newStatus: 'active',
        reason: 'Payment received',
      );

      expect(message, 'Success');
      verify(() => mockCallable.call<Map<String, dynamic>>({
        'userId': 'user123',
        'newStatus': 'active',
        'reason': 'Payment received',
      })).called(1);
    });

    test('setLifetimeLicense calls Cloud Function', () async {
      final mockCallable = MockHttpsCallable();
      final mockResult = MockHttpsCallableResult<Map<String, dynamic>>();

      when(() => mockFunctions.httpsCallable('setLifetimeLicense')).thenReturn(mockCallable);
      when(() => mockResult.data).thenReturn({'message': 'License granted'});
      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenAnswer((_) async => mockResult);

      final message = await repository.setLifetimeLicense(
        userId: 'user123',
        grant: true,
      );

      expect(message, 'License granted');
      verify(() => mockCallable.call<Map<String, dynamic>>({
        'userId': 'user123',
        'grant': true,
      })).called(1);
    });
  });
}
