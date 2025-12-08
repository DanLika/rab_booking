import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/l10n/widget_translations.dart';
import 'package:bookbed/features/widget/presentation/widgets/common/rotate_device_overlay.dart';
import 'package:bookbed/features/widget/presentation/theme/minimalist_colors.dart';

WidgetTranslations get testTranslations => WidgetTranslations.forLanguage('hr');

void main() {
  group('RotateDeviceOverlay', () {
    testWidgets('renders title and description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              RotateDeviceOverlay(
                translations: testTranslations,
                isDarkMode: false,
                colors: const MinimalistColorSchemeAdapter(),
                onSwitchToMonthView: () {},
              ),
            ],
          ),
        ),
      );

      // HR translations
      expect(find.text('Okrenite uređaj'), findsOneWidget);
      expect(
        find.text('Za najbolji prikaz godišnjeg kalendara, molimo okrenite uređaj u pejzažni način.'),
        findsOneWidget,
      );
    });

    testWidgets('renders switch to month view button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              RotateDeviceOverlay(
                translations: testTranslations,
                isDarkMode: false,
                colors: const MinimalistColorSchemeAdapter(),
                onSwitchToMonthView: () {},
              ),
            ],
          ),
        ),
      );

      // HR translation: "Prebaci na mjesečni prikaz"
      expect(find.text('Prebaci na mjesečni prikaz'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('calls onSwitchToMonthView when button is pressed', (tester) async {
      var wasCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              RotateDeviceOverlay(
                translations: testTranslations,
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
                translations: testTranslations,
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

    testWidgets('applies dark mode styling when isDarkMode is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              RotateDeviceOverlay(
                translations: testTranslations,
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
