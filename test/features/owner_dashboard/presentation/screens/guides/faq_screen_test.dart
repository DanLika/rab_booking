import 'package:bookbed/features/owner_dashboard/presentation/screens/guides/faq_screen.dart';
import 'package:bookbed/shared/widgets/redesign.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/widget_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FAQScreen smoke', () {
    testWidgets('renders without throw', (tester) async {
      await tester.pumpWidget(
        createTestWidget(withL10n: true, child: const FAQScreen()),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(FAQScreen), findsOneWidget);
    });

    testWidgets('renders search input + category chips', (tester) async {
      await tester.pumpWidget(
        createTestWidget(withL10n: true, child: const FAQScreen()),
      );
      await tester.pump();

      expect(find.byType(BbInput), findsOneWidget);
      expect(find.byType(BbChip), findsWidgets);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          withL10n: true,
          isDarkMode: true,
          child: const FAQScreen(),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
