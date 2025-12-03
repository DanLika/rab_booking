import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/presentation/screens/subdomain_not_found_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubdomainNotFoundScreen', () {
    testWidgets('renders with subdomain', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SubdomainNotFoundScreen(subdomain: 'test-subdomain'),
        ),
      );

      // Check that the subdomain is displayed
      expect(find.text('test-subdomain'), findsOneWidget);

      // Check that error title is displayed
      expect(find.text('Property Not Found'), findsOneWidget);
    });

    testWidgets('displays error icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SubdomainNotFoundScreen(subdomain: 'invalid'),
        ),
      );

      // Check for error icon
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('displays help section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SubdomainNotFoundScreen(subdomain: 'missing'),
        ),
      );

      // Check for help section
      expect(find.text('Need Help?'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
    });

    testWidgets('displays explanation text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SubdomainNotFoundScreen(subdomain: 'nonexistent'),
        ),
      );

      // Check for explanation bullet points
      expect(find.textContaining('link has expired'), findsOneWidget);
      expect(find.textContaining('typed incorrectly'), findsOneWidget);
      expect(find.textContaining('no longer available'), findsOneWidget);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const SubdomainNotFoundScreen(subdomain: 'dark-test'),
        ),
      );

      expect(find.text('dark-test'), findsOneWidget);
      expect(find.text('Property Not Found'), findsOneWidget);
    });

    testWidgets('renders in light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const SubdomainNotFoundScreen(subdomain: 'light-test'),
        ),
      );

      expect(find.text('light-test'), findsOneWidget);
      expect(find.text('Property Not Found'), findsOneWidget);
    });

    testWidgets('is scrollable on small screens', (tester) async {
      // Set a small screen size
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: SubdomainNotFoundScreen(subdomain: 'scroll-test'),
        ),
      );

      // Verify SingleChildScrollView is present
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Reset
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('handles long subdomain gracefully', (tester) async {
      const longSubdomain = 'this-is-a-very-long-subdomain-that-might-overflow';

      await tester.pumpWidget(
        const MaterialApp(
          home: SubdomainNotFoundScreen(subdomain: longSubdomain),
        ),
      );

      expect(find.text(longSubdomain), findsOneWidget);
    });

    testWidgets('handles special characters in subdomain', (tester) async {
      // This simulates what would happen if an invalid subdomain was passed
      const specialSubdomain = 'test-123';

      await tester.pumpWidget(
        const MaterialApp(
          home: SubdomainNotFoundScreen(subdomain: specialSubdomain),
        ),
      );

      expect(find.text(specialSubdomain), findsOneWidget);
    });
  });
}
