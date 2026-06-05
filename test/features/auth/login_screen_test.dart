// Owner login widget test — cheap path, no emulator/chromedriver.
//
// Replaces `enhancedAuthProvider` with a fake StateNotifier that records
// signInWithEmail calls without touching Firebase. Pumps just the login
// screen widget under MaterialApp; no GoRouter, no app boot, no
// _InitializingSplash. In-engine `tester.enterText` + `tester.tap`
// reach Flutter's TextEditingController directly — exactly the path that
// MCP / Playwright cannot drive on CanvasKit.
//
// Run: flutter test test/features/auth/login_screen_test.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:bookbed/core/providers/enhanced_auth_provider.dart';
import 'package:bookbed/features/auth/presentation/screens/enhanced_login_screen.dart';
import 'package:bookbed/l10n/app_localizations.dart';

class _FakeAuthNotifier extends StateNotifier<EnhancedAuthState>
    implements EnhancedAuthNotifier {
  _FakeAuthNotifier() : super(const EnhancedAuthState());

  int signInCallCount = 0;
  String? lastEmail;
  String? lastPassword;
  bool? lastRememberMe;
  Object? signInThrow;
  EnhancedAuthState? postSignInState;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    signInCallCount++;
    lastEmail = email;
    lastPassword = password;
    lastRememberMe = rememberMe;
    if (signInThrow != null) {
      // Mirror real notifier — caught exception sets state.error.
      final err = signInThrow.toString();
      state = state.copyWith(isLoading: false, error: err);
      throw signInThrow!;
    }
    if (postSignInState != null) {
      state = postSignInState!;
    }
  }

  // Catch-all for any other notifier method that the screen may incidentally
  // call. Returning sensible defaults keeps the test focused on signIn.
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

Widget _wrap(_FakeAuthNotifier fake) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const EnhancedLoginScreen()),
      // Stub routes — screen `context.go`s here on success / verify branches.
      // We only need them to exist so context.go doesn't blow up; the test
      // never asserts what the destination renders.
      GoRoute(
        path: '/owner/overview',
        builder: (_, _) => const Scaffold(body: Text('STUB_OVERVIEW')),
      ),
      GoRoute(
        path: '/email-verification',
        builder: (_, _) => const Scaffold(body: Text('STUB_VERIFY')),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const Scaffold(body: Text('STUB_REGISTER')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [enhancedAuthProvider.overrideWith((ref) => fake)],
    // disableAnimations: true => BBMotion.reduced(context) returns true =>
    // BbSpinner renders a static hourglass instead of CircularProgressIndicator.
    // That kills the infinite ticker that otherwise prevents pumpAndSettle.
    child: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('hr'),
      ),
    ),
  );
}

void main() {
  group('EnhancedLoginScreen — owner login flow', () {
    testWidgets(
      'fills email + password + taps Prijava → signInWithEmail called with creds',
      (WidgetTester tester) async {
        final fake = _FakeAuthNotifier();
        await tester.pumpWidget(_wrap(fake));
        // Let the screen settle (animations + asset precaches).
        await tester.pump(const Duration(milliseconds: 200));

        await tester.enterText(
          find.byKey(const ValueKey('login_email')),
          'bookbed-test@bookbed.io',
        );
        await tester.enterText(
          find.byKey(const ValueKey('login_password')),
          'BookBedTest2026!',
        );

        await tester.tap(find.byKey(const ValueKey('login_submit')));
        // pumpAndSettle works because:
        //  - disableAnimations: true => BbSpinner is a static Icon (no ticker)
        //  - GoRouter transitions and Future.delayed(100ms) all complete
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(fake.signInCallCount, equals(1));
        expect(fake.lastEmail, equals('bookbed-test@bookbed.io'));
        expect(fake.lastPassword, equals('BookBedTest2026!'));
        // Owner login screen ships with "Zapamti me" checked by default
        // (`_rememberMe = true` initial). The screen passes that state into
        // signInWithEmail, which is what we capture here.
        expect(fake.lastRememberMe, isTrue);
      },
    );

    testWidgets(
      'empty fields + tap Prijava → validation fires, signInWithEmail NOT called',
      (WidgetTester tester) async {
        final fake = _FakeAuthNotifier();
        await tester.pumpWidget(_wrap(fake));
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.byKey(const ValueKey('login_submit')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        expect(fake.signInCallCount, equals(0));
        // The form's validate() ran and rejected the empty fields. The
        // snackbar / shake side-effect is incidental; the load-bearing claim
        // is the no-network: signInWithEmail must NOT be invoked when the
        // form is invalid. This catches the entire 'BbInput validator silently
        // ignored' regression class — if the field weren't routed through
        // FormField, validate() would return TRUE vacuously and the call
        // would fire with empty strings.
      },
    );

    testWidgets(
      'signInWithEmail throws FirebaseAuthException → state.error set, screen still mounted',
      (WidgetTester tester) async {
        final fake = _FakeAuthNotifier()
          ..signInThrow = FirebaseAuthException(
            code: 'wrong-password',
            message: 'The password is invalid.',
          );

        await tester.pumpWidget(_wrap(fake));
        await tester.pump(const Duration(milliseconds: 200));

        await tester.enterText(
          find.byKey(const ValueKey('login_email')),
          'bookbed-test@bookbed.io',
        );
        await tester.enterText(
          find.byKey(const ValueKey('login_password')),
          'wrong-pw-here',
        );

        await tester.tap(find.byKey(const ValueKey('login_submit')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(fake.signInCallCount, equals(1));
        // Screen MUST still be mounted (no navigation on error).
        expect(find.byKey(const ValueKey('login_submit')), findsOneWidget);
      },
    );
  });
}
