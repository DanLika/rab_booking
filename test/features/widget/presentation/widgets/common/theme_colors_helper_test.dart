import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/presentation/widgets/common/theme_colors_helper.dart';

void main() {
  group('ThemeColorsHelper', () {
    group('getColor', () {
      test('returns dark color when isDarkMode is true', () {
        final result = ThemeColorsHelper.getColor(
          isDarkMode: true,
          light: Colors.white,
          dark: Colors.black,
        );

        expect(result, Colors.black);
      });

      test('returns light color when isDarkMode is false', () {
        final result = ThemeColorsHelper.getColor(
          isDarkMode: false,
          light: Colors.white,
          dark: Colors.black,
        );

        expect(result, Colors.white);
      });

      test('works with custom colors', () {
        const customLight = Color(0xFFFF0000);
        const customDark = Color(0xFF00FF00);

        final lightResult = ThemeColorsHelper.getColor(
          isDarkMode: false,
          light: customLight,
          dark: customDark,
        );

        final darkResult = ThemeColorsHelper.getColor(
          isDarkMode: true,
          light: customLight,
          dark: customDark,
        );

        expect(lightResult, customLight);
        expect(darkResult, customDark);
      });
    });

    group('createColorGetter', () {
      test('returns function that returns correct colors for light mode', () {
        final getColor = ThemeColorsHelper.createColorGetter(false);

        expect(getColor(Colors.white, Colors.black), Colors.white);
        expect(getColor(Colors.red, Colors.blue), Colors.red);
      });

      test('returns function that returns correct colors for dark mode', () {
        final getColor = ThemeColorsHelper.createColorGetter(true);

        expect(getColor(Colors.white, Colors.black), Colors.black);
        expect(getColor(Colors.red, Colors.blue), Colors.blue);
      });

      test('returned function signature matches expected type', () {
        final getColor = ThemeColorsHelper.createColorGetter(false);

        // Verify function can be called with two Color arguments
        final result = getColor(Colors.amber, Colors.purple);

        expect(result, isA<Color>());
        expect(result, Colors.amber);
      });

      test('captures isDarkMode value correctly', () {
        final getColorLight = ThemeColorsHelper.createColorGetter(false);
        final getColorDark = ThemeColorsHelper.createColorGetter(true);

        const testLight = Color(0xFFAAAAAA);
        const testDark = Color(0xFF555555);

        // Both functions should return different colors for same input
        expect(getColorLight(testLight, testDark), testLight);
        expect(getColorDark(testLight, testDark), testDark);
      });
    });
  });
}
