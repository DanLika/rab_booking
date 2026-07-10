import 'package:bookbed/features/subscription/models/trial_status.dart';
import 'package:bookbed/features/subscription/screens/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../helpers/widget_test_helpers.dart';

/// Seam tests for the subscription trial progress bar.
///
/// The live [_TrialHero] is a `ConsumerWidget` gated on [trialStatusProvider];
/// these tests exercise the provider-free seam ([TrialBarData.fromTrialStatus]
/// for the derivation math + [buildTrialHeroForTest] for the visual) so they
/// prove the FUNCTION without a Firestore stream. Live wiring is eyeball-gated
/// on the running web app (per CLAUDE.md seam-test note).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // DateFormat('d. MMMM yyyy.', 'hr') needs locale symbols loaded.
    await initializeDateFormatting('hr');
    await initializeDateFormatting('en');
  });

  TrialStatus trial({
    required DateTime start,
    required DateTime end,
    AccountStatus status = AccountStatus.trial,
  }) => TrialStatus(
    accountStatus: status,
    trialStartDate: start,
    trialExpiresAt: end,
  );

  group('TrialBarData.fromTrialStatus — derivation', () {
    test('30-day trial, 12 days elapsed → 18 left / 30 total', () {
      final data = TrialBarData.fromTrialStatus(
        trial(start: DateTime(2026, 6, 10), end: DateTime(2026, 7, 10)),
        'hr',
        now: DateTime(2026, 6, 22),
      );
      expect(data, isNotNull);
      expect(data!.totalDays, 30);
      expect(data.daysLeft, 18);
      expect(data.elapsedFraction, closeTo(12 / 30, 0.02));
    });

    test('clamps at 0 when trial fully consumed (never negative)', () {
      final data = TrialBarData.fromTrialStatus(
        trial(start: DateTime(2026, 6, 10), end: DateTime(2026, 7, 10)),
        'hr',
        now: DateTime(2026, 8, 5), // past expiry
      );
      // Still isInTrial (status=trial) but expired-by-date → daysRemaining 0.
      expect(data, isNotNull);
      expect(data!.daysLeft, 0);
      expect(data.elapsedFraction, 1.0);
    });

    test('formats end date in HR locale', () {
      final data = TrialBarData.fromTrialStatus(
        trial(start: DateTime(2026, 6, 10), end: DateTime(2026, 7, 10)),
        'hr',
      );
      expect(data!.endDate, '10. srpnja 2026');
    });

    test('returns null when NOT in trial (active/expired/suspended)', () {
      final DateTime now = DateTime.now();
      for (final s in <AccountStatus>[
        AccountStatus.active,
        AccountStatus.trialExpired,
        AccountStatus.suspended,
      ]) {
        expect(
          TrialBarData.fromTrialStatus(
            trial(
              start: now.subtract(const Duration(days: 5)),
              end: now.add(const Duration(days: 25)),
              status: s,
            ),
            'hr',
          ),
          isNull,
          reason: 'status $s must hide the bar',
        );
      }
    });

    test('returns null when trial bounds not persisted', () {
      expect(
        TrialBarData.fromTrialStatus(
          const TrialStatus(accountStatus: AccountStatus.trial),
          'hr',
        ),
        isNull,
      );
    });
  });

  group('buildTrialHeroForTest — visual', () {
    Future<void> pumpHero(
      WidgetTester tester,
      TrialBarData? data, {
      bool compact = false,
    }) async {
      await tester.pumpWidget(
        createTestWidget(
          withL10n: true,
          child: Builder(
            builder: (context) => buildTrialHeroForTest(
              context: context,
              data: data,
              compact: compact,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('renders bar + days line for trial data', (tester) async {
      await pumpHero(
        tester,
        const TrialBarData(
          daysLeft: 18,
          totalDays: 30,
          endDate: '10. srpnja 2026',
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(FractionallySizedBox), findsOneWidget);
      // "18 of 30 days remaining" (en test locale).
      expect(find.textContaining('18'), findsWidgets);
      expect(find.textContaining('30'), findsWidgets);
    });

    testWidgets('hides (SizedBox.shrink) when data is null', (tester) async {
      await pumpHero(tester, null);
      expect(tester.takeException(), isNull);
      expect(find.byType(FractionallySizedBox), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('compact variant renders without overflow', (tester) async {
      await pumpHero(
        tester,
        const TrialBarData(
          daysLeft: 2,
          totalDays: 30,
          endDate: '10. srpnja 2026',
        ),
        compact: true,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });
  });
}
