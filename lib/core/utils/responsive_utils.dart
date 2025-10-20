import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

/// Responsive utilities for adaptive UI based on screen size
///
/// Provides helpers for:
/// - Device type detection (mobile/tablet/desktop)
/// - Responsive values based on screen size
/// - Adaptive padding, margins, and spacing
/// - Orientation detection
class ResponsiveUtils {
  ResponsiveUtils._(); // Private constructor

  // ============================================================================
  // DEVICE TYPE DETECTION
  // ============================================================================

  /// Check if current device is mobile (width < 600px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < AppDimensions.mobile;
  }

  /// Check if current device is tablet (width 600-1024px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppDimensions.mobile && width < AppDimensions.tablet;
  }

  /// Check if current device is desktop (width >= 1024px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppDimensions.tablet;
  }

  /// Check if current device is large desktop (width >= 1440px)
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppDimensions.desktop;
  }

  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // ============================================================================
  // RESPONSIVE VALUES
  // ============================================================================

  /// Get responsive value based on device type
  ///
  /// Example:
  /// ```dart
  /// final fontSize = ResponsiveUtils.value(
  ///   context,
  ///   mobile: 14.0,
  ///   tablet: 16.0,
  ///   desktop: 18.0,
  /// );
  /// ```
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  /// Get responsive value with additional large desktop support
  static T valueWith<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    if (isLargeDesktop(context)) {
      return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  // ============================================================================
  // SPACING
  // ============================================================================

  /// Get responsive horizontal padding
  ///
  /// Mobile: 16px, Tablet: 24px, Desktop: 32px, Ultra-wide: 48px
  static double getHorizontalPadding(BuildContext context) {
    return valueWith(
      context,
      mobile: AppDimensions.spaceS,     // 16px
      tablet: AppDimensions.spaceM,     // 24px
      desktop: AppDimensions.spaceL,    // 32px
      largeDesktop: AppDimensions.spaceXL, // 48px - for ultra-wide screens
    );
  }

  /// Get responsive vertical padding
  ///
  /// Mobile: 16px, Tablet: 24px, Desktop: 32px
  static double getVerticalPadding(BuildContext context) {
    return value(
      context,
      mobile: AppDimensions.spaceS,
      tablet: AppDimensions.spaceM,
      desktop: AppDimensions.spaceL,
    );
  }

  /// Get responsive screen padding (EdgeInsets)
  static EdgeInsets getScreenPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getHorizontalPadding(context),
      vertical: getVerticalPadding(context),
    );
  }

  /// Get responsive spacing between elements
  ///
  /// Mobile: 8px, Tablet: 12px, Desktop: 16px
  static double getSpacing(BuildContext context) {
    return value(
      context,
      mobile: AppDimensions.spaceXS,
      tablet: 12.0,
      desktop: AppDimensions.spaceS,
    );
  }

  /// Get responsive section spacing
  ///
  /// Mobile: 24px, Tablet: 32px, Desktop: 48px
  static double getSectionSpacing(BuildContext context) {
    return value(
      context,
      mobile: AppDimensions.spaceM,
      tablet: AppDimensions.spaceL,
      desktop: AppDimensions.spaceXL,
    );
  }

  // ============================================================================
  // GRID/COLUMNS
  // ============================================================================

  /// Get responsive grid column count
  ///
  /// Mobile: 1-2, Tablet: 2-3, Desktop: 3-4
  static int getGridColumns(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 3}) {
    return value(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive max width for content
  ///
  /// Mobile: full width, Tablet: 90%, Desktop: 1280px max
  static double getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) {
      return AppDimensions.maxContentWidth;
    }
    return MediaQuery.of(context).size.width;
  }

  // ============================================================================
  // TYPOGRAPHY
  // ============================================================================

  /// Get responsive font size scale factor
  ///
  /// Mobile: 0.9, Tablet: 1.0, Desktop: 1.1
  static double getFontScale(BuildContext context) {
    return value(
      context,
      mobile: 0.9,
      tablet: 1.0,
      desktop: 1.1,
    );
  }

  /// Scale font size based on device
  static double scaledFontSize(BuildContext context, double baseSize) {
    return baseSize * getFontScale(context);
  }

  // ============================================================================
  // LAYOUT HELPERS
  // ============================================================================

  /// Get responsive card width
  static double getCardWidth(BuildContext context) {
    return value(
      context,
      mobile: MediaQuery.of(context).size.width - 32,
      tablet: 350.0,
      desktop: 400.0,
    );
  }

  /// Get responsive dialog width
  static double getDialogWidth(BuildContext context) {
    return value(
      context,
      mobile: MediaQuery.of(context).size.width * 0.9,
      tablet: 500.0,
      desktop: AppDimensions.maxDialogWidth,
    );
  }

  /// Get responsive bottom sheet max height
  static double getBottomSheetMaxHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * AppDimensions.maxBottomSheetHeight;
  }

  // ============================================================================
  // SAFE AREA
  // ============================================================================

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get safe area top padding
  static double getSafeAreaTop(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// Get safe area bottom padding
  static double getSafeAreaBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  // ============================================================================
  // SCREEN SIZE
  // ============================================================================

  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get screen size
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  // ============================================================================
  // ADAPTIVE WIDGETS
  // ============================================================================

  /// Build different widget based on device type
  ///
  /// Example:
  /// ```dart
  /// ResponsiveUtils.adaptive(
  ///   context,
  ///   mobile: MobileLayout(),
  ///   tablet: TabletLayout(),
  ///   desktop: DesktopLayout(),
  /// )
  /// ```
  static Widget adaptive(
    BuildContext context, {
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  /// Build widget with orientation-specific layout
  static Widget orientation(
    BuildContext context, {
    required Widget portrait,
    required Widget landscape,
  }) {
    return isLandscape(context) ? landscape : portrait;
  }
}

/// Extension on BuildContext for easier responsive utilities access
extension ResponsiveContext on BuildContext {
  /// Check if mobile
  bool get isMobile => ResponsiveUtils.isMobile(this);

  /// Check if tablet
  bool get isTablet => ResponsiveUtils.isTablet(this);

  /// Check if desktop
  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  /// Check if landscape
  bool get isLandscape => ResponsiveUtils.isLandscape(this);

  /// Get responsive horizontal padding
  double get horizontalPadding => ResponsiveUtils.getHorizontalPadding(this);

  /// Get responsive vertical padding
  double get verticalPadding => ResponsiveUtils.getVerticalPadding(this);

  /// Get responsive screen padding
  EdgeInsets get screenPadding => ResponsiveUtils.getScreenPadding(this);

  /// Get responsive spacing
  double get spacing => ResponsiveUtils.getSpacing(this);

  /// Get responsive section spacing
  double get sectionSpacing => ResponsiveUtils.getSectionSpacing(this);

  /// Get screen width
  double get screenWidth => ResponsiveUtils.getScreenWidth(this);

  /// Get screen height
  double get screenHeight => ResponsiveUtils.getScreenHeight(this);

  /// Get screen size
  Size get screenSize => ResponsiveUtils.getScreenSize(this);
}
