import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:bookbed/core/services/stripe_service.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock implements HttpsCallableResult<dynamic> {}

void main() {
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockHttpsCallableResult mockResult;
  late StripeService stripeService;

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    mockResult = MockHttpsCallableResult();
    stripeService = StripeService(functions: mockFunctions);
  });

  group('createCheckoutSession', () {
    final bookingData = {
      'guestEmail': 'test@example.com',
      'propertyId': 'prop1',
    };
    const returnUrl = 'https://example.com/return';

    test('success returns StripeCheckoutResult', () async {
      when(() => mockFunctions.httpsCallable('createStripeCheckoutSession'))
          .thenReturn(mockCallable);
      when(
        () => mockCallable.call(
          {'bookingData': bookingData, 'returnUrl': returnUrl},
        ),
      ).thenAnswer((_) async => mockResult);
      when(() => mockResult.data).thenReturn({
        'success': true,
        'sessionId': 'sess_123',
        'checkoutUrl': 'https://checkout.stripe.com/123',
        'bookingReference': 'REF123',
      });

      final result = await stripeService.createCheckoutSession(
        bookingData: bookingData,
        returnUrl: returnUrl,
      );

      expect(result.success, isTrue);
      expect(result.sessionId, 'sess_123');
      expect(result.checkoutUrl, 'https://checkout.stripe.com/123');
      expect(result.bookingReference, 'REF123');
    });

    test('failure throws StripeServiceException', () async {
      when(() => mockFunctions.httpsCallable('createStripeCheckoutSession'))
          .thenReturn(mockCallable);
      when(
        () => mockCallable.call(
          {'bookingData': bookingData, 'returnUrl': returnUrl},
        ),
      ).thenAnswer((_) async => mockResult);
      when(() => mockResult.data).thenReturn({
        'success': false,
        'error': 'Some API error',
      });

      expect(
        () => stripeService.createCheckoutSession(
          bookingData: bookingData,
          returnUrl: returnUrl,
        ),
        throwsA(
          isA<StripeServiceException>().having(
            (e) => e.code,
            'code',
            'StripeServiceException: Checkout session creation failed (code: Some API error)',
          ).having(
            (e) => e.message,
            'message',
            'Unexpected error creating checkout session. Please try again.',
          ),
        ),
      );
    });

    test('maps invalid-argument exception', () async {
      when(() => mockFunctions.httpsCallable('createStripeCheckoutSession'))
          .thenReturn(mockCallable);
      when(
        () => mockCallable.call(any()),
      ).thenThrow(FirebaseFunctionsException(message: 'Msg', code: 'invalid-argument'));

      expect(
        () => stripeService.createCheckoutSession(
          bookingData: bookingData,
          returnUrl: returnUrl,
        ),
        throwsA(
          isA<StripeServiceException>()
              .having((e) => e.code, 'code', 'invalid-argument')
              .having((e) => e.message, 'message', 'Msg'),
        ),
      );
    });

    test('maps failed-precondition exception with default msg', () async {
      when(() => mockFunctions.httpsCallable('createStripeCheckoutSession'))
          .thenReturn(mockCallable);
      when(
        () => mockCallable.call(any()),
      ).thenThrow(FirebaseFunctionsException(message: 'Payment setup incomplete. Please contact the property owner.', code: 'failed-precondition'));

      expect(
        () => stripeService.createCheckoutSession(
          bookingData: bookingData,
          returnUrl: returnUrl,
        ),
        throwsA(
          isA<StripeServiceException>()
              .having((e) => e.code, 'code', 'failed-precondition')
              .having((e) => e.message, 'message', 'Payment setup incomplete. Please contact the property owner.'),
        ),
      );
    });

    test('maps already-exists exception', () async {
      when(() => mockFunctions.httpsCallable('createStripeCheckoutSession'))
          .thenReturn(mockCallable);
      when(
        () => mockCallable.call(any()),
      ).thenThrow(FirebaseFunctionsException(message: 'Already exists', code: 'already-exists'));

      expect(
        () => stripeService.createCheckoutSession(
          bookingData: bookingData,
          returnUrl: returnUrl,
        ),
        throwsA(
          isA<StripeServiceException>()
              .having((e) => e.code, 'code', 'already-exists')
              .having((e) => e.message, 'message', 'Already exists'),
        ),
      );
    });

    test('maps permission-denied exception', () async {
      when(() => mockFunctions.httpsCallable('createStripeCheckoutSession'))
          .thenReturn(mockCallable);
      when(
        () => mockCallable.call(any()),
      ).thenThrow(FirebaseFunctionsException(message: 'Permission denied', code: 'permission-denied'));

      expect(
        () => stripeService.createCheckoutSession(
          bookingData: bookingData,
          returnUrl: returnUrl,
        ),
        throwsA(
          isA<StripeServiceException>()
              .having((e) => e.code, 'code', 'permission-denied')
              .having((e) => e.message, 'message', 'Permission denied. Please refresh the page and try again.'),
        ),
      );
    });

    test('maps default exception', () async {
      when(() => mockFunctions.httpsCallable('createStripeCheckoutSession'))
          .thenReturn(mockCallable);
      when(
        () => mockCallable.call(any()),
      ).thenThrow(FirebaseFunctionsException(message: 'Unknown', code: 'unknown'));

      expect(
        () => stripeService.createCheckoutSession(
          bookingData: bookingData,
          returnUrl: returnUrl,
        ),
        throwsA(
          isA<StripeServiceException>()
              .having((e) => e.code, 'code', 'unknown')
              .having((e) => e.message, 'message', 'Unknown'),
        ),
      );
    });

    test('handles generic exception', () async {
      when(() => mockFunctions.httpsCallable('createStripeCheckoutSession'))
          .thenReturn(mockCallable);
      when(
        () => mockCallable.call(any()),
      ).thenThrow(Exception('Generic error'));

      expect(
        () => stripeService.createCheckoutSession(
          bookingData: bookingData,
          returnUrl: returnUrl,
        ),
        throwsA(
          isA<StripeServiceException>()
              .having((e) => e.message, 'message', 'Unexpected error creating checkout session. Please try again.')
              .having((e) => e.code, 'code', 'Exception: Generic error'),
        ),
      );
    });
  });

  group('getAccountStatus', () {
    test('success returns StripeAccountStatus', () async {
      when(() => mockFunctions.httpsCallable('getStripeAccountStatus'))
          .thenReturn(mockCallable);
      when(() => mockCallable.call()).thenAnswer((_) async => mockResult);
      when(() => mockResult.data).thenReturn({
        'connected': true,
        'accountId': 'acct_123',
        'onboarded': true,
        'chargesEnabled': true,
        'payoutsEnabled': true,
        'email': 'test@example.com',
        'country': 'US',
      });

      final status = await stripeService.getAccountStatus();

      expect(status.connected, isTrue);
      expect(status.accountId, 'acct_123');
      expect(status.onboarded, isTrue);
      expect(status.chargesEnabled, isTrue);
      expect(status.payoutsEnabled, isTrue);
      expect(status.email, 'test@example.com');
      expect(status.country, 'US');
      expect(status.isFullySetup, isTrue);
    });

    test('handles FirebaseFunctionsException', () async {
      when(() => mockFunctions.httpsCallable('getStripeAccountStatus'))
          .thenReturn(mockCallable);
      when(
        () => mockCallable.call(),
      ).thenThrow(FirebaseFunctionsException(message: 'Error', code: 'internal'));

      expect(
        () => stripeService.getAccountStatus(),
        throwsA(
          isA<StripeServiceException>()
              .having((e) => e.message, 'message', 'Failed to get account status: Error')
              .having((e) => e.code, 'code', 'internal'),
        ),
      );
    });
  });

  group('createConnectAccount', () {
    const returnUrl = 'https://example.com/return';
    const refreshUrl = 'https://example.com/refresh';

    test('success returns StripeConnectResult', () async {
      when(() => mockFunctions.httpsCallable('createStripeConnectAccount'))
          .thenReturn(mockCallable);
      when(
        () => mockCallable.call(
          {'returnUrl': returnUrl, 'refreshUrl': refreshUrl},
        ),
      ).thenAnswer((_) async => mockResult);
      when(() => mockResult.data).thenReturn({
        'success': true,
        'accountId': 'acct_123',
        'onboardingUrl': 'https://connect.stripe.com/setup',
      });

      final result = await stripeService.createConnectAccount(
        returnUrl: returnUrl,
        refreshUrl: refreshUrl,
      );

      expect(result.success, isTrue);
      expect(result.accountId, 'acct_123');
      expect(result.onboardingUrl, 'https://connect.stripe.com/setup');
    });

    test('failure throws StripeServiceException', () async {
      when(() => mockFunctions.httpsCallable('createStripeConnectAccount'))
          .thenReturn(mockCallable);
      when(
        () => mockCallable.call(
          {'returnUrl': returnUrl, 'refreshUrl': refreshUrl},
        ),
      ).thenAnswer((_) async => mockResult);
      when(() => mockResult.data).thenReturn({
        'success': false,
        'error': 'API error',
      });

      expect(
        () => stripeService.createConnectAccount(
          returnUrl: returnUrl,
          refreshUrl: refreshUrl,
        ),
        throwsA(
          isA<StripeServiceException>().having((e) => e.code, 'code', 'API error'),
        ),
      );
    });

    test('handles FirebaseFunctionsException', () async {
      when(() => mockFunctions.httpsCallable('createStripeConnectAccount'))
          .thenReturn(mockCallable);
      when(
        () => mockCallable.call(any()),
      ).thenThrow(FirebaseFunctionsException(message: 'Error msg', code: 'internal'));

      expect(
        () => stripeService.createConnectAccount(
          returnUrl: returnUrl,
          refreshUrl: refreshUrl,
        ),
        throwsA(
          isA<StripeServiceException>()
              .having((e) => e.message, 'message', 'Failed to create Connect account: Error msg')
              .having((e) => e.code, 'code', 'internal'),
        ),
      );
    });
  });

  group('StripeAccountStatus.fromMap & isFullySetup', () {
    test('isFullySetup is true when all required fields are true', () {
      final status = StripeAccountStatus.fromMap({
        'connected': true,
        'onboarded': true,
        'chargesEnabled': true,
      });
      expect(status.isFullySetup, isTrue);
    });

    test('isFullySetup is false when connected is false', () {
      final status = StripeAccountStatus.fromMap({
        'connected': false,
        'onboarded': true,
        'chargesEnabled': true,
      });
      expect(status.isFullySetup, isFalse);
    });

    test('isFullySetup is false when onboarded is null/false', () {
      final status1 = StripeAccountStatus.fromMap({
        'connected': true,
        'chargesEnabled': true,
      });
      expect(status1.isFullySetup, isFalse);

      final status2 = StripeAccountStatus.fromMap({
        'connected': true,
        'onboarded': false,
        'chargesEnabled': true,
      });
      expect(status2.isFullySetup, isFalse);
    });

    test('isFullySetup is false when chargesEnabled is null/false', () {
      final status1 = StripeAccountStatus.fromMap({
        'connected': true,
        'onboarded': true,
      });
      expect(status1.isFullySetup, isFalse);

      final status2 = StripeAccountStatus.fromMap({
        'connected': true,
        'onboarded': true,
        'chargesEnabled': false,
      });
      expect(status2.isFullySetup, isFalse);
    });

    test('can parse map with null properties', () {
      final status = StripeAccountStatus.fromMap({
        'connected': true,
      });
      expect(status.connected, isTrue);
      expect(status.accountId, isNull);
      expect(status.onboarded, isNull);
      expect(status.chargesEnabled, isNull);
      expect(status.payoutsEnabled, isNull);
      expect(status.email, isNull);
      expect(status.country, isNull);
      expect(status.balance, isNull);
      expect(status.requirements, isNull);
    });
  });
}
