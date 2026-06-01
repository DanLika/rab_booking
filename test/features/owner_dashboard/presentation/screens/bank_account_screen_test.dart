import 'package:bookbed/features/owner_dashboard/presentation/providers/user_profile_provider.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/bank_account_screen.dart';
import 'package:bookbed/shared/models/user_profile_model.dart';
import 'package:bookbed/shared/widgets/redesign.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final overrides = [
    // Stub the Firestore-backed Stream provider with empty company so the
    // `.when(data:)` branch renders (controllers seed via `_loadData`).
    companyDetailsProvider.overrideWith(
      (ref) => Stream.value(const CompanyDetails()),
    ),
  ];

  group('BankAccountScreen smoke', () {
    setUp(() {
      // Bank account uses a 760-max-width floating panel; default test view
      // (800×600) leaves room but the keyboard-aware LayoutBuilder needs
      // height. Use 1200×1400.
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        ..physicalSize = const Size(1200, 1400)
        ..devicePixelRatio = 1.0;
    });

    tearDown(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    testWidgets('renders without throw', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          withL10n: true,
          overrides: overrides,
          child: const BankAccountScreen(),
        ),
      );
      await tester.pump();
      // Drain any post-frame Timer from keyboard-fix mixin / universal_loader
      // so the test framework's pending-timer guard doesn't trip on dispose.
      await tester.pump(const Duration(seconds: 2));

      allowOverflow(tester);
      expect(find.byType(BankAccountScreen), findsOneWidget);
    });

    testWidgets('renders four BbInputs (IBAN/SWIFT/bank/holder)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          withL10n: true,
          overrides: overrides,
          child: const BankAccountScreen(),
        ),
      );
      await tester.pump();
      // Drain any post-frame Timer from keyboard-fix mixin / universal_loader
      // so the test framework's pending-timer guard doesn't trip on dispose.
      await tester.pump(const Duration(seconds: 2));
      allowOverflow(tester);

      expect(find.byType(BbInput), findsNWidgets(4));
      expect(find.byType(BbCard), findsWidgets);
      expect(find.byType(BbButton), findsWidgets);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          withL10n: true,
          isDarkMode: true,
          overrides: overrides,
          child: const BankAccountScreen(),
        ),
      );
      await tester.pump();
      // Drain any post-frame Timer from keyboard-fix mixin / universal_loader
      // so the test framework's pending-timer guard doesn't trip on dispose.
      await tester.pump(const Duration(seconds: 2));

      allowOverflow(tester);
      expect(find.byType(BankAccountScreen), findsOneWidget);
    });
  });
}
