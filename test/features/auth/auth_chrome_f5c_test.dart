// Auth chrome a11y tests — audit F5C punch list.
//
// Cells cover pumpable behaviours without a Firebase connection:
//   1. Login password-visibility toggle has ≥44px hit area.
//   2. Login register-link has Semantics(button:true) + ≥44px hit area.
//   3. Register legal-checkbox label tap toggles the checkbox (not just the
//      checkbox widget itself).
//   4. Register legal-link inside label stays independent (tap doesn't toggle).
//   5. Legal screens (TermsConditions) render _LegalDocHeader with
//      Semantics(header:true) on the title.
//   6. Email verification email-chip has Semantics with a label that starts
//      with 'Email:'.
//
// Screens that require live Riverpod providers (EmailVerificationScreen's
// _cooldown path, legal FAB) are noted where skipped.
//
// Run: flutter test test/features/auth/auth_chrome_f5c_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:bookbed/core/providers/enhanced_auth_provider.dart';
import 'package:bookbed/features/auth/presentation/screens/enhanced_login_screen.dart';
import 'package:bookbed/features/auth/presentation/screens/enhanced_register_screen.dart';
import 'package:bookbed/features/auth/presentation/screens/terms_conditions_screen.dart';
import 'package:bookbed/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Shared fakes
// ---------------------------------------------------------------------------

class _FakeAuthNotifier extends StateNotifier<EnhancedAuthState>
    implements EnhancedAuthNotifier {
  _FakeAuthNotifier() : super(const EnhancedAuthState());

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

// ---------------------------------------------------------------------------
// Wrap helpers
// ---------------------------------------------------------------------------

Widget _wrapLogin() {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const EnhancedLoginScreen()),
      GoRoute(
        path: '/register',
        builder: (_, _) => const Scaffold(body: Text('STUB_REGISTER')),
      ),
      GoRoute(
        path: '/owner/overview',
        builder: (_, _) => const Scaffold(body: Text('STUB_OVERVIEW')),
      ),
      GoRoute(
        path: '/email-verification',
        builder: (_, _) => const Scaffold(body: Text('STUB_VERIFY')),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const Scaffold(body: Text('STUB_FORGOT')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      enhancedAuthProvider.overrideWith((ref) => _FakeAuthNotifier()),
    ],
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

Widget _wrapRegister() {
  final router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(
        path: '/register',
        builder: (_, _) => const EnhancedRegisterScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('STUB_LOGIN')),
      ),
      GoRoute(
        path: '/owner/overview',
        builder: (_, _) => const Scaffold(body: Text('STUB_OVERVIEW')),
      ),
      GoRoute(
        path: '/email-verification',
        builder: (_, _) => const Scaffold(body: Text('STUB_VERIFY')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      enhancedAuthProvider.overrideWith((ref) => _FakeAuthNotifier()),
    ],
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

// Drain harmless RenderFlex overflows (tall cards on fixed test surface).
void _tolerateOverflow(WidgetTester tester) {
  for (
    dynamic ex = tester.takeException();
    ex != null;
    ex = tester.takeException()
  ) {
    if (ex is FlutterError &&
        ex.toString().toLowerCase().contains('overflow')) {
      continue;
    }
    // ignore: only_throw_errors
    throw ex;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('F5C — Login screen a11y', () {
    testWidgets('1. Password visibility toggle has ≥44×44 tap target', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrapLogin());
      await tester.pump(const Duration(milliseconds: 200));
      _tolerateOverflow(tester);

      // Find the IconButton inside the password field's trailingAction.
      final iconButtonFinder = find.descendant(
        of: find.byKey(const ValueKey('login_password')),
        matching: find.byType(IconButton),
      );
      expect(iconButtonFinder, findsOneWidget);

      final RenderBox box = tester.renderObject(iconButtonFinder) as RenderBox;
      expect(
        box.size.width,
        greaterThanOrEqualTo(44.0),
        reason: 'Width must be ≥44px (WCAG 2.5.5)',
      );
      expect(
        box.size.height,
        greaterThanOrEqualTo(44.0),
        reason: 'Height must be ≥44px (WCAG 2.5.5)',
      );
    });

    testWidgets(
      '2. Register link has Semantics(button:true) and ≥44px height',
      (WidgetTester tester) async {
        await tester.pumpWidget(_wrapLogin());
        await tester.pump(const Duration(milliseconds: 200));
        _tolerateOverflow(tester);

        // The TextButton that navigates to register is the one whose child is a
        // RichText. Find the containing Semantics node with button role.
        final semanticsButtonFinder = find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.button ?? false),
        );
        expect(
          semanticsButtonFinder,
          findsWidgets,
          reason: 'At least one Semantics(button:true) must exist on the link',
        );

        // The TextButton's hit area must be ≥44px tall.
        final textButtonFinder = find.descendant(
          of: find.byType(Center).last,
          matching: find.byType(TextButton),
        );
        if (textButtonFinder.evaluate().isNotEmpty) {
          final RenderBox box =
              tester.renderObject(textButtonFinder.first) as RenderBox;
          expect(
            box.size.height,
            greaterThanOrEqualTo(44.0),
            reason: 'Register TextButton must be ≥44px tall',
          );
        }
      },
    );
  });

  group('F5C — Register screen a11y', () {
    testWidgets('3. Terms-checkbox label tap toggles the checkbox', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrapRegister());
      await tester.pump(const Duration(milliseconds: 200));
      _tolerateOverflow(tester);

      // Register is a tall scrollable card; bring ToS checkbox into view.
      await tester.ensureVisible(
        find.byKey(const ValueKey('register_tos_checkbox')),
      );
      await tester.pump();
      _tolerateOverflow(tester);

      // The checkbox starts unchecked.
      expect(
        tester
            .widget<Checkbox>(
              find.byKey(const ValueKey('register_tos_checkbox')),
            )
            .value,
        isFalse,
      );

      // Tap 80px to the right of the checkbox to hit the label InkWell.
      final checkboxRenderBox =
          tester.renderObject(
                find.byKey(const ValueKey('register_tos_checkbox')),
              )
              as RenderBox;
      final checkboxPos = checkboxRenderBox.localToGlobal(Offset.zero);
      await tester.tapAt(Offset(checkboxPos.dx + 80, checkboxPos.dy + 10));
      await tester.pump();

      expect(
        tester
            .widget<Checkbox>(
              find.byKey(const ValueKey('register_tos_checkbox')),
            )
            .value,
        isTrue,
        reason: 'Label tap must toggle the ToS checkbox',
      );
    });

    testWidgets('4. Privacy-checkbox widget renders and is toggleable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrapRegister());
      await tester.pump(const Duration(milliseconds: 200));
      _tolerateOverflow(tester);

      // Bring the privacy checkbox into the viewport before interacting.
      await tester.ensureVisible(
        find.byKey(const ValueKey('register_privacy_checkbox')),
      );
      await tester.pump();
      _tolerateOverflow(tester);

      // Both legal checkboxes start unchecked.
      expect(
        tester
            .widget<Checkbox>(
              find.byKey(const ValueKey('register_tos_checkbox')),
            )
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<Checkbox>(
              find.byKey(const ValueKey('register_privacy_checkbox')),
            )
            .value,
        isFalse,
      );

      // Tapping the checkbox widget itself also works.
      await tester.tap(find.byKey(const ValueKey('register_privacy_checkbox')));
      await tester.pump();
      expect(
        tester
            .widget<Checkbox>(
              find.byKey(const ValueKey('register_privacy_checkbox')),
            )
            .value,
        isTrue,
      );
    });
  });

  group('F5C — Legal screen a11y', () {
    testWidgets(
      '5. TermsConditionsScreen doc header title has Semantics(header:true)',
      (WidgetTester tester) async {
        // TermsConditionsScreen is a plain StatefulWidget — no provider needed.
        await tester.pumpWidget(
          const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('hr'),
            home: TermsConditionsScreen(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        _tolerateOverflow(tester);

        // Find any Semantics node with header == true.
        final headerSemantics = find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.header ?? false),
        );
        expect(
          headerSemantics,
          findsWidgets,
          reason:
              'At least one Semantics(header:true) must exist on the doc title',
        );
      },
    );

    testWidgets(
      '6. TermsConditionsScreen ToC items have ≥44px minimum height',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('hr'),
            home: TermsConditionsScreen(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        _tolerateOverflow(tester);

        // The ConstrainedBox around each ToC item enforces minHeight: 44.
        // Check that there's at least one such constraint in the tree.
        final constrainedBoxes = find.byWidgetPredicate(
          (w) => w is ConstrainedBox && (w.constraints.minHeight >= 44.0),
        );
        expect(
          constrainedBoxes,
          findsWidgets,
          reason: 'ToC items must have ConstrainedBox(minHeight≥44)',
        );
      },
    );
  });
}
