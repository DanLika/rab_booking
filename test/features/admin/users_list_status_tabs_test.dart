// Status TAB-COUNTS regression for the admin Users list (handoff
// `design_handoff/source/admin-users.jsx` `AU_TABS`: All / Active / Trial /
// Suspended). Verifies:
//   1. the tab set matches the handoff,
//   2. each tab's badge count comes from the real `.count()` aggregate map
//      (incl. Trial folding in `trial_expired`) — never a fabricated 0,
//   3. selecting a tab reports the right filter target,
//   4. the accountStatus filter matches (all always matches; null visible
//      only under `all`).
//
// Pure seams — no Firebase (aggregate map is injected).

import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/admin/presentation/screens/users_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1000, 400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('status tab set (handoff AU_TABS)', () {
    test('is All / Active / Trial / Suspended in order', () {
      expect(statusTabNamesForTest, ['all', 'active', 'trial', 'suspended']);
    });
  });

  group('badge counts from real aggregate map', () {
    const counts = {
      'all': 248,
      'active': 210,
      'trial': 20,
      'trial_expired': 6,
      'suspended': 12,
    };

    test('all/active/suspended read their key directly', () {
      expect(statusTabBadgeCountForTest('all', counts), 248);
      expect(statusTabBadgeCountForTest('active', counts), 210);
      expect(statusTabBadgeCountForTest('suspended', counts), 12);
    });

    test('trial folds in trial_expired (20 + 6 = 26)', () {
      expect(statusTabBadgeCountForTest('trial', counts), 26);
    });

    test('missing keys yield null (no fabricated 0)', () {
      expect(statusTabBadgeCountForTest('suspended', const {}), isNull);
      expect(statusTabBadgeCountForTest('active', const {'all': 5}), isNull);
    });

    test('trial null only when BOTH keys absent; sums whichever present', () {
      expect(statusTabBadgeCountForTest('trial', const {'trial': 4}), 4);
      expect(
        statusTabBadgeCountForTest('trial', const {'trial_expired': 3}),
        3,
      );
      expect(statusTabBadgeCountForTest('trial', const {}), isNull);
    });
  });

  group('accountStatus filter matching', () {
    test('all matches everything, incl. null/unknown', () {
      expect(statusTabMatchesForTest('all', 'active'), isTrue);
      expect(statusTabMatchesForTest('all', null), isTrue);
      expect(statusTabMatchesForTest('all', 'weird'), isTrue);
    });

    test('active matches only active', () {
      expect(statusTabMatchesForTest('active', 'active'), isTrue);
      expect(statusTabMatchesForTest('active', 'trial'), isFalse);
      expect(statusTabMatchesForTest('active', null), isFalse);
    });

    test('trial matches trial AND trial_expired', () {
      expect(statusTabMatchesForTest('trial', 'trial'), isTrue);
      expect(statusTabMatchesForTest('trial', 'trial_expired'), isTrue);
      expect(statusTabMatchesForTest('trial', 'active'), isFalse);
    });

    test('suspended matches only suspended', () {
      expect(statusTabMatchesForTest('suspended', 'suspended'), isTrue);
      expect(statusTabMatchesForTest('suspended', 'active'), isFalse);
    });
  });

  group('tabs render with counts + report selection', () {
    testWidgets('renders all four labels with badge numbers', (tester) async {
      await _pump(
        tester,
        buildStatusTabsForTest(
          counts: const {
            'all': 248,
            'active': 210,
            'trial': 20,
            'trial_expired': 6,
            'suspended': 12,
          },
        ),
      );
      for (final label in ['All', 'Active', 'Trial', 'Suspended']) {
        expect(find.text(label), findsOneWidget);
      }
      // Badge numbers present (Trial shows folded 26, not 20).
      expect(find.text('248'), findsOneWidget);
      expect(find.text('210'), findsOneWidget);
      expect(find.text('26'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a tab reports its enum name', (tester) async {
      String? tapped;
      await _pump(
        tester,
        buildStatusTabsForTest(
          counts: const {'all': 1, 'active': 1, 'trial': 1, 'suspended': 1},
          onSelectedName: (name) => tapped = name,
        ),
      );
      await tester.tap(find.text('Suspended'));
      await tester.pumpAndSettle();
      expect(tapped, 'suspended');
    });

    testWidgets('no badge shown when aggregate empty (no fake 0)', (
      tester,
    ) async {
      await _pump(tester, buildStatusTabsForTest(counts: const {}));
      // Labels still render, but no numeric badges.
      expect(find.text('All'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
