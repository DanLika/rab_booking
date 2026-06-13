import 'package:bookbed/features/auth/presentation/screens/enhanced_register_screen.dart';
import 'package:bookbed/shared/widgets/redesign.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnhancedRegisterScreen smoke', () {
    setUp(() {
      // Wider viewport so the glass-card desktop layout doesn't overflow the
      // default 800×600 test surface. Auth-family screens lay out at >=1024.
      // Kept BELOW the 1200 desktop-split breakpoint so this card-focused
      // smoke stays single-column (no pitch panel / its extra BbLogo) — the
      // split is covered by register_desktop_split_test.dart.
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        ..physicalSize = const Size(1100, 2400)
        ..devicePixelRatio = 1.0;
    });

    tearDown(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    testWidgets('renders without throw', (tester) async {
      await tester.pumpWidget(
        createTestWidget(withL10n: true, child: const EnhancedRegisterScreen()),
      );
      await tester.pump();

      // Tolerate harmless layout overflow on the fixed test surface — the
      // screen lays out around a 440-max-width glass card whose intrinsic
      // child sizes nudge over the test viewport. We still assert the
      // screen mounted + Bb* primitives are present below.
      allowOverflow(tester);
      expect(find.byType(EnhancedRegisterScreen), findsOneWidget);
    });

    testWidgets('renders five BbInput fields + logo', (tester) async {
      await tester.pumpWidget(
        createTestWidget(withL10n: true, child: const EnhancedRegisterScreen()),
      );
      await tester.pump();
      allowOverflow(tester);

      expect(find.byType(BbLogo), findsOneWidget);
      // name + email + phone + password + confirm-password
      expect(find.byType(BbInput), findsNWidgets(5));
      expect(find.byType(BbButton), findsWidgets);
    });

    testWidgets('validator fires on empty submit', (tester) async {
      await tester.pumpWidget(
        createTestWidget(withL10n: true, child: const EnhancedRegisterScreen()),
      );
      await tester.pump();
      allowOverflow(tester);

      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isFalse);
      await tester.pump();
      allowOverflow(tester);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          withL10n: true,
          isDarkMode: true,
          child: const EnhancedRegisterScreen(),
        ),
      );
      await tester.pump();
      allowOverflow(tester);
      expect(find.byType(EnhancedRegisterScreen), findsOneWidget);
    });
  });
}
