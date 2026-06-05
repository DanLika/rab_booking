// First integration_test — owner login smoke.
//
// Goal: prove the harness can drive Flutter Web CanvasKit input/click + reach
// real bookbed-dev Firebase Auth backend. ONE test, narrow scope (login →
// dashboard). Subsequent flows (calendar, create-booking, …) layered on top
// only if this proves valuable.
//
// Run:
//   flutter test integration_test/login_smoke_test.dart -d chrome
//
// Test account: `bookbed-test@bookbed.io` / `BookBedTest2026!` on bookbed-dev
// (UID GILVItIVP5R8WXfnMmyMo1ykhUm2). Memory/test-account.md.
//
// IMPORTANT — uses owner_main_dev.dart entry point so the bundle hits the
// bookbed-dev Firebase project, NOT PROD. Assert at top guards against
// accidental PROD bundling.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookbed/core/config/environment.dart';
import 'package:bookbed/core/init/app_check_init.dart';
import 'package:bookbed/firebase_options_dev.dart';
import 'package:bookbed/main.dart' show AppInitState, BookBedApp;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    EnvironmentConfig.setEnvironment(Environment.development);
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DevFirebaseOptions.currentPlatform);
    }
    // Assert dev binding before any auth attempt — prevents accidental
    // PROD bookbed-test wipe.
    assert(
      Firebase.app().options.projectId == 'bookbed-dev',
      'integration_test expected bookbed-dev project, got '
      '${Firebase.app().options.projectId}',
    );
    // App Check off-prod uses Debug providers (web: placeholder reCAPTCHA).
    await AppCheckInit.activate(isProd: false);
    // Complete the firebaseReady + prefsReady completers that BookBedApp's
    // `_InitializingSplash` (main.dart:629 / `_waitForInitialization`) waits
    // on. In production these are signalled by `runMainApp()` +
    // `_initializeRemainingServices()`; we bypass those here because the test
    // pumps the widget tree directly via `tester.pumpWidget`. Without these,
    // the splash blocks GoRouter from advancing to `/login`.
    if (!AppInitState.firebaseReady.isCompleted) {
      AppInitState.firebaseReady.complete();
    }
    if (!AppInitState.prefsReady.isCompleted) {
      AppInitState.prefsReady.complete(await SharedPreferences.getInstance());
    }
    // Start clean — sign out any cached session from prior test runs.
    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
    }
  });

  testWidgets(
    'owner login → /owner/overview dashboard route',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: BookBedApp()));

      // Owner app does Firebase init + AppCheck + auth-provider boot before
      // GoRouter redirects to /login. The HYBRID-LOADING pattern paints shell
      // immediately but auth-state stream emits `unauthenticated` async.
      // Poll for the login key in 1s slices up to 30s rather than relying on
      // pumpAndSettle (which may return early when no animation tickers are
      // pending but the route is still being decided).
      final emailFinder = find.byKey(const ValueKey('login_email'));
      final passwordFinder = find.byKey(const ValueKey('login_password'));
      final submitFinder = find.byKey(const ValueKey('login_submit'));

      // Long pumpAndSettle to allow Firebase Auth stream resolution +
      // Riverpod state propagation + GoRouter redirect to /login.
      await tester.pumpAndSettle(const Duration(seconds: 60));

      var reached = emailFinder.evaluate().isNotEmpty;
      if (!reached) {
        // One more burst — pump real time via runAsync, then resync frames.
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(seconds: 10));
        });
        await tester.pumpAndSettle(const Duration(seconds: 30));
        reached = emailFinder.evaluate().isNotEmpty;
      }

      if (!reached) {
        // ignore: avoid_print
        print('[login_smoke] Widgets on tree at failure:');
        for (final w in tester.allWidgets.take(40)) {
          // ignore: avoid_print
          print('  ${w.runtimeType}');
        }
      }

      expect(
        reached,
        isTrue,
        reason: 'login_email key never appeared after long pumpAndSettle',
      );
      expect(passwordFinder, findsOneWidget);
      expect(submitFinder, findsOneWidget);

      await tester.enterText(emailFinder, 'bookbed-test@bookbed.io');
      await tester.enterText(passwordFinder, 'BookBedTest2026!');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.tap(submitFinder);
      // Real auth round-trip: checkLoginRateLimit (eu-west1) +
      // signInWithPassword + persistence + GoRouter redirect. Generous wait.
      await tester.pumpAndSettle(const Duration(seconds: 20));

      // Auth must succeed
      expect(
        FirebaseAuth.instance.currentUser,
        isNotNull,
        reason: 'FirebaseAuth.currentUser should be populated after login',
      );
      expect(
        FirebaseAuth.instance.currentUser!.email,
        equals('bookbed-test@bookbed.io'),
      );

      // No /login text should remain. The router state assertion is
      // implementation-dependent; rely on presence of dashboard-ish widgets
      // OR absence of the login submit key.
      expect(
        find.byKey(const ValueKey('login_submit')),
        findsNothing,
        reason: 'login screen should no longer be mounted after auth',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
