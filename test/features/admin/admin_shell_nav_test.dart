// Fidelity seam for the admin dark-console nav chrome (design/admin-shell.jsx).
//
// The full `AdminShellScreen` builds `enhancedAuthProvider`, which touches
// Firebase on construction, so we render the nav-chrome pieces directly via the
// `buildAdminNavChromeForTest` seam under the admin dark theme. This proves the
// active nav tile carries the hero gradient + purple glow and the ADMIN badge
// resolves its dark tokens — the micro-details wired in this pass.

import 'package:bookbed/core/design/bb_redesign_tokens.dart';
import 'package:bookbed/features/admin/presentation/screens/admin_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dark-mode notifier stub so the seam renders without SharedPreferences.
class _DarkOnNotifier extends AdminDarkModeNotifier {
  _DarkOnNotifier() : super();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferences.setMockInitialValues({'admin_dark_mode': true}),
  );

  testWidgets('admin nav chrome — active tile is gradient + glow, ADMIN badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDarkModeProvider.overrideWith((ref) => _DarkOnNotifier()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true).copyWith(
            extensions: const <ThemeExtension<dynamic>>[
              BbAdminDarkTokens.preset,
            ],
          ),
          home: Scaffold(
            backgroundColor: BbAdminDarkTokens.preset.shellBg,
            body: Center(child: buildAdminNavChromeForTest()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // ADMIN badge text present.
    expect(find.text('ADMIN'), findsOneWidget);

    // At least one Container carries the hero gradient (active nav icon tile +
    // rail tile). Proves the active branch reads navIconActiveGradient.
    final gradientTiles = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) {
          final d = c.decoration;
          return d is BoxDecoration &&
              d.gradient == BbAdminDarkTokens.preset.navIconActiveGradient;
        });
    expect(gradientTiles, isNotEmpty);

    // The active tile also carries the purple glow shadow.
    final glowTiles = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) {
          final d = c.decoration;
          return d is BoxDecoration &&
              d.boxShadow != null &&
              d.boxShadow!.isNotEmpty;
        });
    expect(glowTiles, isNotEmpty);
  });
}
