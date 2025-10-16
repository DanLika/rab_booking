/// Application dimensions and spacing constants
/// Provides consistent spacing, sizing, and breakpoints across the app
class AppDimensions {
  AppDimensions._(); // Private constructor

  // ============================================================================
  // SPACING SCALE (based on 4px grid)
  // ============================================================================

  /// Extra extra small spacing (2px)
  static const double spaceXXS = 2.0;

  /// Extra small spacing (4px)
  static const double spaceXS = 4.0;

  /// Small spacing (8px)
  static const double spaceS = 8.0;

  /// Medium spacing (12px)
  static const double spaceM = 12.0;

  /// Large spacing (16px)
  static const double spaceL = 16.0;

  /// Extra large spacing (24px)
  static const double spaceXL = 24.0;

  /// Extra extra large spacing (32px)
  static const double spaceXXL = 32.0;

  /// Extra extra extra large spacing (48px)
  static const double spaceXXXL = 48.0;

  /// Huge spacing (64px)
  static const double spaceHuge = 64.0;

  // ============================================================================
  // BREAKPOINTS (for responsive design)
  // ============================================================================

  /// Mobile breakpoint (0-600px)
  static const double mobile = 600;

  /// Tablet breakpoint (601-1024px)
  static const double tablet = 1024;

  /// Desktop breakpoint (1025px+)
  static const double desktop = 1440;

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================

  /// Extra small radius (4px)
  static const double radiusXS = 4.0;

  /// Small radius (8px)
  static const double radiusS = 8.0;

  /// Medium radius (12px)
  static const double radiusM = 12.0;

  /// Large radius (16px)
  static const double radiusL = 16.0;

  /// Extra large radius (20px)
  static const double radiusXL = 20.0;

  /// Full/circular radius (999px)
  static const double radiusFull = 999.0;

  // ============================================================================
  // COMPONENT SIZES
  // ============================================================================

  /// Button height (default)
  static const double buttonHeight = 48.0;

  /// Button height (small)
  static const double buttonHeightSmall = 40.0;

  /// Button height (large)
  static const double buttonHeightLarge = 56.0;

  /// Input field height
  static const double inputHeight = 56.0;

  /// App bar height (standard)
  static const double appBarHeight = 56.0;

  /// Bottom navigation bar height
  static const double bottomNavHeight = 64.0;

  /// Icon size (small)
  static const double iconSizeS = 16.0;

  /// Icon size (medium)
  static const double iconSizeM = 24.0;

  /// Icon size (large)
  static const double iconSizeL = 32.0;

  /// Icon size (extra large)
  static const double iconSizeXL = 48.0;

  /// Avatar size (small)
  static const double avatarSizeS = 32.0;

  /// Avatar size (medium)
  static const double avatarSizeM = 48.0;

  /// Avatar size (large)
  static const double avatarSizeL = 64.0;

  /// Avatar size (extra large)
  static const double avatarSizeXL = 96.0;

  // ============================================================================
  // CARD & CONTAINER DIMENSIONS
  // ============================================================================

  /// Property card height (mobile)
  static const double propertyCardHeightMobile = 280.0;

  /// Property card height (desktop)
  static const double propertyCardHeightDesktop = 320.0;

  /// Property card image aspect ratio
  static const double propertyCardImageAspectRatio = 16 / 9;

  /// Hero section height (mobile)
  static const double heroHeightMobile = 400.0;

  /// Hero section height (tablet)
  static const double heroHeightTablet = 500.0;

  /// Hero section height (desktop)
  static const double heroHeightDesktop = 600.0;

  /// Max content width (for centered layouts on large screens)
  static const double maxContentWidth = 1280.0;

  /// Max dialog width
  static const double maxDialogWidth = 600.0;

  /// Max bottom sheet height
  static const double maxBottomSheetHeight = 0.9; // 90% of screen height

  // ============================================================================
  // ELEVATION (Material Design 3 style)
  // ============================================================================

  /// No elevation
  static const double elevation0 = 0.0;

  /// Level 1 elevation (cards, chips)
  static const double elevation1 = 1.0;

  /// Level 2 elevation (buttons, FAB)
  static const double elevation2 = 3.0;

  /// Level 3 elevation (app bar, bottom nav)
  static const double elevation3 = 6.0;

  /// Level 4 elevation (dialogs, modals)
  static const double elevation4 = 8.0;

  /// Level 5 elevation (popups, tooltips)
  static const double elevation5 = 12.0;

  // ============================================================================
  // GRID & LAYOUT
  // ============================================================================

  /// Grid column count (mobile)
  static const int gridColumnsMobile = 2;

  /// Grid column count (tablet)
  static const int gridColumnsTablet = 3;

  /// Grid column count (desktop)
  static const int gridColumnsDesktop = 4;

  /// Grid spacing
  static const double gridSpacing = 16.0;

  /// Section padding (mobile)
  static const double sectionPaddingMobile = 16.0;

  /// Section padding (tablet)
  static const double sectionPaddingTablet = 24.0;

  /// Section padding (desktop)
  static const double sectionPaddingDesktop = 32.0;

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================

  /// Fast animation (100ms)
  static const Duration animationFast = Duration(milliseconds: 100);

  /// Normal animation (200ms)
  static const Duration animationNormal = Duration(milliseconds: 200);

  /// Medium animation (300ms)
  static const Duration animationMedium = Duration(milliseconds: 300);

  /// Slow animation (500ms)
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get responsive spacing based on screen width
  static double getResponsiveSpacing(double width) {
    if (width < mobile) return spaceL;
    if (width < tablet) return spaceXL;
    return spaceXXL;
  }

  /// Get responsive card height
  static double getCardHeight(double width) {
    if (width < mobile) return propertyCardHeightMobile;
    return propertyCardHeightDesktop;
  }

  /// Get responsive grid columns
  static int getGridColumns(double width) {
    if (width < mobile) return gridColumnsMobile;
    if (width < tablet) return gridColumnsTablet;
    return gridColumnsDesktop;
  }

  /// Get hero height based on screen width
  static double getHeroHeight(double width) {
    if (width < mobile) return heroHeightMobile;
    if (width < tablet) return heroHeightTablet;
    return heroHeightDesktop;
  }

  /// Get section padding based on screen width
  static double getSectionPadding(double width) {
    if (width < mobile) return sectionPaddingMobile;
    if (width < tablet) return sectionPaddingTablet;
    return sectionPaddingDesktop;
  }
}
