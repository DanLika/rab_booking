import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:bookbed/core/providers/enhanced_auth_provider.dart';
import 'package:bookbed/core/services/rate_limit_service.dart';
import 'package:bookbed/core/services/security_events_service.dart';
import 'package:bookbed/core/services/ip_geolocation_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockRateLimitService extends Mock implements RateLimitService {}
class MockSecurityEventsService extends Mock implements SecurityEventsService {}
class MockIpGeolocationService extends Mock implements IpGeolocationService {}
class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}
class MockHttpsCallable extends Mock implements HttpsCallable {}
class MockHttpsCallableResult<T> extends Mock implements HttpsCallableResult<T> {}
class MockLoginAttempt extends Mock implements LoginAttempt {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockRateLimitService mockRateLimit;
  late MockSecurityEventsService mockSecurity;
  late MockIpGeolocationService mockGeolocation;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockHttpsCallableResult mockResult;
  late EnhancedAuthNotifier notifier;

  setUpAll(() {
    registerFallbackValue(Persistence.LOCAL);
  });

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockRateLimit = MockRateLimitService();
    mockSecurity = MockSecurityEventsService();
    mockGeolocation = MockIpGeolocationService();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    mockResult = MockHttpsCallableResult();

    when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.empty());

    when(() => mockFunctions.httpsCallable('checkLoginRateLimit'))
        .thenReturn(mockCallable);
    when(() => mockCallable.call(any()))
        .thenAnswer((_) async => mockResult);

    notifier = EnhancedAuthNotifier(
      mockAuth,
      mockFirestore,
      mockRateLimit,
      mockSecurity,
      mockGeolocation,
      mockFunctions,
    );
  });

  test('signInWithEmail gracefully handles FirebaseAuthException in try-catch block and falls back correctly', () async {
    const email = 'test@example.com';
    const password = 'password123';

    // Setup local checks to return no rate limit
    when(() => mockRateLimit.checkRateLimit(email))
        .thenAnswer((_) async => null);

    // Setup recordFailedAttempt
    when(() => mockRateLimit.recordFailedAttempt(email))
        .thenAnswer((_) => Future.value());

    when(() => mockAuth.setPersistence(any()))
        .thenAnswer((_) => Future.value());

    // Simulate FirebaseAuthException when calling signInWithEmailAndPassword
    when(() => mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(code: 'user-not-found', message: 'User not found.'));

    try {
      await notifier.signInWithEmail(email: email, password: password);
      fail('Expected an exception');
    } catch (e) {
      // The provider catches FirebaseAuthException and throws a user-friendly String message
      expect(e, isA<String>());
    }

    // Verify that rate limit failed attempt was recorded
    verify(() => mockRateLimit.recordFailedAttempt(email)).called(1);

    // Verify that isLoading is set to false
    expect(notifier.debugState.isLoading, false);
  });
}
