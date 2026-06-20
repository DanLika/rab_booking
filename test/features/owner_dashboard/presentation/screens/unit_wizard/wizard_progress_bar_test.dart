// Render + overflow guard for the Unit Wizard progress bar (audit/134 §F).
//
// The §F polish pass (1) retired the off-palette `#66BB6A` literal in favour of
// the theme-aware system success token (`BBColor.of(context).success`) on the
// completed nodes / labels / connectors / mobile bar, and (2) added the handoff
// `--bb-shadow-purple-sm` glow (`BBShadow.purpleGlow(context)`) to the CURRENT
// step node. Both are context+theme-resolved, so the real regression risk is a
// token call that throws (or overflows) in one theme or one layout branch.
//
//   * PRIMARY assertion: NO RenderFlex / layout overflow and no resolve-time
//     exception at any breakpoint, in light + dark — across BOTH render
//     branches (compact bar < 600, full stepper >= 600) and every step state
//     (pending-only, mixed completed+current, final step).
//
// Hermetic: [WizardProgressBar] is a plain StatelessWidget driven by value
// params — no providers, no Firebase, no network.

import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/unit_wizard/widgets/wizard_progress_bar.dart';
import 'package:bookbed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _breakpoints = <({String name, double w, double h})>[
  (name: 'mobile_360', w: 360, h: 800), // compact bar branch
  (name: 'mobile_414', w: 414, h: 896), // compact bar branch
  (name: 'tablet_600', w: 600, h: 1024), // full stepper branch (boundary)
  (name: 'tablet_768', w: 768, h: 1024),
  (name: 'desktop_1024', w: 1024, h: 1000),
  (name: 'desktop_1280', w: 1280, h: 1000),
  (name: 'desktop_1440', w: 1440, h: 1000),
];

// Step states that exercise every colour branch:
//  - completed nodes  -> success token (emerald)
//  - current node     -> primary + purpleGlow boxShadow (P2)
//  - pending nodes    -> outline
const _states = <({String name, int current, Map<int, bool> completed})>[
  (name: 'step1-none-done', current: 1, completed: <int, bool>{}),
  (
    name: 'step3-1n2-done',
    current: 3,
    completed: <int, bool>{1: true, 2: true},
  ),
  (
    name: 'step4-all-done',
    current: 4,
    completed: <int, bool>{1: true, 2: true, 3: true},
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required double w,
  required double h,
  required bool dark,
  required int current,
  required Map<int, bool> completed,
}) async {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('hr'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: WizardProgressBar(
            currentStep: current,
            completedSteps: completed,
            onStepTap: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('wizard progress bar — no overflow / clean token resolve', () {
    for (final bp in _breakpoints) {
      for (final dark in const [false, true]) {
        final theme = dark ? 'dark' : 'light';
        for (final st in _states) {
          testWidgets('${bp.name} $theme — ${st.name}', (tester) async {
            await _pump(
              tester,
              w: bp.w,
              h: bp.h,
              dark: dark,
              current: st.current,
              completed: st.completed,
            );
            expect(tester.takeException(), isNull);
            expect(find.byType(WizardProgressBar), findsOneWidget);
          });
        }
      }
    }
  });
}
