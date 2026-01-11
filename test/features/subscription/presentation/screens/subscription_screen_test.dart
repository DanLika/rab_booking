import 'package:bookbed/features/subscription/models/trial_status.dart';
import 'package:bookbed/features/subscription/providers/trial_status_provider.dart';
import 'package:bookbed/features/subscription/screens/subscription_screen.dart';
import 'package:bookbed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest(TrialStatus trialStatus) {
    return ProviderScope(
      overrides: [
        trialStatusProvider.overrideWith((ref) => Stream.value(trialStatus)),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: SubscriptionScreen(),
      ),
    );
  }

  testWidgets('Free Trial User - displays Current on Free Plan and Countdown', (tester) async {
    final now = DateTime.now();
    final trialStatus = TrialStatus(
      accountStatus: AccountStatus.trial,
      trialStartDate: now.subtract(const Duration(days: 10)),
      trialExpiresAt: now.add(const Duration(days: 20)),
    );

    await tester.pumpWidget(createWidgetUnderTest(trialStatus));
    await tester.pumpAndSettle();

    // Verify "Current" badge exists
    expect(find.text('Current'), findsOneWidget);

    // Verify it is associated with Free Trial (simplified check: both text present)
    expect(find.text('Free Trial'), findsOneWidget);

    // Verify countdown is shown (new implementation)
    expect(find.textContaining('days left'), findsOneWidget);
  });

  testWidgets('Pro User - displays Current on Pro Plan and NO Countdown', (tester) async {
    final trialStatus = TrialStatus(
      accountStatus: AccountStatus.active,
    );

    await tester.pumpWidget(createWidgetUnderTest(trialStatus));
    await tester.pumpAndSettle();

    // Verify "Current" badge exists
    expect(find.text('Current'), findsOneWidget);

    // Verify Pro plan title
    expect(find.text('Pro'), findsOneWidget);

    // Verify NO countdown
    expect(find.textContaining('Expires:'), findsNothing);
  });

  testWidgets('Expired Trial - Read-only, Expired message, CTA', (tester) async {
    final trialStatus = TrialStatus(
      accountStatus: AccountStatus.trialExpired,
    );

    await tester.pumpWidget(createWidgetUnderTest(trialStatus));
    await tester.pumpAndSettle();

    // Verify NO "Current" badge
    expect(find.text('Current'), findsNothing);

    // Verify status text (localized)
    expect(find.text('Trial Expired'), findsOneWidget);

    // Verify CTA
    expect(find.text('Upgrade Now'), findsOneWidget);
  });
}
