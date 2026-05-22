import 'package:bookbed/features/subscription/data/subscription_repository.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult<T> extends Mock implements HttpsCallableResult<T> {}

void main() {
  late SubscriptionRepository repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockHttpsCallableResult<dynamic> mockResult;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    mockResult = MockHttpsCallableResult<dynamic>();
    repository = SubscriptionRepository(
      firestore: fakeFirestore,
      functions: mockFunctions,
    );
  });

  group('SubscriptionRepository', () {
    group('hasActiveSubscription', () {
      test('returns true when accountStatus is active', () async {
        await fakeFirestore.collection('users').doc('user_123').set({
          'accountStatus': 'active',
        });

        final result = await repository.hasActiveSubscription('user_123');
        expect(result, isTrue);
      });

      test('returns true when accountStatus is trial', () async {
        await fakeFirestore.collection('users').doc('user_123').set({
          'accountStatus': 'trial',
        });

        final result = await repository.hasActiveSubscription('user_123');
        expect(result, isTrue);
      });

      test('returns false when accountStatus is trial_expired', () async {
        await fakeFirestore.collection('users').doc('user_123').set({
          'accountStatus': 'trial_expired',
        });

        final result = await repository.hasActiveSubscription('user_123');
        expect(result, isFalse);
      });

      test('returns false when accountStatus is suspended', () async {
        await fakeFirestore.collection('users').doc('user_123').set({
          'accountStatus': 'suspended',
        });

        final result = await repository.hasActiveSubscription('user_123');
        expect(result, isFalse);
      });

      test('returns false when user document does not exist', () async {
        final result = await repository.hasActiveSubscription('non_existent_user');
        expect(result, isFalse);
      });
    });

    group('createCheckoutSession', () {
      const priceId = 'price_123';
      const returnUrl = 'https://example.com/return';

      test('returns url when response is valid', () async {
        when(() => mockFunctions.httpsCallable('createSubscriptionCheckoutSession'))
            .thenReturn(mockCallable);
        when(() => mockCallable.call<dynamic>(any())).thenAnswer((_) async => mockResult);
        when(() => mockResult.data).thenReturn({'url': 'https://checkout.stripe.com/123'});

        final url = await repository.createCheckoutSession(
          priceId: priceId,
          returnUrl: returnUrl,
        );

        expect(url, 'https://checkout.stripe.com/123');
        verify(() => mockFunctions.httpsCallable('createSubscriptionCheckoutSession')).called(1);
        verify(() => mockCallable.call<dynamic>({'priceId': priceId, 'returnUrl': returnUrl})).called(1);
      });

      test('throws Exception when url is missing from response', () async {
        when(() => mockFunctions.httpsCallable('createSubscriptionCheckoutSession'))
            .thenReturn(mockCallable);
        when(() => mockCallable.call<dynamic>(any())).thenAnswer((_) async => mockResult);
        when(() => mockResult.data).thenReturn({}); // Missing url

        expect(
          () => repository.createCheckoutSession(
            priceId: priceId,
            returnUrl: returnUrl,
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Checkout URL missing from response'),
            ),
          ),
        );
      });

      test('throws Exception when callable fails', () async {
        when(() => mockFunctions.httpsCallable('createSubscriptionCheckoutSession'))
            .thenReturn(mockCallable);
        when(() => mockCallable.call<dynamic>(any())).thenThrow(Exception('Firebase Error'));

        expect(
          () => repository.createCheckoutSession(
            priceId: priceId,
            returnUrl: returnUrl,
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to create subscription session'),
            ),
          ),
        );
      });
    });

    group('createPortalSession', () {
      const returnUrl = 'https://example.com/return';

      test('returns url when response is valid', () async {
        when(() => mockFunctions.httpsCallable('createCustomerPortalSession'))
            .thenReturn(mockCallable);
        when(() => mockCallable.call<dynamic>(any())).thenAnswer((_) async => mockResult);
        when(() => mockResult.data).thenReturn({'url': 'https://billing.stripe.com/123'});

        final url = await repository.createPortalSession(returnUrl: returnUrl);

        expect(url, 'https://billing.stripe.com/123');
        verify(() => mockFunctions.httpsCallable('createCustomerPortalSession')).called(1);
        verify(() => mockCallable.call<dynamic>({'returnUrl': returnUrl})).called(1);
      });

      test('throws Exception when callable fails', () async {
        when(() => mockFunctions.httpsCallable('createCustomerPortalSession'))
            .thenReturn(mockCallable);
        when(() => mockCallable.call<dynamic>(any())).thenThrow(Exception('Network Error'));

        expect(
          () => repository.createPortalSession(returnUrl: returnUrl),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to create portal session'),
            ),
          ),
        );
      });
    });
  });

  group('subscriptionRepositoryProvider', () {
    test('returns a valid SubscriptionRepository instance', () {
      final container = ProviderContainer(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(
            SubscriptionRepository(
              firestore: fakeFirestore,
              functions: mockFunctions,
            ),
          ),
        ],
      );

      final repo = container.read(subscriptionRepositoryProvider);
      expect(repo, isA<SubscriptionRepository>());
    });
  });
}
