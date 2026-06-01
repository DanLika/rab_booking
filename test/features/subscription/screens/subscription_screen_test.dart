import 'package:bookbed/features/subscription/screens/subscription_screen.dart';
import 'package:bookbed/shared/widgets/redesign.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/widget_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // SCOPE: In `flutter test` kIsWeb is false, so these tests exercise the
  // NATIVE fallback path (`_buildNativeRedirectContent`) — a single button
  // pointing at the web dashboard. The redesigned web surface
  // (`_buildWebContent` — trial hero, billing toggle, plan cards) is NOT
  // covered here; widget tests can't flip kIsWeb. Track separately if
  // web-surface coverage is needed.
  group('SubscriptionScreen native-fallback smoke', () {
    testWidgets('renders without throw (native redirect branch)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(withL10n: true, child: const SubscriptionScreen()),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SubscriptionScreen), findsOneWidget);
    });

    testWidgets('renders Bb* button + AppBar', (tester) async {
      await tester.pumpWidget(
        createTestWidget(withL10n: true, child: const SubscriptionScreen()),
      );
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(BbButton), findsOneWidget);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          withL10n: true,
          isDarkMode: true,
          child: const SubscriptionScreen(),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
