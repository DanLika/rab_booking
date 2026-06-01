import 'package:bookbed/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:bookbed/shared/widgets/redesign.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ForgotPasswordScreen smoke', () {
    testWidgets('renders without throw', (tester) async {
      await tester.pumpWidget(
        createTestWidget(withL10n: true, child: const ForgotPasswordScreen()),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('renders key Bb* primitives (logo, input, submit button)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(withL10n: true, child: const ForgotPasswordScreen()),
      );
      await tester.pump();

      expect(find.byType(BbLogo), findsOneWidget);
      expect(find.byType(BbInput), findsOneWidget);
      expect(find.byType(BbButton), findsWidgets);
    });

    testWidgets('email validator fires on empty submit', (tester) async {
      await tester.pumpWidget(
        createTestWidget(withL10n: true, child: const ForgotPasswordScreen()),
      );
      await tester.pump();

      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isFalse);
      await tester.pump();

      expect(find.byType(BbInput), findsOneWidget);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          withL10n: true,
          isDarkMode: true,
          child: const ForgotPasswordScreen(),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });
  });
}
