// Seam test for the admin topbar OWNERS-ONLY global search
// (design/admin-shell.jsx AdminTopbar, L117-123).
//
// Proves:
//  1. Desktop/tablet (showMenuButton:false) → the search input renders.
//  2. Mobile (showMenuButton:true) → the search input is HIDDEN (handoff gate).
//  3. Submitting a query publishes it to `adminOwnersSearchQueryProvider` AND
//     routes to `/users` — reusing the existing owners filter, no new backend.
//
// `_AdminEnvPill` self-hides when Firebase is uninitialised, so the topbar
// pumps without Firebase/auth.

import 'package:bookbed/features/admin/presentation/screens/admin_shell_screen.dart';
import 'package:bookbed/features/admin/providers/admin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _harness({
  required ProviderContainer container,
  required bool showMenuButton,
}) {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (_, _) => Scaffold(
          appBar: AppBar(),
          body: buildAdminTopbarForTest(showMenuButton: showMenuButton),
        ),
      ),
      GoRoute(
        path: '/users',
        builder: (_, _) => const Scaffold(body: Text('USERS SCREEN')),
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('topbar renders the owners search input on desktop/tablet', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _harness(container: container, showMenuButton: false),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin_topbar_search')), findsOneWidget);
    // Data-honest placeholder — owners only, not "bookings, properties".
    expect(find.text('Search owners…'), findsOneWidget);
  });

  testWidgets('search is hidden on mobile (handoff gate)', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _harness(container: container, showMenuButton: true),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin_topbar_search')), findsNothing);
  });

  testWidgets('submitting a query sets the provider and routes to /users', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _harness(container: container, showMenuButton: false),
    );
    await tester.pumpAndSettle();

    // Precondition: on dashboard, empty query.
    expect(find.text('USERS SCREEN'), findsNothing);
    expect(container.read(adminOwnersSearchQueryProvider), '');

    await tester.enterText(
      find.byKey(const Key('admin_topbar_search')),
      '  petra  ',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Query published (trimmed) + navigation applied.
    expect(container.read(adminOwnersSearchQueryProvider), 'petra');
    expect(find.text('USERS SCREEN'), findsOneWidget);
  });
}
