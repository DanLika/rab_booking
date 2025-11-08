import 'package:flutter/material.dart';

/// Modern spacing system based on 8px grid
/// Ensures consistent spacing throughout the widget
class Spacing {
  Spacing._(); // Private constructor

  // ============================================================================
  // BASE UNIT: 8px
  // ============================================================================

  /// Base unit for spacing calculations (8px)
  static const double baseUnit = 8.0;

  // ============================================================================
  // SPACING SCALE
  // ============================================================================

  /// Extra small: 4px (0.5 unit) - Tight spacing, minimal gaps
  static const double xs = 4.0;

  /// Small: 8px (1 unit) - Close elements, subtle separation
  static const double sm = 8.0;

  /// Medium: 16px (2 units) - Standard gap between related elements
  static const double md = 16.0;

  /// Large: 24px (3 units) - Section spacing, card gaps
  static const double lg = 24.0;

  /// Extra large: 32px (4 units) - Major section dividers
  static const double xl = 32.0;

  /// 2X large: 48px (6 units) - Page-level spacing
  static const double xxl = 48.0;

  /// 3X large: 64px (8 units) - Hero sections, major breaks
  static const double xxxl = 64.0;

  // ============================================================================
  // COMPONENT-SPECIFIC SPACING
  // ============================================================================

  /// Button padding - Horizontal
  static const double buttonPaddingH = 24.0; // 3 units

  /// Button padding - Vertical (for 56px height buttons)
  static const double buttonPaddingV = 16.0; // 2 units

  /// Button padding - Horizontal (small buttons)
  static const double buttonPaddingHSmall = 16.0; // 2 units

  /// Button padding - Vertical (small buttons, 48px height)
  static const double buttonPaddingVSmall = 14.0;

  /// Card padding - All sides
  static const double cardPadding = 20.0; // 2.5 units (slightly off-grid for better visual)

  /// Card padding - Compact cards
  static const double cardPaddingCompact = 16.0; // 2 units

  /// Input field padding - Horizontal
  static const double inputPaddingH = 16.0; // 2 units

  /// Input field padding - Vertical
  static const double inputPaddingV = 14.0;

  /// Tooltip padding - Horizontal
  static const double tooltipPaddingH = 16.0;

  /// Tooltip padding - Vertical
  static const double tooltipPaddingV = 12.0;

  /// Calendar cell gap (between cells)
  static const double calendarCellGap = 0.0; // Cells share borders

  /// Calendar section spacing
  static const double calendarSectionGap = 16.0;

  // ============================================================================
  // LAYOUT SPACING
  // ============================================================================

  /// Container padding - Mobile
  static const double containerPaddingMobile = 16.0;

  /// Container padding - Tablet
  static const double containerPaddingTablet = 24.0;

  /// Container padding - Desktop
  static const double containerPaddingDesktop = 32.0;

  /// Section spacing - Mobile
  static const double sectionGapMobile = 24.0;

  /// Section spacing - Tablet
  static const double sectionGapTablet = 32.0;

  /// Section spacing - Desktop
  static const double sectionGapDesktop = 48.0;

  /// Gap between form fields
  static const double formFieldGap = 16.0;

  /// Gap between cards in a list
  static const double cardListGap = 16.0;

  // ============================================================================
  // INSETS (EdgeInsets shortcuts)
  // ============================================================================

  /// Zero inset
  static const EdgeInsets zero = EdgeInsets.zero;

  /// Extra small inset - 4px all sides
  static const EdgeInsets allXS = EdgeInsets.all(xs);

  /// Small inset - 8px all sides
  static const EdgeInsets allSM = EdgeInsets.all(sm);

  /// Medium inset - 16px all sides
  static const EdgeInsets allMD = EdgeInsets.all(md);

  /// Large inset - 24px all sides
  static const EdgeInsets allLG = EdgeInsets.all(lg);

  /// Extra large inset - 32px all sides
  static const EdgeInsets allXL = EdgeInsets.all(xl);

  /// Horizontal small - 8px left/right
  static const EdgeInsets horizontalSM = EdgeInsets.symmetric(horizontal: sm);

  /// Horizontal medium - 16px left/right
  static const EdgeInsets horizontalMD = EdgeInsets.symmetric(horizontal: md);

  /// Horizontal large - 24px left/right
  static const EdgeInsets horizontalLG = EdgeInsets.symmetric(horizontal: lg);

  /// Vertical small - 8px top/bottom
  static const EdgeInsets verticalSM = EdgeInsets.symmetric(vertical: sm);

  /// Vertical medium - 16px top/bottom
  static const EdgeInsets verticalMD = EdgeInsets.symmetric(vertical: md);

  /// Vertical large - 24px top/bottom
  static const EdgeInsets verticalLG = EdgeInsets.symmetric(vertical: lg);

  /// Button padding (24px horizontal, 16px vertical)
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: buttonPaddingH,
    vertical: buttonPaddingV,
  );

  /// Button padding small (16px horizontal, 14px vertical)
  static const EdgeInsets buttonSmall = EdgeInsets.symmetric(
    horizontal: buttonPaddingHSmall,
    vertical: buttonPaddingVSmall,
  );

  /// Card padding (20px all sides)
  static const EdgeInsets card = EdgeInsets.all(cardPadding);

  /// Card padding compact (16px all sides)
  static const EdgeInsets cardCompact = EdgeInsets.all(cardPaddingCompact);

  /// Input field padding (16px horizontal, 14px vertical)
  static const EdgeInsets input = EdgeInsets.symmetric(
    horizontal: inputPaddingH,
    vertical: inputPaddingV,
  );

  /// Tooltip padding (16px horizontal, 12px vertical)
  static const EdgeInsets tooltip = EdgeInsets.symmetric(
    horizontal: tooltipPaddingH,
    vertical: tooltipPaddingV,
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get responsive container padding based on screen width
  static double getContainerPadding(double screenWidth) {
    if (screenWidth < 768) return containerPaddingMobile;
    if (screenWidth < 1024) return containerPaddingTablet;
    return containerPaddingDesktop;
  }

  /// Get responsive section gap based on screen width
  static double getSectionGap(double screenWidth) {
    if (screenWidth < 768) return sectionGapMobile;
    if (screenWidth < 1024) return sectionGapTablet;
    return sectionGapDesktop;
  }

  /// Create custom EdgeInsets from spacing constants
  static EdgeInsets custom({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (all != null) {
      return EdgeInsets.all(all);
    }
    if (horizontal != null || vertical != null) {
      return EdgeInsets.symmetric(
        horizontal: horizontal ?? 0,
        vertical: vertical ?? 0,
      );
    }
    return EdgeInsets.only(
      left: left ?? 0,
      top: top ?? 0,
      right: right ?? 0,
      bottom: bottom ?? 0,
    );
  }

  /// Create SizedBox with vertical spacing
  static SizedBox vertical(double height) => SizedBox(height: height);

  /// Create SizedBox with horizontal spacing
  static SizedBox horizontal(double width) => SizedBox(width: width);

  /// Vertical spacing shortcuts
  static const SizedBox vXS = SizedBox(height: xs);
  static const SizedBox vSM = SizedBox(height: sm);
  static const SizedBox vMD = SizedBox(height: md);
  static const SizedBox vLG = SizedBox(height: lg);
  static const SizedBox vXL = SizedBox(height: xl);
  static const SizedBox vXXL = SizedBox(height: xxl);

  /// Horizontal spacing shortcuts
  static const SizedBox hXS = SizedBox(width: xs);
  static const SizedBox hSM = SizedBox(width: sm);
  static const SizedBox hMD = SizedBox(width: md);
  static const SizedBox hLG = SizedBox(width: lg);
  static const SizedBox hXL = SizedBox(width: xl);
  static const SizedBox hXXL = SizedBox(width: xxl);
}
