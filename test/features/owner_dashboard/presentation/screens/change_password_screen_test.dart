import 'package:bookbed/features/owner_dashboard/presentation/screens/change_password_screen.dart';
import 'package:bookbed/shared/widgets/redesign.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChangePasswordScreen smoke', () {
    testWidgets('renders without throw', (tester) async {
      await tester.pumpWidget(
        createTestWidget(withL10n: true, child: const ChangePasswordScreen()),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets('renders three password inputs + submit button', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(withL10n: true, child: const ChangePasswordScreen()),
      );
      await tester.pump();

      expect(find.byType(BbInput), findsNWidgets(3));
      expect(find.byType(BbButton), findsWidgets);
      expect(find.byType(BbCard), findsWidgets);
    });

    testWidgets('validator fires on empty submit', (tester) async {
      await tester.pumpWidget(
        createTestWidget(withL10n: true, child: const ChangePasswordScreen()),
      );
      await tester.pump();

      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isFalse);
      await tester.pump();
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          withL10n: true,
          isDarkMode: true,
          child: const ChangePasswordScreen(),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
