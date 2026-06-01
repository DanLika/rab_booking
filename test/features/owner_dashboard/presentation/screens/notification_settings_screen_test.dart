import 'package:bookbed/features/owner_dashboard/presentation/providers/user_profile_provider.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/notification_settings_screen.dart';
import 'package:bookbed/shared/models/notification_preferences_model.dart';
import 'package:bookbed/shared/widgets/redesign.dart';
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
}
