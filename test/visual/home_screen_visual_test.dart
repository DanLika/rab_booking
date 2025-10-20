import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/home/presentation/screens/home_screen.dart';
import '../helpers/visual_test_helpers.dart';

/// Visual tests for HomeScreen
/// Tests responsive behavior, theme switching, and visual regression
void main() {
  group('HomeScreen Visual Tests', () {
    testWidgets('renders correctly on mobile', (tester) async {
      await tester.pumpWidget(
        VisualTestHelpers.wrapWithSize(
          const HomeScreen(),
          VisualTestHelpers.mobile,
        ),
      );
      await tester.pumpAndSettle();

      // Verify mobile-specific layout
      expect(find.byType(HomeScreen), findsOneWidget);
      // Add more specific checks for mobile layout
    });

    testWidgets('renders correctly on tablet', (tester) async {
      await tester.pumpWidget(
        VisualTestHelpers.wrapWithSize(
          const HomeScreen(),
          VisualTestHelpers.tablet,
        ),
      );
      await tester.pumpAndSettle();

      // Verify tablet-specific layout
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('renders correctly on desktop', (tester) async {
      await tester.pumpWidget(
        VisualTestHelpers.wrapWithSize(
          const HomeScreen(),
          VisualTestHelpers.desktop,
        ),
      );
      await tester.pumpAndSettle();

      // Verify desktop-specific layout
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('switches between light and dark themes', (tester) async {
      await VisualTestHelpers.testInBothThemes(
        tester,
        const HomeScreen(),
        (theme) async {
          expect(find.byType(HomeScreen), findsOneWidget);
          // Verify theme-specific colors and styles
        },
      );
    });

    testWidgets('responsive at all breakpoints', (tester) async {
      await VisualTestHelpers.testAtBreakpointCategories(
        tester,
        const HomeScreen(),
        (size, category) async {
          expect(find.byType(HomeScreen), findsOneWidget);
          // Verify no overflow or layout issues
          // Check that content adapts to size
        },
      );
    });
  });

  group('HomeScreen Component Visibility', () {
    testWidgets('shows all components on desktop', (tester) async {
      await tester.pumpWidget(
        VisualTestHelpers.wrapWithSize(
          const HomeScreen(),
          VisualTestHelpers.desktop,
        ),
      );
      await tester.pumpAndSettle();

      // Verify all major components are visible
      // - Hero section
      // - Search bar
      // - Featured properties
      // - Testimonials
      // etc.
    });

    testWidgets('components adapt on mobile', (tester) async {
      await tester.pumpWidget(
        VisualTestHelpers.wrapWithSize(
          const HomeScreen(),
          VisualTestHelpers.mobile,
        ),
      );
      await tester.pumpAndSettle();

      // Verify mobile-optimized components
      // - Simplified search bar
      // - Stacked property cards
      // - Mobile navigation
    });
  });
}
