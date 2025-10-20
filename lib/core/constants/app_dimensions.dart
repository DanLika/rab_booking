/// Application dimensions and spacing constants
/// Provides consistent spacing, sizing, and breakpoints across the app
class AppDimensions {
  AppDimensions._(); // Private constructor

  // ============================================================================
  // SPACING SCALE (based on 8px grid system)
  // ============================================================================

  /// Base spacing unit - 8px (all spacing should be multiples of this)
  static const double baseUnit = 8.0;

  /// XXS spacing: 4px (0.5 × base unit)
  static const double spaceXXS = 4.0;

  /// XS spacing: 8px (1 × base unit)
  static const double spaceXS = 8.0;

  /// S spacing: 16px (2 × base unit)
  static const double spaceS = 16.0;

  /// M spacing: 24px (3 × base unit)
  static const double spaceM = 24.0;

  /// L spacing: 32px (4 × base unit)
  static const double spaceL = 32.0;

  /// XL spacing: 48px (6 × base unit)
  static const double spaceXL = 48.0;

  /// XXL spacing: 64px (8 × base unit)
  static const double spaceXXL = 64.0;

  /// XXXL spacing: 96px (12 × base unit)
  static const double spaceXXXL = 96.0;

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
  // BORDER RADIUS (Modern, premium values)
  // ============================================================================

  /// Extra small radius (6px) - For micro elements, badges
  static const double radiusXS = 6.0;

  /// Small radius (12px) - For buttons, inputs, chips
  static const double radiusS = 12.0;

  /// Medium radius (20px) - For cards, modals, panels
  static const double radiusM = 20.0;

  /// Large radius (24px) - For hero sections, featured cards
  static const double radiusL = 24.0;

  /// Extra large radius (32px) - For premium elements, images
  static const double radiusXL = 32.0;

  /// Full/circular radius (999px) - For pills, avatars
  static const double radiusFull = 999.0;

  // ============================================================================
  // BORDER WIDTHS
  // ============================================================================

  /// Default border width (1px)
  static const double borderWidth = 1.0;

  /// Focused border width (2px)
  static const double borderWidthFocus = 2.0;

  /// Thick border width (3px)
  static const double borderWidthThick = 3.0;

  // ============================================================================
  // COMPONENT SIZES
  // ============================================================================

  /// Button height (default) - 48px
  static const double buttonHeight = 48.0;

  /// Button height (small) - 40px
  static const double buttonHeightSmall = 40.0;

  /// Button height (large) - 56px
  static const double buttonHeightLarge = 56.0;

  /// Input field height - 48px
  static const double inputHeight = 48.0;

  /// App bar height - 64px
  static const double appBarHeight = 64.0;

  /// Bottom navigation bar height - 64px
  static const double bottomNavHeight = 64.0;

  /// Icon size (small)
  static const double iconSizeS = 16.0;

  /// Icon size (medium)
  static const double iconSizeM = 24.0;

  /// Icon size (large)
  static const double iconSizeL = 32.0;

  /// Icon size (extra large)
  static const double iconSizeXL = 48.0;

  // Icon size aliases (shorter names for convenience)
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

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
  // 12-COLUMN GRID SYSTEM
  // ============================================================================

  /// Total number of grid columns (standard 12-column grid)
  static const int gridColumns = 12;

  /// Grid gutter size (mobile) - 16px
  static const double gridGutterMobile = spaceS;

  /// Grid gutter size (tablet) - 24px
  static const double gridGutterTablet = spaceM;

  /// Grid gutter size (desktop) - 32px
  static const double gridGutterDesktop = spaceL;

  /// Grid margin (mobile) - 16px
  static const double gridMarginMobile = spaceS;

  /// Grid margin (tablet) - 24px
  static const double gridMarginTablet = spaceM;

  /// Grid margin (desktop) - 48px
  static const double gridMarginDesktop = spaceXL;

  // ============================================================================
  // CONTAINER MAX-WIDTHS (responsive containers)
  // ============================================================================

  /// Small container max-width (forms, narrow content)
  static const double containerXS = 480.0;

  /// Medium container max-width (content sections)
  static const double containerS = 640.0;

  /// Default container max-width (main content)
  static const double containerM = 768.0;

  /// Large container max-width (wide layouts)
  static const double containerL = 1024.0;

  /// Extra large container max-width (full-width sections)
  static const double containerXL = 1280.0;

  /// Maximum container max-width (ultra-wide screens)
  static const double containerXXL = 1536.0;

  // ============================================================================
  // SECTION PADDING SCALES (responsive section spacing)
  // ============================================================================

  /// Section padding (mobile) - compact: 32px vertical, 16px horizontal
  static const double sectionPaddingVerticalMobile = spaceL;
  static const double sectionPaddingHorizontalMobile = spaceS;

  /// Section padding (tablet) - medium: 48px vertical, 32px horizontal
  static const double sectionPaddingVerticalTablet = spaceXL;
  static const double sectionPaddingHorizontalTablet = spaceL;

  /// Section padding (desktop) - dramatic: 80px vertical, 48px horizontal
  static const double sectionPaddingVerticalDesktop = 80.0;
  static const double sectionPaddingHorizontalDesktop = spaceXL;

  /// Section padding (large desktop) - extra dramatic: 120px vertical, 64px horizontal
  static const double sectionPaddingVerticalLarge = 120.0;
  static const double sectionPaddingHorizontalLarge = spaceXXL;

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
