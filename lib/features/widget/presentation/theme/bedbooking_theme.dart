import 'package:flutter/material.dart';

/// BedBooking color scheme matching screenshots
class BedBookingColors {
  // ============================================================================
  // LIGHT MODE COLORS
  // ============================================================================

  // Primary colors
  static const Color primaryGreen = Color(0xFF6EB64E);
  static const Color darkGreen = Color(0xFF5A9E3F);

  // Background colors
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGrey = Color(0xFFF5F5F5);

  // Border colors
  static const Color borderGrey = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFBDBDBD);

  // Text colors
  static const Color textDark = Color(0xFF212121);
  static const Color textGrey = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFA000);

  // Shadow
  static const Color shadowLight = Color(0x1A000000);

  // ============================================================================
  // DARK MODE COLORS
  // ============================================================================

  // Primary colors (brighter for dark bg)
  static const Color primaryGreenDark = Color(0xFF8BC34A);
  static const Color accentGreenDark = Color(0xFF9CCC65);

  // Background colors
  static const Color backgroundDark = Color(0xFF121212);
  static const Color backgroundDarkElevated = Color(0xFF1E1E1E);
  static const Color backgroundDarkCard = Color(0xFF2C2C2C);

  // Border colors (dark mode)
  static const Color borderDarkMode = Color(0xFF424242);
  static const Color borderDarkModeLight = Color(0xFF616161);

  // Text colors
  static const Color textDarkMode = Color(0xFFE0E0E0);
  static const Color textGreyDark = Color(0xFFBDBDBD);
  static const Color textLightDark = Color(0xFF757575);

  // Shadow (more prominent on dark)
  static const Color shadowDark = Color(0x40000000);
}

/// BedBooking button styles
class BedBookingButtons {
  /// Primary green button matching screenshots
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: BedBookingColors.primaryGreen,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

  /// Secondary outline button
  static ButtonStyle secondaryButton = OutlinedButton.styleFrom(
    foregroundColor: BedBookingColors.textDark,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
    side: const BorderSide(color: BedBookingColors.borderGrey),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

  /// Cancel/Back button (red outline)
  static ButtonStyle cancelButton = OutlinedButton.styleFrom(
    foregroundColor: BedBookingColors.error,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
    side: const BorderSide(color: BedBookingColors.error),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}

/// BedBooking card decoration
class BedBookingCards {
  /// White card with shadow
  static BoxDecoration cardDecoration = BoxDecoration(
    color: BedBookingColors.backgroundWhite,
    borderRadius: BorderRadius.circular(8),
    boxShadow: const [
      BoxShadow(
        color: BedBookingColors.shadowLight,
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  );

  /// Card with border only (no shadow)
  static BoxDecoration borderedCard = BoxDecoration(
    color: BedBookingColors.backgroundWhite,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: BedBookingColors.borderGrey),
  );

  /// Green highlighted card (selected state)
  static BoxDecoration selectedCard = BoxDecoration(
    color: BedBookingColors.backgroundWhite,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: BedBookingColors.primaryGreen, width: 2),
  );
}

/// Text styles matching BedBooking design
class BedBookingTextStyles {
  // Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: BedBookingColors.textDark,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: BedBookingColors.textDark,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: BedBookingColors.textDark,
  );

  // Body text
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: BedBookingColors.textDark,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: BedBookingColors.textDark,
  );

  static const TextStyle bodyGrey = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: BedBookingColors.textGrey,
  );

  // Small text
  static const TextStyle small = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: BedBookingColors.textGrey,
  );

  static const TextStyle smallBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: BedBookingColors.textDark,
  );

  // Price
  static const TextStyle price = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: BedBookingColors.textDark,
  );

  static const TextStyle priceSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: BedBookingColors.textGrey,
  );
}
