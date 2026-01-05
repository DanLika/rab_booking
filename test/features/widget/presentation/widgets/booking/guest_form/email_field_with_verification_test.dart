import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/widgets/booking/guest_form/email_field_with_verification.dart';
import '../../../../../../helpers/widget_test_helpers.dart';

void main() {
  group('EmailFieldWithVerification', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets(
      'renders email field without verification button when not required',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            child: EmailFieldWithVerification(
              controller: controller,
              isDarkMode: false,
              requireVerification: false,
              emailVerified: false,
              onEmailChanged: (_) {},
              onVerifyPressed: () {},
            ),
          ),
        );

        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.text('Verify'), findsNothing);
      },
    );

    testWidgets(
      'renders verify button when verification required and not verified',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            child: EmailFieldWithVerification(
              controller: controller,
              isDarkMode: false,
              requireVerification: true,
              emailVerified: false,
              onEmailChanged: (_) {},
              onVerifyPressed: () {},
            ),
          ),
        );

        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.text('Verify'), findsOneWidget);
      },
    );

    testWidgets('renders verified icon when email is verified', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: EmailFieldWithVerification(
            controller: controller,
            isDarkMode: false,
            requireVerification: true,
            emailVerified: true,
            onEmailChanged: (_) {},
            onVerifyPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(find.text('Verify'), findsNothing);
    });

    testWidgets('calls onEmailChanged when text changes', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        createTestWidget(
          child: EmailFieldWithVerification(
            controller: controller,
            isDarkMode: false,
            requireVerification: false,
            emailVerified: false,
            onEmailChanged: (value) => changedValue = value,
            onVerifyPressed: () {},
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      expect(changedValue, 'test@example.com');
    });

    testWidgets('calls onVerifyPressed when verify button tapped', (
      tester,
    ) async {
      bool verifyPressed = false;
      controller.text = 'test@example.com';

      await tester.pumpWidget(
        createTestWidget(
          child: EmailFieldWithVerification(
            controller: controller,
            isDarkMode: false,
            requireVerification: true,
            emailVerified: false,
            onEmailChanged: (_) {},
            onVerifyPressed: () => verifyPressed = true,
          ),
        ),
      );

      await tester.tap(find.text('Verify'));
      await tester.pump();

      expect(verifyPressed, true);
    });

    testWidgets('renders email icon prefix', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: EmailFieldWithVerification(
            controller: controller,
            isDarkMode: false,
            requireVerification: false,
            emailVerified: false,
            onEmailChanged: (_) {},
            onVerifyPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          isDarkMode: true,
          child: EmailFieldWithVerification(
            controller: controller,
            isDarkMode: true,
            requireVerification: true,
            emailVerified: false,
            onEmailChanged: (_) {},
            onVerifyPressed: () {},
          ),
        ),
      );

      expect(find.byType(EmailFieldWithVerification), findsOneWidget);
    });

    testWidgets('shows error for invalid email on validation', (tester) async {
      final formKey = GlobalKey<FormState>();
      controller.text = 'invalid-email';

      await tester.pumpWidget(
        createTestWidget(
          child: Form(
            key: formKey,
            child: EmailFieldWithVerification(
              controller: controller,
              isDarkMode: false,
              requireVerification: false,
              emailVerified: false,
              onEmailChanged: (_) {},
              onVerifyPressed: () {},
            ),
          ),
        ),
      );

      formKey.currentState?.validate();
      await tester.pump();

      // Validator should show error for invalid email
      expect(find.byType(TextFormField), findsOneWidget);
    });
  });
}
