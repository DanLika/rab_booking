import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/presentation/widgets/common/rotate_device_overlay.dart';
import 'package:rab_booking/features/widget/presentation/theme/minimalist_colors.dart';

void main() {
  group('RotateDeviceOverlay', () {
    testWidgets('renders title and description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              RotateDeviceOverlay(
                isDarkMode: false,
                colors: const MinimalistColorSchemeAdapter(),
                onSwitchToMonthView: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.text('Rotate Your Device'), findsOneWidget);
      expect(
        find.text(
          'For the best year view experience, please rotate your device to landscape mode.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders switch to month view button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              RotateDeviceOverlay(
                isDarkMode: false,
                colors: const MinimalistColorSchemeAdapter(),
                onSwitchToMonthView: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.text('Switch to Month View'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('calls onSwitchToMonthView when button is pressed',
        (tester) async {
      var wasCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              RotateDeviceOverlay(
                isDarkMode: false,
                colors: const MinimalistColorSchemeAdapter(),
                onSwitchToMonthView: () {
                  wasCalled = true;
                },
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(wasCalled, isTrue);
    });

    testWidgets('renders rotate icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              RotateDeviceOverlay(
                isDarkMode: false,
                colors: const MinimalistColorSchemeAdapter(),
                onSwitchToMonthView: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.screen_rotation), findsOneWidget);
    });

    testWidgets('applies dark mode styling when isDarkMode is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              RotateDeviceOverlay(
                isDarkMode: true,
                colors: const MinimalistColorSchemeAdapter(dark: true),
                onSwitchToMonthView: () {},
              ),
            ],
          ),
        ),
      );

      // Widget should render without errors in dark mode
      expect(find.byType(RotateDeviceOverlay), findsOneWidget);
    });
  });
}
