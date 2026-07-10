import 'package:bookbed/features/owner_dashboard/presentation/providers/user_profile_provider.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/notification_settings_screen.dart';
import 'package:bookbed/shared/models/notification_preferences_model.dart';
import 'package:bookbed/shared/widgets/redesign.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final overrides = [
    // Stub the Firestore-backed Stream provider with empty preferences so the
    // `.when(data:)` branch renders. Avoids needing a Firebase Auth init.
    notificationPreferencesProvider.overrideWith(
      (ref) => Stream.value(const NotificationPreferences(userId: 'test-uid')),
    ),
  ];

  group('NotificationSettingsScreen smoke', () {
    testWidgets('renders without throw (preferences data branch)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          withL10n: true,
          overrides: overrides,
          child: const NotificationSettingsScreen(),
        ),
      );
      await tester.pump();

      allowOverflow(tester);
      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
    });

    testWidgets('renders BbSwitch primitive(s) + BbCard sections', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          withL10n: true,
          overrides: overrides,
          child: const NotificationSettingsScreen(),
        ),
      );
      await tester.pump();
      allowOverflow(tester);

      expect(find.byType(BbSwitch), findsWidgets);
      expect(find.byType(BbCard), findsWidgets);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          withL10n: true,
          isDarkMode: true,
          overrides: overrides,
          child: const NotificationSettingsScreen(),
        ),
      );
      await tester.pump();

      allowOverflow(tester);
      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
    });
  });

  group('Quiet Hours (Tihi sati) section', () {
    testWidgets('renders quiet-hours switch on the screen', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          withL10n: true,
          overrides: overrides,
          child: const NotificationSettingsScreen(),
        ),
      );
      await tester.pump();
      allowOverflow(tester);

      // Section lives below the fold in the ListView; scroll it into view.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('quiet_hours_switch')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('quiet_hours_switch')), findsOneWidget);
    });

    testWidgets(
      'time fields hidden when disabled, shown when enabled (builder seam)',
      (tester) async {
        var toggled = false;
        String? pickedStart;

        Widget host(QuietHours qh) => createTestWidget(
          withL10n: true,
          child: Builder(
            builder: (context) => buildQuietHoursCard(
              context: context,
              quietHours: qh,
              enabled: true,
              onToggle: (_) => toggled = true,
              onPickStart: () => pickedStart = 'tapped',
              onPickEnd: () {},
            ),
          ),
        );

        // Disabled → no time fields.
        await tester.pumpWidget(host(const QuietHours()));
        await tester.pump();
        allowOverflow(tester);
        expect(find.byKey(const ValueKey('quiet_hours_start')), findsNothing);

        // Enabled → both time fields render.
        await tester.pumpWidget(host(const QuietHours(enabled: true)));
        await tester.pump();
        allowOverflow(tester);
        expect(find.byKey(const ValueKey('quiet_hours_start')), findsOneWidget);
        expect(find.byKey(const ValueKey('quiet_hours_end')), findsOneWidget);
        expect(find.text('22:00'), findsOneWidget);

        // Callbacks dispatch.
        await tester.tap(find.byKey(const ValueKey('quiet_hours_switch')));
        await tester.pump();
        expect(toggled, isTrue);

        await tester.tap(find.byKey(const ValueKey('quiet_hours_start')));
        await tester.pump();
        expect(pickedStart, 'tapped');
      },
    );
  });
}
