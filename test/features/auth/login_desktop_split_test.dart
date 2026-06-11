// Desktop login split regression (audit/124): at ≥1200 logical width the
// login route renders the handoff pitch panel (auth.jsx AuthLoginDesktop)
// beside the 560px glass card — and lays out without flex/height blowups
// inside the keyboard-aware scroll view.
//
// Run: flutter test test/features/auth/login_desktop_split_test.dart

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
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

Widget _wrap() {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const EnhancedLoginScreen()),
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

    expect(find.text('OWNER APLIKACIJA'), findsOneWidget);
    expect(find.text('45+'), findsOneWidget);
    expect(find.text('99.9%'), findsOneWidget);
    expect(find.byKey(const ValueKey('login_email')), findsOneWidget);
  });

  testWidgets('<1200: centered card only, no pitch panel', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('OWNER APLIKACIJA'), findsNothing);
    expect(find.byKey(const ValueKey('login_email')), findsOneWidget);
  });
}
