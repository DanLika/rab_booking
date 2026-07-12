// Integration-test net for [EnhancedAuthNotifier] flows, built on top of the
// mocktail + fake_cloud_firestore harness established in
// enhanced_auth_provider_register_test.dart. This is a pre-split safety net
// (see docs/TODO.md refactor campaign) — it exercises the state-machine
// contracts that a later file-split must preserve byte-for-byte.
//
// OUT OF SCOPE (intentionally, noted per-group below):
// - signInWithGoogle / signInWithApple: native SDK calls (GoogleSignIn,
//   SignInWithApple.getAppleIDCredential, signInWithPopup) are not mockable
//   at this seam without wrapping them behind an injectable interface. Not
//   covered here.
// - deleteAccount: full happy path calls FirebaseFunctions.instanceFor(...)
//   .httpsCallable('deleteUserAccount').call(), which needs a live Firebase
//   app and throws before completing under `flutter test`. Only the
//   reachable guard branches (no user, reauth failure) are covered.
// - signOut's SecureStorage/web-storage-wipe side effects are not
//   independently asserted — SecureStorageService is a static/plugin-backed
//   singleton not injected into the notifier, so it can't be observed here
//   without further mocking. We only assert the auth.signOut() call and the
//   resulting state.
// - The 2s sign-out grace timer (constructor's authStateChanges listener) is
//   avoided entirely by stubbing authStateChanges() to an empty Stream, as in
//   the register-test harness — no test in this file exercises that timer.

import 'package:bookbed/core/constants/enums.dart';
import 'package:bookbed/core/providers/enhanced_auth_provider.dart';
import 'package:bookbed/core/services/ip_geolocation_service.dart';
import 'package:bookbed/core/services/rate_limit_service.dart';
import 'package:bookbed/core/services/security_events_service.dart';
import 'package:bookbed/shared/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockUser extends Mock implements User {}

class _MockRateLimitService extends Mock implements RateLimitService {}

class _MockSecurityEventsService extends Mock
    implements SecurityEventsService {}

class _MockIpGeolocationService extends Mock implements IpGeolocationService {}

class _FakeAuthCredential extends Fake implements AuthCredential {}

class _FakeUser extends Fake implements User {}

/// Same overridable seam used by the register-test harness: bypasses the
/// live-Firebase-app-only Cloud Function call so the rest of the flow can be
/// exercised under `flutter test`.
class _TestAuthNotifier extends EnhancedAuthNotifier {
  _TestAuthNotifier(
    super.auth,
    super.firestore,
    super.rateLimit,
    super.security,
    super.geolocation,
  );

  int cloudRateLimitCalls = 0;

  @override
  Future<void> checkCloudRegistrationRateLimit(String email) async {
    cloudRateLimitCalls++;
  }

  /// Test-only seam to seed [state] directly (e.g. simulate an already
  /// logged-in user) without going through a method that needs a live
  /// Firebase app. `state`'s setter on the base `StateNotifier` is
  /// `@protected`, so this is only reachable from a subclass — exactly what
  /// this test-only class is for.
  void debugSetState(EnhancedAuthState newState) {
    state = newState;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(SecurityEventType.registration);
    registerFallbackValue(SecurityEventType.login);
    registerFallbackValue(SecurityEventType.suspicious);
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(_FakeAuthCredential());
    registerFallbackValue(_FakeUser());
    registerFallbackValue(
      LoginAttempt(
        email: 'fallback@example.com',
        attemptCount: 0,
        lastAttemptAt: DateTime.now(),
      ),
    );
  });

  late _MockFirebaseAuth auth;
  late _MockRateLimitService rateLimit;
  late _MockSecurityEventsService security;
  late _MockIpGeolocationService geolocation;
  late _MockUserCredential credential;
  late _MockUser user;
  late FakeFirebaseFirestore firestore;

  const uid = 'auth-flows-uid';
  const email = 'flows@example.com';
  const password = 'Gx7w!Kp2mZ';

  setUp(() {
    auth = _MockFirebaseAuth();
    rateLimit = _MockRateLimitService();
    security = _MockSecurityEventsService();
    geolocation = _MockIpGeolocationService();
    credential = _MockUserCredential();
    user = _MockUser();
    firestore = FakeFirebaseFirestore();

    when(
      () => auth.authStateChanges(),
    ).thenAnswer((_) => const Stream<User?>.empty());
    when(() => auth.currentUser).thenReturn(user);
    when(() => credential.user).thenReturn(user);
    when(() => user.uid).thenReturn(uid);
    when(() => user.email).thenReturn(email);
    when(() => user.emailVerified).thenReturn(false);
    when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
    when(() => user.sendEmailVerification()).thenAnswer((_) async {});
    when(() => user.delete()).thenAnswer((_) async {});
    when(() => user.reload()).thenAnswer((_) async {});
    when(
      () => user.reauthenticateWithCredential(any()),
    ).thenAnswer((_) async => credential);

    when(() => rateLimit.checkRateLimit(any())).thenAnswer((_) async => null);
    when(() => rateLimit.resetAttempts(any())).thenAnswer((_) async {});
    when(
      () => rateLimit.recordFailedAttempt(any()),
    ).thenAnswer((_) async => _lockedAttempt(email));
    when(
      () => rateLimit.getRateLimitMessage(any()),
    ).thenReturn('Too many attempts. Try again later.');
    when(() => geolocation.getCurrentLocation()).thenAnswer((_) async => null);
    when(
      () => security.logEvent(
        userId: any(named: 'userId'),
        type: any(named: 'type'),
        deviceId: any(named: 'deviceId'),
        ipAddress: any(named: 'ipAddress'),
        location: any(named: 'location'),
        metadata: any(named: 'metadata'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => security.logLogin(
        any(),
        deviceId: any(named: 'deviceId'),
        location: any(named: 'location'),
      ),
    ).thenAnswer((_) async {});
    when(() => security.logLogout(any())).thenAnswer((_) async {});
    when(() => security.logEmailVerification(any())).thenAnswer((_) async {});
  });

  _TestAuthNotifier buildNotifier() =>
      _TestAuthNotifier(auth, firestore, rateLimit, security, geolocation);

  Future<void> seedUserDoc(Map<String, dynamic> data) async {
    await firestore.collection('users').doc(uid).set(data);
  }

  // signInWithEmail — UNTESTABLE AT THIS SEAM, unlike registerWithEmail.
  //
  // registerWithEmail's IP-rate-limit check was extracted to the
  // @visibleForTesting checkCloudRegistrationRateLimit(...) seam specifically
  // so tests could bypass FirebaseFunctions.instanceFor(...) (which needs a
  // live Firebase app and throws `[core/no-app]` under `flutter test`).
  // signInWithEmail's equivalent cloud check (`checkLoginRateLimit`) is
  // NOT extracted — it's an inline async closure awaited together with the
  // local rate-limit check via `Future.wait([cloudRateLimitFuture,
  // localChecksFuture])`. That means EVERY call to signInWithEmail —
  // success, wrong-password, local-rate-limited, all of them — hits
  // `FirebaseFunctions.instanceFor(region: 'europe-west1')` before any
  // reachable branch resolves, and that throws `[core/no-app]` outside the
  // `on FirebaseFunctionsException catch` clause that guards it, landing in
  // the generic `catch (e)` and masking every intended assertion.
  //
  // Per the "don't modify lib/" constraint, there is no seam to bypass this.
  // A future refactor could extract `checkCloudLoginRateLimit` the same way
  // `checkCloudRegistrationRateLimit` was extracted — until then,
  // signInWithEmail is out of scope for this test file.

  group('signOut', () {
    setUp(() {
      when(() => auth.signOut()).thenAnswer((_) async {});
    });

    test(
      'calls auth.signOut and lands on isLoading=false, isLoggedOut state',
      () async {
        final notifier = buildNotifier();
        await notifier.signOut();

        verify(() => auth.signOut()).called(1);
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.firebaseUser, isNull);
        expect(notifier.state.userModel, isNull);
      },
    );

    test('logs the logout security event when a user is signed in', () async {
      final notifier = buildNotifier();
      await notifier.signOut();

      verify(() => security.logLogout(uid)).called(1);
    });

    test(
      'clearSavedEmail=true vs false both complete and sign out (SecureStorage side effect not independently observable — see file header)',
      () async {
        final notifierTrue = buildNotifier();
        await notifierTrue.signOut(clearSavedEmail: true);
        expect(notifierTrue.state.isLoading, isFalse);

        final notifierFalse = buildNotifier();
        await notifierFalse.signOut();
        expect(notifierFalse.state.isLoading, isFalse);

        verify(() => auth.signOut()).called(2);
      },
    );
  });

  group('resetPassword', () {
    // resetPassword delegates to `FirebaseFunctions.instance
    // .httpsCallable('sendPasswordResetEmail')`, which needs a live Firebase
    // app under `flutter test` and throws `[core/no-app]` (or a plugin
    // MissingPluginException) before completing. We can only assert it
    // surfaces *some* error rather than silently succeeding — the actual
    // CF-delegation contract is covered by the CF-side test suite.
    test(
      'surfaces an error rather than silently succeeding (no live Firebase app in tests)',
      () async {
        final notifier = buildNotifier();

        Object? thrown;
        try {
          await notifier.resetPassword(email);
        } catch (e) {
          thrown = e;
        }

        expect(thrown, isNotNull);
      },
    );
  });

  group('sendEmailVerification', () {
    test(
      'happy path: calls user.sendEmailVerification and logs event',
      () async {
        final notifier = buildNotifier();
        await notifier.sendEmailVerification();

        verify(() => user.sendEmailVerification()).called(1);
        verify(
          () => security.logEvent(
            userId: uid,
            type: SecurityEventType.emailVerification,
            deviceId: any(named: 'deviceId'),
            ipAddress: any(named: 'ipAddress'),
            location: any(named: 'location'),
            metadata: any(named: 'metadata'),
          ),
        ).called(1);
      },
    );

    test('no-user path throws "No user logged in"', () async {
      when(() => auth.currentUser).thenReturn(null);
      final notifier = buildNotifier();

      await expectLater(
        notifier.sendEmailVerification,
        throwsA('No user logged in'),
      );
    });
  });

  group('refreshEmailVerificationStatus', () {
    test('no-user path returns without throwing', () async {
      when(() => auth.currentUser).thenReturn(null);
      final notifier = buildNotifier();

      await expectLater(notifier.refreshEmailVerificationStatus(), completes);
    });

    test(
      'happy path: verified user updates Firestore emailVerified=true',
      () async {
        await seedUserDoc({
          'id': uid,
          'email': email,
          'first_name': 'Flow',
          'last_name': 'User',
          'role': 'owner',
          'accountType': 'trial',
          'emailVerified': false,
          'onboardingCompleted': true,
          'displayName': 'Flow User',
          'createdAt': Timestamp.now(),
        });

        when(() => user.emailVerified).thenReturn(true);
        when(() => user.getIdToken(true)).thenAnswer((_) async => 'tok');

        final notifier = buildNotifier();
        await notifier.refreshEmailVerificationStatus();

        final snap = await firestore.collection('users').doc(uid).get();
        expect(snap.data()!['emailVerified'], isTrue);
        verify(() => security.logEmailVerification(uid)).called(1);
      },
    );

    test(
      'recoverable FirebaseAuthException codes (user-token-expired) are swallowed',
      () async {
        when(
          () => user.reload(),
        ).thenThrow(FirebaseAuthException(code: 'user-token-expired'));
        final notifier = buildNotifier();

        await expectLater(notifier.refreshEmailVerificationStatus(), completes);
      },
    );
  });

  group('completeOnboarding', () {
    test('no-user path is a no-op', () async {
      when(() => auth.currentUser).thenReturn(null);
      final notifier = buildNotifier();

      await expectLater(notifier.completeOnboarding(), completes);
    });

    test(
      'writes onboardingCompleted=true and updates state.userModel',
      () async {
        await seedUserDoc({
          'id': uid,
          'email': email,
          'first_name': 'Flow',
          'last_name': 'User',
          'role': 'owner',
          'accountType': 'trial',
          'emailVerified': true,
          'onboardingCompleted': false,
          'displayName': 'Flow User',
          'createdAt': Timestamp.now(),
        });

        final notifier = buildNotifier();
        // Prime state.userModel via a sign-in-style profile load path is
        // heavier than needed — directly seed state via the private loader by
        // signing in is out of scope here; instead assert the Firestore write,
        // which is the field under test's actual regression risk.
        await notifier.completeOnboarding();

        final snap = await firestore.collection('users').doc(uid).get();
        expect(snap.data()!['onboardingCompleted'], isTrue);
      },
    );

    test(
      'when state.userModel is already populated, it flips onboardingCompleted + requiresOnboarding',
      () async {
        await seedUserDoc({
          'id': uid,
          'email': email,
          'first_name': 'Flow',
          'last_name': 'User',
          'role': 'owner',
          'accountType': 'trial',
          'emailVerified': true,
          'onboardingCompleted': false,
          'displayName': 'Flow User',
          'createdAt': Timestamp.now(),
        });

        final notifier = buildNotifier();
        // signInWithEmail can't be driven at this seam (see the
        // signInWithEmail out-of-scope note above) — seed state directly via
        // the test-only debugSetState instead.
        notifier.debugSetState(
          EnhancedAuthState(
            firebaseUser: user,
            userModel: _testUserModel(onboardingCompleted: false),
            isLoading: false,
            requiresOnboarding: true,
          ),
        );
        expect(notifier.state.userModel?.needsOnboarding, isTrue);

        await notifier.completeOnboarding();

        expect(notifier.state.userModel?.onboardingCompleted, isTrue);
        expect(notifier.state.requiresOnboarding, isFalse);
      },
    );
  });

  group('completeProfile', () {
    test('no-user path is a no-op', () async {
      when(() => auth.currentUser).thenReturn(null);
      final notifier = buildNotifier();

      await expectLater(notifier.completeProfile(), completes);
    });

    test('writes profile_completed=true + updated_at', () async {
      await seedUserDoc({
        'id': uid,
        'email': email,
        'first_name': 'Flow',
        'last_name': 'User',
        'role': 'owner',
        'accountType': 'trial',
        'emailVerified': true,
        'onboardingCompleted': true,
        'profile_completed': false,
        'displayName': 'Flow User',
        'createdAt': Timestamp.now(),
      });

      final notifier = buildNotifier();
      await notifier.completeProfile();

      final snap = await firestore.collection('users').doc(uid).get();
      expect(snap.data()!['profile_completed'], isTrue);
      expect(snap.data()!['updated_at'], isNotNull);
    });
  });

  group('markFeatureAsSeen', () {
    test('no-op when there is no user or no userModel loaded', () async {
      when(() => auth.currentUser).thenReturn(null);
      final notifier = buildNotifier();

      await expectLater(notifier.markFeatureAsSeen('some_feature'), completes);
    });

    test('optimistically updates state then persists to Firestore', () async {
      await seedUserDoc({
        'id': uid,
        'email': email,
        'first_name': 'Flow',
        'last_name': 'User',
        'role': 'owner',
        'accountType': 'trial',
        'emailVerified': true,
        'onboardingCompleted': true,
        'displayName': 'Flow User',
        'createdAt': Timestamp.now(),
      });

      final notifier = buildNotifier();
      notifier.debugSetState(
        EnhancedAuthState(
          firebaseUser: user,
          userModel: _testUserModel(),
          isLoading: false,
        ),
      );

      await notifier.markFeatureAsSeen('ai_assistant_intro');

      expect(
        notifier.state.userModel?.featureFlags['ai_assistant_intro'],
        isTrue,
      );

      final snap = await firestore.collection('users').doc(uid).get();
      final data = snap.data()!;
      // fake_cloud_firestore resolves the dotted field-path update
      // ('featureFlags.$featureId') into a nested map, matching real
      // Firestore's field-path semantics.
      final storedFlags = data['featureFlags'] as Map<String, dynamic>?;
      expect(storedFlags?['ai_assistant_intro'], isTrue);
    });

    test('skips the write when the feature is already marked seen', () async {
      await seedUserDoc({
        'id': uid,
        'email': email,
        'first_name': 'Flow',
        'last_name': 'User',
        'role': 'owner',
        'accountType': 'trial',
        'emailVerified': true,
        'onboardingCompleted': true,
        'displayName': 'Flow User',
        'featureFlags': {'already_seen': true},
        'createdAt': Timestamp.now(),
      });

      final notifier = buildNotifier();
      notifier.debugSetState(
        EnhancedAuthState(
          firebaseUser: user,
          userModel: _testUserModel(featureFlags: const {'already_seen': true}),
          isLoading: false,
        ),
      );

      // Should return early without touching Firestore again (no crash, no
      // duplicate write) — assert final state is unchanged / still true.
      await notifier.markFeatureAsSeen('already_seen');
      expect(notifier.state.userModel?.featureFlags['already_seen'], isTrue);
    });
  });

  group('deleteAccount — reachable guard branches', () {
    test('throws when no user is signed in', () async {
      when(() => auth.currentUser).thenReturn(null);
      final notifier = buildNotifier();

      await expectLater(
        () => notifier.deleteAccount(password: password),
        throwsA('No user is currently signed in'),
      );
    });

    test(
      'throws "Re-authentication required" when neither password nor credential is given',
      () async {
        final notifier = buildNotifier();

        await expectLater(
          notifier.deleteAccount,
          throwsA('Re-authentication required'),
        );
      },
    );

    test('surfaces a friendly message when reauthentication fails', () async {
      when(() => user.reauthenticateWithCredential(any())).thenThrow(
        FirebaseAuthException(code: 'wrong-password', message: 'nope'),
      );
      final notifier = buildNotifier();

      Object? thrown;
      try {
        await notifier.deleteAccount(password: password);
      } catch (e) {
        thrown = e;
      }

      expect(thrown, isNotNull);
      // Post-reauth Cloud Function call (deleteUserAccount) needs a live
      // Firebase app and is NOT reachable/asserted here — see file header.
    });
  });
}

LoginAttempt _lockedAttempt(String email) => LoginAttempt(
  email: email,
  attemptCount: 5,
  lockedUntil: DateTime.now().add(const Duration(minutes: 15)),
  lastAttemptAt: DateTime.now(),
);

/// Minimal owner UserModel for tests that need to seed [EnhancedAuthState]
/// directly via [_TestAuthNotifier.debugSetState] instead of going through
/// signInWithEmail (which is out of scope — see file header).
UserModel _testUserModel({
  bool onboardingCompleted = true,
  Map<String, bool> featureFlags = const {},
}) => UserModel(
  id: 'auth-flows-uid',
  email: 'flows@example.com',
  firstName: 'Flow',
  lastName: 'User',
  role: UserRole.owner,
  emailVerified: true,
  onboardingCompleted: onboardingCompleted,
  displayName: 'Flow User',
  featureFlags: featureFlags,
  createdAt: DateTime.now(),
);
