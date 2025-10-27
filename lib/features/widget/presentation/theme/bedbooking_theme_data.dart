import 'package:flutter/material.dart';
import 'bedbooking_theme.dart';

/// BedBooking ThemeData generator for light and dark modes
class BedBookingTheme {
  BedBookingTheme._();

  /// Get ThemeData based on brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

  /// Light theme (default)
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: BedBookingColors.backgroundWhite,
      primaryColor: BedBookingColors.primaryGreen,

      colorScheme: const ColorScheme.light(
        primary: BedBookingColors.primaryGreen,
        secondary: BedBookingColors.darkGreen,
        surface: BedBookingColors.backgroundWhite,
        error: BedBookingColors.error,
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: BedBookingColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: BedBookingColors.backgroundWhite,
        elevation: 2,
        shadowColor: BedBookingColors.shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BedBookingColors.backgroundWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: BedBookingColors.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: BedBookingColors.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(
            color: BedBookingColors.primaryGreen,
            width: 2,
          ),
        ),
      ),

      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: BedBookingColors.textDark,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: BedBookingColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: BedBookingColors.textDark,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: BedBookingColors.textGrey,
          fontSize: 14,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: BedBookingColors.textDark,
      ),
    );
  }

  /// Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: BedBookingColors.backgroundDark,
      primaryColor: BedBookingColors.primaryGreenDark,

      colorScheme: const ColorScheme.dark(
        primary: BedBookingColors.primaryGreenDark,
        secondary: BedBookingColors.accentGreenDark,
        surface: BedBookingColors.backgroundDarkElevated,
        error: BedBookingColors.error,
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: BedBookingColors.backgroundDarkElevated,
        foregroundColor: BedBookingColors.textDarkMode,
        elevation: 0,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: BedBookingColors.backgroundDarkCard,
        elevation: 4,
        shadowColor: BedBookingColors.shadowDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BedBookingColors.backgroundDarkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: BedBookingColors.borderDarkMode),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: BedBookingColors.borderDarkMode),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(
            color: BedBookingColors.primaryGreenDark,
            width: 2,
          ),
        ),
      ),

      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: BedBookingColors.textDarkMode,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: BedBookingColors.textDarkMode,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: BedBookingColors.textDarkMode,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: BedBookingColors.textGreyDark,
          fontSize: 14,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: BedBookingColors.textDarkMode,
      ),
    );
  }

  /// Helper to convert theme mode string to ThemeMode enum
  static ThemeMode themeModeFromString(String mode) {
    switch (mode.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
