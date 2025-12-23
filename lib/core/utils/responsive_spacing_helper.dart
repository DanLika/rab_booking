import 'package:flutter/material.dart';

/// Screen type enum for responsive design
enum ScreenType {
  /// Landscape mobile - width > height && height < 500px
  landscapeMobile,

  /// Portrait mobile - width < 600px
  portraitMobile,

  /// Tablet - width 600-1199px
  tablet,

  /// Desktop - width >= 1200px
  desktop,
}

/// Page density type for different content requirements
enum PageDensity {
  /// Dense: Bookings, Calendar, Unit Hub - more data, need density
  /// Mobile: 12px, Tablet: 16px
  dense,

  /// Normal: Most pages - standard spacing
  /// Mobile: 16px, Tablet: 20px
  normal,

  /// Spacious: Auth pages - more breathing room
  /// Mobile: 24px, Tablet: 32px
  spacious,
}

/// Responsive breakpoint constants
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  // Width breakpoints
  static const double mobileMaxWidth = 600.0;
  static const double tabletMaxWidth = 1199.0;
  static const double desktopMinWidth = 1200.0;

  // Height breakpoints (critical for landscape)
  static const double landscapeMaxHeight = 500.0;

  // Very small screens
  static const double verySmallWidth = 400.0;
}

/// Responsive spacing helper - single source of truth for all spacing values
class ResponsiveSpacingHelper {
  ResponsiveSpacingHelper._();

  /// Detect screen type based on dimensions
  static ScreenType getScreenType(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // Landscape mobile - HIGHEST PRIORITY (smallest usable space)
    if (width > height && height < ResponsiveBreakpoints.landscapeMaxHeight) {
      return ScreenType.landscapeMobile;
    }

    // Portrait mobile
    if (width < ResponsiveBreakpoints.mobileMaxWidth) {
      return ScreenType.portraitMobile;
    }

    // Tablet
    if (width < ResponsiveBreakpoints.desktopMinWidth) {
      return ScreenType.tablet;
    }

    // Desktop
    return ScreenType.desktop;
  }

  /// Check if screen is in landscape mode on mobile
  static bool isLandscapeMobile(BuildContext context) {
    return getScreenType(context) == ScreenType.landscapeMobile;
  }

  /// Check if screen is very small (< 400px width)
  static bool isVerySmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width <
        ResponsiveBreakpoints.verySmallWidth;
  }

  /// Get page padding based on screen type and density
  static EdgeInsets getPagePadding(
    BuildContext context, {
    PageDensity density = PageDensity.normal,
  }) {
    final screenType = getScreenType(context);

    switch (density) {
      case PageDensity.dense:
        return _getDensePadding(screenType);
      case PageDensity.normal:
        return _getNormalPadding(screenType);
      case PageDensity.spacious:
        return _getSpaciousPadding(screenType);
    }
  }

  /// Dense padding - for data-heavy pages (Bookings, Calendar, Unit Hub)
  static EdgeInsets _getDensePadding(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.landscapeMobile:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case ScreenType.portraitMobile:
        return const EdgeInsets.all(12);
      case ScreenType.tablet:
        return const EdgeInsets.all(16);
      case ScreenType.desktop:
        return const EdgeInsets.all(20);
    }
  }

  /// Normal padding - for most pages
  static EdgeInsets _getNormalPadding(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.landscapeMobile:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ScreenType.portraitMobile:
        return const EdgeInsets.all(16);
      case ScreenType.tablet:
        return const EdgeInsets.all(20);
      case ScreenType.desktop:
        return const EdgeInsets.all(24);
    }
  }

  /// Spacious padding - for auth pages, forms with focus
  static EdgeInsets _getSpaciousPadding(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.landscapeMobile:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case ScreenType.portraitMobile:
        return const EdgeInsets.all(24);
      case ScreenType.tablet:
        return const EdgeInsets.all(32);
      case ScreenType.desktop:
        return const EdgeInsets.all(40);
    }
  }

  /// Get dialog content padding
  static EdgeInsets getDialogPadding(BuildContext context) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.landscapeMobile:
        return const EdgeInsets.all(12);
      case ScreenType.portraitMobile:
        return const EdgeInsets.all(16);
      case ScreenType.tablet:
      case ScreenType.desktop:
        return const EdgeInsets.all(20);
    }
  }

  /// Get dialog max height as percentage of screen
  static double getDialogMaxHeightPercent(BuildContext context) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.landscapeMobile:
        return 0.85; // More restrictive on landscape
      case ScreenType.portraitMobile:
      case ScreenType.tablet:
      case ScreenType.desktop:
        return 0.9;
    }
  }

  /// Get bottom sheet max height as percentage of screen
  static double getBottomSheetMaxHeightPercent(BuildContext context) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.landscapeMobile:
        return 0.8;
      case ScreenType.portraitMobile:
        return 0.7;
      case ScreenType.tablet:
      case ScreenType.desktop:
        return 0.6;
    }
  }

  /// Get bottom navigation bar padding
  static EdgeInsets getBottomBarPadding(BuildContext context) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.landscapeMobile:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ScreenType.portraitMobile:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
      case ScreenType.tablet:
      case ScreenType.desktop:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  /// Get button vertical padding
  static double getButtonVerticalPadding(BuildContext context) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.landscapeMobile:
        return 8;
      case ScreenType.portraitMobile:
        return 12;
      case ScreenType.tablet:
      case ScreenType.desktop:
        return 14;
    }
  }

  /// Get card padding
  static EdgeInsets getCardPadding(BuildContext context) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.landscapeMobile:
        return const EdgeInsets.all(10);
      case ScreenType.portraitMobile:
        return const EdgeInsets.all(12);
      case ScreenType.tablet:
        return const EdgeInsets.all(16);
      case ScreenType.desktop:
        return const EdgeInsets.all(20);
    }
  }

  /// Get section spacing (between sections on a page)
  static double getSectionSpacing(BuildContext context) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.landscapeMobile:
        return 12;
      case ScreenType.portraitMobile:
        return 16;
      case ScreenType.tablet:
        return 20;
      case ScreenType.desktop:
        return 24;
    }
  }

  /// Get header padding for dialogs/bottom sheets
  static EdgeInsets getHeaderPadding(BuildContext context) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.landscapeMobile:
        return const EdgeInsets.fromLTRB(16, 12, 16, 12);
      case ScreenType.portraitMobile:
        return const EdgeInsets.fromLTRB(20, 16, 20, 16);
      case ScreenType.tablet:
      case ScreenType.desktop:
        return const EdgeInsets.fromLTRB(24, 20, 24, 16);
    }
  }

  /// Get footer padding for dialogs
  static EdgeInsets getFooterPadding(BuildContext context) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.landscapeMobile:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
      case ScreenType.portraitMobile:
        return const EdgeInsets.all(16);
      case ScreenType.tablet:
      case ScreenType.desktop:
        return const EdgeInsets.all(20);
    }
  }

  /// Get dialog header height constraints
  /// Returns (minHeight, maxHeight) - null means unconstrained
  /// - Landscape mobile: compact (40-56px) - minimal space, single line
  /// - Portrait mobile: flexible (48-80px) - allow 2 lines
  /// - Tablet/Desktop: comfortable (56-80px)
  static ({double? minHeight, double? maxHeight}) getDialogHeaderConstraints(
    BuildContext context,
  ) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.landscapeMobile:
        return (minHeight: 40, maxHeight: 56);
      case ScreenType.portraitMobile:
        return (minHeight: 48, maxHeight: 80);
      case ScreenType.tablet:
      case ScreenType.desktop:
        return (minHeight: 56, maxHeight: 80);
    }
  }

  /// Get dialog footer height constraints
  /// Returns (minHeight, maxHeight) - null means unconstrained
  /// - Landscape mobile: compact (36-48px) - minimal space
  /// - Portrait mobile: flexible (44-64px)
  /// - Tablet/Desktop: comfortable (48-72px)
  static ({double? minHeight, double? maxHeight}) getDialogFooterConstraints(
    BuildContext context,
  ) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.landscapeMobile:
        return (minHeight: 36, maxHeight: 48);
      case ScreenType.portraitMobile:
        return (minHeight: 44, maxHeight: 64);
      case ScreenType.tablet:
      case ScreenType.desktop:
        return (minHeight: 48, maxHeight: 72);
    }
  }

  /// Get dialog icon size
  /// - Landscape mobile: 18px - compact
  /// - Portrait mobile: 20px
  /// - Tablet/Desktop: 24px
  static double getDialogIconSize(BuildContext context) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.landscapeMobile:
        return 18;
      case ScreenType.portraitMobile:
        return 20;
      case ScreenType.tablet:
      case ScreenType.desktop:
        return 24;
    }
  }

  /// Get dialog title font size
  /// - Landscape mobile: 14px - compact
  /// - Portrait mobile: 16px
  /// - Tablet/Desktop: 18px
  static double getDialogTitleFontSize(BuildContext context) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.landscapeMobile:
        return 14;
      case ScreenType.portraitMobile:
        return 16;
      case ScreenType.tablet:
      case ScreenType.desktop:
        return 18;
    }
  }

  /// Get max lines for dialog title
  /// - Landscape mobile: 1 - must be single line
  /// - Portrait mobile: 2 - can wrap
  /// - Tablet/Desktop: 2
  static int getDialogTitleMaxLines(BuildContext context) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.landscapeMobile:
        return 1;
      case ScreenType.portraitMobile:
      case ScreenType.tablet:
      case ScreenType.desktop:
        return 2;
    }
  }
}
