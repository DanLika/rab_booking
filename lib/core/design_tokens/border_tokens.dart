import 'package:flutter/widgets.dart';

/// Border design tokens for consistent borders across the app
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: BorderTokens.circularMedium,
///     border: Border.all(width: BorderTokens.widthThin),
///   ),
/// )
/// ```
class BorderTokens {
  // Prevent instantiation
  BorderTokens._();

  // ============================================================
  // BORDER WIDTH VALUES
  // ============================================================
  static const double widthNone = 0.0;
  static const double widthThin = 1.0;
  static const double widthMedium = 1.5; // More pronounced than thin
  static const double widthThick = 2.0;

  // ============================================================
  // BORDER RADIUS VALUES
  // ============================================================
  static const double radiusSharp = 0.0;
  static const double radiusTiny = 2.0; // Very small rounded corners
  static const double radiusSubtle = 4.0;
  static const double radiusSmall = 6.0; // Slightly more rounded than subtle
  static const double radiusMedium = 8.0;
  static const double radiusRounded = 12.0;
  static const double radiusLarge = 16.0; // Noticeably rounded corners
  static const double radiusXL = 20.0; // Extra large rounded corners
  static const double radiusPill = 999.0;

  // Responsive border radius for calendar cells
  static const double calendarCellRadius = radiusSubtle;

  // Widget container border radius
  static const double widgetContainerRadius = radiusMedium;

  // Card border radius
  static const double cardRadius = radiusMedium;

  // Button border radius
  static const double buttonRadius = radiusMedium;

  /// Input field border radius
  static const double inputRadius = radiusMedium;

  // ============================================================
  // BORDER RADIUS HELPERS
  // ============================================================

  static final BorderRadius circularSharp = BorderRadius.circular(radiusSharp);
  static final BorderRadius circularTiny = BorderRadius.circular(radiusTiny);
  static final BorderRadius circularSubtle = BorderRadius.circular(
    radiusSubtle,
  );
  static final BorderRadius circularSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius circularMedium = BorderRadius.circular(
    radiusMedium,
  );
  static final BorderRadius circularRounded = BorderRadius.circular(
    radiusRounded,
  );
  static final BorderRadius circularLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius circularXL = BorderRadius.circular(radiusXL);

  // ============================================================
  // COMPONENT-SPECIFIC HELPERS
  // ============================================================

  static final BorderRadius calendarCell = BorderRadius.circular(
    calendarCellRadius,
  );
  static final BorderRadius widgetContainer = BorderRadius.circular(
    widgetContainerRadius,
  );
  static final BorderRadius card = BorderRadius.circular(cardRadius);
  static final BorderRadius button = BorderRadius.circular(buttonRadius);
  static final BorderRadius input = BorderRadius.circular(inputRadius);

  // ============================================================
  // SAFE BORDER RADIUS HELPERS (prevents null check errors)
  // ============================================================

  /// Safely create BorderRadius.only with explicit zero values for unspecified corners
  /// This prevents null check operator errors in Flutter's internal code
  static BorderRadius only({
    Radius? topLeft,
    Radius? topRight,
    Radius? bottomLeft,
    Radius? bottomRight,
  }) {
    // Ensure all corners are explicitly set (use Radius.zero if not specified)
    // This prevents Flutter from accessing null values internally
    return BorderRadius.only(
      topLeft: topLeft ?? Radius.zero,
      topRight: topRight ?? Radius.zero,
      bottomLeft: bottomLeft ?? Radius.zero,
      bottomRight: bottomRight ?? Radius.zero,
    );
  }

  /// Safely create BorderRadius.only with a single corner specified
  static BorderRadius onlyTopLeft(double radius) {
    return only(topLeft: Radius.circular(radius));
  }

  /// Safely create BorderRadius.only with top-right corner specified
  static BorderRadius onlyTopRight(double radius) {
    return only(topRight: Radius.circular(radius));
  }

  /// Safely create BorderRadius.only with bottom-left corner specified
  static BorderRadius onlyBottomLeft(double radius) {
    return only(bottomLeft: Radius.circular(radius));
  }

  /// Safely create BorderRadius.only with bottom-right corner specified
  static BorderRadius onlyBottomRight(double radius) {
    return only(bottomRight: Radius.circular(radius));
  }

  /// Safely create BorderRadius.only with top corners specified
  static BorderRadius onlyTop(double radius) {
    return only(
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );
  }

  /// Safely create BorderRadius.only with bottom corners specified
  static BorderRadius onlyBottom(double radius) {
    return only(
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
  }
}
