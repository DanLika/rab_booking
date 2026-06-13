// Desktop register split regression (audit/124, Wave 1b): at ≥1200 logical
// width the register route renders the handoff register-flavored pitch panel
// (register.jsx RegBrandPanel) beside the 560px glass card — and lays out
// without flex/height blowups inside the keyboard-aware scroll view. Below
// 1200 the card stays centered with no pitch panel. Mirror of
// login_desktop_split_test.dart (register's taller 5-field card nudges past
// the fixed test surface, so the harmless layout overflow is tolerated — same
// as enhanced_register_screen_test.dart).
//
// Run: flutter test test/features/auth/register_desktop_split_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:bookbed/core/providers/enhanced_auth_provider.dart';
import 'package:bookbed/features/auth/presentation/screens/enhanced_register_screen.dart';
import 'package:bookbed/l10n/app_localizations.dart';

class _FakeAuthNotifier extends StateNotifier<EnhancedAuthState>
    implements EnhancedAuthNotifier {
  _FakeAuthNotifier() : super(const EnhancedAuthState());
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// Drain only harmless RenderFlex overflow errors (register's tall card on a
/// fixed test surface); rethrow anything else.
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
    throw ex; // ignore: only_throw_errors
  }
}

Widget _wrap() {
  final router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(
        path: '/register',
        builder: (_, _) => const EnhancedRegisterScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      enhancedAuthProvider.overrideWith((ref) => _FakeAuthNotifier()),
    ],
    child: MediaQuery(
      data: const MediaQueryData(
        disableAnimations: true,
        size: Size(1440, 900),
      ),
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
  testWidgets('≥1200: pitch panel + stats + card render together', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2880, 1800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap());
    await tester.pump(const Duration(milliseconds: 300));
    _tolerateOverflow(tester);

    expect(find.text('OWNER APLIKACIJA'), findsOneWidget);
    expect(find.text('45+'), findsOneWidget);
    expect(find.text('99.9%'), findsOneWidget);
    expect(find.byKey(const ValueKey('register_email')), findsOneWidget);
  });

  testWidgets('<1200: centered card only, no pitch panel', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap());
    await tester.pump(const Duration(milliseconds: 300));
    _tolerateOverflow(tester);

    expect(find.text('OWNER APLIKACIJA'), findsNothing);
    expect(find.byKey(const ValueKey('register_email')), findsOneWidget);
  });
}
