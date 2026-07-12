// Permanent regression guard for the registration → users/{uid} CREATE contract.
//
// Background: PR #514 (anti-escalation hardening) added `role` to the users
// CREATE blocklist in firestore.rules. Registration writes `role: 'owner'` on
// first create, so every signup write was denied → the Auth user was created
// but its profile doc never landed → the next login died in `_loadUserProfile`
// ("Pristup odbijen"). PR #737 fixed it two ways: rules now value-PIN
// `role == 'owner'` at create (instead of key-blocking it), and the client wraps
// the profile `.set()` in try/catch that rolls the orphaned Auth user back.
//
// The rules side is covered by users.test.ts cases 10-12. This file covers the
// CLIENT half of the contract — the half that actually regressed and had NO
// test: (1) registration sends exactly `role: 'owner'` and none of the fields
// the create rule rejects; (2) a failed profile write deletes the Auth user.
//
// See memory/registration-userdoc-rules-create-blocklist.md.

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

// Firestore chain mocks for the rollback test. FakeFirebaseFirestore always
// succeeds, so to simulate a denied/failed profile write we mock the
// collection → doc → set() chain and make set() throw.
class _MockFirestore extends Mock implements FirebaseFirestore {}

// mocktail must implement the sealed CollectionReference (a Query subtype)
// to stub the collection('users').doc(uid) chain.
// ignore: subtype_of_sealed_class
class _MockUsersCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// mocktail must implement the sealed DocumentReference so set() can throw —
// FakeFirebaseFirestore always succeeds and can't simulate a denied write.
// ignore: subtype_of_sealed_class
class _MockUserDoc extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

/// [EnhancedAuthNotifier] with the Cloud-Function IP rate-limit check stubbed
/// out. The real check calls `FirebaseFunctions.instanceFor`, which needs a
/// live Firebase app (unavailable under `flutter test`) and otherwise throws
/// `[core/no-app]` before registration ever reaches the profile write. The
/// production seam ([EnhancedAuthNotifier.checkCloudRegistrationRateLimit]) is
/// `@visibleForTesting` precisely so this subclass can no-op it — mirroring the
/// repo's Fake-bypass pattern for FirebaseFunctions in the widget repo tests.
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(SecurityEventType.registration);
    registerFallbackValue(<String, dynamic>{});
  });

  late _MockFirebaseAuth auth;
  late _MockRateLimitService rateLimit;
  late _MockSecurityEventsService security;
  late _MockIpGeolocationService geolocation;
  late _MockUserCredential credential;
  late _MockUser user;

  const uid = 'new-owner-uid';
  // No sequential or repeating runs → passes PasswordValidator (SF-006).
  const password = 'Gx7w!Kp2mZ';

  // The exact key set the users CREATE rule rejects (firestore.rules
  // `allow create` blocklist). Registration must never send any of these.
  const blockedCreateFields = <String>[
    'accountStatus',
    'trialStartDate',
    'trialExpiresAt',
    'statusChangedAt',
    'statusChangedBy',
    'account_type',
    'admin_override_account_type',
    'lifetime_license_granted_at',
    'lifetime_license_granted_by',
    'isAdmin',
    'stripe_account_id',
    'stripe_customer_id',
    'stripe_connected_at',
    'stripeSubscriptionId',
    'stripeCustomerId',
  ];

  setUp(() {
    auth = _MockFirebaseAuth();
    rateLimit = _MockRateLimitService();
    security = _MockSecurityEventsService();
    geolocation = _MockIpGeolocationService();
    credential = _MockUserCredential();
    user = _MockUser();

    // Constructor subscribes to authStateChanges(); an empty stream means no
    // profile load fires and no sign-out grace timer is armed.
    when(
      () => auth.authStateChanges(),
    ).thenAnswer((_) => const Stream<User?>.empty());
    when(
      () => auth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => credential);
    when(() => credential.user).thenReturn(user);
    when(() => user.uid).thenReturn(uid);
    when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
    when(() => user.sendEmailVerification()).thenAnswer((_) async {});
    when(() => user.delete()).thenAnswer((_) async {});

    when(() => rateLimit.checkRateLimit(any())).thenAnswer((_) async => null);
    when(() => rateLimit.resetAttempts(any())).thenAnswer((_) async {});
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
  });

  group('registerWithEmail — users/{uid} CREATE payload (PR #737 / #514)', () {
    test('writes role:"owner" and none of the rule-blocked fields', () async {
      final firestore = FakeFirebaseFirestore();
      final notifier = _TestAuthNotifier(
        auth,
        firestore,
        rateLimit,
        security,
        geolocation,
      );

      // The profile write happens, then the happy path touches
      // AnalyticsService.instance (FirebaseAnalytics → needs a live app) and
      // throws a test-environment error. That is AFTER the write, so we tolerate
      // it and assert the write — the contract that regressed.
      try {
        await notifier.registerWithEmail(
          email: 'new.owner@example.com',
          password: password,
          firstName: 'New',
          lastName: 'Owner',
          acceptedTerms: true,
          acceptedPrivacy: true,
        );
      } catch (_) {
        // Post-write Firebase-only side effects are out of scope here.
      }

      expect(
        notifier.cloudRateLimitCalls,
        1,
        reason: 'registration must run the IP rate-limit seam exactly once',
      );

      final snap = await firestore.collection('users').doc(uid).get();
      expect(
        snap.exists,
        isTrue,
        reason:
            'registration must create users/{uid}; PR #514 denied this '
            'write and orphaned the Auth account',
      );

      final data = snap.data()!;

      // THE regression: the create rule value-pins role to the literal 'owner'.
      // A drift to 'admin' or anything else is denied in prod → orphaned account
      // and broken login, exactly the #737 failure.
      expect(data['role'], 'owner');

      // Identity fields registration is allowed to set.
      expect(data['email'], 'new.owner@example.com');
      expect(data['first_name'], 'New');
      expect(data['last_name'], 'Owner');
      expect(data['displayName'], 'New Owner');
      // New signups start on the trial tier.
      expect(data['accountType'], AccountType.trial.name);

      // The canonical creation timestamp MUST be written under the snake_case
      // `created_at` — that is what [UserModel] deserializes and what the admin
      // Users list orders by. Writing only the legacy camelCase `createdAt` made
      // every app-created owner invisible there: Firestore's
      // `orderBy('created_at')` silently drops documents missing the field, so
      // the owner was excluded from the list while still counted by the `.count()`
      // badge (PROD: 11 of 23 owners hidden). Guards that regression.
      expect(
        data['created_at'],
        isNotNull,
        reason: 'missing created_at → owner invisible in the admin Users list',
      );

      // SECURITY: the payload must not carry any field the create rule rejects
      // (privilege/billing/status/Stripe linkage). Sending one would re-break
      // the whole signup write.
      for (final blocked in blockedCreateFields) {
        expect(
          data.containsKey(blocked),
          isFalse,
          reason:
              'registration payload must not contain rule-blocked field '
              '"$blocked"',
        );
      }
    });
  });

  group('registerWithEmail — orphan rollback (PR #737 safety)', () {
    test('deletes the Auth user when the profile write fails', () async {
      final firestore = _MockFirestore();
      final usersCol = _MockUsersCollection();
      final userDoc = _MockUserDoc();
      when(() => firestore.collection('users')).thenReturn(usersCol);
      when(() => usersCol.doc(uid)).thenReturn(userDoc);
      when(() => userDoc.set(any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );

      final notifier = _TestAuthNotifier(
        auth,
        firestore,
        rateLimit,
        security,
        geolocation,
      );

      Object? thrown;
      try {
        await notifier.registerWithEmail(
          email: 'denied.owner@example.com',
          password: password,
          firstName: 'Denied',
          lastName: 'Owner',
          acceptedTerms: true,
          acceptedPrivacy: true,
        );
      } catch (e) {
        thrown = e;
      }

      // #737: a failed profile write must roll the just-created Auth user back,
      // so a half-account can't survive to break login later.
      verify(() => user.delete()).called(1);

      // …and registration must fail loud (the user-facing retry message), not
      // pretend success.
      expect(thrown, isNotNull);
      expect(thrown.toString(), contains('could not be completed'));
    });
  });
}
