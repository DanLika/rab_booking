import 'package:flutter/widgets.dart';

/// Border design tokens for consistent borders across the widget
class BorderTokens {
  // Border width values
  static const double widthNone = 0.0;
  static const double widthThin = 1.0;
  static const double widthMedium = 1.5; // More pronounced than thin
  static const double widthThick = 2.0;

  // Border radius values
  static const double radiusSharp = 0.0;
  static const double radiusTiny = 2.0;    // Very small rounded corners
  static const double radiusSubtle = 4.0;
  static const double radiusSmall = 6.0;   // Slightly more rounded than subtle
  static const double radiusMedium = 8.0;
  static const double radiusRounded = 12.0;
  static const double radiusLarge = 16.0;  // Noticeably rounded corners
  static const double radiusXL = 20.0;     // Extra large rounded corners
  static const double radiusPill = 999.0;

  // Responsive border radius for calendar cells
  static const double calendarCellRadius = radiusSubtle;

  // Widget container border radius
  static const double widgetContainerRadius = radiusMedium;

  // Card border radius
  static const double cardRadius = radiusMedium;

  // Button border radius
  static const double buttonRadius = radiusMedium;

  // Input field border radius
  static const double inputRadius = radiusMedium;

  // BorderRadius helpers
  static BorderRadius circularSharp = BorderRadius.circular(radiusSharp);
  static BorderRadius circularTiny = BorderRadius.circular(radiusTiny);
  static BorderRadius circularSubtle = BorderRadius.circular(radiusSubtle);
  static BorderRadius circularSmall = BorderRadius.circular(radiusSmall);
  static BorderRadius circularMedium = BorderRadius.circular(radiusMedium);
  static BorderRadius circularRounded = BorderRadius.circular(radiusRounded);
  static BorderRadius circularLarge = BorderRadius.circular(radiusLarge);
  static BorderRadius circularXL = BorderRadius.circular(radiusXL);

  // Calendar cell border radius
  static BorderRadius calendarCell = BorderRadius.circular(calendarCellRadius);

  // Widget container border radius
  static BorderRadius widgetContainer = BorderRadius.circular(widgetContainerRadius);

  // Card border radius
  static BorderRadius card = BorderRadius.circular(cardRadius);

  // Button border radius
  static BorderRadius button = BorderRadius.circular(buttonRadius);

  // Input field border radius
  static BorderRadius input = BorderRadius.circular(inputRadius);
}
